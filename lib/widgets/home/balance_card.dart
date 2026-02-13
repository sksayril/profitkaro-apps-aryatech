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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Total Balance label centered
          Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          // Amount centered
          widget.isLoading
              ? _buildSkeletonLoader()
              : Text(
                  _formatCurrency(widget.walletBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
          const SizedBox(height: 12),
          // Daily earnings indicator - pill shaped, light blue
          widget.isLoading
              ? const SizedBox.shrink()
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6BA3D6).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Chart icon
                      Icon(
                        Icons.show_chart,
                        color: Colors.white.withOpacity(0.9),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      // Green text for earnings
                      const Text(
                        '+₹120 Today',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 20),
          // Withdraw button - white pill
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Withdraw',
                    style: TextStyle(
                      color: Color(0xFF1E3A5F),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF1E3A5F),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
