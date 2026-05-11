import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'storage_service.dart';
import 'google_mobile_ads_service.dart';

/// Global task-completion ad rotation (same for every mini-game / task):
/// 1st completion → Interstitial (`AdConfig.interstitialUnitId`)
/// 2nd completion → Rewarded (`AdConfig.rewardedUnitId`)
/// 3rd completion → no ad
/// then repeats (4th → Interstitial, …).
///
/// Native ads use `AdConfig.nativeUnitId` where screens embed a [NativeAd] widget separately.
class TaskCompletionAdsService {
  TaskCompletionAdsService._();
  static final TaskCompletionAdsService instance = TaskCompletionAdsService._();

  static const String _prefsKey = 'global_task_completion_count_v1';
  static const Set<String> _supportedTaskTypes = {
    'Quiz',
    'Captcha',
    'DailySpin',
    'ScratchCard',
    'ScratchCardDailyLimit',
    'AppInstall',
  };

  /// Increments global counter and asks backend which ad to show for this task.
  /// Falls back to local rotation if decision API fails.
  void runAfterTaskCompleted(
    void Function() onContinue, {
    required String taskType,
  }) {
    Future<void>(() async {
      final prefs = await SharedPreferences.getInstance();
      final n = (prefs.getInt(_prefsKey) ?? 0) + 1;
      await prefs.setInt(_prefsKey, n);

      final normalizedTaskType = taskType.trim();
      final token = await StorageService.getToken();
      if (token != null &&
          token.isNotEmpty &&
          _supportedTaskTypes.contains(normalizedTaskType)) {
        final decisionResult = await ApiService.getAdsDecision(
          token: token,
          taskType: normalizedTaskType,
          actionCount: n,
        );

        if (decisionResult['success'] == true) {
          final data = decisionResult['data'] as Map<String, dynamic>? ?? {};
          final decision = data['decision'] as Map<String, dynamic>? ?? {};
          final globalAdsEnabled = data['globalAdsEnabled'] == true;
          final rewardedEnabled = data['rewardedAdsEnabled'] == true;
          final interstitialEnabled = data['interstitialAdsEnabled'] == true;
          final taskActive = data['taskActive'] == true;
          final showRewarded = decision['showRewarded'] == true;
          final showInterstitial = decision['showInterstitial'] == true;
          final shouldShowRewardedNow = decision['shouldShowRewardedNow'] == true;
          final shouldShowInterstitialNow =
              decision['shouldShowInterstitialNow'] == true;

          if (!globalAdsEnabled || !taskActive) {
            onContinue();
            return;
          }

          if (shouldShowRewardedNow && showRewarded && rewardedEnabled) {
            await GoogleMobileAdsService.instance.showRewardedAd(
              onRewardEarned: onContinue,
              onFailed: onContinue,
            );
            return;
          }

          if (shouldShowInterstitialNow &&
              showInterstitial &&
              interstitialEnabled) {
            await GoogleMobileAdsService.instance.showInterstitialAd(
              onComplete: onContinue,
              onFailed: onContinue,
            );
            return;
          }

          onContinue();
          return;
        }
      }

      // Fallback: legacy local rotation (1st interstitial, 2nd rewarded, 3rd none).
      final phase = n % 3;
      if (phase == 1) {
        await GoogleMobileAdsService.instance.showInterstitialAd(
          onComplete: onContinue,
          onFailed: onContinue,
        );
        return;
      }
      if (phase == 2) {
        await GoogleMobileAdsService.instance.showRewardedAd(
          onRewardEarned: onContinue,
          onFailed: onContinue,
        );
        return;
      }

      onContinue();
    });
  }
}
