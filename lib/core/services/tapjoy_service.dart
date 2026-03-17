import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart' as plugin;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'storage_service.dart';

class TapjoyService {
  // Tapjoy API Credentials
  static const String appId = '67d638fe-6b2a-4a61-9b81-92c25b3b0fa2';
  static const String sdkKey = 'Z9Y4_msqSmGbgZLCWzsPogECs9zdQNwI88Y6MOAqjPxyCKIJle9HYmysHYoc';
  static const String placement = 'offerwall_card';
  
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
  
  /// Simple method to show offerwall (matches the pattern from requirements)
  /// This is a cleaner wrapper that ensures proper initialization
  static Future<void> showOfferwallSimple() async {
    try {
      // Ensure initialized
      if (!_isConnected) {
        await init();
        await Future.delayed(const Duration(milliseconds: 2000));
      }
      
      // Request content first
      if (Platform.isAndroid) {
        await platform.invokeMethod('prepareOfferwall');
        await Future.delayed(const Duration(milliseconds: 2000));
      } else if (Platform.isIOS && _offerwallPlacement != null) {
        _offerwallPlacement!.requestContent();
        await Future.delayed(const Duration(milliseconds: 2000));
      }
      
      // Check if ready
      bool isReady = await checkContentReady();
      
      if (isReady) {
        // Show offerwall
        await showOfferwall();
        if (kDebugMode) print('Tapjoy: Offerwall Opened ✅');
      } else {
        if (kDebugMode) print('Tapjoy: Offerwall not ready ❌');
      }
    } catch (e) {
      if (kDebugMode) print('Tapjoy: Error showing offerwall: $e');
    }
  }
  
  /// Check if offerwall content is ready to be shown
  static Future<bool> checkContentReady() async {
    if (Platform.isAndroid) {
      try {
        final bool isReady = await platform.invokeMethod('isContentReady') ?? false;
        return isReady;
      } catch (e) {
        if (kDebugMode) print("Tapjoy: Error checking content ready: $e");
        return false;
      }
    }
    
    if (_offerwallPlacement == null) return false;
    try {
      return await _offerwallPlacement!.isContentReady();
    } catch (e) {
      if (kDebugMode) print("Tapjoy: Error checking content ready: $e");
      return false;
    }
  }

