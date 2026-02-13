import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms || !_acceptPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept Terms & Conditions and Privacy Policy'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final mobileNumber = _mobileController.text.trim();
      final password = _passwordController.text.trim();
      final referralCode = _referralCodeController.text.trim();

      final result = await ApiService.signup(
        mobileNumber: mobileNumber,
        password: password,
        referralCode: referralCode.isNotEmpty ? referralCode : null,
      );

      if (result['success'] && result['token'] != null) {
        // Save token and mobile number
        await StorageService.saveToken(result['token']);
        await StorageService.saveMobileNumber(mobileNumber);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Signup failed'),
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1F3A47), // Dark teal
              Color(0xFF1A2F3D), // Mid dark
              Color(0xFF0F1E2E), // Darker blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background decorative elements
              _buildBackgroundElements(),
              
              // Main content - Fixed layout without scrolling
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Secure & Safe button
                    _buildSecureButton(),
                    
                    const SizedBox(height: 16),
                    
                    // App Logo
                    _buildAppLogo(),
                    
                    const SizedBox(height: 10),
                    
                    // App Name
                    _buildAppName(),
                    
                    const SizedBox(height: 6),
                    
                    // Tagline
                    _buildTagline(),
                    
                    const SizedBox(height: 16),
                    
                    // Signup Form - Flexible to take remaining space
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildSignupForm(),
                            const SizedBox(height: 16),
                            // Terms and Privacy
                            _buildTermsAndPrivacy(),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // Financial growth chart - subtle in background
        Positioned(
          top: 80,
          right: 20,
          child: Opacity(
            opacity: 0.15,
            child: CustomPaint(
              size: const Size(180, 120),
              painter: _ChartPainter(),
            ),
          ),
        ),
        // Coins - more subtle and darker
        Positioned(
          top: 200,
          left: 30,
          child: Opacity(
            opacity: 0.12,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4A6572),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Positioned(
          top: 250,
          right: 40,
          child: Opacity(
            opacity: 0.1,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF4A6572),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Positioned(
          top: 320,
          left: 60,
          child: Opacity(
            opacity: 0.08,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4A6572),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 350,
          left: 20,
          child: Opacity(
            opacity: 0.1,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF4A6572),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 300,
          right: 30,
          child: Opacity(
            opacity: 0.12,
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFF4A6572),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecureButton() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2936).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF2A3F4D),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 18,
              color: const Color(0xFF4A9EFF),
            ),
            const SizedBox(width: 10),
            const Text(
              '100% SECURE & SAFE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/profitkarologo.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2936),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.image,
                color: Colors.white,
                size: 50,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return const Text(
      'Profit Karo',
      style: TextStyle(
        color: Colors.white,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        height: 1.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTagline() {
    return const Text(
      'Earn daily from Music, Games & Surveys',
      style: TextStyle(
        color: Color(0xFFB8C5CF),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter Mobile Number',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.grey.shade900.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
              ),
              prefixIcon: const Icon(Icons.phone, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter mobile number';
              }
              if (value.length != 10) {
                return 'Please enter valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter Password',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.grey.shade900.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
              ),
              prefixIcon: const Icon(Icons.lock, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Confirm Password',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.grey.shade900.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
              ),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showConfirmPassword = !_showConfirmPassword;
                  });
                },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Referral Code Input (Optional)
          TextFormField(
            controller: _referralCodeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Referral Code (Optional)',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.grey.shade900.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
              ),
              prefixIcon: const Icon(Icons.card_giftcard, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isLoading || !_acceptTerms || !_acceptPrivacy) ? null : _handleSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(color: Colors.grey.shade500),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Login',
                  style: TextStyle(color: Color(0xFF2196F3)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTermsAndPrivacy() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Terms & Conditions Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
                activeColor: const Color(0xFF4A9EFF),
                checkColor: Colors.white,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFFB8C5CF),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms and Conditions',
                          style: const TextStyle(
                            color: Color(0xFF4A9EFF),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF4A9EFF),
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _launchURL('https://loankingofficial.blogspot.com/p/terms-and-conditions-by-profit-karo.html?m=1');
                            },
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Privacy Policy Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _acceptPrivacy,
                onChanged: (value) {
                  setState(() {
                    _acceptPrivacy = value ?? false;
                  });
                },
                activeColor: const Color(0xFF4A9EFF),
                checkColor: Colors.white,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFFB8C5CF),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            color: Color(0xFF4A9EFF),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF4A9EFF),
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _launchURL('https://loankingofficial.blogspot.com/p/privacy-policy-by-profit-karo.html?m=1');
                            },
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom painter for financial chart background
class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle line graph
    final linePaint = Paint()
      ..color = const Color(0xFF4A6572)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.6);
    path.lineTo(size.width * 0.4, size.height * 0.4);
    path.lineTo(size.width * 0.6, size.height * 0.35);
    path.lineTo(size.width * 0.8, size.height * 0.25);
    path.lineTo(size.width, size.height * 0.15);
    canvas.drawPath(path, linePaint);

    // Draw subtle bars
    final barPaint = Paint()
      ..color = const Color(0xFF3A4F5C)
      ..style = PaintingStyle.fill;

    final barWidth = size.width / 8;
    canvas.drawRect(
      Rect.fromLTWH(barWidth * 0.5, size.height * 0.7, barWidth * 0.8, size.height * 0.3),
      barPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(barWidth * 2, size.height * 0.5, barWidth * 0.8, size.height * 0.5),
      barPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(barWidth * 3.5, size.height * 0.35, barWidth * 0.8, size.height * 0.65),
      barPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(barWidth * 5, size.height * 0.2, barWidth * 0.8, size.height * 0.8),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) => false;
}
