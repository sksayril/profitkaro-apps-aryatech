import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/wallet/coin_conversion_dialog.dart';

class CoinsScreen extends StatefulWidget {
  const CoinsScreen({super.key});

  @override
  State<CoinsScreen> createState() => _CoinsScreenState();
}

class _CoinsScreenState extends State<CoinsScreen> {
  int _coins = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
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

      final result = await ApiService.getWalletBalance(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          final coinsValue = data['Coins'];
          if (coinsValue is int) {
            _coins = coinsValue;
          } else if (coinsValue is double) {
            _coins = coinsValue.toInt();
          } else if (coinsValue is String) {
            _coins = int.tryParse(coinsValue) ?? 0;
          } else {
            _coins = 0;
          }
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

  void _showConvertDialog() {
    showDialog(
      context: context,
      builder: (context) => CoinConversionDialog(
        currentCoins: _coins,
        onConversionSuccess: () {
          _fetchWalletBalance();
        },
      ),
    );
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
          'My Coins',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWalletBalance,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Coins Display Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.yellow.withValues(alpha: 0.3),
                        AppColors.orange.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.yellow.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellow.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Coin Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.yellow.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.yellow,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.monetization_on,
                          color: AppColors.yellow,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Total Coins',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const SizedBox(
                              height: 60,
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _coins.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -2,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'coins',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Convert Button - More Prominent
                GestureDetector(
                  onTap: _coins > 0 ? _showConvertDialog : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: _coins > 0
                          ? LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _coins > 0 ? null : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _coins > 0
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : Colors.grey.shade600,
                        width: 2,
                      ),
                      boxShadow: _coins > 0
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Convert Coins to Rupees',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_coins == 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'You need coins to convert',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                // Info Card
                Container(
                  width: double.infinity,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'About Coins',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'Earn coins',
                        'Complete tasks, surveys, and activities',
                        Icons.stars,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Convert coins',
                        'Exchange coins for real money',
                        Icons.swap_horiz,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Withdraw money',
                        'Transfer to your bank or UPI',
                        Icons.account_balance_wallet,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
