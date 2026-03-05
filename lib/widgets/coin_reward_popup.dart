import 'package:flutter/material.dart';
import 'dart:math' as math;

class CoinRewardPopup extends StatefulWidget {
  final int coins;
  final VoidCallback? onClose;
  final VoidCallback? onGreatButtonClick; // Callback for showing ad when Add Wallet button is clicked

  const CoinRewardPopup({
    super.key,
    required this.coins,
    this.onClose,
    this.onGreatButtonClick,
  });

  @override
  State<CoinRewardPopup> createState() => _CoinRewardPopupState();
}

class _CoinRewardPopupState extends State<CoinRewardPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() {
    Navigator.of(context).pop();
    // If onGreatButtonClick is provided, call it (to show ad)
    // The onGreatButtonClick will handle calling onClose after ad is watched
    if (widget.onGreatButtonClick != null) {
      widget.onGreatButtonClick!();
    } else {
      // If no onGreatButtonClick, call onClose immediately
      widget.onClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E), // Dark background
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Orange circle with star icon at top
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF9800), // Orange
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Color(0xFF1A1A2E), // Dark star
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // CONGRATULATIONS! text
                  const Text(
                    'CONGRATULATIONS!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Success message
                  Text(
                    'You have successfully claimed your reward',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Reward box with coins
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3E), // Dark card background
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade800,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Orange circle with dollar sign
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF9800), // Orange
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Coins amount and label
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Animated coin count
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: widget.coins.toDouble()),
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Text(
                                  '+${value.toInt()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coins Added',
                              style: TextStyle(
                                color: const Color(0xFFFF9800), // Orange
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Add Wallet button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800), // Bright orange
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Add Wallet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
