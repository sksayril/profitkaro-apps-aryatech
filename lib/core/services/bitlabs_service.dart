import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../screens/bitlabs/bitlabs_offerwall_screen.dart';
import 'storage_service.dart';

class BitLabsService {
  // BitLabs API Credentials from Integration page
  static const String apiToken = 'a35d4e74-34a4-4949-bf48-e05dff23baba';
  static const String secretKey = 'pS95rv88N216iCzM0qDUPi7G2bQyTw0O';
  static const String serverToServerKey = 'pNobVtw17qFfP93LQbF5y4QWUCXbaBaf';
  
  static const platform = MethodChannel('bitlabs_offerwall');
  
  static bool _isInitialized = false;
  static bool _isContentAvailable = false;
  
  // Callbacks
  static Function(String? currency, int amount)? onRewardEarned;
  static Function()? onOfferwallShown;
  static Function()? onOfferwallDismissed;

  static bool get isInitialized => _isInitialized;
  static bool get isContentAvailable => _isContentAvailable;
  
  /// Initialize BitLabs SDK
  static Future<void> init() async {
    if (_isInitialized) {
      if (kDebugMode) print('BitLabs: Already initialized');
      return;
    }

    if (Platform.isAndroid) {
      if (kDebugMode) {
        print('BitLabs: Initializing for Android');
        print('BitLabs: API Token: $apiToken');
      }
      
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onRewardEarned') {
          final currency = call.arguments['currency'] as String?;
          final amount = call.arguments['amount'] as int? ?? 0;
          if (kDebugMode) {
            print('BitLabs: Reward Earned: $amount $currency');
          }
          if (onRewardEarned != null) {
            onRewardEarned!(currency, amount);
          }
        } else if (call.method == 'onOfferwallShown') {
          if (kDebugMode) print('BitLabs: Offerwall shown');
          if (onOfferwallShown != null) {
            onOfferwallShown!();
          }
        } else if (call.method == 'onOfferwallDismissed') {
          if (kDebugMode) print('BitLabs: Offerwall dismissed');
          if (onOfferwallDismissed != null) {
            onOfferwallDismissed!();
          }
        }
      });
      
      try {
        // Initialize native SDK
        await platform.invokeMethod('init', {
          'apiToken': apiToken,
          'secretKey': secretKey,
        });
        
        // Set User ID if available
        String? userId = await StorageService.getMobileNumber() ?? await StorageService.getDeviceId();
        if (userId != null && userId.isNotEmpty) {
          await setUserID(userId);
        }
        
        _isInitialized = true;
        if (kDebugMode) print('BitLabs: ✓ Initialized successfully');
      } catch (e) {
        if (kDebugMode) {
          print('BitLabs: ✗ Initialization error: $e');
        }
      }
    } else if (Platform.isIOS) {
      // iOS implementation would go here
      if (kDebugMode) print('BitLabs: iOS not yet implemented');
    }
  }

  /// Set User ID for BitLabs
  static Future<void> setUserID(String userId) async {
    if (userId.isEmpty) return;
    
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('setUserID', {'userId': userId});
        if (kDebugMode) print('BitLabs: UserID set: $userId');
      } catch (e) {
        if (kDebugMode) print('BitLabs: Could not set UserID: $e');
      }
    }
  }

  /// Check if offerwall content is ready
  static Future<bool> checkContentReady() async {
    if (Platform.isAndroid) {
      try {
        final bool isReady = await platform.invokeMethod('isContentReady') ?? false;
        return isReady;
      } catch (e) {
        if (kDebugMode) print("BitLabs: Error checking content ready: $e");
        return false;
      }
    }
    return false;
  }

  /// Show the BitLabs offerwall
  /// Returns a map with 'success' (bool) and 'message' (String) keys
  static Future<Map<String, dynamic>> showOfferwall({int maxWaitSeconds = 5}) async {
    if (!_isInitialized) {
      await init();
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    if (Platform.isAndroid) {
      try {
        if (kDebugMode) {
          print('=== BitLabs: Show Offerwall Requested ===');
        }
        
        // Ensure User ID is set
        String? userId = await StorageService.getMobileNumber() ?? await StorageService.getDeviceId();
        if (userId != null && userId.isNotEmpty) {
          await setUserID(userId);
        }
        
        // Prepare offerwall
        try {
          await platform.invokeMethod('prepareOfferwall');
          if (kDebugMode) print('BitLabs: Placement preparation requested');
        } catch (e) {
          if (kDebugMode) print('BitLabs: Error preparing: $e');
        }
        
        // Wait for placement to initialize
        if (kDebugMode) print('BitLabs: Waiting for placement initialization...');
        await Future.delayed(const Duration(milliseconds: 2000));
        
        // Check if content is ready
        if (kDebugMode) print('BitLabs: Checking content status...');
        final bool isReady = await platform.invokeMethod('isContentReady') ?? false;
        if (kDebugMode) print('BitLabs: Content ready status: $isReady');
        
        // If not ready, wait a bit more
        if (!isReady) {
          if (kDebugMode) print('BitLabs: Content not ready, waiting a bit more...');
          await Future.delayed(const Duration(milliseconds: 2000));
          
          try {
            await platform.invokeMethod('prepareOfferwall');
            await Future.delayed(const Duration(milliseconds: 1500));
          } catch (e) {
            if (kDebugMode) print('BitLabs: Error re-requesting content: $e');
          }
        }
        
        // Try to show offerwall
        if (kDebugMode) print('BitLabs: Attempting to show offerwall...');
        final bool showed = await platform.invokeMethod('showOfferwall') ?? false;
        
        if (showed) {
          if (kDebugMode) {
            print('BitLabs: ✓✓✓ SUCCESS - Offerwall shown!');
          }
          _isContentAvailable = true;
          return {'success': true, 'message': 'Offerwall opened successfully'};
        } else {
          if (kDebugMode) {
            print('BitLabs: ✗ showOfferwall returned false');
            print('BitLabs: Error: No placement content available');
            print('BitLabs: ===== ROOT CAUSE =====');
            print('BitLabs: No offers are available in BitLabs dashboard');
            print('BitLabs: ===== SOLUTION =====');
            print('BitLabs: 1. Login to BitLabs Dashboard');
            print('BitLabs: 2. Ensure offers are ACTIVE and PUBLISHED');
            print('BitLabs: 3. Assign offers to placement');
          }
          return {
            'success': false,
            'message': 'No offers available at the moment. Please check back later or contact support if this issue persists.'
          };
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print("BitLabs: ✗✗✗ ERROR: $e");
          print("BitLabs: Stack: $stackTrace");
        }
        return {
          'success': false,
          'message': 'Failed to open offerwall. Please try again later.'
        };
      }
    }

    return {
      'success': false,
      'message': 'BitLabs offerwall is not available on this platform.'
    };
  }

  /// Show BitLabs offerwall using WebView (Simple approach - no backend needed)
  /// This method navigates to the WebView-based offerwall screen
  static Future<Map<String, dynamic>> showOfferwallWebView(BuildContext context) async {
    try {
      if (kDebugMode) {
        print('BitLabs: Opening WebView offerwall...');
      }
      
      // Navigate to WebView screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BitlabsOfferwallScreen(),
        ),
      );
      
      if (kDebugMode) {
        print('BitLabs: ✓ WebView offerwall closed');
      }
      
      return {
        'success': true,
        'message': 'Offerwall opened successfully'
      };
    } catch (e) {
      if (kDebugMode) {
        print('BitLabs: ✗ Error opening WebView offerwall: $e');
      }
      return {
        'success': false,
        'message': 'Failed to open offerwall. Please try again later.'
      };
    }
  }
}
