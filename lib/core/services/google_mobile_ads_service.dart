import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ad_config.dart';

/// Loads and shows AdMob / Ad Manager ads (app open, interstitial, rewarded).
class GoogleMobileAdsService {
  GoogleMobileAdsService._();
  static final GoogleMobileAdsService instance = GoogleMobileAdsService._();
  static const bool _adsEnabled = false;

  /// Rewarded ads for flows like Math Quiz (without enabling interstitial / app open preload).
  static const bool _rewardedAdsEnabled = true;

  /// Banner + native ads (in-feed promo slots like the History screen).
  /// Independent from `_adsEnabled` so we can show inline ads without
  /// re-enabling interstitial / app-open ads.
  static const bool _bannerAndNativeAdsEnabled = true;

  InterstitialAd? _interstitial;
  AdManagerInterstitialAd? _adManagerInterstitial;
  bool _interstitialLoading = false;
  bool _interstitialShowing = false;
  RewardedAd? _rewarded;
  bool _rewardedLoading = false;
  bool _rewardedShowing = false;
  final ValueNotifier<bool> rewardedReadyNotifier = ValueNotifier<bool>(false);
  AppOpenAd? _appOpen;
  bool _appOpenLoading = false;
  DateTime? _lastInterstitialNav;
  DateTime? _lastInterstitialSocial;
  bool _appOpenShowing = false;

  static bool get _useTestAds => kDebugMode;
  bool get isEnabled => _adsEnabled;

  /// True when in-feed banner / native ads are allowed to load.
  bool get bannerAndNativeAdsEnabled =>
      _adsEnabled || _bannerAndNativeAdsEnabled;

  bool _mobileAdsSdkInitialized = false;

  /// Ensures the Mobile Ads SDK has been initialized at least once. Safe to
  /// call repeatedly. Used by ad-loading widgets (banner / native) so they
  /// can render even if the parent app forgot to call `initialize()` early.
  Future<void> ensureMobileAdsInitialized() async {
    if (_mobileAdsSdkInitialized) return;
    await MobileAds.instance.initialize();
    _mobileAdsSdkInitialized = true;
  }

  Future<void> initialize() async {
    if (!_adsEnabled && !_rewardedAdsEnabled && !_bannerAndNativeAdsEnabled) {
      return;
    }
    await MobileAds.instance.initialize();
    _mobileAdsSdkInitialized = true;
    if (_adsEnabled) {
      _loadInterstitial();
      _loadAppOpen();
    }
    if (_adsEnabled || _rewardedAdsEnabled) {
      _loadRewarded();
    }
  }

  /// Lazily initializes the Mobile Ads SDK and preloads rewarded (quiz / rewarded-only flows).
  Future<void> ensureRewardedAdsReady() async {
    if (!_rewardedAdsEnabled) return;
    if (!_mobileAdsSdkInitialized) {
      await MobileAds.instance.initialize();
      _mobileAdsSdkInitialized = true;
    }
    if (_rewarded == null && !_rewardedLoading) {
      _loadRewarded();
    }
  }

  bool get isRewardedAdReady =>
      (_rewardedAdsEnabled || _adsEnabled) && _rewarded != null;

  void _loadRewarded() {
    if (!_adsEnabled && !_rewardedAdsEnabled) return;
    if (_rewarded != null || _rewardedLoading) return;
    _rewardedLoading = true;
    final callback = RewardedAdLoadCallback(
      onAdLoaded: (ad) {
        _rewardedLoading = false;
        _rewarded = ad;
        rewardedReadyNotifier.value = true;
      },
      onAdFailedToLoad: (LoadAdError e) {
        _rewardedLoading = false;
        rewardedReadyNotifier.value = false;
        debugPrint('Rewarded failed to load: code=${e.code} ${e.message}');
        Future.delayed(const Duration(seconds: 5), _loadRewarded);
      },
    );
    if (_useTestAds) {
      RewardedAd.load(
        adUnitId: AdConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: callback,
      );
    } else {
      RewardedAd.load(
        adUnitId: AdConfig.rewardedAdUnitId,
        request: const AdManagerAdRequest(),
        rewardedAdLoadCallback: callback,
      );
    }
  }

