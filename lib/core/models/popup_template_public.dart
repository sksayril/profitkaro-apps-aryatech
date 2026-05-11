/// Server: GET /users/popup-template/public (no auth).
///
/// New contract returns `isActive: true` plus `title` and `description` only
/// when `IsActive` is true and at least one of `title` / `description` is
/// non-empty (`description` merges legacy `Body` until admins save
/// `Description`). Otherwise `isActive: false` with `title` / `description`
/// `null` plus a `note`.
class PopupTemplatePublic {
  final bool isActive;
  final String? imageUrl;
  final String? title;

  /// Body / description text. Reads `description` first (new field),
  /// falls back to legacy `body`.
  final String? body;
  final String? actionLabel;
  final String? actionUrl;
  final String? note;

  const PopupTemplatePublic({
    required this.isActive,
    this.imageUrl,
    this.title,
    this.body,
    this.actionLabel,
    this.actionUrl,
    this.note,
  });

  /// Show the popup whenever the server says it's active **and** there is
  /// something visible to render: an image, a title, or a description/body.
  bool get shouldShow {
    if (!isActive) return false;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final hasTitle = title != null && title!.trim().isNotEmpty;
    final hasBody = body != null && body!.trim().isNotEmpty;
    return hasImage || hasTitle || hasBody;
  }

  /// Stable key for de-duplication (e.g. "show once per day"). Combines all
  /// rendered content so admins can re-trigger a popup by editing any field.
  String get contentKey {
    final parts = [
      imageUrl ?? '',
      title ?? '',
      body ?? '',
      actionLabel ?? '',
      actionUrl ?? '',
    ];
    return parts.join('|');
  }

  factory PopupTemplatePublic.fromJson(Map<String, dynamic> json) {
    bool pickBool(dynamic v) {
      if (v is bool) return v;
      if (v == null) return false;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    String? pickStr(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return PopupTemplatePublic(
      isActive: pickBool(json['isActive'] ?? json['IsActive']),
      imageUrl: pickStr(json['imageUrl'] ?? json['ImageUrl']),
      title: pickStr(json['title'] ?? json['Title']),
      body: pickStr(
        json['description'] ??
            json['Description'] ??
            json['body'] ??
            json['Body'],
      ),
      actionLabel: pickStr(json['actionLabel'] ?? json['ActionLabel']),
      actionUrl: pickStr(json['actionUrl'] ?? json['ActionUrl']),
      note: pickStr(json['note'] ?? json['Note']),
    );
  }
}
