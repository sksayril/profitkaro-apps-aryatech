import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/home/header_widget.dart';
import '../../widgets/home/balance_card.dart';
import '../../widgets/home/hot_offers_section.dart';
import '../../widgets/home/earn_money_section.dart';
import '../../widgets/home/quick_actions_row.dart'; // New Import
import '../../widgets/home/leaderboard_section.dart';
import '../../widgets/home/watch_videos_card.dart';
import '../../widgets/signup_bonus_popup.dart';
import '../../screens/auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _walletBalance = 0.0;
  int _coins = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
    _checkAndShowSignupBonus();
  }

  Future<void> _checkAndShowSignupBonus() async {
    // Wait a bit for the screen to load
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Check if signup bonus has already been shown
    final hasBeenShown = await StorageService.hasSignupBonusBeenShown();
    if (hasBeenShown) return;
    
    // Get token
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return;
    
    // Fetch signup bonus info
    try {
      final result = await ApiService.getSignupBonusInfo(token: token);
      
      if (mounted && result['success'] && result['data'] != null) {
        final data = result['data'];
        final signupBonusAmount = (data['signupBonusAmount'] ?? 0).toDouble();
        final rewardType = data['rewardType'] ?? 'Coins';
        final description = data['description'] ?? 'New users receive bonus as signup reward';
        final isCoins = rewardType.toLowerCase() == 'coins';
        
        // Show the popup
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => SignupBonusPopup(
              signupBonusAmount: signupBonusAmount,
              rewardType: rewardType,
              description: description,
              onClose: () async {
                // Mark as shown
                await StorageService.markSignupBonusAsShown();
                // Refresh balance to get updated values from server
                _fetchWalletBalance();
              },
              onBonusAdded: (balance, coins) {
                // Update local state immediately for better UX
                if (mounted) {
                  setState(() {
                    if (isCoins) {
                      _coins += coins;
                    } else {
                      _walletBalance += balance;
                    }
                  });
                }
              },
            ),
          );
        }
      }
    } catch (e) {
      // Silently fail - don't show error for bonus popup
      debugPrint('Error fetching signup bonus: $e');
    }
  }

  Future<void> _fetchWalletBalance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final result = await ApiService.getWalletBalance(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          // Handle different number types from API
          final balance = data['WalletBalance'];
          if (balance is double) {
            _walletBalance = balance;
          } else if (balance is int) {
            _walletBalance = balance.toDouble();
          } else if (balance is String) {
            _walletBalance = double.tryParse(balance) ?? 0.0;
          } else {
            _walletBalance = 0.0;
          }

          final coinsValue = data['Coins'];
          if (coinsValue is int) {
            _coins = coinsValue;
          } else if (coinsValue is double) {
            _coins = coinsValue.toInt();
          } else if (coinsValue is String) {
            _coins = int.tryParse(coinsValue) ?? 0;
          } else {
            _coins = 0;
          }

          _isLoading = false;
        });
      } else if (result['isBlocked'] == true) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Account Blocked'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result['message'] ?? 'Your account has been blocked.'),
                  if (result['blockedReason'] != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Reason: ${result['blockedReason']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Text('Please contact the administrator.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Clear storage and logout
                    await StorageService.clearAll();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch wallet balance'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchWalletBalance,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  const HeaderWidget(),
                  const SizedBox(height: 24),

                  // Total Balance Card
                  BalanceCard(
                    walletBalance: _walletBalance,
                    coins: _coins,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions Row (Claim Bonus, Daily Deals, Refer & Earn)
                  const QuickActionsRow(),
                  const SizedBox(height: 24),

                  // Watch Videos
                  const WatchVideosCard(),
                  const SizedBox(height: 24),

                  // Leaderboard Section
                  const LeaderboardSection(),
                  const SizedBox(height: 24),

                  // Hot Offers Section
                  const HotOffersSection(),
                  const SizedBox(height: 24),

                  // Earn Money Section
                  const EarnMoneySection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
