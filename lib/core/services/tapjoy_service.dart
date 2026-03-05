import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart' as plugin;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'storage_service.dart';

class TapjoyService {
  static const String sdkKey = 'Z9Y4_msqSmGbgZLCWzsPogECs9zdQNwI88Y6MOAqjPxyCKIJle9HYmysHYoc';
  static const platform = MethodChannel('tapjoy_offerwall');
  
  static bool _isConnected = false;
  static bool _isContentAvailable = false;
  static plugin.TJPlacement? _offerwallPlacement;
  
  // Callbacks
  static Function(String? currency, int amount)? onRewardEarned;
  static Function()? onOfferwallShown;
  static Function()? onOfferwallDismissed;

  static bool get isConnected => _isConnected;
  static bool get isContentAvailable => _isContentAvailable;
  
  /// Check if offerwall content is ready to be shown
  static Future<bool> checkContentReady() async {
    if (Platform.isAndroid) {
      try {
        final bool isReady = await platform.invokeMethod('isContentReady') ?? false;
        return isReady;
      } catch (e) {
        if (kDebugMode) print("Error checking content ready: $e");
        return false;
      }
    }
    
    if (_offerwallPlacement == null) return false;
    try {
      return await _offerwallPlacement!.isContentReady();
    } catch (e) {
      if (kDebugMode) print("Error checking content ready: $e");
      return false;
    }
  }

  static Future<void> init() async {
    if (Platform.isAndroid) {
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onRewardEarned') {
          final currency = call.arguments['currency'] as String?;
          final amount = call.arguments['amount'] as int? ?? 0;
          if (kDebugMode) {
            print('Reward Earned on Android: $amount $currency');
          }
          // Trigger callback if set
          if (onRewardEarned != null) {
            onRewardEarned!(currency, amount);
          }
        }
      });
      
      // Set User ID for Android Native
      String? userId = await StorageService.getMobileNumber() ?? await StorageService.getDeviceId();
      if (userId != null) {
        await platform.invokeMethod('setUserID', {'userId': userId});
        if (kDebugMode) print('Tapjoy Native UserID set: $userId');
      }
      // Native Android handles connection in MainActivity.onStart
      _isConnected = true; 
      return;
    }

    try {
      if (Platform.isIOS) {
        final status = await AppTrackingTransparency.requestTrackingAuthorization();
        if (kDebugMode) {
          print('App Tracking Transparency status: $status');
        }
      }

      final Map<String, dynamic> optionFlags = {};
      
      await plugin.Tapjoy.connect(
        sdkKey: sdkKey,
        options: optionFlags,
        onConnectSuccess: () async {
          _isConnected = true;
          if (kDebugMode) {
            print('Tapjoy connected successfully');
          }
          
          // Set User ID for tracking rewards
          String? userId = await StorageService.getMobileNumber() ?? await StorageService.getDeviceId();
          if (userId != null) {
            await plugin.Tapjoy.setUserID(userId: userId);
          }
          
          _prepareOfferwallPlugin();
        },
        onConnectFailure: (int code, String? error) async {
          _isConnected = false;
          if (kDebugMode) {
            print('Tapjoy connect failed: $error (code: $code)');
          }
        },
        onConnectWarning: (int code, String? warning) async {
          if (kDebugMode) {
            print('Tapjoy connect warning: $warning (code: $code)');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Tapjoy: $e');
      }
    }
  }

  static Future<void> _prepareOfferwallPlugin() async {
    if (!_isConnected || Platform.isAndroid) return;
    
    try {
      _offerwallPlacement = await plugin.Tapjoy.getPlacement(
        placementName: 'offerwall_main', // Matches Dashboard configuration
        onRequestSuccess: (placement) {
          if (kDebugMode) print('Tapjoy placement request success');
        },
        onRequestFailure: (placement, error) {
          if (kDebugMode) print('Tapjoy placement request failure: $error');
          _isContentAvailable = false;
        },
        onContentReady: (placement) {
          if (kDebugMode) print('Tapjoy placement content ready');
          _isContentAvailable = true;
        },
        onContentShow: (placement) {
          if (kDebugMode) print('Tapjoy placement content show');
          _isContentAvailable = true;
          // Trigger callback if set
          if (onOfferwallShown != null) {
            onOfferwallShown!();
          }
        },
        onContentDismiss: (placement) {
          if (kDebugMode) print('Tapjoy placement content dismiss');
          _isContentAvailable = false;
          // Trigger callback if set
          if (onOfferwallDismissed != null) {
            onOfferwallDismissed!();
          }
          // Reload content for next time
          placement.requestContent();
        },
      );
      
      _offerwallPlacement?.requestContent();
    } catch (e) {
      if (kDebugMode) print('Error preparing Tapjoy placement: $e');
    }
  }

  static Future<bool> showOfferwall({int maxWaitSeconds = 10}) async {
    if (Platform.isAndroid) {
      try {
        if (kDebugMode) print('Requesting Native Offerwall to show...');
        
        // First, ensure placement is prepared
        await platform.invokeMethod('prepareOfferwall');
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Wait for content to be ready with timeout
        int waited = 0;
        while (waited < maxWaitSeconds * 10) {
          // Check if content is ready now
          final bool isReady = await platform.invokeMethod('isContentReady') ?? false;
          
          if (isReady) {
            // Content is ready, try to show
            final bool showed = await platform.invokeMethod('showOfferwall');
            if (showed) {
              if (kDebugMode) print('Native showOfferwall result: true - Content shown successfully');
              return true;
            } else {
              if (kDebugMode) print('Content ready but showOfferwall returned false, waiting a bit more...');
              await Future.delayed(const Duration(milliseconds: 300));
            }
          } else {
            if (kDebugMode && waited % 10 == 0) {
              print('Waiting for content to be ready... (${waited / 10}s)');
            }
          }
          
          // Wait a bit before checking again
          await Future.delayed(const Duration(milliseconds: 100));
          waited++;
        }
        
        // Final check - maybe content became ready
        final bool isReady = await platform.invokeMethod('isContentReady') ?? false;
        if (isReady) {
          final bool showed = await platform.invokeMethod('showOfferwall');
          if (showed) {
            if (kDebugMode) print('Native showOfferwall result: true - Shown on final check');
            return true;
          }
        }
        
        if (kDebugMode) {
          print('No premium offers available right now after waiting $maxWaitSeconds seconds');
        }
        return false;
      } catch (e) {
        if (kDebugMode) print("Native Channel Error: $e");
        return false;
      }
    }

    if (!_isConnected || _offerwallPlacement == null) {
      if (kDebugMode) print('Tapjoy not connected or placement null');
      if (!_isConnected) await init();
      return false;
    }

    try {
      // Wait for content to be ready with timeout
      int waited = 0;
      while (waited < maxWaitSeconds * 10) {
        if (await _offerwallPlacement!.isContentReady()) {
          await _offerwallPlacement!.showContent();
          if (kDebugMode) print('Offerwall content shown successfully');
          return true;
        }
        
        // Wait a bit before checking again
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }
      
      // If not ready, request content and return false
      if (kDebugMode) print('Offerwall content not ready after waiting, requesting...');
      await _offerwallPlacement!.requestContent();
      return false;
    } catch (e) {
      if (kDebugMode) print('Error showing Tapjoy Offerwall: $e');
      return false;
    }
  }
}
