import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../screens/ayet/ayet_offerwall_screen.dart';

class AyetService {
  // Ayet Studio API Credentials
  static const String appKey = '95d451486ca911e80562d842250055a7';
  static const String placementId = '22259';
  
  /// Show Ayet offerwall using WebView (Simple approach - no backend needed)
  /// This method navigates to the WebView-based offerwall screen
  static Future<Map<String, dynamic>> showOfferwallWebView(BuildContext context) async {
    try {
      if (kDebugMode) {
        print('Ayet: Opening WebView offerwall...');
        print('Ayet: Placement ID: $placementId');
        print('Ayet: App Key: $appKey');
      }
      
      // Navigate to WebView screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AyetOfferwallScreen(),
        ),
      );
      
      if (kDebugMode) {
        print('Ayet: ✓ WebView offerwall closed');
      }
      
      return {
        'success': true,
        'message': 'Offerwall opened successfully'
      };
    } catch (e) {
      if (kDebugMode) {
        print('Ayet: ✗ Error opening WebView offerwall: $e');
      }
      return {
        'success': false,
        'message': 'Failed to open offerwall. Please try again later.'
      };
    }
  }
}
