import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/referral_service.dart';

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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/referearnthubnail.jpeg',
          width: double.infinity,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient if image fails to load
            if (kDebugMode) {
              print('Error loading referearnthubnail.jpeg: $error');
            }
            return Container(
              height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7DD3C0), Color(0xFF5CBCA9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
              child: Center(
                child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                    Icon(
                      Icons.image_not_supported,
                      color: Colors.white.withOpacity(0.5),
                      size: 48,
                  ),
                  const SizedBox(height: 8),
                    Text(
                      'Image not found',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        ),
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
                const TextSpan(text: 'Earn up to '),
                const TextSpan(
                  text: '₹150',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' per referral by inviting your friends to the app.'),
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

  Widget _buildReferralLinkSkeleton() {
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
            height: 16,
            width: 180,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF201E2B), // Dark indigo background like in image
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // QR Code Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Refer Link Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Refer Link',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isLoading
                      ? _buildReferralLinkSkeleton()
                      : _referCode.isEmpty
                          ? Text(
                              'N/A',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            )
                      : Text(
                              ReferralService.getReferralUrl(_referCode),
                              style: TextStyle(
                            color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                          ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                        ),
                ],
              ),
            ),
            // Copy Button
            GestureDetector(
              onTap: _referCode.isEmpty || _isLoading
                  ? null
                        : () {
                            // Copy the full referral URL using ReferralService (path format)
                            final referralUrl = ReferralService.getReferralUrl(_referCode);
                            Clipboard.setData(ClipboardData(text: referralUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Referral link copied! Share it with friends.'),
                          backgroundColor: AppColors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
              child: Opacity(
                opacity: (_referCode.isEmpty || _isLoading) ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Copy Link',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
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
            'Refer & Earn Program',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Invite your friends to join Profit Karo and earn exciting rewards.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Earning Points
          _buildEarningPoint(
            'Earn up to ₹150 per referral by inviting your friends to the app.',
          ),
          const SizedBox(height: 12),
          _buildEarningPoint(
            'Get ₹10 instantly when your friend completes their first 3 tasks after joining.',
          ),
          const SizedBox(height: 12),
          _buildEarningPoint(
            'After that, whenever your friend earns on the app, you will receive 5% of their earnings as a bonus.',
          ),
          const SizedBox(height: 24),
          // Bonus Tiers
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Referral Bonus Tiers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBonusTier('Refer 10 friends', 'Get ₹20 Bonus'),
                const SizedBox(height: 12),
                _buildBonusTier('Refer 50 friends', 'Get ₹100 Bonus'),
                const SizedBox(height: 12),
                _buildBonusTier('Refer 100 friends', 'Get ₹250 Bonus'),
                const SizedBox(height: 12),
                _buildBonusTier('Refer 200 friends', 'Get ₹500 Mega Bonus', isHighlighted: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Closing Message
        Container(
            padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                  children: [
                    Icon(
                      Icons.celebration,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'That means when your friends earn, you earn too!',
                        style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              Text(
                  'Start sharing your referral link now and grow your earnings together.',
                style: TextStyle(
                    color: Colors.grey.shade400,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildEarningPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBonusTier(String friends, String bonus, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isHighlighted
            ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: isHighlighted ? AppColors.primary : Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                friends,
                style: TextStyle(
                  color: isHighlighted ? Colors.white : Colors.grey.shade300,
                  fontSize: 14,
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            bonus,
            style: TextStyle(
              color: isHighlighted ? AppColors.primary : Colors.grey.shade400,
              fontSize: 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Get the share message with referral code and URL
  String _getShareMessage() {
    if (_referCode.isEmpty) {
      return 'Join Profit Karo and start earning!';
    }
    final referralUrl = ReferralService.getReferralUrl(_referCode);
    return 'Join Profit Karo and start earning!\n\nUse my referral code: $_referCode\n\nGet the app here: $referralUrl';
  }

  /// Share via WhatsApp
  Future<void> _shareViaWhatsApp() async {
    if (_referCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final message = _getShareMessage();
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/?text=$encodedMessage';
      final uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp is not installed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing via WhatsApp: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Share via Telegram
  Future<void> _shareViaTelegram() async {
    if (_referCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final referralUrl = ReferralService.getReferralUrl(_referCode);
      final message = 'Join Profit Karo and start earning!\n\nUse my referral code: $_referCode';
      final encodedUrl = Uri.encodeComponent(referralUrl);
      final encodedMessage = Uri.encodeComponent(message);
      final telegramUrl = 'https://t.me/share/url?url=$encodedUrl&text=$encodedMessage';
      final uri = Uri.parse(telegramUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telegram is not installed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing via Telegram: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Share via system share sheet
  Future<void> _shareViaSystem() async {
    if (_referCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final message = _getShareMessage();
      await Share.share(
        message,
        subject: 'Join Profit Karo - Referral Code: $_referCode',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              child: GestureDetector(
                onTap: (_referCode.isEmpty || _isLoading) ? null : _shareViaWhatsApp,
                child: Opacity(
                  opacity: (_referCode.isEmpty || _isLoading) ? 0.5 : 1.0,
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
              ),
            ),
            const SizedBox(width: 12),
            // Telegram Button
            Expanded(
              child: GestureDetector(
                onTap: (_referCode.isEmpty || _isLoading) ? null : _shareViaTelegram,
                child: Opacity(
                  opacity: (_referCode.isEmpty || _isLoading) ? 0.5 : 1.0,
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
              ),
            ),
            const SizedBox(width: 12),
            // More Button
            GestureDetector(
              onTap: (_referCode.isEmpty || _isLoading) ? null : _shareViaSystem,
              child: Opacity(
                opacity: (_referCode.isEmpty || _isLoading) ? 0.5 : 1.0,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(Icons.more_horiz, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
