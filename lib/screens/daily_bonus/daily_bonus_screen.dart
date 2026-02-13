import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../wallet/wallet_screen.dart';
import '../scratch_card/scratch_card_screen.dart';

class DailyBonusScreen extends StatefulWidget {
  const DailyBonusScreen({super.key});

  @override
  State<DailyBonusScreen> createState() => _DailyBonusScreenState();
}

class _DailyBonusScreenState extends State<DailyBonusScreen> {
  List<Map<String, dynamic>> _bonuses = [];
  String _rewardType = 'Coins';
  String _currentDay = '';
  bool _isLoading = true;
  bool _isClaiming = false;
  double _walletBalance = 0.0;
  int _coins = 0;
  bool _isLoadingBalance = true;
  bool _scratchCardClaimed = false;
  bool _canClaimScratchCard = false;
  bool _isLoadingScratchCard = true;

  @override
  void initState() {
    super.initState();
    _fetchDailyBonuses();
    _fetchWalletBalance();
    _fetchScratchCard();
  }

  Future<void> _fetchScratchCard() async {
    setState(() {
      _isLoadingScratchCard = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingScratchCard = false;
        });
        return;
      }

      final result = await ApiService.getScratchCard(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          _scratchCardClaimed = data['isClaimed'] ?? false;
          _canClaimScratchCard = data['canClaim'] ?? false;
          _isLoadingScratchCard = false;
        });
      } else {
        setState(() {
          _isLoadingScratchCard = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingScratchCard = false;
      });
    }
  }

  Future<void> _fetchWalletBalance() async {
    setState(() {
      _isLoadingBalance = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingBalance = false;
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

          _isLoadingBalance = false;
        });
      } else {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingBalance = false;
      });
    }
  }

  Future<void> _fetchDailyBonuses() async {
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

      final result = await ApiService.getDailyBonuses(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          _bonuses = List<Map<String, dynamic>>.from(data['bonuses'] ?? []);
          _rewardType = data['rewardType'] ?? 'Coins';
          _currentDay = data['currentDay'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch daily bonuses'),
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

  Future<void> _claimBonus(String day) async {
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

      final result = await ApiService.claimDailyBonus(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        
        // Update wallet balance and coins from response
        setState(() {
          // Update coins
          final coinsValue = data['totalCoins'] ?? data['coins'];
          if (coinsValue is int) {
            _coins = coinsValue;
          } else if (coinsValue is double) {
            _coins = coinsValue.toInt();
          } else if (coinsValue is String) {
            _coins = int.tryParse(coinsValue) ?? _coins;
          }

          // Update wallet balance
          final balanceValue = data['totalWalletBalance'] ?? data['walletBalance'];
          if (balanceValue is double) {
            _walletBalance = balanceValue;
          } else if (balanceValue is int) {
            _walletBalance = balanceValue.toDouble();
          } else if (balanceValue is String) {
            _walletBalance = double.tryParse(balanceValue) ?? _walletBalance;
          }
        });

        // Refresh bonuses after claiming
        await _fetchDailyBonuses();

        if (mounted) {
          final amount = data['amount'] ?? 0;
          final rewardType = data['rewardType'] ?? 'Coins';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Success! You earned ${rewardType == 'Coins' ? '$amount Coins' : '₹$amount'}',
              ),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to claim bonus'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
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
          'Daily Bonus',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchDailyBonuses();
          await _fetchWalletBalance();
          await _fetchScratchCard();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Balance Card
                _buildBalanceCard(context),
                const SizedBox(height: 16),

                // VIP Level Card
                _buildVIPCard(),
                const SizedBox(height: 24),

                // Daily Bonus Check-in
                _buildCheckInSection(),
                const SizedBox(height: 24),

                // Music Streak
                _buildMusicStreakCard(context),
                const SizedBox(height: 24),

                // Scratch & Win
                _buildScratchAndWinSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return formatter.format(amount);
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet Balance',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _isLoadingBalance
                        ? const SizedBox(
                            height: 28,
                            width: 100,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          )
                        : Text(
                            _formatCurrency(_walletBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WalletScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Withdraw',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Coins display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundLight(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: AppColors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coins',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _isLoadingBalance
                          ? const SizedBox(
                              height: 18,
                              width: 60,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              '$_coins',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVIPCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Yellow checkmark icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.yellow,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VIP Level 3: Gold',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Earn 20% more on every task completed',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.diamond_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '750 XP',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '1000 XP to Platinum',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.75,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Weekly Daily Bonus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_currentDay.isNotEmpty)
              Text(
                _currentDay,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  children: [
                    // Week days header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                        return SizedBox(
                          width: 36,
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Daily bonuses
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _bonuses.map((bonus) {
                        return _buildBonusDay(bonus);
                      }).toList(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildBonusDay(Map<String, dynamic> bonus) {
    final day = bonus['day'] ?? '';
    final amount = bonus['amount'] ?? 0;
    final claimed = bonus['claimed'] ?? false;
    final isToday = bonus['isToday'] ?? false;
    
    // Get first letter of day for display
    final dayLetter = day.isNotEmpty ? day[0] : '';
    
    Color bgColor;
    Color textColor;
    Widget child;

    if (claimed) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
      child = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (isToday) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
      child = GestureDetector(
        onTap: _isClaiming ? null : () => _claimBonus(day),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayLetter,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _rewardType == 'Coins' ? '$amount' : '₹$amount',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      bgColor = const Color(0xFF2A2A3E);
      textColor = Colors.grey.shade500;
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayLetter,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _rewardType == 'Coins' ? '$amount' : '₹$amount',
            style: TextStyle(
              color: textColor,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: isToday && !claimed && !_isClaiming
          ? () => _claimBonus(day)
          : null,
      child: Container(
        width: 50,
        height: 60,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !claimed
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }


  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Coming Soon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'This feature is coming soon!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicStreakCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D2A6A), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'MUSIC STREAK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '4 Days',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Don't break the chain!",
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Listen for 5 mins today.',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.headphones,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              _showComingSoonDialog(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: Text(
                  'Listen Now',
                  style: TextStyle(
                    color: Color(0xFF3D2A6A),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchAndWinSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Scratch & Win',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScratchCardScreen(),
                    ),
                  ).then((_) {
                    // Refresh scratch card status when returning
                    _fetchScratchCard();
                    _fetchWalletBalance();
                  });
                },
                child: _buildScratchCard(
                  title: 'Daily Lucky\nDraw',
                  icon: Icons.card_giftcard,
                  iconColor: AppColors.yellow,
                  status: _isLoadingScratchCard
                      ? 'Loading...'
                      : _scratchCardClaimed
                          ? 'Claimed'
                          : _canClaimScratchCard
                              ? 'Ready'
                              : 'Not Available',
                  statusColor: _isLoadingScratchCard
                      ? Colors.grey
                      : _scratchCardClaimed
                          ? Colors.grey
                          : _canClaimScratchCard
                              ? AppColors.green
                              : Colors.grey,
                  isLocked: !_canClaimScratchCard || _scratchCardClaimed,
                  isSquare: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildScratchCard(
                title: 'Survey Bonus',
                icon: Icons.lock_outline,
                iconColor: Colors.grey,
                status: 'Complete 1 survey to unlock',
                statusColor: Colors.grey,
                isLocked: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScratchCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String status,
    required Color statusColor,
    required bool isLocked,
    bool isSquare = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isSquare ? BorderRadius.circular(8) : null,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isLocked ? Colors.grey : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