  static Future<void> setUserID(String userId) async {
    if (userId.isEmpty) return;
    
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('setUserID', {'userId': userId});
        if (kDebugMode) print('Tapjoy: UserID set: $userId');
      } catch (e) {
        if (kDebugMode) print('Tapjoy: Could not set UserID: $e');
      }
    } else if (Platform.isIOS) {
      try {
        await plugin.Tapjoy.setUserID(userId: userId);
        if (kDebugMode) print('Tapjoy: UserID set: $userId (iOS)');
      } catch (e) {
        if (kDebugMode) print('Tapjoy: Could not set UserID: $e (iOS)');
      }
    }
  }

  static Future<void> init() async {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        print('Tapjoy: Initializing for Android');
        print('Tapjoy: Native SDK will connect in MainActivity.onStart()');
      }
      
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onRewardEarned') {
          final currency = call.arguments['currency'] as String?;
          final amount = call.arguments['amount'] as int? ?? 0;
          if (kDebugMode) {
            print('Tapjoy: Reward Earned: $amount $currency');
          }
          if (onRewardEarned != null) {
            onRewardEarned!(currency, amount);
          }
        }
      });
      
      // Wait for native connection
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Set User ID if available
      String? userId = await StorageService.getMobileNumber() ?? await StorageService.getDeviceId();
      if (userId != null && userId.isNotEmpty) {
        await setUserID(userId);
      }
      
      _isConnected = true;
      return;
    }

    // iOS implementation
    try {
      if (Platform.isIOS) {
        final status = await AppTrackingTransparency.requestTrackingAuthorization();
        if (kDebugMode) {
          print('Tapjoy: App Tracking Transparency status: $status');
        }
      }

      final Map<String, dynamic> optionFlags = {};
      
      await plugin.Tapjoy.connect(
        sdkKey: sdkKey,
        options: optionFlags,
        onConnectSuccess: () async {
          _isConnected = true;
          if (kDebugMode) {
            print('Tapjoy: Connected successfully (iOS)');
          }
          
          String? userId = await StorageService.getMobileNumber() ?? await StorageService.getDeviceId();
          if (userId != null && userId.isNotEmpty) {
            await setUserID(userId);
          }
          
          _prepareOfferwallPlugin();
        },
        onConnectFailure: (int code, String? error) async {
          _isConnected = false;
          if (kDebugMode) {
            print('Tapjoy: Connect failed: $error (code: $code)');
          }
        },
        onConnectWarning: (int code, String? warning) async {
          if (kDebugMode) {
            print('Tapjoy: Connect warning: $warning (code: $code)');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Tapjoy: Error initializing: $e');
      }
    }
  }

  static Future<void> _prepareOfferwallPlugin() async {
    if (!_isConnected || Platform.isAndroid) return;
    
    try {
      _offerwallPlacement = await plugin.Tapjoy.getPlacement(
        placementName: placement,
        onRequestSuccess: (placement) {
          if (kDebugMode) print('Tapjoy: Placement request success (iOS)');
        },
        onRequestFailure: (placement, error) {
          if (kDebugMode) print('Tapjoy: Placement request failure: $error');
          _isContentAvailable = false;
        },
        onContentReady: (placement) {
          if (kDebugMode) print('Tapjoy: Content ready (iOS)');
          _isContentAvailable = true;
        },
        onContentShow: (placement) {
          if (kDebugMode) print('Tapjoy: Content shown (iOS)');
          _isContentAvailable = true;
          if (onOfferwallShown != null) {
            onOfferwallShown!();
          }
        },
        onContentDismiss: (placement) {
          if (kDebugMode) print('Tapjoy: Content dismissed (iOS)');
          _isContentAvailable = false;
          if (onOfferwallDismissed != null) {
            onOfferwallDismissed!();
          }
          placement.requestContent();
        },
      );
      
      _offerwallPlacement?.requestContent();
    } catch (e) {
      if (kDebugMode) print('Tapjoy: Error preparing placement: $e');
    }
  }

  /// Show the Tapjoy offerwall
  /// Returns a map with 'success' (bool) and 'message' (String) keys
  /// Follows the correct flow: requestContent() -> check isContentReady() -> showOfferwall()
  static Future<Map<String, dynamic>> showOfferwall({int maxWaitSeconds = 5}) async {
    if (Platform.isAndroid) {
      try {
        if (kDebugMode) {
          print('=== Tapjoy: Show Offerwall Requested ===');
          print('Tapjoy: App ID: $appId');
          print('Tapjoy: Placement: $placement');
        }
        
        // Ensure Tapjoy is initialized
        if (!_isConnected) {
          if (kDebugMode) print('Tapjoy: Not initialized, initializing now...');
          await init();
          await Future.delayed(const Duration(milliseconds: 2000));
        }
        
        // Ensure User ID is set before requesting content
        String? userId = await StorageService.getMobileNumber() ?? await StorageService.getDeviceId();
        if (userId != null && userId.isNotEmpty) {
          await setUserID(userId);
        }
        
        // STEP 1: Request content FIRST (IMPORTANT - fixes content ready = false issue)
        if (kDebugMode) print('Tapjoy: Step 1 - Requesting content for placement...');
        try {
          await platform.invokeMethod('prepareOfferwall'); // This calls requestContent() in native
          if (kDebugMode) print('Tapjoy: ✓ Content request sent');
        } catch (e) {
          if (kDebugMode) print('Tapjoy: Error requesting content: $e');
        }
        
        // Wait for content to load
        if (kDebugMode) print('Tapjoy: Waiting for content to load...');
        await Future.delayed(const Duration(milliseconds: 2000));
        
        // STEP 2: Check if content is ready
        if (kDebugMode) print('Tapjoy: Step 2 - Checking if content is ready...');
        bool isReady = await platform.invokeMethod('isContentReady') ?? false;
        if (kDebugMode) print('Tapjoy: Content ready status: $isReady');
        
        // If not ready, wait a bit more and check again
        if (!isReady) {
          if (kDebugMode) print('Tapjoy: Content not ready, waiting a bit more...');
          await Future.delayed(const Duration(milliseconds: 2000));
          
          // Request content again
          try {
            await platform.invokeMethod('prepareOfferwall');
            await Future.delayed(const Duration(milliseconds: 1500));
            isReady = await platform.invokeMethod('isContentReady') ?? false;
            if (kDebugMode) print('Tapjoy: Content ready status after retry: $isReady');
          } catch (e) {
            if (kDebugMode) print('Tapjoy: Error re-requesting content: $e');
          }
        }
        
        // STEP 3: Show offerwall if ready
        if (kDebugMode) print('Tapjoy: Step 3 - Attempting to show offerwall...');
        final bool showed = await platform.invokeMethod('showOfferwall');
        
        if (showed) {
          if (kDebugMode) {
            print('Tapjoy: ✓✓✓ SUCCESS - Offerwall shown!');
          }
          _isContentAvailable = true;
          return {'success': true, 'message': 'Offerwall opened successfully'};
        } else {
          if (kDebugMode) {
            print('Tapjoy: ✗ showOfferwall returned false');
            print('Tapjoy: Content ready: $isReady');
            print('Tapjoy: ===== ROOT CAUSE =====');
            print('Tapjoy: No offers are available in Tapjoy dashboard for placement "$placement"');
            print('Tapjoy: ===== SOLUTION =====');
            print('Tapjoy: 1. Login to Tapjoy Dashboard');
            print('Tapjoy: 2. Go to Placements > $placement');
            print('Tapjoy: 3. Ensure placement is ACTIVE');
            print('Tapjoy: 4. Ensure offers are ACTIVE and PUBLISHED');
            print('Tapjoy: 5. Assign offers to this placement');
            print('Tapjoy: 6. Enable Test Mode if testing');
          }
          return {
            'success': false,
            'message': 'No offers available at the moment. Please check back later or contact support if this issue persists.'
          };
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print("Tapjoy: ✗✗✗ ERROR: $e");
          print("Tapjoy: Stack: $stackTrace");
        }
        return {
          'success': false,
          'message': 'Failed to open offerwall. Please try again later.'
        };
      }
    }

    // iOS implementation
    if (!_isConnected || _offerwallPlacement == null) {
      if (kDebugMode) print('Tapjoy: Not connected or placement null (iOS)');
      if (!_isConnected) await init();
      return {
        'success': false,
        'message': 'Offerwall not ready. Please try again in a moment.'
      };
    }

    try {
      int waited = 0;
      while (waited < maxWaitSeconds * 10) {
        if (await _offerwallPlacement!.isContentReady()) {
          await _offerwallPlacement!.showContent();
          if (kDebugMode) print('Tapjoy: Offerwall shown (iOS)');
          return {'success': true, 'message': 'Offerwall opened successfully'};
        }
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }
      
      // Try to show even if not ready
      await _offerwallPlacement!.showContent();
      if (kDebugMode) print('Tapjoy: Offerwall shown (may be empty)');
      return {'success': true, 'message': 'Offerwall opened successfully'};
    } catch (e) {
      if (kDebugMode) print('Tapjoy: Error showing offerwall: $e');
      return {
        'success': false,
        'message': 'Failed to open offerwall. Please try again later.'
      };
    }
  }
}
