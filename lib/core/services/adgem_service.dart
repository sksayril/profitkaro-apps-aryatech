import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../screens/adgem/adgem_offerwall_screen.dart';

class AdGemService {
  // AdGem API Credentials - Placeholder (Replace with actual)
  static const String appId = 'your_adgem_app_id';
  
  /// Show AdGem offerwall using WebView (Simple approach - no native SDK needed)
  /// This method navigates to the WebView-based offerwall screen
  static Future<Map<String, dynamic>> showOfferwallWebView(BuildContext context) async {
    try {
      if (kDebugMode) {
        print('AdGem: Opening WebView offerwall...');
        print('AdGem: App ID: $appId');
      }
      
      // Navigate to WebView screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdGemOfferwallScreen(),
        ),
      );
      
      if (kDebugMode) {
        print('AdGem: ✓ WebView offerwall closed');
      }
      
      return {
        'success': true,
        'message': 'Offerwall opened successfully'
      };
    } catch (e) {
      if (kDebugMode) {
        print('AdGem: ✗ Error opening AdGem WebView offerwall: $e');
      }
      return {
        'success': false,
        'message': 'Failed to open offerwall. Please try again later.'
      };
    }
  }
}
