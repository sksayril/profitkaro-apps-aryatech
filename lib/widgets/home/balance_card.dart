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
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
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

  Widget _buildDecorationCircles() {
    return Positioned(
      right: -40,
      top: -40,
      child: Container(
        height: 200,
        width: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildCoinStack() {
    return SizedBox(
      height: 120,
      width: 100,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Base coins
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.rotate(
              angle: 0.2,
              child: Icon(Icons.monetization_on, size: 50, color: Colors.amber[800]),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 5,
            child: Transform.rotate(
              angle: -0.2,
              child: Icon(Icons.monetization_on, size: 50, color: Colors.amber[800]),
            ),
          ),
          // Middle layer
          Positioned(
            bottom: 15,
            right: 15,
            child: Icon(Icons.monetization_on, size: 50, color: Colors.amber[600]),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            child: Icon(Icons.monetization_on, size: 50, color: Colors.amber[600]),
          ),
          // Top coin
          Positioned(
            bottom: 35,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.monetization_on, size: 55, color: Colors.amber[400]),
            ),
          ),
          // Sparkles
          Positioned(
            top: 10,
            right: 10,
            child: Icon(Icons.auto_awesome, size: 24, color: Colors.yellow[200]),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            child: Icon(Icons.star, size: 16, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Estimate Dollar value (approx rate)
    final double dollarValue = widget.walletBalance / 84.0;
    
    return Container(
      width: double.infinity,
      height: 200, // Fixed height for consistent look
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF0055FF)], // Brighter blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0055FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background circles
          _buildDecorationCircles(),
          Positioned(
            bottom: -20,
            right: 60,
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Illustration on the right
          Positioned(
            right: 20,
            bottom: 20,
            child: widget.isLoading ? const SizedBox.shrink() : _buildCoinStack(),
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
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
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
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.monetization_on_outlined, 
                              color: Colors.white, 
                              size: 20
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            // Display coins with decimals to match UI style "503.00000"
                            '${widget.coins}.00000',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Secondary Balance (Rupees | Dollars)
                      Text(
                        '${_formatCurrency(widget.walletBalance)} | \$ ${dollarValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                          color: Color(0xFF0055FF),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Wallet',
                          style: TextStyle(
                            color: Color(0xFF0055FF),
                            fontSize: 14,
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
