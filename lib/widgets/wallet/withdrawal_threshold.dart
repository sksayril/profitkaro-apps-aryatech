import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class WithdrawalThreshold extends StatefulWidget {
  const WithdrawalThreshold({super.key});

  @override
  State<WithdrawalThreshold> createState() => _WithdrawalThresholdState();
}

class _WithdrawalThresholdState extends State<WithdrawalThreshold> {
  double _minimumWithdrawalAmount = 500.0;
  double _currentWalletBalance = 0.0;
  bool _canWithdraw = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWithdrawalThreshold();
  }

  Future<void> _fetchWithdrawalThreshold() async {
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

      final result = await ApiService.getWithdrawalThreshold(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          // Handle minimumWithdrawalAmount
          final minAmount = data['minimumWithdrawalAmount'];
          if (minAmount is double) {
            _minimumWithdrawalAmount = minAmount;
          } else if (minAmount is int) {
            _minimumWithdrawalAmount = minAmount.toDouble();
          } else if (minAmount is String) {
            _minimumWithdrawalAmount = double.tryParse(minAmount) ?? 500.0;
          }

          // Handle currentWalletBalance
          final balance = data['currentWalletBalance'];
          if (balance is double) {
            _currentWalletBalance = balance;
          } else if (balance is int) {
            _currentWalletBalance = balance.toDouble();
          } else if (balance is String) {
            _currentWalletBalance = double.tryParse(balance) ?? 0.0;
          }

          // Handle canWithdraw
          _canWithdraw = data['canWithdraw'] ?? false;

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentWalletBalance / _minimumWithdrawalAmount).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();
    final remaining = (_minimumWithdrawalAmount - _currentWalletBalance).clamp(0.0, _minimumWithdrawalAmount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Withdrawal Threshold',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: progress >= 1.0
                            ? AppColors.green.withValues(alpha: 0.2)
                            : AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: progress >= 1.0
                              ? AppColors.green.withValues(alpha: 0.5)
                              : AppColors.primary.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        progress >= 1.0 ? '100% Reached' : '$percentage% Reached',
                        style: TextStyle(
                          color: progress >= 1.0 ? AppColors.green : AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(_currentWalletBalance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Minimum',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatCurrency(_minimumWithdrawalAmount)} (Min)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackgroundLight(context),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: progress >= 1.0
                                ? [AppColors.green, AppColors.secondary]
                                : [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: progress >= 1.0
                              ? [
                                  BoxShadow(
                                    color: AppColors.green.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: progress >= 1.0
                        ? AppColors.green.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: progress >= 1.0
                          ? AppColors.green.withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: progress >= 1.0 ? AppColors.green : AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 13,
                            ),
                            children: [
                              if (remaining > 0) ...[
                                const TextSpan(text: 'You need '),
                                TextSpan(
                                  text: _formatCurrency(remaining),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const TextSpan(text: ' more to withdraw.'),
                              ] else ...[
                                const TextSpan(
                                  text: 'You can withdraw now!',
                                  style: TextStyle(
                                    color: AppColors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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
