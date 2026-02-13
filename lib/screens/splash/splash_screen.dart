import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../main_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.forward();
    
    // Navigate to login or main screen after 3 seconds
    Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        final isLoggedIn = await StorageService.isLoggedIn();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isLoggedIn 
                ? const MainScreen() 
                : const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        child: Stack(
          children: [
            // Background icons
            _buildBackgroundIcons(),
            
            // Main content
            Column(
              children: [
                const SizedBox(height: 120),
                // App Icon - positioned in upper-middle
                _buildAppIcon(),
                const SizedBox(height: 20),
                
                // App Name
                _buildAppName(),
                const Spacer(),
                
                // Features and Loading
                _buildBottomSection(),
                const SizedBox(height: 80),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundIcons() {
    return Stack(
      children: [
        // Top-left: Headphones
        Positioned(
          top: 60,
          left: 30,
          child: Icon(
            Icons.headphones,
            size: 50,
            color: Colors.grey.shade600.withOpacity(0.3),
          ),
        ),
        // Top-right: Game controller
        Positioned(
          top: 60,
          right: 30,
          child: Icon(
            Icons.sports_esports,
            size: 50,
            color: Colors.grey.shade600.withOpacity(0.3),
          ),
        ),
        // Bottom-left: Dollar sign in circle
        Positioned(
          bottom: 100,
          left: 30,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(
                color: Colors.grey.shade600.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.attach_money,
              size: 24,
              color: Colors.grey.shade600.withOpacity(0.3),
            ),
          ),
        ),
        // Bottom-right: Currency notes
        Positioned(
          bottom: 100,
          right: 30,
          child: Icon(
            Icons.money,
            size: 50,
            color: Colors.grey.shade600.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/images/profitkarologo.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2936),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.image,
                color: Colors.white,
                size: 70,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Profit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF4A90D9), Color(0xFF9C27B0)],
              ).createShader(bounds),
              child: const Text(
                ' Karo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        // Features list
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFeatureText('LISTEN'),
            _buildFeatureDot(),
            _buildFeatureText('PLAY'),
            _buildFeatureDot(),
            _buildFeatureText('EARN'),
            _buildFeatureDot(),
            _buildFeatureText('WITHDRAW'),
          ],
        ),
        const SizedBox(height: 24),
        
        // Loading bar
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              width: 220,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5BA3F5), Color(0xFF9C27B0)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        
        // Loading text
        Text(
          'LOADING...',
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildFeatureDot() {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF5BA3F5), // Brighter blue
        shape: BoxShape.circle,
      ),
    );
  }
}
