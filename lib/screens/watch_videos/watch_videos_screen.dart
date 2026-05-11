import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/google_mobile_ads_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/device_service.dart';
import '../../widgets/coin_reward_popup.dart';

class WatchVideosScreen extends StatefulWidget {
  const WatchVideosScreen({super.key});

  @override
  State<WatchVideosScreen> createState() => _WatchVideosScreenState();
}

class _WatchVideosScreenState extends State<WatchVideosScreen> {
  bool _isAdLoading = false;

  NativeAd? _nativeAd;
  bool _nativeLoaded = false;
  
  // Video watching state
  int _videosWatchedToday = 0;
  static const int _dailyVideoLimit = 3;
  static const int _coinsPerVideo = 10;
  static const int _cooldownHours = 5;
  DateTime? _cooldownUntil;
  bool _isLoading = true;
  String? _deviceId;
  
  // Timer for countdown
  Timer? _countdownTimer;
  String _countdownText = '';

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
    _initialize();
  }

  void _loadNativeAd() {
    if (!GoogleMobileAdsService.instance.isEnabled) {
      return;
    }
    if (kDebugMode) {
      _nativeAd = NativeAd(
        adUnitId: AdConfig.nativeAdUnitId,
        listener: NativeAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _nativeLoaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Watch Videos native ad failed: ${error.message}');
            ad.dispose();
          },
        ),
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
        ),
      )..load();
    } else {
      _nativeAd = NativeAd.fromAdManagerRequest(
        adUnitId: AdConfig.nativeUnitId,
        listener: NativeAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _nativeLoaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Watch Videos native ad (Ad Manager) failed: ${error.message}');
            ad.dispose();
          },
        ),
        adManagerRequest: const AdManagerAdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
        ),
      )..load();
    }
  }

  Future<void> _initialize() async {
    // Get device ID
    _deviceId = await DeviceService.getDeviceId();
    if (_deviceId == null) {
      _deviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Load video watching data from local storage
    await _loadVideoData();
    
    
    // Start countdown timer if in cooldown
    if (_cooldownUntil != null && _cooldownUntil!.isAfter(DateTime.now())) {
      _startCountdownTimer();
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadVideoData() async {
    try {
      // Load videos watched today
      final videosWatchedKey = 'watch_videos_count_$_deviceId';
      final videosWatched = await StorageService.getInt(videosWatchedKey);
      _videosWatchedToday = videosWatched ?? 0;
      
      // Load cooldown timestamp
      final cooldownKey = 'watch_videos_cooldown_$_deviceId';
      final cooldownTimestamp = await StorageService.getInt(cooldownKey);
      if (cooldownTimestamp != null) {
        _cooldownUntil = DateTime.fromMillisecondsSinceEpoch(cooldownTimestamp);
        
        // Check if cooldown has expired
        if (_cooldownUntil!.isBefore(DateTime.now())) {
          _cooldownUntil = null;
          _videosWatchedToday = 0; // Reset count after cooldown
          await StorageService.saveInt(videosWatchedKey, 0);
          await StorageService.saveInt(cooldownKey, 0);
        }
      }
      
      // Check if it's a new day (reset daily count)
      final lastDateKey = 'watch_videos_last_date_$_deviceId';
      final lastDateStr = await StorageService.getString(lastDateKey);
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      
      if (lastDateStr != todayStr) {
        // New day, reset count
        _videosWatchedToday = 0;
        await StorageService.saveInt(videosWatchedKey, 0);
        await StorageService.saveString(lastDateKey, todayStr);
      }
    } catch (e) {
      debugPrint('Error loading video data: $e');
    }
  }

  Future<void> _saveVideoData() async {
    try {
      final videosWatchedKey = 'watch_videos_count_$_deviceId';
      await StorageService.saveInt(videosWatchedKey, _videosWatchedToday);
      
      if (_cooldownUntil != null) {
        final cooldownKey = 'watch_videos_cooldown_$_deviceId';
        await StorageService.saveInt(cooldownKey, _cooldownUntil!.millisecondsSinceEpoch);
      }
      
      final lastDateKey = 'watch_videos_last_date_$_deviceId';
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      await StorageService.saveString(lastDateKey, todayStr);
    } catch (e) {
      debugPrint('Error saving video data: $e');
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownUntil == null || !mounted) {
        timer.cancel();
        return;
      }
      
      final now = DateTime.now();
      if (_cooldownUntil!.isBefore(now)) {
        // Cooldown expired
        setState(() {
          _cooldownUntil = null;
          _videosWatchedToday = 0;
        });
        _saveVideoData();
        timer.cancel();
        return;
      }
      
      final difference = _cooldownUntil!.difference(now);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      
      setState(() {
        _countdownText = '${hours}h ${minutes}m';
      });
    });
  }

  Future<void> _watchVideo() async {
    if (!GoogleMobileAdsService.instance.isRewardedAdReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad is loading, please try again in a moment.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check if daily limit reached
    if (_videosWatchedToday >= _dailyVideoLimit) {
      // Check if cooldown is active
      if (_cooldownUntil != null && _cooldownUntil!.isAfter(DateTime.now())) {
        _showCooldownDialog();
        return;
      } else {
        // Cooldown expired, reset
        setState(() {
          _videosWatchedToday = 0;
          _cooldownUntil = null;
        });
        await _saveVideoData();
      }
    }
    
    setState(() {
      _isAdLoading = true;
    });

    await GoogleMobileAdsService.instance.showRewardedAd(
      onRewardEarned: () {
        if (mounted) {
          setState(() {
            _isAdLoading = false;
          });
          _handleVideoWatched();
        }
      },
      onFailed: () {
        if (mounted) {
          setState(() {
            _isAdLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load video ad. Please try again later.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  Future<void> _handleVideoWatched() async {
    // Increment videos watched
    setState(() {
      _videosWatchedToday++;
    });
    
    // Add coins via API
    await _addCoinsToWallet(_coinsPerVideo);
    
    // Show coin reward popup
    if (mounted) {
      _showCoinRewardPopup(_coinsPerVideo);
    }
    
    // Check if all 3 videos watched
    if (_videosWatchedToday >= _dailyVideoLimit) {
      // Set cooldown for 5 hours
      _cooldownUntil = DateTime.now().add(Duration(hours: _cooldownHours));
      _startCountdownTimer();
      
      // Show cooldown dialog after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showCooldownDialog();
        }
      });
    }
    
    // Save data
    await _saveVideoData();
  }

  Future<void> _addCoinsToWallet(int coins) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        return;
      }
      
      final result = await ApiService.addCoins(
        token: token,
        coins: coins,
      );
      
      if (result['success'] != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add coins'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding coins: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCoinRewardPopup(int coins) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CoinRewardPopup(
          coins: coins,
          // No ads on "Add Wallet" button for watch videos
        );
      },
    );
  }

  void _showCooldownDialog() {
    if (_cooldownUntil == null) return;
    
    final now = DateTime.now();
    if (_cooldownUntil!.isBefore(now)) {
      // Cooldown expired
      setState(() {
        _cooldownUntil = null;
        _videosWatchedToday = 0;
      });
      _saveVideoData();
      return;
    }
    
    Timer? dialogTimer;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Initialize timer only once
            if (dialogTimer == null || !dialogTimer!.isActive) {
              dialogTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (!mounted) {
                  timer.cancel();
                  return;
                }
                
                final now = DateTime.now();
                if (_cooldownUntil == null || _cooldownUntil!.isBefore(now)) {
                  timer.cancel();
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }
                  setState(() {
                    _cooldownUntil = null;
                    _videosWatchedToday = 0;
                  });
                  _saveVideoData();
                  return;
                }
                
                // Trigger rebuild of dialog
                setDialogState(() {});
              });
            }
            
            final now = DateTime.now();
            if (_cooldownUntil == null || _cooldownUntil!.isBefore(now)) {
              Future.microtask(() {
                dialogTimer?.cancel();
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
              });
              return const SizedBox.shrink();
            }
            
            final difference = _cooldownUntil!.difference(now);
            final hours = difference.inHours;
            final minutes = difference.inMinutes % 60;
            
            return AlertDialog(
              backgroundColor: AppColors.cardBackground(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Daily Limit Reached',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Colors.orange, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'You have watched all 3 videos today!',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Next videos available in:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${hours}h ${minutes}m',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    dialogTimer?.cancel();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Clean up timer when dialog is closed
      dialogTimer?.cancel();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Watch Videos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact copy — rewarded ad plays when user taps the button below
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: AppColors.primary,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Watch a rewarded ad',
                              style: TextStyle(
                                color: AppColors.textPrimary(context),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the button to earn $_coinsPerVideo coins per video (up to $_dailyVideoLimit per day).',
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daily Progress',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$_videosWatchedToday/$_dailyVideoLimit',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _videosWatchedToday / _dailyVideoLimit,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade800,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        ),
                        if (_cooldownUntil != null && _cooldownUntil!.isAfter(DateTime.now())) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Next videos in: $_countdownText',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Watch Video Button (loads Google rewarded ad)
                  ValueListenableBuilder<bool>(
                    valueListenable: GoogleMobileAdsService.instance.rewardedReadyNotifier,
                    builder: (context, isRewardedReady, _) {
                      final isDailyLimitLocked =
                          _videosWatchedToday >= _dailyVideoLimit &&
                          _cooldownUntil != null &&
                          _cooldownUntil!.isAfter(DateTime.now());
                      final isEnabled = !isDailyLimitLocked && isRewardedReady;

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isEnabled ? _watchVideo : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDailyLimitLocked
                                ? Colors.grey
                                : const Color(0xFFF39C12),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isAdLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : isDailyLimitLocked
                                  ? const Text(
                                      'Daily Limit Reached',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : !isRewardedReady
                                      ? const Text(
                                          'Ad is loading...',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : const Text(
                                          'Watch Video & Earn $_coinsPerVideo Coins',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Native ad (bottom section)
                  if (_nativeLoaded && _nativeAd != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 280,
                        width: double.infinity,
                        child: AdWidget(ad: _nativeAd!),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
