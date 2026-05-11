import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/services/google_mobile_ads_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/wallet/currency_toggle.dart';
import '../../widgets/wallet/wallet_balance_card.dart';
import '../../widgets/wallet/withdrawal_threshold.dart';
import '../../widgets/wallet/payment_method_section.dart';
import '../../widgets/wallet/upi_input.dart';
import '../../widgets/wallet/recent_transactions.dart';
import '../../widgets/wallet/withdrawal_type_tabs.dart';
import '../../widgets/wallet/gift_voucher_form.dart';
import '../coins/coins_screen.dart';

class WalletScreen extends StatefulWidget {
  final VoidCallback? onBack;
  
  const WalletScreen({super.key, this.onBack});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isAdLoading = false;
  /// User must complete rewarded ad (`AdConfig.rewardedUnitId`) before Withdraw Money.
  bool _withdrawRewardedCompleted = false;

  int _selectedCurrencyTab = 0;
  int _selectedPaymentMethod = 0;
  // Top-level withdrawal type: 0 = Gift Voucher, 1 = UPI, 2 = Bank.
  int _withdrawalType = 0;
  // Gift voucher selection state.
  String? _selectedGiftBrand;
  int? _selectedGiftAmount;
  List<Map<String, dynamic>> _giftVoucherRequests = [];
  bool _isLoadingGiftVoucherRequests = false;
  double _walletBalance = 0.0;
  int _coins = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingThreshold = false;
  double _minimumWithdrawalAmount = 500.0;
  bool _apiCanWithdraw = false;
  int _dailyWithdrawalRequestLimit = 0;
  int _requestsToday = 0;
  int _remainingRequestsToday = 0;
  
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
  void initState() {
    super.initState();
    _fetchWalletBalance();
    _fetchWithdrawalThreshold();
    _fetchWithdrawalRequests();
    _fetchGiftVoucherRequests();
  }

  void _playWithdrawRewardedAd() {
    if (_isAdLoading || _isSubmitting) return;
    setState(() {
      _isAdLoading = true;
    });

    GoogleMobileAdsService.instance.showRewardedAd(
      onRewardEarned: () {
        if (!mounted) return;
        setState(() {
          _isAdLoading = false;
          _withdrawRewardedCompleted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can submit your withdrawal below.'),
            backgroundColor: AppColors.green,
          ),
        );
      },
      onFailed: () {
        if (!mounted) return;
        setState(() {
          _isAdLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not available. Try again in a moment.'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

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

  double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Future<void> _fetchWithdrawalThreshold() async {
    setState(() {
      _isLoadingThreshold = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoadingThreshold = false;
        });
        return;
      }

      final result = await ApiService.getWithdrawalThreshold(token: token);
      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        setState(() {
          _minimumWithdrawalAmount = _asDouble(
            data['minimumWithdrawalAmount'],
            fallback: _minimumWithdrawalAmount,
          );
          _dailyWithdrawalRequestLimit = _asInt(data['dailyWithdrawalRequestLimit']);
          _requestsToday = _asInt(data['requestsToday']);
          _remainingRequestsToday = _asInt(data['remainingRequestsToday']);
          _apiCanWithdraw = data['canWithdraw'] == true;
          _isLoadingThreshold = false;
        });
      } else {
        setState(() {
          _isLoadingThreshold = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingThreshold = false;
      });
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
          await _fetchWithdrawalThreshold();
          await _fetchWithdrawalRequests();
          await _fetchGiftVoucherRequests();
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

                // Top-level withdrawal type selector (Gift Voucher / UPI / Bank)
                WithdrawalTypeTabs(
                  selectedIndex: _withdrawalType,
                  onChanged: _onWithdrawalTypeChanged,
                ),
                const SizedBox(height: 24),

                // Mode-specific content.
                ..._buildModeContent(),

                const SizedBox(height: 24),

                // Recent Transactions / Withdrawal Requests
                if (_withdrawalType == 0)
                  _buildGiftVoucherRequestsList()
                else
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

  /// Build the mode-specific section between the type tabs and the
  /// request history. Returns a list of widgets so the caller can spread
  /// them into a column without wrapping a Column-in-Column.
  List<Widget> _buildModeContent() {
    switch (_withdrawalType) {
      case 0: // Gift Voucher Withdraw.
        return [
          GiftVoucherForm(
            selectedBrand: _selectedGiftBrand,
            selectedAmount: _selectedGiftAmount,
            walletBalance: _walletBalance,
            onBrandSelected: (brand) {
              setState(() => _selectedGiftBrand = brand);
            },
            onAmountSelected: (amount) {
              setState(() => _selectedGiftAmount = amount);
            },
          ),
        ];
      case 1: // UPI Withdraw — only UPI / VPA.
        return [
          _buildAmountInput(),
          const SizedBox(height: 24),
          UPIInput(
            selectedPaymentMethod: 0,
            upiIdController: _upiIdController,
            virtualIdController: _virtualIdController,
            bankAccountController: _bankAccountController,
            bankIFSCController: _bankIFSCController,
            bankNameController: _bankNameController,
            accountHolderController: _accountHolderController,
          ),
        ];
      case 2: // Bank Withdraw.
      default:
        return [
          _buildAmountInput(),
          const SizedBox(height: 24),
          UPIInput(
            selectedPaymentMethod: 3,
            upiIdController: _upiIdController,
            virtualIdController: _virtualIdController,
            bankAccountController: _bankAccountController,
            bankIFSCController: _bankIFSCController,
            bankNameController: _bankNameController,
            accountHolderController: _accountHolderController,
          ),
        ];
    }
  }

  void _onWithdrawalTypeChanged(int index) {
    if (index == _withdrawalType) return;
    setState(() {
      _withdrawalType = index;
      if (index == 1) {
        _selectedPaymentMethod = 0; // UPI / VPA
      } else if (index == 2) {
        _selectedPaymentMethod = 3; // Bank Transfer
      }
    });
  }

  Future<void> _fetchGiftVoucherRequests() async {
    setState(() {
      _isLoadingGiftVoucherRequests = true;
    });
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoadingGiftVoucherRequests = false);
        return;
      }
      final result = await ApiService.getGiftVoucherRequests(token: token);
      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _giftVoucherRequests = List<Map<String, dynamic>>.from(
              result['data']['requests'] ?? []);
          _isLoadingGiftVoucherRequests = false;
        });
      } else {
        setState(() => _isLoadingGiftVoucherRequests = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingGiftVoucherRequests = false);
    }
  }

  Widget _buildGiftVoucherRequestsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Gift Voucher Requests',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingGiftVoucherRequests)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_giftVoucherRequests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(Icons.card_giftcard,
                    color: Colors.grey.shade500, size: 32),
                const SizedBox(height: 8),
                Text(
                  'No gift voucher requests yet.',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _giftVoucherRequests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _buildGiftVoucherRequestTile(_giftVoucherRequests[index]);
            },
          ),
      ],
    );
  }

  Widget _buildGiftVoucherRequestTile(Map<String, dynamic> req) {
    final brand = (req['brand'] ?? '').toString();
    final amount = req['amount'];
    final status = (req['status'] ?? 'Pending').toString();
    final voucherCode = req['voucherCode']?.toString();
    final createdAt = req['createdAt']?.toString();

    String formattedDate = '';
    if (createdAt != null && createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(dt);
      } catch (_) {
        formattedDate = createdAt;
      }
    }

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'delivered':
        statusColor = AppColors.green;
        break;
      case 'approved':
        statusColor = AppColors.primary;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'pending':
      default:
        statusColor = AppColors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.card_giftcard,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${amount ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (voucherCode != null && voucherCode.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.green.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number,
                      color: AppColors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      voucherCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: voucherCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Voucher code copied!'),
                          backgroundColor: AppColors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.copy_rounded,
                          color: AppColors.green, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitWithdrawalRequest() async {
    // Gift voucher flow has its own validation/submission path.
    if (_withdrawalType == 0) {
      await _submitGiftVoucherRequest();
      return;
    }

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

    if (amount < _minimumWithdrawalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum withdrawal amount is ₹${_minimumWithdrawalAmount.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_remainingRequestsToday <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _dailyWithdrawalRequestLimit > 0
                ? 'Daily withdrawal request limit reached ($_requestsToday/$_dailyWithdrawalRequestLimit). Try tomorrow.'
                : 'Daily withdrawal request limit reached. Try tomorrow.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_apiCanWithdraw) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal is currently not allowed as per server limits.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate payment method specific fields
    String paymentMethod = 'UPI';
    if (_selectedPaymentMethod == 3) {
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

    if (!_withdrawRewardedCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please watch the rewarded ad above first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _processWithdrawalRequest(amount, paymentMethod);
  }

  /// Validate the gift voucher selection, deduct the wallet balance, and
  /// persist the request via the gift voucher API.
  Future<void> _submitGiftVoucherRequest() async {
    final brand = _selectedGiftBrand;
    final amount = _selectedGiftAmount;

    if (brand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a gift voucher brand.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a denomination.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (amount > _walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance. Available: ₹${_walletBalance.toStringAsFixed(0)}, Requested: ₹$amount',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_remainingRequestsToday <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _dailyWithdrawalRequestLimit > 0
                ? 'Daily withdrawal request limit reached ($_requestsToday/$_dailyWithdrawalRequestLimit). Try tomorrow.'
                : 'Daily withdrawal request limit reached. Try tomorrow.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_withdrawRewardedCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please watch the rewarded ad above first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirm with the user.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground(ctx),
        title: const Text(
          'Confirm Gift Voucher',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Redeem a $brand voucher for ₹$amount?\n\n₹$amount will be deducted from your wallet immediately. The request will be set to "Pending" until admin approval.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        return;
      }

      final result = await ApiService.submitGiftVoucherRequest(
        token: token,
        brand: brand,
        amount: amount,
      );

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final remainingBalance = data['remainingWalletBalance'];
        if (remainingBalance != null) {
          setState(() {
            _walletBalance = _asDouble(remainingBalance,
                fallback: _walletBalance);
          });
        }

        // Reset selection.
        setState(() {
          _selectedGiftBrand = null;
          _selectedGiftAmount = null;
          _withdrawRewardedCompleted = false;
        });

        await _fetchWithdrawalThreshold();
        await _fetchGiftVoucherRequests();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                'Gift voucher request submitted successfully'),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                'Failed to submit gift voucher request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _processWithdrawalRequest(double amount, String paymentMethod) async {
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
        await _fetchWithdrawalThreshold();
        await _fetchWithdrawalRequests();

        if (mounted) {
          setState(() {
            _withdrawRewardedCompleted = false;
          });
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

  Widget _buildWithdrawRewardedStrip() {
    return Material(
      color: AppColors.cardBackground(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: (_isAdLoading || _isSubmitting) ? null : _playWithdrawRewardedAd,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.play_circle_filled,
                color: AppColors.primary,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rewarded ad',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _withdrawRewardedCompleted
                          ? 'Done — tap Withdraw Money below'
                          : 'Watch this ad first, then withdraw',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isAdLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else if (_withdrawRewardedCompleted)
                const Icon(Icons.check_circle, color: AppColors.green, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawButton() {
    final isGiftVoucher = _withdrawalType == 0;
    final hasGiftSelection =
        _selectedGiftBrand != null && _selectedGiftAmount != null;

    final canWithdraw = _withdrawRewardedCompleted &&
        !_isSubmitting &&
        !_isLoadingThreshold &&
        _remainingRequestsToday > 0 &&
        (isGiftVoucher ? hasGiftSelection : _apiCanWithdraw);

    final buttonLabel = isGiftVoucher ? 'Confirm Voucher' : 'Withdraw Money';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background(context),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWithdrawRewardedStrip(),
            const SizedBox(height: 12),
            if (_isLoadingThreshold)
              const Text(
                'Checking withdrawal limits...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              )
            else
              Text(
                _dailyWithdrawalRequestLimit > 0
                    ? 'Requests today: $_requestsToday/$_dailyWithdrawalRequestLimit (remaining: $_remainingRequestsToday)'
                    : 'Requests remaining today: $_remainingRequestsToday',
                style: TextStyle(
                  color: (_remainingRequestsToday > 0 && _apiCanWithdraw)
                      ? Colors.white70
                      : Colors.orangeAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: canWithdraw ? _submitWithdrawalRequest : null,
              child: Opacity(
                opacity: _isSubmitting || canWithdraw ? 1.0 : 0.45,
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              buttonLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isGiftVoucher
                                  ? Icons.card_giftcard
                                  : Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
