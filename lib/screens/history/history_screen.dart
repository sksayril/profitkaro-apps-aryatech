import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  
  const HistoryScreen({super.key, this.onBack});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNextPage = false;
  int _currentPage = 1;
  static const int _limit = 20;
  String? _selectedType; // null = All

  Map<String, dynamic>? _totals;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchHistory(initial: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasNextPage) {
      _fetchHistory(initial: false);
    }
  }

  Future<void> _fetchHistory({required bool initial}) async {
    if (initial) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _events.clear();
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
        return;
      }

      final result = await ApiService.getWalletHistory(
        token: token,
        page: _currentPage,
        limit: _limit,
        type: _selectedType,
      );

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final events = (data['events'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final pagination =
            (data['pagination'] as Map<String, dynamic>? ?? {});

        setState(() {
          _events.addAll(events);
          _totals = data['totals'] as Map<String, dynamic>?;
          _hasNextPage = pagination['hasNextPage'] == true;
          if (_hasNextPage) {
            _currentPage = (pagination['currentPage'] as int? ?? _currentPage) +
                1;
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch history'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _changeFilter(String? type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
    });
    _fetchHistory(initial: true);
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
          'History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchHistory(initial: true),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildTotalsCard(context),
            const SizedBox(height: 8),
            _buildFiltersRow(context),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _events.isEmpty
                      ? _buildEmptyState(context)
                      : _buildGrid(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context) {
    final totals = _totals;
    if (totals == null) {
      return const SizedBox.shrink();
    }

    final totalCoins = totals['totalCoinsChange'] ?? 0;
    final totalWallet = (totals['totalWalletChange'] ?? 0).toDouble();
    final currentCoins = totals['currentCoins'] ?? 0;
    final currentWallet = (totals['currentWalletBalance'] ?? 0).toDouble();

    String formatCurrency(double value) {
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 2,
      );
      return formatter.format(value);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow(context),
        ),
        child: Row(
          children: [
            _buildTotalsColumn(
              title: 'Coins',
              primary: '$currentCoins',
              secondary:
                  (totalCoins >= 0 ? '+$totalCoins' : '$totalCoins') + ' today',
              primaryColor: Colors.white,
              secondaryColor:
                  totalCoins >= 0 ? AppColors.green : Colors.redAccent,
            ),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 40,
              color: AppColors.borderLight(context),
            ),
            const SizedBox(width: 16),
            _buildTotalsColumn(
              title: 'Wallet',
              primary: formatCurrency(currentWallet),
              secondary:
                  (totalWallet >= 0 ? '+${totalWallet.toStringAsFixed(2)}' : totalWallet.toStringAsFixed(2)),
              primaryColor: Colors.white,
              secondaryColor:
                  totalWallet >= 0 ? AppColors.green : Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsColumn({
    required String title,
    required String primary,
    required String secondary,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            primary,
            style: TextStyle(
              color: primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            secondary,
            style: TextStyle(
              color: secondaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow(BuildContext context) {
    const types = [
      {'label': 'All', 'value': null},
      {'label': 'Scratch Cards', 'value': 'SCRATCH_CARD'},
      {'label': 'Daily Limit', 'value': 'SCRATCH_CARD_DAILY_LIMIT'},
      {'label': 'Captcha', 'value': 'CAPTCHA'},
      {'label': 'App Installs', 'value': 'APP_INSTALL'},
      {'label': 'Withdrawals', 'value': 'WITHDRAWAL'},
      {'label': 'Conversions', 'value': 'COIN_CONVERSION'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = types[index];
          final label = item['label'] as String;
          final value = item['value'] as String?;
          final isSelected = _selectedType == value || (value == null && _selectedType == null);

          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary(context),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.cardBackgroundLight(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderLight(context),
              ),
            ),
            onSelected: (_) => _changeFilter(value),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: types.length,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded,
              size: 64, color: Colors.grey.shade700),
          const SizedBox(height: 12),
          const Text(
            'No history yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start playing games, installing apps,\n or withdrawing to see history here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: _events.length,
            itemBuilder: (context, index) {
              final event = _events[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildHistoryCard(context, event),
              );
            },
          ),
        ),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> event) {
    final type = (event['type'] as String? ?? '').toUpperCase();
    final title = event['title'] as String? ?? 'History Item';
    final coinsChange = (event['coinsChange'] ?? 0) as num;
    final walletChange = (event['walletChange'] ?? 0).toDouble();
    final status = event['status'] as String? ?? 'Completed';
    final createdAtStr = event['createdAt'] as String?;

    DateTime? createdAt;
    String dateLabel = '';
    String timeLabel = '';
    if (createdAtStr != null) {
      try {
        createdAt = DateTime.parse(createdAtStr).toLocal();
        dateLabel = DateFormat('d MMM, yyyy').format(createdAt);
        timeLabel = DateFormat('hh:mm a').format(createdAt);
      } catch (_) {}
    }

    final config = _getTypeConfig(type);
    final icon = config.icon;
    final bgColor = config.bgColor;
    final accent = config.accentColor;
    final typeLabel = config.label;

    String coinsText;
    Color coinsColor;
    if (coinsChange == 0) {
      coinsText = '0 Coins';
      coinsColor = AppColors.textSecondary(context);
    } else {
      final sign = coinsChange > 0 ? '+' : '';
      coinsText = '$sign$coinsChange Coins';
      coinsColor = coinsChange > 0 ? AppColors.green : Colors.redAccent;
    }

    String walletText;
    Color walletColor;
    if (walletChange == 0) {
      walletText = '₹0.00';
      walletColor = AppColors.textSecondary(context);
    } else {
      final sign = walletChange > 0 ? '+' : '';
      walletText = '₹$sign${walletChange.toStringAsFixed(2)}';
      walletColor = walletChange > 0 ? AppColors.green : Colors.redAccent;
    }

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = AppColors.amber;
        break;
      case 'rejected':
      case 'failed':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = AppColors.green;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground(context),
            AppColors.cardBackground(context).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          ...AppColors.cardShadow(context),
        ],
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Decorative gradient overlay
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    accent.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container with gradient
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withOpacity(0.3),
                        accent.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accent.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, size: 28, color: accent),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type label badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Rewards row
                      Row(
                        children: [
                          // Coins
                          if (coinsChange != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: coinsColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: coinsColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.monetization_on_rounded,
                                    size: 16,
                                    color: coinsColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    coinsText,
                                    style: TextStyle(
                                      color: coinsColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (coinsChange != 0 && walletChange != 0)
                            const SizedBox(width: 8),
                          // Wallet
                          if (walletChange != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: walletColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: walletColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 16,
                                    color: walletColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    walletText,
                                    style: TextStyle(
                                      color: walletColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Date and status row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Date time
                          if (dateLabel.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary(context),
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateLabel,
                                      style: TextStyle(
                                        color: AppColors.textSecondary(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (timeLabel.isNotEmpty)
                                      Text(
                                        timeLabel,
                                        style: TextStyle(
                                          color: AppColors.textSecondary(context)
                                              .withOpacity(0.8),
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  statusColor.withOpacity(0.3),
                                  statusColor.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _TypeConfig _getTypeConfig(String type) {
    switch (type) {
      case 'SCRATCH_CARD':
        return _TypeConfig(
          icon: Icons.card_giftcard_rounded,
          bgColor: AppColors.iconBgPink,
          accentColor: AppColors.pink,
          label: 'Scratch Card',
        );
      case 'SCRATCH_CARD_DAILY_LIMIT':
        return _TypeConfig(
          icon: Icons.calendar_month_rounded,
          bgColor: AppColors.iconBgYellow,
          accentColor: AppColors.yellow,
          label: 'Daily Limit',
        );
      case 'CAPTCHA':
        return _TypeConfig(
          icon: Icons.keyboard_rounded,
          bgColor: AppColors.iconBgTeal,
          accentColor: AppColors.teal,
          label: 'Captcha',
        );
      case 'APP_INSTALL':
        return _TypeConfig(
          icon: Icons.download_rounded,
          bgColor: AppColors.iconBgOrange,
          accentColor: AppColors.orange,
          label: 'App Install',
        );
      case 'WITHDRAWAL':
        return _TypeConfig(
          icon: Icons.outbox_rounded,
          bgColor: AppColors.iconBgBlue,
          accentColor: AppColors.primary,
          label: 'Withdrawal',
        );
      case 'COIN_CONVERSION':
        return _TypeConfig(
          icon: Icons.currency_exchange_rounded,
          bgColor: AppColors.iconBgPurple,
          accentColor: AppColors.purple,
          label: 'Conversion',
        );
      default:
        return _TypeConfig(
          icon: Icons.history_rounded,
          bgColor: AppColors.cardBackgroundLight(context),
          accentColor: AppColors.primary,
          label: type.isEmpty ? 'History' : type,
        );
    }
  }
}

class _TypeConfig {
  final IconData icon;
  final Color bgColor;
  final Color accentColor;
  final String label;

  _TypeConfig({
    required this.icon,
    required this.bgColor,
    required this.accentColor,
    required this.label,
  });
}

