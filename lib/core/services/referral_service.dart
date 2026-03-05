import 'package:flutter/foundation.dart';
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
  static String getPlayStoreUrl({String? referCode}) {
    final baseUrl = 'https://play.google.com/store/apps/details?id=com.profitkaro';
    if (referCode != null && referCode.isNotEmpty) {
      return '$baseUrl&referrer=${referCode.toUpperCase()}';
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
}
