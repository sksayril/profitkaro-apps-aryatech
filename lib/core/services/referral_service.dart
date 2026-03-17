import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'storage_service.dart';

class ReferralService {
  /// Extract referral code from URL
  /// Supports formats like:
  /// - https://apiprofit.seotube.in/refer/VYD62W (path format)
  /// - https://apiprofit.seotube.in/refer?code=VYD62W (query param 'code')
  /// - https://apiprofit.seotube.in/refer?refer=VYD62W (query param 'refer')
  /// - https://apiprofit.seotube.in/refer=VYD62W (legacy format)
  /// - profitkaro://refer?code=VYD62W (custom scheme)
  static String? extractReferralCodeFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      
      // 1. Check query parameters first (for ?code=CODE or ?refer=CODE)
      final codeParam = uri.queryParameters['code'];
      if (codeParam != null && codeParam.isNotEmpty) {
        return codeParam.toUpperCase().trim();
      }
      
      final referParam = uri.queryParameters['refer'];
      if (referParam != null && referParam.isNotEmpty) {
        return referParam.toUpperCase().trim();
      }

      // 2. Check path segments (for /refer/CODE or /refer=CODE format)
      final path = uri.path;
      
      // Match /refer/CODE format
      final pathMatch = RegExp(r'/refer/([A-Z0-9]+)', caseSensitive: false).firstMatch(path);
      if (pathMatch != null && pathMatch.group(1) != null) {
        return pathMatch.group(1)!.toUpperCase().trim();
      }
      
      // Match /refer=CODE format (legacy)
      if (path.contains('refer=')) {
        final match = RegExp(r'refer=([A-Z0-9]+)', caseSensitive: false).firstMatch(path);
        if (match != null && match.group(1) != null) {
          return match.group(1)!.toUpperCase().trim();
        }
      }

      // 3. Check fragment (for #refer=CODE format)
      final fragment = uri.fragment;
      if (fragment.contains('refer=')) {
        final match = RegExp(r'refer=([A-Z0-9]+)', caseSensitive: false).firstMatch(fragment);
        if (match != null && match.group(1) != null) {
          return match.group(1)!.toUpperCase().trim();
        }
      }
      
      // 4. Check for code in fragment (for #code=CODE)
      if (fragment.contains('code=')) {
        final match = RegExp(r'code=([A-Z0-9]+)', caseSensitive: false).firstMatch(fragment);
        if (match != null && match.group(1) != null) {
          return match.group(1)!.toUpperCase().trim();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting referral code from URL: $e');
      }
    }

