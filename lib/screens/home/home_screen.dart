import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/home/header_widget.dart';
import '../../widgets/home/balance_card.dart';
import '../../widgets/home/earn_money_section.dart';
import '../../widgets/home/quick_actions_row.dart'; // New Import
import '../../widgets/home/leaderboard_section.dart';
import '../../widgets/home/popup_template_dialog.dart';
import '../../widgets/signup_bonus_popup.dart';
import '../../screens/auth/login_screen.dart';
import '../../core/models/popup_template_public.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Persistent flag — once the popup has been shown to the user one time,
  /// the value `'1'` is written here and the dialog will never appear again
  /// on this device (regardless of how many times the app is opened, the
  /// user logs out and back in, or the popup template changes on the
  /// server).
  static const String _popupShownOnceKey = 'home_popup_template_shown_once';

  bool _popupCheckInFlight = false;

  double _walletBalance = 0.0;
  int _coins = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runHomePopupsSequentially();
    });
  }

  Future<void> _runHomePopupsSequentially() async {
    if (_popupCheckInFlight) return;
    _popupCheckInFlight = true;
    try {
      await _checkAndShowSignupBonus();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await _checkAndShowPopupTemplate();
    } finally {
      _popupCheckInFlight = false;
    }
  }

  Future<void> _checkAndShowPopupTemplate() async {
    // Show the popup ONLY the very first time the user lands on the home
    // screen on this device. Subsequent app launches must never see it.
    final alreadyShown =
        await StorageService.getString(_popupShownOnceKey);
    if (alreadyShown == '1') {
      debugPrint('Popup template skipped — already shown once on this device');
      return;
    }

    try {
      final result = await ApiService.getPopupTemplatePublic();
      if (!mounted) return;
      if (result['success'] != true) {
        debugPrint(
          'Popup template skipped — API non-success: ${result['message']}',
        );
        return;
      }

      final raw = result['data'];
      if (raw is! Map) {
        debugPrint('Popup template skipped — data is not a Map: $raw');
        return;
      }

      final template = PopupTemplatePublic.fromJson(
        Map<String, dynamic>.from(raw),
      );
      if (!template.shouldShow) {
        debugPrint(
          'Popup template skipped — shouldShow=false '
          '(isActive=${template.isActive}, hasTitle=${template.title != null}, '
          'hasBody=${template.body != null}, hasImage=${template.imageUrl != null})',
        );
        return;
      }

      // Mark as shown BEFORE awaiting the dialog so that even if the user
      // backgrounds the app while the popup is open, we never show it twice.
      await StorageService.saveString(_popupShownOnceKey, '1');

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => PopupTemplateDialog(template: template),
      );
    } catch (e) {
      debugPrint('Error fetching popup template: $e');
    }
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
          await showDialog<void>(
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
                  const SizedBox(height: 16),

                  // Leaderboard Section
                  const LeaderboardSection(),
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

