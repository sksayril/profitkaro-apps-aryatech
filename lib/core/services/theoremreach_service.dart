import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'storage_service.dart';

class TheoremReachService {
  // TheoremReach API Credentials from screenshot
  static const String apiKey = '427674cfe834dfcbf30d3294e838';
  static const String appId = '24767';
  static const String secretKey = 'b0ee8ab516bee6479748bf44c51093f54bad8c01';

  /// Check if surveys are available for the current user
  /// Returns a map with 'available' (bool) and 'profiled' (bool)
  static Future<Map<String, dynamic>> checkSurveyAvailability() async {
    try {
      // Get user ID - prefer mobile number, fallback to device ID
      String? userId = await StorageService.getMobileNumber() ?? await StorageService.getDeviceId();
      
      if (userId == null || userId.isEmpty) {
        return {'available': false, 'profiled': false, 'message': 'User ID not found'};
      }

      // We'll use a public IP API or just omit the IP as TheoremReach uses IP to determine country
      // TheoremReach says: "We use their IP address to determine country for new users."
      // Let's try to get the public IP if possible, or just send a request without it if the API allows
      // or use a placeholder if needed. TheoremReach example shows &ip={USERS_IP_ADDRESS}
      
      // For simplicity, let's first check without IP as TheoremReach server will see the request IP
      // Wait, if it's a server-to-server check from the app, the IP will be the user's IP.
      
      final url = Uri.parse('https://api.theoremreach.com/api/publishers/v1/user_details')
          .replace(queryParameters: {
        'api_key': apiKey,
        'user_id': userId,
      });

      if (kDebugMode) {
        print('TheoremReach: Checking availability for User: $userId');
      }

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          print('TheoremReach: Availability response: $data');
        }
        return {
          'available': data['surveys_available'] ?? false,
          'profiled': data['profiled'] ?? false,
          'success': true,
        };
      } else {
        if (kDebugMode) {
          print('TheoremReach: Error response: ${response.statusCode} - ${response.body}');
        }
        return {'available': false, 'profiled': false, 'success': false};
      }
    } catch (e) {
      if (kDebugMode) {
        print('TheoremReach: Exception during availability check: $e');
      }
      return {'available': false, 'profiled': false, 'success': false};
    }
  }

  /// Launch the TheoremReach offerwall in the external browser
  static Future<Map<String, dynamic>> showOfferwall() async {
    try {
      String? userId = await StorageService.getMobileNumber() ?? await StorageService.getDeviceId();
      
      if (userId == null || userId.isEmpty) {
        return {'success': false, 'message': 'User ID not found. Please log in again.'};
      }

      final offerwallUrl = 'https://theoremreach.com/respondent_entry/direct?api_key=$apiKey&user_id=$userId';
      
      if (kDebugMode) {
        print('TheoremReach: Opening offerwall with URL: $offerwallUrl');
      }

      final uri = Uri.parse(offerwallUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return {'success': true, 'message': 'Offerwall opened successfully'};
      } else {
        return {'success': false, 'message': 'Could not launch the browser. Please check your settings.'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('TheoremReach: Error launching offerwall: $e');
      }
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