  /// Full-screen interstitial with completion callbacks (replaces pooled ad for this show).
  Future<void> showInterstitialAd({
    VoidCallback? onComplete,
    VoidCallback? onFailed,
  }) async {
    if (!_adsEnabled) {
      onFailed?.call();
      return;
    }
    if (_useTestAds) {
      final ad = _interstitial;
      if (ad == null) {
        onFailed?.call();
        _loadInterstitial();
        return;
      }
      _interstitial = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          onComplete?.call();
          ad.dispose();
          _loadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, AdError error) {
          debugPrint('Interstitial failed to show: $error');
          onFailed?.call();
          ad.dispose();
          _loadInterstitial();
        },
      );
      await ad.show();
    } else {
      final ad = _adManagerInterstitial;
      if (ad == null) {
        onFailed?.call();
        _loadInterstitial();
        return;
      }
      _adManagerInterstitial = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          onComplete?.call();
          ad.dispose();
          _loadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, AdError error) {
          debugPrint('Interstitial (Ad Manager) failed to show: $error');
          onFailed?.call();
          ad.dispose();
          _loadInterstitial();
        },
      );
      await ad.show();
    }
  }

  Future<void> showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onFailed,
    Duration waitForLoaded = const Duration(seconds: 15),
  }) async {
    if (!_adsEnabled && !_rewardedAdsEnabled) {
      onFailed?.call();
      return;
    }
    if (_rewardedShowing) {
      onFailed?.call();
      return;
    }

    await ensureRewardedAdsReady();
    final deadline = DateTime.now().add(waitForLoaded);
    while (_rewarded == null &&
        !_rewardedShowing &&
        DateTime.now().isBefore(deadline)) {
      if (!_rewardedLoading) {
        _loadRewarded();
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    if (_rewarded == null || _rewardedShowing) {
      onFailed?.call();
      return;
    }

    final ad = _rewarded!;
    _rewarded = null;
    rewardedReadyNotifier.value = false;
    _rewardedShowing = true;
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _rewardedShowing = false;
        ad.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        debugPrint('Rewarded failed to show: $error');
        _rewardedShowing = false;
        if (!earned) onFailed?.call();
        ad.dispose();
        _loadRewarded();
      },
    );
    await ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        earned = true;
        onRewardEarned();
      },
    );
  }

  /// Shows a rewarded ad and waits until it closes. Returns `true` if the user earned the reward.
  Future<bool> showRewardedAwaitEarned({
    Duration waitForLoaded = const Duration(seconds: 10),
  }) async {
    if (!_rewardedAdsEnabled && !_adsEnabled) return false;

    await ensureRewardedAdsReady();

    final deadline = DateTime.now().add(waitForLoaded);
    while (_rewarded == null && DateTime.now().isBefore(deadline)) {
      if (!_rewardedLoading) {
        _loadRewarded();
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    final adToShow = _rewarded;
    if (adToShow == null || _rewardedShowing) {
      debugPrint('Rewarded ad not ready to show.');
      return false;
    }

    _rewarded = null;
    rewardedReadyNotifier.value = false;
    _rewardedShowing = true;
    var earned = false;
    final outcome = Completer<bool>();

    adToShow.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _rewardedShowing = false;
        ad.dispose();
        _loadRewarded();
        if (!outcome.isCompleted) {
          outcome.complete(earned);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        debugPrint('Rewarded failed to show: $error');
        _rewardedShowing = false;
        ad.dispose();
        _loadRewarded();
        if (!outcome.isCompleted) {
          outcome.complete(false);
        }
      },
    );

    try {
      await adToShow.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          earned = true;
        },
      );
    } catch (e) {
      debugPrint('Rewarded show threw: $e');
      _rewardedShowing = false;
      if (!outcome.isCompleted) {
        outcome.complete(false);
      }
      _loadRewarded();
      return false;
    }

    return outcome.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => earned,
    );
  }

  void _loadInterstitial() {
    if (!_adsEnabled) return;
    if (_useTestAds) {
      if (_interstitial != null || _interstitialLoading) return;
      _interstitialLoading = true;
      InterstitialAd.load(
        adUnitId: AdConfig.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialLoading = false;
            _interstitial = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                _interstitialShowing = false;
                ad.dispose();
                _interstitial = null;
                _loadInterstitial();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _interstitialShowing = false;
                ad.dispose();
                _interstitial = null;
                _loadInterstitial();
              },
            );
          },
          onAdFailedToLoad: (e) {
            _interstitialLoading = false;
            debugPrint('Interstitial (test) failed: ${e.message}');
          },
        ),
      );
    } else {
      if (_adManagerInterstitial != null || _interstitialLoading) return;
      _interstitialLoading = true;
      AdManagerInterstitialAd.load(
        adUnitId: AdConfig.interstitialUnitId,
        request: const AdManagerAdRequest(),
        adLoadCallback: AdManagerInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialLoading = false;
            _adManagerInterstitial = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                _interstitialShowing = false;
                ad.dispose();
                _adManagerInterstitial = null;
                _loadInterstitial();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _interstitialShowing = false;
                ad.dispose();
                _adManagerInterstitial = null;
                _loadInterstitial();
              },
            );
          },
          onAdFailedToLoad: (e) {
            _interstitialLoading = false;
            debugPrint('Interstitial (Ad Manager) failed: ${e.message}');
          },
        ),
      );
    }
  }

  void _loadAppOpen() {
    if (!_adsEnabled) return;
    if (_appOpen != null || _appOpenLoading) return;
    _appOpenLoading = true;
    if (_useTestAds) {
      AppOpenAd.load(
        adUnitId: AdConfig.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenLoading = false;
            _appOpen?.dispose();
            _appOpen = ad;
          },
          onAdFailedToLoad: (e) {
            _appOpenLoading = false;
            debugPrint('App open (test) failed: ${e.message}');
          },
        ),
      );
    } else {
      AppOpenAd.loadWithAdManagerAdRequest(
        adUnitId: AdConfig.appOpenUnitId,
        adManagerAdRequest: const AdManagerAdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenLoading = false;
            _appOpen?.dispose();
            _appOpen = ad;
          },
          onAdFailedToLoad: (e) {
            _appOpenLoading = false;
            debugPrint('App open (Ad Manager) failed: ${e.message}');
          },
        ),
      );
    }
  }

  /// After switching bottom tabs (throttled).
  void maybeShowInterstitialOnNavigation() {
    if (!_adsEnabled) return;
    _maybeShowInterstitial(_lastInterstitialNav, (t) => _lastInterstitialNav = t);
  }

  /// After a social reward flow (separate throttle).
  void maybeShowInterstitialAfterSocial() {
    if (!_adsEnabled) return;
    _maybeShowInterstitial(
        _lastInterstitialSocial, (t) => _lastInterstitialSocial = t);
  }

  void _maybeShowInterstitial(
    DateTime? last,
    void Function(DateTime) setLast,
  ) {
    if (!_adsEnabled) return;
    final now = DateTime.now();
    if (last != null &&
        now.difference(last) < const Duration(seconds: 90)) {
      return;
    }
    if (_useTestAds) {
      final ad = _interstitial;
      if (ad == null || _interstitialShowing) return;
      _interstitialShowing = true;
      ad.show();
      setLast(now);
    } else {
      final ad = _adManagerInterstitial;
      if (ad == null || _interstitialShowing) return;
      _interstitialShowing = true;
      ad.show();
      setLast(now);
    }
  }

  /// Call when app returns from background (not first launch).
  void showAppOpenIfReady() {
    if (!_adsEnabled) return;
    if (_appOpenShowing) return;
    final ad = _appOpen;
    if (ad == null) {
      _loadAppOpen();
      return;
    }
    _appOpenShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _appOpenShowing = false;
        ad.dispose();
        _appOpen = null;
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        debugPrint('App open failed to show: $error');
        _appOpenShowing = false;
        ad.dispose();
        _appOpen = null;
        _loadAppOpen();
      },
    );
    ad.show();
  }
}
