import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen>
    with SingleTickerProviderStateMixin {
  String _referCode = '';
  int _referralCount = 0;
  double _totalEarnings = 0.0;
  String _rewardType = 'Coins';
  double _rewardPerReferral = 0.0;
  bool _isLoading = true;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _fetchReferCode();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _fetchReferCode() async {
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

      final result = await ApiService.getReferCode(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          _referCode = data['ReferCode'] ?? '';
          
          // Handle different number types for ReferralCount
          final count = data['ReferralCount'];
          if (count is int) {
            _referralCount = count;
          } else if (count is double) {
            _referralCount = count.toInt();
          } else if (count is String) {
            _referralCount = int.tryParse(count) ?? 0;
          } else {
            _referralCount = 0;
          }

          // Handle TotalEarnings
          final earnings = data['TotalEarnings'];
          if (earnings is double) {
            _totalEarnings = earnings;
          } else if (earnings is int) {
            _totalEarnings = earnings.toDouble();
          } else if (earnings is String) {
            _totalEarnings = double.tryParse(earnings) ?? 0.0;
          } else {
            _totalEarnings = 0.0;
          }

          // Handle RewardType
          _rewardType = data['RewardType'] ?? 'Coins';

          // Handle RewardPerReferral
          final rewardPerRef = data['RewardPerReferral'];
          if (rewardPerRef is double) {
            _rewardPerReferral = rewardPerRef;
          } else if (rewardPerRef is int) {
            _rewardPerReferral = rewardPerRef.toDouble();
          } else if (rewardPerRef is String) {
            _rewardPerReferral = double.tryParse(rewardPerRef) ?? 0.0;
          } else {
            _rewardPerReferral = 0.0;
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch referral code'),
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
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Refer & Earn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border(context), width: 1),
            ),
            child: const Icon(Icons.history, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Hero Image
                  _buildHeroImage(),
                  
                  // Title & Subtitle
                  _buildTitleSection(),
                  const SizedBox(height: 24),
                  
                  // Referral Code
                  _buildReferralCodeSection(context),
                  const SizedBox(height: 20),
                  
                  // Stats Cards
                  _buildStatsCards(),
                  const SizedBox(height: 28),
                  
                  // How it works
                  _buildHowItWorks(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Bottom Buttons
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      width: double.infinity,
      height: 220,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7DD3C0), Color(0xFF5CBCA9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Two people illustration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Person 1 (Male)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8C4A8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.grey, size: 40),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5DADE2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Gift box
                  Container(
                    width: 35,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFFB74D), width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.card_giftcard, color: Color(0xFFFFB74D), size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 40),
              // Person 2 (Female)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8C4A8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.grey, size: 40),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Gift box
                  Container(
                    width: 35,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF81C784), width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.card_giftcard, color: Color(0xFF81C784), size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Text(
            'Invite Friends,',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Earn Real Cash!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Get '),
                TextSpan(
                  text: _rewardType == 'Coins'
                      ? '$_rewardPerReferral Coins'
                      : '₹$_rewardPerReferral',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' for every friend who completes their first task.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + _shimmerController.value * 2, 0),
              end: Alignment(1.0 + _shimmerController.value * 2, 0),
              colors: const [
                Colors.white24,
                Colors.white38,
                Colors.white24,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: Container(
            height: 24,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReferralCodeSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              'YOUR REFERRAL CODE',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _isLoading
                        ? _buildReferralCodeSkeleton()
                        : Text(
                            _referCode.isEmpty ? 'N/A' : _referCode,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                  GestureDetector(
                    onTap: _referCode.isEmpty || _isLoading
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: _referCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Referral code copied!'),
                                backgroundColor: AppColors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                    child: Opacity(
                      opacity: (_referCode.isEmpty || _isLoading) ? 0.5 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Copy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.copy, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + _shimmerController.value * 2, 0),
              end: Alignment(1.0 + _shimmerController.value * 2, 0),
              colors: const [
                Colors.white24,
                Colors.white38,
                Colors.white24,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: Container(
            height: 28,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.group_add, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? _buildStatSkeleton()
                      : Text(
                          _referralCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    'Friends Joined',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _rewardType == 'Coins'
                          ? const Icon(
                              Icons.monetization_on,
                              color: AppColors.primary,
                              size: 22,
                            )
                          : const Text(
                              '₹',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? _buildStatSkeleton()
                      : Text(
                          _rewardType == 'Coins'
                              ? '$_totalEarnings'
                              : '₹$_totalEarnings',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Earned',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildHowItWorksItem(
            icon: Icons.share,
            iconColor: AppColors.primary,
            title: 'Share your link',
            description: 'Send your unique link to friends via WhatsApp or Telegram.',
          ),
          const SizedBox(height: 16),
          _buildHowItWorksItem(
            icon: Icons.smartphone,
            iconColor: Colors.grey,
            title: 'Friend signs up & plays',
            description: 'They create an account and complete their first micro-task.',
          ),
          const SizedBox(height: 16),
          _buildHowItWorksItem(
            icon: Icons.account_balance_wallet,
            iconColor: Colors.grey,
            title: 'You get paid instantly',
            description: '₹50 is credited directly to your Profit Karo wallet.',
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        border: Border(
          top: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // WhatsApp Button
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.chat, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'WhatsApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Telegram Button
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0088CC),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.send, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Telegram',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // More Button
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(Icons.more_horiz, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
