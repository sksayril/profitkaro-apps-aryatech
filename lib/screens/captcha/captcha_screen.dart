import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class CaptchaScreen extends StatefulWidget {
  const CaptchaScreen({super.key});

  @override
  State<CaptchaScreen> createState() => _CaptchaScreenState();
}

class _CaptchaScreenState extends State<CaptchaScreen> {
  final TextEditingController _captchaController = TextEditingController();
  String _captchaCode = '';
  bool _isLoadingCaptcha = true;
  bool _isSubmitting = false;
  int _todaySolves = 0;
  int _dailyLimit = 10;
  double _rewardAmount = 0.0;
  String _rewardType = 'Coins';
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _fetchCaptcha();
    _fetchProgress();
  }

  @override
  void dispose() {
    _captchaController.dispose();
    super.dispose();
  }

  Future<void> _fetchCaptcha() async {
    setState(() {
      _isLoadingCaptcha = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingCaptcha = false;
        });
        return;
      }

      final result = await ApiService.getCaptcha(token: token);

      if (result['success'] && result['data'] != null) {
        setState(() {
          _captchaCode = result['data']['Captcha'] ?? '';
          _isLoadingCaptcha = false;
        });
      } else {
        setState(() {
          _isLoadingCaptcha = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch captcha'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingCaptcha = false;
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

  Future<void> _fetchProgress() async {
    // Progress will be updated after solving captcha
    setState(() {
      _isLoadingProgress = false;
    });
  }

  void _refreshCaptcha() {
    _captchaController.clear();
    _fetchCaptcha();
  }

  Future<void> _submitCaptcha() async {
    final captchaInput = _captchaController.text.trim().toUpperCase();

    if (captchaInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the captcha code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final result = await ApiService.solveCaptcha(
        token: token,
        captcha: captchaInput,
      );

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          // Update progress from response
          _todaySolves = data['TodaySolves'] ?? 0;
          _dailyLimit = data['DailyLimit'] ?? 10;
          _rewardAmount = (data['RewardAmount'] ?? 0).toDouble();
          _rewardType = data['RewardType'] ?? 'Coins';
        });

        // Clear input and fetch new captcha
        _captchaController.clear();
        _fetchCaptcha();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Success! You earned ${_rewardType == 'Coins' ? '$_rewardAmount Coins' : '₹$_rewardAmount'}',
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
              content: Text(result['message'] ?? 'Failed to solve captcha'),
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
          _isSubmitting = false;
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
          'Captcha Task',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Solve & Earn Card
            _buildSolveEarnCard(),
            const SizedBox(height: 24),
            
            // Daily Progress Section
            _buildDailyProgressSection(),
            const SizedBox(height: 24),
            
            // Pro Tip Section
            _buildProTipSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSolveEarnCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reward and Verified badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.green, width: 1),
                ),
                child: Text(
                  _rewardType == 'Coins'
                      ? 'Reward: $_rewardAmount Coins'
                      : 'Reward: ₹$_rewardAmount',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.verified, color: Colors.grey.shade400, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Verified Task',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Title
          const Text(
            'Solve & Earn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type the characters seen in the image below.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          // Captcha Image Area
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Stack(
              children: [
                // Captcha text
                Center(
                  child: _isLoadingCaptcha
                      ? const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _captchaCode.isEmpty ? 'Loading...' : _captchaCode,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                ),
                // Refresh button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _refreshCaptcha,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Input Field
          Text(
            'Enter Captcha Code',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _captchaController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
              LengthLimitingTextInputFormatter(5),
            ],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. ABC12',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              filled: true,
              fillColor: AppColors.cardBackgroundLight(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          
          // Submit Button
          GestureDetector(
            onTap: (_isSubmitting || _isLoadingCaptcha || _captchaCode.isEmpty) ? null : _submitCaptcha,
            child: Opacity(
              opacity: (_isSubmitting || _isLoadingCaptcha || _captchaCode.isEmpty) ? 0.5 : 1.0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.green, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isSubmitting
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _rewardType == 'Coins'
                              ? 'Submit & Earn $_rewardAmount Coins'
                              : 'Submit & Earn ₹$_rewardAmount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgressSection() {
    final progress = _dailyLimit > 0 ? (_todaySolves / _dailyLimit).clamp(0.0, 1.0) : 0.0;
    final remaining = _dailyLimit - _todaySolves;
    
    return Column(
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
              remaining > 0 ? '$remaining Left' : 'Limit Reached',
              style: TextStyle(
                color: remaining > 0 ? AppColors.orange : Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(
              remaining > 0 ? AppColors.orange : Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completed: $_todaySolves/$_dailyLimit',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
            Text(
              'Resets at 12:00 AM',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProTipSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pro Tip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Captcha codes are case-sensitive. Ensure you type exactly what you see to get instant credit to your wallet.',
                  style: TextStyle(
                    color: AppColors.primary,
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
}
