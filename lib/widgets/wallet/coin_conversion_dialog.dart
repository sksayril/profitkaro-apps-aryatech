import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class CoinConversionDialog extends StatefulWidget {
  final int currentCoins;
  final VoidCallback? onConversionSuccess;

  const CoinConversionDialog({
    super.key,
    required this.currentCoins,
    this.onConversionSuccess,
  });

  @override
  State<CoinConversionDialog> createState() => _CoinConversionDialogState();
}

class _CoinConversionDialogState extends State<CoinConversionDialog> {
  int? _coinsPerRupee;
  int? _minimumCoinsToConvert;
  int? _userCoins;
  String? _rupeesValue;
  bool? _canConvert;
  bool _isLoadingRate = true;
  bool _isConverting = false;
  final TextEditingController _coinsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchConversionRate();
  }

  @override
  void dispose() {
    _coinsController.dispose();
    super.dispose();
  }

  Future<void> _fetchConversionRate() async {
    setState(() {
      _isLoadingRate = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingRate = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await ApiService.getCoinConversionRate(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          // Handle coinsPerRupee - can be int or double
          final coinsPerRupeeValue = data['coinsPerRupee'];
          if (coinsPerRupeeValue is int) {
            _coinsPerRupee = coinsPerRupeeValue;
          } else if (coinsPerRupeeValue is double) {
            _coinsPerRupee = coinsPerRupeeValue.toInt();
          } else {
            _coinsPerRupee = 10;
          }

          // Handle minimumCoinsToConvert - can be int or double
          final minimumCoinsValue = data['minimumCoinsToConvert'];
          if (minimumCoinsValue is int) {
            _minimumCoinsToConvert = minimumCoinsValue;
          } else if (minimumCoinsValue is double) {
            _minimumCoinsToConvert = minimumCoinsValue.toInt();
          } else {
            _minimumCoinsToConvert = 100;
          }

          // Handle userCoins - can be int or double
          final userCoinsValue = data['userCoins'];
          if (userCoinsValue is int) {
            _userCoins = userCoinsValue;
          } else if (userCoinsValue is double) {
            _userCoins = userCoinsValue.toInt();
          } else {
            _userCoins = widget.currentCoins;
          }

          // Handle rupeesValue - can be String, double, or int
          final rupeesValue = data['rupeesValue'];
          if (rupeesValue is String) {
            _rupeesValue = rupeesValue;
          } else if (rupeesValue is double) {
            _rupeesValue = rupeesValue.toStringAsFixed(2);
          } else if (rupeesValue is int) {
            _rupeesValue = rupeesValue.toStringAsFixed(2);
          } else {
            _rupeesValue = '0.00';
          }

          _canConvert = data['canConvert'] ?? false;
          _isLoadingRate = false;
        });
      } else {
        setState(() {
          _isLoadingRate = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch conversion rate'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingRate = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleConvert() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final coinsText = _coinsController.text.trim();
    if (coinsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter coins to convert'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final coins = int.tryParse(coinsText);
    if (coins == null || coins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number of coins'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_minimumCoinsToConvert != null && coins < _minimumCoinsToConvert!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum $_minimumCoinsToConvert coins required to convert'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_userCoins != null && coins > _userCoins!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient coins. You have $_userCoins coins'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isConverting = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isConverting = false;
        });
        return;
      }

      final result = await ApiService.convertCoins(
        token: token,
        coins: coins,
      );

      if (result['success'] && result['data'] != null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Coins converted successfully'),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          // Notify parent to refresh wallet balance
          if (widget.onConversionSuccess != null) {
            widget.onConversionSuccess!();
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to convert coins'),
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
          _isConverting = false;
        });
      }
    }
  }

  String _formatCurrency(String amount) {
    final value = double.tryParse(amount) ?? 0.0;
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return formatter.format(value);
  }

  double? _calculateRupees(int coins) {
    if (_coinsPerRupee == null || _coinsPerRupee == 0) return null;
    return coins / _coinsPerRupee!;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: _isLoadingRate
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Convert Coins to Rupees',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Conversion Rate Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Conversion Rate',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${_coinsPerRupee ?? 10} coins = ₹1',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Your Coins',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${_userCoins ?? widget.currentCoins} coins',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Worth',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatCurrency(_rupeesValue ?? '0.00'),
                                  style: const TextStyle(
                                    color: AppColors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (_minimumCoinsToConvert != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Minimum to Convert',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '$_minimumCoinsToConvert coins',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Coins Input
                      TextFormField(
                        controller: _coinsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Coins to Convert',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Enter coins',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: AppColors.background(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter coins to convert';
                          }
                          final coins = int.tryParse(value.trim());
                          if (coins == null || coins <= 0) {
                            return 'Please enter a valid number';
                          }
                          if (_minimumCoinsToConvert != null &&
                              coins < _minimumCoinsToConvert!) {
                            return 'Minimum $_minimumCoinsToConvert coins required';
                          }
                          if (_userCoins != null && coins > _userCoins!) {
                            return 'Insufficient coins';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      // Quick Select Buttons
                      if (_userCoins != null && _userCoins! > 0) ...[
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildQuickButton('25%', () {
                              final amount = (_userCoins! * 0.25).round();
                              _coinsController.text = amount.toString();
                              setState(() {});
                            }),
                            _buildQuickButton('50%', () {
                              final amount = (_userCoins! * 0.5).round();
                              _coinsController.text = amount.toString();
                              setState(() {});
                            }),
                            _buildQuickButton('75%', () {
                              final amount = (_userCoins! * 0.75).round();
                              _coinsController.text = amount.toString();
                              setState(() {});
                            }),
                            _buildQuickButton('All', () {
                              _coinsController.text = _userCoins!.toString();
                              setState(() {});
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Conversion Preview
                      if (_coinsController.text.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final coins = int.tryParse(_coinsController.text.trim());
                            if (coins == null || coins <= 0) {
                              return const SizedBox.shrink();
                            }
                            final rupees = _calculateRupees(coins);
                            if (rupees == null) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$coins coins = ',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(rupees.toStringAsFixed(2)),
                                    style: const TextStyle(
                                      color: AppColors.green,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Convert Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isConverting || !(_canConvert ?? false)
                              ? null
                              : _handleConvert,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey.shade700,
                          ),
                          child: _isConverting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Convert to Rupees',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      if (!(_canConvert ?? false)) ...[
                        const SizedBox(height: 8),
                        Text(
                          'You need at least ${_minimumCoinsToConvert ?? 100} coins to convert',
                          style: TextStyle(
                            color: Colors.red.shade300,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
