import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/coin_reward_popup.dart';

class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isClaiming = false;
  bool _isScratched = false;
  bool _isClaimed = false;
  String? _currentDay;
  int? _todayAmount;
  String? _rewardType;
  Map<String, dynamic>? _allDays;
  List<List<Offset>> _scratchPaths = [];
  final GlobalKey _scratchKey = GlobalKey();
  
  // AdMob Configuration
  static const String _rewardedAdUnitId = 'ca-app-pub-4532355113190688/5923175121';
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  
  // Track scratch card count for alternating ads pattern (1st = Ads, 2nd = Skip, 3rd = Ads, etc.)
  int _scratchCardCount = 0; // Track total scratch cards claimed
  
  // Animation for card switching
  late AnimationController _switchAnimationController;
  late Animation<double> _switchAnimation;
  int _cardKey = 0; // Key to force rebuild for animation
  bool _isSwipingOut = false; // Track if card is swiping out
  bool _popupClosedByUser = false; // Track if popup was closed by user clicking GREAT

  @override
  void initState() {
    super.initState();
    _switchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _switchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _switchAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _loadScratchCardCount();
    _initializeAds();
    _fetchScratchCard();
  }

  void _initializeAds() {
    MobileAds.instance.initialize().then((status) {
      _loadRewardedAd();
    });
  }

  void _loadRewardedAd() {
    if (_isAdLoading) return;
    
    setState(() {
      _isAdLoading = true;
      _isAdLoaded = false;
    });

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
            _isAdLoading = false;
          });
          
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              if (mounted) {
                setState(() {
                  _rewardedAd = null;
                  _isAdLoaded = false;
                });
                // Reload ad for next time
                _loadRewardedAd();
              }
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();
              if (mounted) {
                setState(() {
                  _rewardedAd = null;
                  _isAdLoaded = false;
                });
                // Retry loading ad
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    _loadRewardedAd();
                  }
                });
              }
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          setState(() {
            _isAdLoading = false;
            _isAdLoaded = false;
          });
        },
      ),
    );
  }

  Future<void> _loadScratchCardCount() async {
    final count = await StorageService.getInt('scratch_card_count');
    setState(() {
      _scratchCardCount = count ?? 0;
    });
  }

  Future<void> _saveScratchCardCount(int count) async {
    await StorageService.saveInt('scratch_card_count', count);
    setState(() {
      _scratchCardCount = count;
    });
  }

  // Check if current scratch card should show ad when "Add Wallet" button is clicked
  // Pattern: 1 Ads + 1 Skip
  // 1st scratch card = Ads, 2nd = Skip, 3rd = Ads, 4th = Skip, 5th = Ads, 6th = Skip, 7th = Ads, 8th = Skip, 9th = Ads, etc.
  bool _shouldShowAd() {
    // Count 0 (1st card) → Show Ad
    // Count 1 (2nd card) → Skip (No Ads)
    // Count 2 (3rd card) → Show Ad
    // Count 3 (4th card) → Skip (No Ads)
    // Count 4 (5th card) → Show Ad
    // Count 5 (6th card) → Skip (No Ads)
    // Count 6 (7th card) → Show Ad
    // Count 7 (8th card) → Skip (No Ads)
    // Count 8 (9th card) → Show Ad
    // Pattern: count % 2 == 0 means show ad (1st, 3rd, 5th, 7th, 9th...)
    return (_scratchCardCount % 2 == 0);
  }

  void _showRewardedAd({required VoidCallback onAdWatched, VoidCallback? onSkip}) async {
    // If ad is not loaded, try to load it first
    if (!_isAdLoaded && !_isAdLoading) {
      _loadRewardedAd();
      // Wait for ad to load (with timeout)
      int waitCount = 0;
      while (!_isAdLoaded && waitCount < 30 && mounted) {
        await Future.delayed(const Duration(milliseconds: 200));
        waitCount++;
      }
    }
    
    if (_rewardedAd != null && _isAdLoaded) {
      // Ad is loaded and ready, show it
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // User watched ad, proceed with claim
          onAdWatched();
        },
      );
    } else {
      // Ad not loaded, show loading message and wait
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading ad... Please wait'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Try to load ad and wait
        if (!_isAdLoading) {
          _loadRewardedAd();
        }
        
        // Wait for ad to load (with timeout)
        int waitCount = 0;
        while (!_isAdLoaded && waitCount < 30 && mounted) {
          await Future.delayed(const Duration(milliseconds: 200));
          waitCount++;
        }
        
        // If ad loaded, show it
        if (_rewardedAd != null && _isAdLoaded && mounted) {
          _rewardedAd!.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              onAdWatched();
            },
          );
        } else {
          // Ad still not ready after waiting, proceed anyway
          if (mounted) {
            onAdWatched();
          }
        }
      } else {
        // Not mounted, but still proceed
        onAdWatched();
      }
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _switchAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchScratchCard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await ApiService.getScratchCard(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          _currentDay = data['currentDay'] ?? '';
          // Handle todayAmount - can be int or double
          final todayAmountValue = data['todayAmount'];
          if (todayAmountValue is int) {
            _todayAmount = todayAmountValue;
          } else if (todayAmountValue is double) {
            _todayAmount = todayAmountValue.toInt();
          } else {
            _todayAmount = 0;
          }
          _rewardType = data['rewardType'] ?? 'Coins';
          _isClaimed = data['isClaimed'] ?? false;
          _isScratched = _isClaimed; // If already claimed, show as scratched
          _allDays = data['allDays'] ?? {};
          _isLoading = false;
        });
        
        // If card is already claimed when fetched, automatically get next card
        if (_isClaimed && mounted) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              _resetAndFetchNext();
            }
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch scratch card'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _claimReward() async {
    if (_isClaimed || _isClaiming) return;

    // No ads on claim button - ads will show when "Add Wallet" button is clicked
    // Directly process claim
    _processClaim();
  }

  Future<void> _processClaim() async {
    setState(() {
      _isClaiming = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isClaiming = false;
        });
        return;
      }

      final result = await ApiService.claimScratchCard(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        final amount = data['amount'] ?? _todayAmount;
        final type = data['rewardType'] ?? _rewardType;
        
        // Store current count before incrementing (for ad pattern check)
        final currentCountForAd = _scratchCardCount;
        
        // Increment scratch card count after successful claim
        final newCount = _scratchCardCount + 1;
        _saveScratchCardCount(newCount);
        
        setState(() {
          _isClaimed = true;
          _isClaiming = false;
        });
        
        if (mounted) {
          final coinsToShow = type == 'Coins' ? amount : 0;
          // Show reward popup - ads will show when "Add Wallet" button is clicked
          _showCoinRewardPopup(coinsToShow, currentCountForAd, () {
            // Callback when popup is closed and ad is watched (if applicable)
          });
        }
      } else {
        setState(() {
          _isClaiming = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to claim reward'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isClaiming = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetAndFetchNext() {
    if (!mounted) return;
    
    // First, swipe out the claimed card
    setState(() {
      _isSwipingOut = true;
      _cardKey++; // Increment key to trigger swipe out animation
    });
    
    // Wait for swipe out animation to complete, then fetch next card
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      
      // Reset state for next scratch card
      setState(() {
        _isScratched = false;
        _isClaimed = false;
        _isClaiming = false;
        _scratchPaths.clear();
        _isSwipingOut = false;
        _cardKey++; // Increment again to trigger slide in animation for new card
      });
      
      // Fetch next scratch card and reload screen
      _fetchScratchCard();
    });
  }

  void _showCoinRewardPopup(int coins, int countForAdCheck, VoidCallback? onClose) {
    // Reset flag
    _popupClosedByUser = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return CoinRewardPopup(
          coins: coins,
          onClose: () {
            // This will be called after ad is watched (via onGreatButtonClick)
            // Call the provided onClose callback if available
            onClose?.call();
          },
          onGreatButtonClick: () {
            // Mark popup as closed by user to prevent auto-close
            _popupClosedByUser = true;
            // Close the popup dialog first
            Navigator.of(dialogContext).pop();
            
            // Check if we should show ad based on alternating pattern when "Add Wallet" button is clicked
            // Pattern: 1 Ads + 1 Skip
            // 1st = Ads, 2nd = Skip, 3rd = Ads, 4th = Skip, 5th = Ads, 6th = Skip, 7th = Ads, 8th = Skip, 9th = Ads, etc.
            // Use the count before increment (countForAdCheck)
            final shouldShowAd = (countForAdCheck % 2 == 0);
            
            if (shouldShowAd) {
              // Show rewarded ad (for 1st, 3rd, 5th, 7th, 9th, etc.)
              _showRewardedAd(
                onAdWatched: () {
                  // After ad is watched, proceed to next card
                  if (mounted) {
                    _reloadScreenAndFetchNext();
                  }
                  // Call onClose callback if available
                  onClose?.call();
                },
              );
            } else {
              // Skip ad (for 2nd, 4th, 6th, 8th, etc.) - directly proceed to next card without ads
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _reloadScreenAndFetchNext();
                }
              });
              // Call onClose callback if available
              onClose?.call();
            }
          },
        );
      },
    );
    
    // Auto-close popup after 5 seconds if user doesn't click GREAT button
    // This ensures automatic progression even without user interaction
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_popupClosedByUser) {
        // Close popup if still open
        try {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          // Popup might already be closed, continue anyway
        }
        // Automatically proceed to next card after popup auto-closes
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _reloadScreenAndFetchNext();
          }
        });
      }
    });
  }

  void _reloadScreenAndFetchNext() {
    if (!mounted) return;
    
    // First, swipe out the claimed card if it's still visible
    if (_isClaimed) {
      setState(() {
        _isSwipingOut = true;
        _cardKey++; // Increment key to trigger swipe out animation
      });
      
      // Wait for swipe out animation to complete, then reset and fetch next card
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        
        // Reset all state for fresh start
        setState(() {
          _isScratched = false;
          _isClaimed = false;
          _isClaiming = false;
          _scratchPaths.clear();
          _isSwipingOut = false;
          _cardKey++; // Increment again to trigger slide in animation for new card
        });
        
        // Reload screen by fetching next scratch card
        _fetchScratchCard();
      });
    } else {
      // If not claimed, just reset and fetch
      setState(() {
        _isScratched = false;
        _isClaimed = false;
        _isClaiming = false;
        _scratchPaths.clear();
        _isSwipingOut = false;
        _cardKey++; // Increment key to trigger rebuild
      });
      
      // Reload screen by fetching next scratch card
      _fetchScratchCard();
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_isClaimed || _isScratched) return;
    
    final RenderBox? renderBox = _scratchKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _scratchPaths.add([localPosition]);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isClaimed || _isScratched || _scratchPaths.isEmpty) return;

    final RenderBox? renderBox = _scratchKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;

    if (localPosition.dx < 0 ||
        localPosition.dx > size.width ||
        localPosition.dy < 0 ||
        localPosition.dy > size.height) {
      return;
    }

    setState(() {
      _scratchPaths.last.add(localPosition);

      int pointsCount = 0;
      for (var path in _scratchPaths) {
        pointsCount += path.length;
      }
      
      if (pointsCount > 150) {
        _isScratched = true;
      }
    });
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
          'Scratch & Win',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to history screen
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Current Day Info
                    if (_currentDay != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Today: $_currentDay',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 30),

                    // Scratch Card with switching animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        // Determine if this is entering or exiting
                        final isExiting = _isSwipingOut && animation.status == AnimationStatus.reverse;
                        
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: isExiting 
                                ? Offset.zero 
                                : const Offset(1.0, 0.0), // New card comes from right
                            end: isExiting 
                                ? const Offset(-1.0, 0.0) // Old card exits to left
                                : Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: isExiting ? Curves.easeIn : Curves.easeOut,
                          )),
                          child: FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: isExiting ? 1.0 : 0.8,
                                end: isExiting ? 0.8 : 1.0,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: isExiting ? Curves.easeIn : Curves.easeOut,
                              )),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey<int>(_cardKey),
                        child: _buildScratchCard(),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Claim Button
                    if (_isScratched && !_isClaimed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isClaiming ? null : _claimReward,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37), // Gold
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isClaiming
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Claim Reward',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                    if (_isClaimed)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.green,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reward Claimed!',
                              style: const TextStyle(
                                color: AppColors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Weekly Rewards Preview
                    if (_allDays != null) _buildWeeklyPreview(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildScratchCard() {
    return Container(
      key: _scratchKey,
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
            blurRadius: 25,
            spreadRadius: 3,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        child: Stack(
          children: [
            // Reward Content (Background) - Purple with Golden accents
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF9C27B0), // Purple
                    const Color(0xFF7B1FA2), // Darker purple
                    const Color(0xFF6A1B9A), // Deep purple
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CustomPaint(
                  painter: _ScratchPainter(_scratchPaths),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Stack(
                      children: [
                        // Sparkles and confetti
                        ..._buildSparkles(),
                        // Cloud-like shapes (white blobs)
                        ..._buildCloudShapes(),
                        // Main content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Gift Box Icon with Ring
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer ring
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                // Inner ring
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                // Gift icon
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.card_giftcard,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Cloud shapes around number
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Left cloud
                                Positioned(
                                  left: 20,
                                  child: _buildCloudBlob(80, 40),
                                ),
                                // Right cloud
                                Positioned(
                                  right: 20,
                                  child: _buildCloudBlob(80, 40),
                                ),
                                // Number with flip animation when revealed
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 450),
                                  transitionBuilder: (child, animation) {
                                    final rotateAnim = Tween<double>(
                                      begin: math.pi / 2,
                                      end: 0.0,
                                    ).animate(animation);

                                    return AnimatedBuilder(
                                      animation: rotateAnim,
                                      child: child,
                                      builder: (context, child) {
                                        final value = rotateAnim.value;
                                        return Transform(
                                          transform: Matrix4.identity()
                                            ..setEntry(3, 2, 0.001)
                                            ..rotateY(value),
                                          alignment: Alignment.center,
                                          child: child,
                                        );
                                      },
                                    );
                                  },
                                  child: Text(
                                    _isScratched || _isClaimed
                                        ? '${_todayAmount ?? 0}'
                                        : '???',
                                    key: ValueKey<bool>(_isScratched || _isClaimed),
                                    style: TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFD4AF37), // Golden color
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                        Shadow(
                                          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Coins text
                            Text(
                              _rewardType ?? 'Coins',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                  Shadow(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                            if (!_isScratched && !_isClaimed) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Scratch to reveal!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFFD4AF37),
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Scratch Layer (Foreground) - Golden/Purple gradient
            if (!_isScratched && !_isClaimed)
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CustomPaint(
                  painter: _ScratchLayerPainter(_scratchPaths),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF7B1FA2),
                          const Color(0xFF6A1B9A),
                          const Color(0xFF4A148C),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Gift box icon on scratch layer
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.card_giftcard,
                                  size: 56,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Scratch Here',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD4AF37),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use your finger to scratch',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudBlob(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSparkles() {
    return [
      // Sparkles around gift icon
      Positioned(
        top: 50,
        left: 50,
        child: Icon(
          Icons.star,
          size: 12,
          color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
        ),
      ),
      Positioned(
        top: 70,
        right: 50,
        child: Icon(
          Icons.star,
          size: 10,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
      Positioned(
        top: 90,
        left: 80,
        child: Icon(
          Icons.star,
          size: 8,
          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
        ),
      ),
      Positioned(
        top: 110,
        right: 70,
        child: Icon(
          Icons.star,
          size: 14,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      // Sparkles around number
      Positioned(
        top: 200,
        left: 40,
        child: Icon(
          Icons.star,
          size: 10,
          color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
        ),
      ),
      Positioned(
        top: 220,
        right: 50,
        child: Icon(
          Icons.star,
          size: 12,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      Positioned(
        top: 240,
        left: 60,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: 250,
        right: 40,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: 50,
        child: Icon(
          Icons.star,
          size: 14,
          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
        ),
      ),
      Positioned(
        bottom: 120,
        right: 60,
        child: Icon(
          Icons.star,
          size: 10,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    ];
  }

  List<Widget> _buildCloudShapes() {
    return [
      // Cloud-like white blobs around the number area
      Positioned(
        top: 180,
        left: 30,
        child: _buildCloudBlob(60, 35),
      ),
      Positioned(
        top: 190,
        right: 30,
        child: _buildCloudBlob(60, 35),
      ),
      Positioned(
        top: 200,
        left: 50,
        child: _buildCloudBlob(50, 30),
      ),
      Positioned(
        top: 210,
        right: 50,
        child: _buildCloudBlob(50, 30),
      ),
    ];
  }

  Widget _buildWeeklyPreview() {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dayAbbr = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Rewards',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final day = days[index];
              final amount = _allDays![day] ?? 0;
              final isToday = day == _currentDay;
              final isClaimedToday = isToday && _isClaimed;

              return Column(
                children: [
                  Text(
                    dayAbbr[index],
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isToday
                          ? (isClaimedToday ? AppColors.green : const Color(0xFFD4AF37))
                          : AppColors.cardBackgroundLight(context),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(
                              color: isClaimedToday ? AppColors.green : const Color(0xFFD4AF37),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: isClaimedToday
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : Text(
                              '$amount',
                              style: TextStyle(
                                color: isToday ? Colors.white : Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// Custom painter for scratch layer
class _ScratchLayerPainter extends CustomPainter {
  final List<List<Offset>> paths;
  _ScratchLayerPainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 1. Cover
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7B1FA2), Color(0xFF6A1B9A), Color(0xFF4A148C)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 2. Dots pattern
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.1);
    for (double i = 0; i < size.width; i += 20) {
      for (double j = 0; j < size.height; j += 20) {
        canvas.drawCircle(Offset(i, j), 1.5, dotPaint);
      }
    }

    // 3. Instruction Text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Scratch Here',
        style: TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, size.height / 2 + 50));

    // 4. Eraser (Paths)
    final eraser = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeWidth = 60
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var pathPoints in paths) {
      if (pathPoints.length > 1) {
        final path = Path();
        path.moveTo(pathPoints[0].dx, pathPoints[0].dy);
        for (int i = 1; i < pathPoints.length; i++) {
          path.lineTo(pathPoints[i].dx, pathPoints[i].dy);
        }
        canvas.drawPath(path, eraser);
      } else if (pathPoints.isNotEmpty) {
        canvas.drawCircle(pathPoints[0], 30, eraser);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScratchLayerPainter oldDelegate) => true;
}

// Custom painter for scratch effect background
class _ScratchPainter extends CustomPainter {
  final List<List<Offset>> paths;
  _ScratchPainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 60
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var pathPoints in paths) {
      if (pathPoints.length > 1) {
        final path = Path();
        path.moveTo(pathPoints[0].dx, pathPoints[0].dy);
        for (int i = 1; i < pathPoints.length; i++) {
          path.lineTo(pathPoints[i].dx, pathPoints[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ScratchPainter oldDelegate) => true;
}

