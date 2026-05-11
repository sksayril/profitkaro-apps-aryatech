import 'dart:convert';

import '../models/social_links_public.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Loads `/users/social-links/public`, caches locally for offline display.
class SocialLinksPublicService {
  SocialLinksPublicService._();
  static final SocialLinksPublicService instance = SocialLinksPublicService._();

  static const String _cacheKey = 'social_links_public_json_v1';

  Future<SocialLinksPublic> loadCachedOrDefaults() async {
    final raw = await StorageService.getString(_cacheKey);
    if (raw != null && raw.isNotEmpty) {
      final parsed = SocialLinksPublic.tryParseCache(raw);
      if (parsed != null) {
        return parsed;
      }
    }
    return SocialLinksPublic.defaults();
  }

  Future<void> saveCache(SocialLinksPublic links) async {
    await StorageService.saveString(_cacheKey, jsonEncode(links.toJson()));
  }

  /// Fetches from API and updates cache on success.
  Future<SocialLinksPublic?> fetchAndRefreshCache() async {
    final result = await ApiService.getSocialLinksPublic();
    if (result['success'] == true &&
        result['data'] != null &&
        result['data'] is Map) {
      try {
        final links = SocialLinksPublic.fromJson(
          Map<String, dynamic>.from(result['data'] as Map),
        );
        await saveCache(links);
        return links;
      } catch (_) {}
    }
    return null;
  }
}
