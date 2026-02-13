import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../main_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showLoginInput = false;
  bool _showSignupOption = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final mobileNumber = _mobileController.text.trim();
      final password = _passwordController.text.trim();

      final result = await ApiService.login(
        mobileNumber: mobileNumber,
        password: password,
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
              content: Text(result['message'] ?? 'Login failed'),
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
    final screenHeight = MediaQuery.of(context).size.height;
    
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
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Secure & Safe button
                    _buildSecureButton(),
                    
                    const SizedBox(height: 20),
                    
                    // App Logo
                    _buildAppLogo(),
                    
                    const SizedBox(height: 12),
                    
                    // App Name
                    _buildAppName(),
                    
                    const SizedBox(height: 8),
                    
                    // Tagline
                    _buildTagline(),
                    
                    const SizedBox(height: 12),
                    
                    // Fast Withdrawal button
                    _buildFastWithdrawalButton(),
                    
                    const SizedBox(height: 20),
                    
                    // Authentication Buttons - Flexible to take remaining space
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_showLoginInput && !_showSignupOption) ...[
                            // Mobile Number Login Button
                            _buildMobileLoginButton(),
                            const SizedBox(height: 16),
                            // Guest Explore
                            _buildGuestExplore(),
                          ] else if (_showLoginInput) ...[
                            // Login Input Form
                            _buildLoginInput(),
                          ] else if (_showSignupOption) ...[
                            // Signup Option - show choice between login and signup
                            _buildMobileAuthChoice(),
                          ],
                        ],
                      ),
                    ),
                    
                    // Terms and Privacy
                    _buildTermsAndPrivacy(),
                    
                    const SizedBox(height: 16),
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

  Widget _buildFastWithdrawalButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.flash_on,
          color: const Color(0xFF4A9EFF),
          size: 20,
        ),
        const SizedBox(width: 6),
        const Text(
          'Fast Withdrawal to UPI & Paytm',
          style: TextStyle(
            color: Color(0xFF4A9EFF),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // Widget _buildGoogleLoginButton() {
  //   return SizedBox(
  //     width: double.infinity,
  //     child: ElevatedButton(
  //       onPressed: () {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Google Login - Coming Soon'),
  //             backgroundColor: Colors.orange,
  //             duration: Duration(seconds: 2),
  //           ),
  //         );
  //       },
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.white,
  //         padding: const EdgeInsets.symmetric(vertical: 18),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(32),
  //         ),
  //         elevation: 0,
  //       ),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Container(
  //             width: 28,
  //             height: 28,
  //             decoration: BoxDecoration(
  //               color: Colors.black,
  //               borderRadius: BorderRadius.circular(4),
  //             ),
  //             child: const Center(
  //               child: Text(
  //                 'G',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ),
  //           const SizedBox(width: 14),
  //           const Text(
  //             'Continue with Google',
  //             style: TextStyle(
  //               color: Colors.black,
  //               fontSize: 17,
  //               fontWeight: FontWeight.w700,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildMobileLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
                setState(() {
                  _showSignupOption = true;
                  _showLoginInput = false;
                });
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.smartphone,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 14),
            const Text(
              'Login with Mobile Number',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestExplore() {
    return TextButton(
      onPressed: () {
        // Navigate to main screen as guest
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      },
      child: const Text(
        'Skip and Explore as Guest',
        style: TextStyle(
          color: Color(0xFFB8C5CF),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMobileAuthChoice() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade700,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.phone,
                color: Color(0xFF2196F3),
                size: 40,
              ),
              const SizedBox(height: 16),
              const Text(
                'Continue with Mobile Number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose an option to continue',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showLoginInput = true;
                      _showSignupOption = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2196F3),
                    side: const BorderSide(color: Color(0xFF2196F3), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _showSignupOption = false;
              _showLoginInput = false;
            });
          },
          child: const Text(
            'Back',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginInput() {
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
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
                      'Login',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showLoginInput = false;
                    _showSignupOption = false;
                    _mobileController.clear();
                    _passwordController.clear();
                  });
                },
                child: const Text(
                  'Back',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showLoginInput = false;
                    _showSignupOption = true;
                  });
                },
                child: const Text(
                  'Sign Up',
                  style: TextStyle(color: Color(0xFF2196F3)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF6B7C8A),
            fontSize: 12.5,
            height: 1.5,
          ),
          children: [
            const TextSpan(
              text: 'By continuing, you acknowledge that you have read and\nunderstood, and agree to our ',
            ),
            TextSpan(
              text: 'Terms of Service',
              style: const TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terms of Service')),
                  );
                },
            ),
            const TextSpan(text: ' & '),
            TextSpan(
              text: 'Privacy Policy',
              style: const TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy')),
                  );
                },
            ),
          ],
        ),
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
