import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'referral_service.dart';
import 'storage_service.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _initialLink;
  Uri? _latestLink;

  /// Initialize deep link service
  Future<void> init() async {
    try {
      _appLinks = AppLinks();

      // Set up method channel for Android deep links
      const methodChannel = MethodChannel('deep_link');
      methodChannel.setMethodCallHandler((call) async {
        if (call.method == 'onDeepLink') {
          final url = call.arguments['url'] as String?;
          if (url != null) {
            try {
              final uri = Uri.parse(url);
              _latestLink = uri;
              await _processLink(uri);
            } catch (e) {
              if (kDebugMode) {
                print('DeepLink: Error parsing URL from method channel: $e');
              }
            }
          }
        }
      });

      // Get initial link if app was opened from a link
      _initialLink = await _appLinks?.getInitialLink();
      if (_initialLink != null) {
        if (kDebugMode) {
          print('DeepLink: Initial link received: ${_initialLink.toString()}');
        }
        await _processLink(_initialLink!);
      }

      // Listen for incoming links when app is running
      _linkSubscription = _appLinks?.uriLinkStream.listen(
        (Uri uri) {
          if (kDebugMode) {
            print('DeepLink: New link received: ${uri.toString()}');
          }
          _latestLink = uri;
          _processLink(uri);
        },
        onError: (err) {
          if (kDebugMode) {
            print('DeepLink: Error: $err');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('DeepLink: Initialization error: $e');
      }
    }
  }

  /// Process a deep link URI
  Future<void> _processLink(Uri uri) async {
    try {
      final url = uri.toString();
      
      // Extract and save referral code
      final referralCode = ReferralService.extractReferralCodeFromUrl(url);
      if (referralCode != null && referralCode.isNotEmpty) {
        if (kDebugMode) {
          print('DeepLink: Referral code extracted: $referralCode');
        }
        await StorageService.savePendingReferralCode(referralCode);
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeepLink: Error processing link: $e');
      }
    }
  }

  /// Get the initial link (if app was opened from a link)
  Uri? getInitialLink() => _initialLink;

  /// Get the latest link
  Uri? getLatestLink() => _latestLink;

  /// Get the app links instance for listening to new links
  AppLinks? get appLinks => _appLinks;

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
