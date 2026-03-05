import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../screens/wallet/wallet_screen.dart';

class BalanceCard extends StatefulWidget {
  final double walletBalance;
  final int coins;
  final bool isLoading;

  const BalanceCard({
    super.key,
    required this.walletBalance,
    required this.coins,
    this.isLoading = false,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  AnimationController? _treeAnimationController;
  Animation<double>? _treeScaleAnimation;
  Animation<double>? _treeRotationAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Tree animation controller
    _treeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    // Tree scale animation (breathing effect)
    _treeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _treeAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Tree rotation animation (gentle sway)
    _treeRotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _treeAnimationController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _treeAnimationController?.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return formatter.format(amount);
  }

  Widget _buildSkeletonLoader() {
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
          child: Column(
            children: [
              // Skeleton for balance amount
              Container(
                height: 36,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              // Skeleton for daily earnings pill
              Container(
                height: 32,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildIllustration() {
    return SizedBox(
      height: 150,
      width: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Positioned(
            right: 20,
            bottom: 20,
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 50,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),

          // 500 Notes Bundle - Premium Large View
          Positioned(
            right: 10,
            bottom: 10,
            child: Transform.rotate(
              angle: -0.15,
              child: Image.asset(
                'assets/images/500notes.png',
                width: 130,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Secondary Sparkles
          const Positioned(
            top: 30,
            right: 40,
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          Positioned(
            bottom: 40,
            right: 10,
            child: Icon(Icons.star, color: Colors.white.withOpacity(0.6), size: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF2962FF), // Base blue color
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF2962FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2962FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Wave Background Decoration
          Positioned.fill(
             child: ClipRRect(
               borderRadius: BorderRadius.circular(24),
               child: CustomPaint(
                 painter: _BalanceCardBackgroundPainter(),
               ),
             ),
          ),

          // Illustration on the right
          Positioned(
            right: 0,
            bottom: 10,
            child: widget.isLoading ? const SizedBox.shrink() : _buildIllustration(),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header
                Text(
                  'BALANCE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                
                // Main Balance (Coins)
                widget.isLoading
                ? _buildSkeletonLoader()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _treeAnimationController != null && 
                          _treeScaleAnimation != null && 
                          _treeRotationAnimation != null
                          ? AnimatedBuilder(
                              animation: _treeAnimationController!,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _treeScaleAnimation!.value,
                                  child: Transform.rotate(
                                    angle: _treeRotationAnimation!.value,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        '🌴',
                                        style: TextStyle(
                                          fontSize: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                '🌴',
                                style: TextStyle(
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.coins}.00',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32, // Larger font
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Secondary Balance (Rupees)
                      Text(
                        _formatCurrency(widget.walletBalance),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                // Action Button (Wallet)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WalletScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF2962FF),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Wallet',
                          style: TextStyle(
                            color: Color(0xFF2962FF),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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

class _BalanceCardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.4, 0);
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.5,
      size.width,
      size.height * 0.3,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.8),
      100,
      paint2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
