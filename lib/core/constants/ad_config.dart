import 'package:flutter/foundation.dart';

/// AdMob application ID (Android & iOS `APPLICATION_ID` / `GADApplicationIdentifier`).
class AdConfig {
  AdConfig._();

  static const String applicationId = 'ca-app-pub-7664893030317051~1681851676';

  /// Production ad unit paths from your AdMob / Ad Manager setup.
  static const String appOpenUnitId =
      '/21753324030,23346327069/com.profitkaro_AppOpen';
  static const String interstitialUnitId =
      '/21753324030,23346327069/com.profitkaro_Interstitial';
  static const String nativeUnitId =
      '/21753324030,23346327069/com.profitkaro_Native';
  static const String rewardedUnitId =
      '/21753324030,23346327069/com.profitkaro_Rewarded';
  // Anchored adaptive banner used on screens like History.
  static const String bannerUnitId =
      '/21753324030,23346327069/com.profitkaro_Banner';

  /// Google sample IDs for debug builds (avoids invalid-format / policy issues while developing).
  static const String _testAppOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testNative = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testRewarded =
      'ca-app-pub-3940256099942544/5224354917';
  // Google's official adaptive-banner test unit.
  static const String _testBanner = 'ca-app-pub-3940256099942544/9214589741';

  static String get appOpenAdUnitId =>
      kDebugMode ? _testAppOpen : appOpenUnitId;

  static String get interstitialAdUnitId =>
      kDebugMode ? _testInterstitial : interstitialUnitId;

  static String get nativeAdUnitId =>
      kDebugMode ? _testNative : nativeUnitId;

  static String get rewardedAdUnitId =>
      kDebugMode ? _testRewarded : rewardedUnitId;

  static String get bannerAdUnitId =>
      kDebugMode ? _testBanner : bannerUnitId;
}
