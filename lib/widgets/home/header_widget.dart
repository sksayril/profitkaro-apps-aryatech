import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final List<String> _carouselTexts = [
    'Fast Payouts',
    'Smart Earning',
    'Unlimited Rewards',
    'Earn Instantly',
  ];
  Timer? _timer;
  AnimationController? _fireController;
  Animation<double>? _fireAnimation;

  @override
  void initState() {
    super.initState();
    _startCarousel();
    // Animation init moved/checked in didChangeDependencies for hot reload safety
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fireController == null) {
      _initFireAnimation();
    }
  }

  void _initFireAnimation() {
    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _fireAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _fireController!, curve: Curves.easeInOut),
    );
  }

  void _startCarousel() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _carouselTexts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fireController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Avatar Area
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9EA1D4), // Light purple background
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                image: const DecorationImage(
                  // Using a network image as a placeholder for the avatar
                  image: NetworkImage('https://cdn-icons-png.flaticon.com/512/4140/4140048.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Carousel Pill
            Stack(
              alignment: Alignment.bottomCenter, // For the red dot
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6), // Very light purple
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFFD1C4E9),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Invisible widget to set the maximum width based on the longest text
                      Opacity(
                        opacity: 0.0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Unlimited Rewards', // Longest text
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.keyboard_double_arrow_right, size: 18),
                          ],
                        ),
                      ),
                      // The actual animated content
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.5),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Row(
                          key: ValueKey<int>(_currentIndex), // Important for animation
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: Color(0xFFFFD600), // Yellow lightning
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _carouselTexts[_currentIndex],
                              style: const TextStyle(
                                color: Color(0xFF673AB7), // Deep purple text
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.keyboard_double_arrow_right,
                              color: Color(0xFF673AB7), // Deep purple arrows
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ],
        ),

        // Fire Icon Button
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE0B2), // Light orange bg
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFCC80),
              width: 1,
            ),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _fireAnimation ?? const AlwaysStoppedAnimation(1.0),
              child: const Icon(
                Icons.local_fire_department,
                color: Color(0xFFEF6C00), // Orange fire
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
