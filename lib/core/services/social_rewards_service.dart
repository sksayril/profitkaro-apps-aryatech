import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'storage_service.dart';

enum SocialPlatform {
  telegram,
  youtube,
  instagram,
}

class SocialRewardsService {
  // Coins rewarded per social action
  static const int _rewardCoins = 10;
  // Cooldown duration per platform
  static const Duration _cooldown = Duration(hours: 24);

  static Future<_SocialRewardState> _getState(SocialPlatform platform) async {
    DateTime? lastTime;

    switch (platform) {
      case SocialPlatform.telegram:
        lastTime = await StorageService.getLastTelegramRewardTime();
        break;
      case SocialPlatform.youtube:
        lastTime = await StorageService.getLastYoutubeRewardTime();
        break;
      case SocialPlatform.instagram:
        lastTime = await StorageService.getLastInstagramRewardTime();
        break;
    }

    final now = DateTime.now();
    if (lastTime == null) {
      return _SocialRewardState(
        canClaim: true,
        nextAvailableAt: now,
      );
    }

    final diff = now.difference(lastTime);
    if (diff >= _cooldown) {
      return _SocialRewardState(
        canClaim: true,
        nextAvailableAt: now,
      );
    }

    return _SocialRewardState(
      canClaim: false,
      nextAvailableAt: lastTime.add(_cooldown),
    );
  }

  /// Returns whether user can currently claim reward for this social platform.
  static Future<bool> canClaim(SocialPlatform platform) async {
    final state = await _getState(platform);
    return state.canClaim;
  }

  /// Returns remaining cooldown in seconds (null if can claim now).
  static Future<Duration?> getRemainingCooldown(SocialPlatform platform) async {
    final state = await _getState(platform);
    if (state.canClaim) return null;
    final now = DateTime.now();
    return state.nextAvailableAt.difference(now);
  }

  /// Try to claim reward for a platform.
  ///
  /// Returns a map:
  /// { 'success': bool, 'message': String, 'coins': int? }
  static Future<Map<String, dynamic>> claimReward(
    SocialPlatform platform,
  ) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Please login to earn coins',
          'reason': 'not_logged_in',
        };
      }

      final state = await _getState(platform);
      if (!state.canClaim) {
        return {
          'success': false,
          'message': 'You have already claimed this reward. Try again later.',
          'reason': 'cooldown',
        };
      }

      final apiResult = await ApiService.addCoins(
        token: token,
        coins: _rewardCoins,
      );

      if (apiResult['success'] == true) {
        final now = DateTime.now();
        switch (platform) {
          case SocialPlatform.telegram:
            await StorageService.setLastTelegramRewardTime(now);
            break;
          case SocialPlatform.youtube:
            await StorageService.setLastYoutubeRewardTime(now);
            break;
          case SocialPlatform.instagram:
            await StorageService.setLastInstagramRewardTime(now);
            break;
        }

        if (kDebugMode) {
          // ignore: avoid_print
          print(
            'Social reward claimed for $platform: $_rewardCoins coins',
          );
        }

        return {
          'success': true,
          'message': 'You earned $_rewardCoins coins!',
          'coins': _rewardCoins,
        };
      } else {
        return {
          'success': false,
          'message': apiResult['message'] ?? 'Failed to add coins',
          'reason': 'api_error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'reason': 'exception',
      };
    }
  }
}

class _SocialRewardState {
  final bool canClaim;
  final DateTime nextAvailableAt;

  _SocialRewardState({
    required this.canClaim,
    required this.nextAvailableAt,
  });
}

