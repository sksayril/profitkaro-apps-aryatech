import 'dart:convert';

/// Backend: GET /users/social-links/public (camelCase; PascalCase fallbacks optional).
class SocialLinksPublic {
  final String telegramLink;
  final String youtubeLink;
  final String instagramLink;
  final bool isActive;

  const SocialLinksPublic({
    required this.telegramLink,
    required this.youtubeLink,
    required this.instagramLink,
    this.isActive = true,
  });

  static SocialLinksPublic defaults() => const SocialLinksPublic(
        telegramLink: 'https://t.me/profitkaroofficial',
        youtubeLink: 'https://youtube.com/@profitkaroindia',
        instagramLink: 'https://www.instagram.com/profitkaroindia',
        isActive: true,
      );

  bool get hasAnyLink =>
      telegramLink.trim().isNotEmpty ||
      youtubeLink.trim().isNotEmpty ||
      instagramLink.trim().isNotEmpty;

  factory SocialLinksPublic.fromJson(Map<String, dynamic> json) {
    String pick(String camel, [String? pascal]) {
      for (final k in [camel, if (pascal != null) pascal]) {
        final v = json[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    bool pickActive() {
      final v = json['isActive'] ?? json['IsActive'];
      return v != false;
    }

    return SocialLinksPublic(
      telegramLink: pick('telegramLink', 'TelegramLink'),
      youtubeLink: pick('youtubeLink', 'YoutubeLink'),
      instagramLink: pick('instagramLink', 'InstagramLink'),
      isActive: pickActive(),
    );
  }

  Map<String, dynamic> toJson() => {
        'telegramLink': telegramLink,
        'youtubeLink': youtubeLink,
        'instagramLink': instagramLink,
        'isActive': isActive,
      };

  static SocialLinksPublic? tryParseCache(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SocialLinksPublic.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
