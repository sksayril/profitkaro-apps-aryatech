import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/wallet/currency_toggle.dart';
import '../../widgets/wallet/wallet_balance_card.dart';
import '../../widgets/wallet/withdrawal_threshold.dart';
import '../../widgets/wallet/payment_method_section.dart';
import '../../widgets/wallet/upi_input.dart';
import '../../widgets/wallet/recent_transactions.dart';
import '../../widgets/wallet/coin_conversion_dialog.dart';
import '../coins/coins_screen.dart';

class WalletScreen extends StatefulWidget {
  final VoidCallback? onBack;
  
  const WalletScreen({super.key, this.onBack});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedCurrencyTab = 0;
  int _selectedPaymentMethod = 0;
  double _walletBalance = 0.0;
  int _coins = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  // Withdrawal form controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _virtualIdController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _bankIFSCController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    _upiIdController.dispose();
    _virtualIdController.dispose();
    _bankAccountController.dispose();
    _bankIFSCController.dispose();
    _bankNameController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _withdrawalRequests = [];
  bool _isLoadingRequests = false;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
    _fetchWithdrawalRequests();
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
          // Handle different number types from API
          final balance = data['WalletBalance'];
          if (balance is double) {
            _walletBalance = balance;
          } else if (balance is int) {
            _walletBalance = balance.toDouble();
          } else if (balance is String) {
            _walletBalance = double.tryParse(balance) ?? 0.0;
          } else {
            _walletBalance = 0.0;
          }

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch wallet balance'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: const Text(
          'My Wallet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchWalletBalance();
          await _fetchWithdrawalRequests();
        },
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Currency Toggle
                CurrencyToggle(
                  selectedIndex: _selectedCurrencyTab,
                  onChanged: (index) {
                    setState(() => _selectedCurrencyTab = index);
                  },
                ),
                const SizedBox(height: 20),

                // Balance Card
                WalletBalanceCard(
                  walletBalance: _walletBalance,
                  coins: _coins,
                  isLoading: _isLoading,
                  onCoinsTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CoinsScreen()),
                    ).then((_) {
                      // Refresh wallet balance when returning
                      _fetchWalletBalance();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Withdrawal Threshold
                const WithdrawalThreshold(),
                const SizedBox(height: 24),

                // Payment Method
                PaymentMethodSection(
                  selectedIndex: _selectedPaymentMethod,
                  onChanged: (index) {
                    setState(() => _selectedPaymentMethod = index);
                  },
                ),
                const SizedBox(height: 24),

                // Amount Input
                _buildAmountInput(),
                const SizedBox(height: 24),

                // Payment Details Input
                UPIInput(
                  selectedPaymentMethod: _selectedPaymentMethod,
                  upiIdController: _upiIdController,
                  virtualIdController: _virtualIdController,
                  bankAccountController: _bankAccountController,
                  bankIFSCController: _bankIFSCController,
                  bankNameController: _bankNameController,
                  accountHolderController: _accountHolderController,
                ),
                const SizedBox(height: 24),

                // Recent Transactions / Withdrawal Requests
                RecentTransactions(
                  withdrawalRequests: _withdrawalRequests,
                  isLoading: _isLoadingRequests,
                ),
                const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildWithdrawButton(),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Withdrawal Amount',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter amount (₹)',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixText: '₹ ',
            prefixStyle: const TextStyle(color: Colors.white, fontSize: 16),
            filled: true,
            fillColor: AppColors.cardBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _submitWithdrawalRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter withdrawal amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount > _walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. Available: ₹$_walletBalance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate payment method specific fields
    String paymentMethod = 'UPI';
    if (_selectedPaymentMethod == 0) {
      paymentMethod = 'UPI';
    } else if (_selectedPaymentMethod == 1) {
      paymentMethod = 'Paytm';
    } else if (_selectedPaymentMethod == 2) {
      paymentMethod = 'Google Pay';
    } else if (_selectedPaymentMethod == 3) {
      paymentMethod = 'BankTransfer';
    }

    if (paymentMethod == 'BankTransfer') {
      if (_accountHolderController.text.trim().isEmpty ||
          _bankAccountController.text.trim().isEmpty ||
          _bankIFSCController.text.trim().isEmpty ||
          _bankNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all bank account details'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_upiIdController.text.trim().isEmpty && _virtualIdController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter UPI ID or Virtual ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final result = await ApiService.submitWithdrawalRequest(
        token: token,
        amount: amount,
        paymentMethod: paymentMethod,
        upiId: _upiIdController.text.trim().isNotEmpty ? _upiIdController.text.trim() : null,
        virtualId: _virtualIdController.text.trim().isNotEmpty ? _virtualIdController.text.trim() : null,
        bankAccountNumber: paymentMethod == 'BankTransfer' ? _bankAccountController.text.trim() : null,
        bankIFSC: paymentMethod == 'BankTransfer' ? _bankIFSCController.text.trim() : null,
        bankName: paymentMethod == 'BankTransfer' ? _bankNameController.text.trim() : null,
        accountHolderName: paymentMethod == 'BankTransfer' ? _accountHolderController.text.trim() : null,
      );

      if (result['success'] && result['data'] != null) {
        // Update wallet balance from response
        final data = result['data'];
        final remainingBalance = data['remainingWalletBalance'];
        if (remainingBalance != null) {
          setState(() {
            if (remainingBalance is double) {
              _walletBalance = remainingBalance;
            } else if (remainingBalance is int) {
              _walletBalance = remainingBalance.toDouble();
            } else if (remainingBalance is String) {
              _walletBalance = double.tryParse(remainingBalance) ?? _walletBalance;
            }
          });
        }

        // Clear form
        _amountController.clear();
        _upiIdController.clear();
        _virtualIdController.clear();
        _bankAccountController.clear();
        _bankIFSCController.clear();
        _bankNameController.clear();
        _accountHolderController.clear();

        // Refresh withdrawal requests
        await _fetchWithdrawalRequests();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Withdrawal request submitted successfully'),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to submit withdrawal request'),
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
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _fetchWithdrawalRequests() async {
    setState(() {
      _isLoadingRequests = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingRequests = false;
        });
        return;
      }

      final result = await ApiService.getWithdrawalRequests(token: token);

      if (result['success'] && result['data'] != null) {
        setState(() {
          _withdrawalRequests = List<Map<String, dynamic>>.from(result['data']['requests'] ?? []);
          _isLoadingRequests = false;
        });
      } else {
        setState(() {
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  void _showCoinConversionDialog() {
    showDialog(
      context: context,
      builder: (context) => CoinConversionDialog(
        currentCoins: _coins,
        onConversionSuccess: () {
          // Refresh wallet balance after conversion
          _fetchWalletBalance();
        },
      ),
    );
  }

  Widget _buildWithdrawButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background(context),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: _isSubmitting ? null : _submitWithdrawalRequest,
          child: Opacity(
            opacity: _isSubmitting ? 0.5 : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Withdraw Money',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
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