    return null;
  }

  /// Process referral code from URL and save it
  static Future<bool> processReferralCodeFromUrl(String? url) async {
    final code = extractReferralCodeFromUrl(url);
    if (code != null && code.isNotEmpty) {
      return await StorageService.savePendingReferralCode(code);
    }
    return false;
  }

  /// Get the referral URL for a given code (path format)
  static String getReferralUrl(String referCode) {
    return 'https://apiprofit.seotube.in/refer/${referCode.toUpperCase()}';
  }

  /// Get referral URL with query parameter format
  static String getReferralUrlWithQuery(String referCode, {bool useCode = true}) {
    final param = useCode ? 'code' : 'refer';
    return 'https://apiprofit.seotube.in/refer?$param=${referCode.toUpperCase()}';
  }

  /// Get Play Store URL with referrer parameter
  /// Format: https://play.google.com/store/apps/details?id=com.profitkaro&referrer=utm_source%3Dreferral%26code%3DABC123
  static String getPlayStoreUrl({String? referCode}) {
    final baseUrl = 'https://play.google.com/store/apps/details?id=com.profitkaro';
    if (referCode != null && referCode.isNotEmpty) {
      // Format: utm_source=referral&code=ABC123 (URL encoded)
      final referrerParam = 'utm_source=referral&code=${referCode.toUpperCase()}';
      final encodedReferrer = Uri.encodeComponent(referrerParam);
      return '$baseUrl&referrer=$encodedReferrer';
    }
    return baseUrl;
  }

  /// Get Android Intent URL (for direct app opening)
  /// Format: intent://refer?code=VYD62W#Intent;scheme=profitkaro;package=com.profitkaro;S.refer=VYD62W;end
  static String getIntentUrl(String referCode) {
    final code = referCode.toUpperCase();
    return 'intent://refer?code=$code#Intent;scheme=profitkaro;package=com.profitkaro;S.refer=$code;end';
  }

  /// Get custom scheme URL (fallback)
  /// Format: profitkaro://refer?code=VYD62W
  static String getCustomSchemeUrl(String referCode) {
    return 'profitkaro://refer?code=${referCode.toUpperCase()}';
  }

  /// Get referral code from Play Store Install Referrer API
  /// This is called when app is first opened after installation from Play Store
  /// Supports formats like:
  /// - utm_source=referral&code=ABC123
  /// - utm_source=referral&utm_content=ABC123
  /// - code=ABC123
  /// - ABC123 (direct code)
  static Future<String?> getReferralCodeFromInstallReferrer() async {
    try {
      if (kDebugMode) {
        print("=== Checking Install Referrer ===");
      }
      
      final ReferrerDetails referrerDetails = await PlayInstallReferrer.installReferrer;
      
      final referrerUrl = referrerDetails.installReferrer;
      
      if (kDebugMode) {
        print("Raw Install Referrer String: '$referrerUrl'");
        print("Install Timestamp: ${referrerDetails.installBeginTimestampSeconds}");
        print("Referrer Click Timestamp: ${referrerDetails.referrerClickTimestampSeconds}");
      }

      if (referrerUrl != null && referrerUrl.isNotEmpty) {
        if (kDebugMode) {
          print("Referrer found, parsing: $referrerUrl");
        }
        
        // Parse the referrer string
        // Format can be: utm_source=referral&code=ABC123 or code=ABC123
        final code = _parseReferrerString(referrerUrl);
        
        if (kDebugMode) {
          print("Parsed Referral Code: $code");
        }
        
        return code;
      } else {
        if (kDebugMode) {
          print("Install Referrer is null or empty");
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Install Referrer error: $e");
        print("Stack trace: $stackTrace");
      }
    }
    return null;
  }

  /// Parse referral code from Play Store referrer string
  /// Handles formats like:
  /// - utm_source=referral&code=ABC123
  /// - utm_source=referral&utm_content=ABC123
  /// - code=ABC123
  /// - referrer=utm_source%3Dreferral%26code%3DABC123 (URL encoded)
  /// - ABC123 (direct code without parameters)
  static String? _parseReferrerString(String referrer) {
    try {
      if (kDebugMode) {
        print("Parsing referrer string: '$referrer'");
      }
      
      // First, try to decode if it's URL encoded
      String decodedReferrer = referrer;
      try {
        decodedReferrer = Uri.decodeComponent(referrer);
        if (kDebugMode && decodedReferrer != referrer) {
          print("Decoded referrer: '$decodedReferrer'");
        }
      } catch (e) {
        // If decoding fails, use original
        decodedReferrer = referrer;
      }

      // If referrer is just a code without parameters (e.g., "ABC123")
      final directCodeMatch = RegExp(r'^([A-Z0-9]{4,20})$', caseSensitive: false)
          .firstMatch(decodedReferrer.trim());
      if (directCodeMatch != null && directCodeMatch.group(1) != null) {
        final code = directCodeMatch.group(1)!.toUpperCase().trim();
        if (kDebugMode) {
          print("Found direct code: $code");
        }
        return code;
      }

      // Parse as query string
      String queryString = decodedReferrer;
      
      // If it doesn't start with ?, add it for proper parsing
      if (!queryString.startsWith('?')) {
        queryString = '?$queryString';
      }
      
      final uri = Uri.parse(queryString);
      
      if (kDebugMode) {
        print("Query parameters: ${uri.queryParameters}");
      }
      
      // Check for 'code' parameter first (most common)
      final codeParam = uri.queryParameters['code'];
      if (codeParam != null && codeParam.isNotEmpty) {
        final code = codeParam.toUpperCase().trim();
        if (kDebugMode) {
          print("Found code parameter: $code");
        }
        return code;
      }

      // Check for 'utm_content' parameter (alternative format)
      final utmContent = uri.queryParameters['utm_content'];
      if (utmContent != null && utmContent.isNotEmpty) {
        final code = utmContent.toUpperCase().trim();
        if (kDebugMode) {
          print("Found utm_content parameter: $code");
        }
        return code;
      }

      // Check for 'refer' parameter
      final referParam = uri.queryParameters['refer'];
      if (referParam != null && referParam.isNotEmpty) {
        final code = referParam.toUpperCase().trim();
        if (kDebugMode) {
          print("Found refer parameter: $code");
        }
        return code;
      }

      // Check for direct code in referrer string (fallback)
      // Pattern: code=ABC123 or utm_content=ABC123 or refer=ABC123
      final codeMatch = RegExp(r'(?:code|utm_content|refer)=([A-Z0-9]{4,20})', caseSensitive: false)
          .firstMatch(decodedReferrer);
      if (codeMatch != null && codeMatch.group(1) != null) {
        final code = codeMatch.group(1)!.toUpperCase().trim();
        if (kDebugMode) {
          print("Found code in string pattern: $code");
        }
        return code;
      }

      if (kDebugMode) {
        print("No referral code found in referrer string");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error parsing referrer string: $e');
        print('Stack trace: $stackTrace');
      }
    }

    return null;
  }

  /// Process referral code from Install Referrer and save it
  /// This should be called on app first launch
  static Future<bool> processReferralCodeFromInstallReferrer() async {
    try {
      if (kDebugMode) {
        print("=== Processing Install Referrer Code ===");
      }
      
      final code = await getReferralCodeFromInstallReferrer();
      
      if (code != null && code.isNotEmpty) {
        if (kDebugMode) {
          print("Saving referral code to storage: $code");
        }
        
        final saved = await StorageService.savePendingReferralCode(code);
        
        if (kDebugMode) {
          print("Referral code saved: $saved");
        }
        
        return saved;
      } else {
        if (kDebugMode) {
          print("No referral code found in install referrer");
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error processing install referrer: $e");
        print("Stack trace: $stackTrace");
      }
    }
    
    return false;
  }
}
