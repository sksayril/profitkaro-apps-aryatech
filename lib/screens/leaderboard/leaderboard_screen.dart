import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _leaderboardData = [];
  String _currentType = 'wallet';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchLeaderboard();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      if (_tabController.index == 0) {
        _currentType = 'wallet';
      } else {
        _currentType = 'coins';
      }
      _fetchLeaderboard();
    }
  }

  Future<void> _fetchLeaderboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to view leaderboard')),
        );
      }
      return;
    }

    final result = await ApiService.getLeaderboard(
      token: token,
      type: _currentType,
      limit: 50,
      page: 1,
    );

    if (mounted) {
      if (result['success'] == true && result['data'] != null) {
        final data = result['data']['leaderboard'] as List;
        setState(() {
          _leaderboardData = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _leaderboardData = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to load leaderboard')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppColors.background(context),
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: AppColors.primary,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary(context),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Top Earners'),
                Tab(text: 'Top Tree Holders'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboardData.isEmpty
              ? Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(color: AppColors.textSecondary(context)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _leaderboardData.length,
                  itemBuilder: (context, index) {
                    final item = _leaderboardData[index];
                    final rank = item['rank'];
                    final userName = item['userName'] ?? item['UserName'] ?? 'Unknown';
                    final walletBalance = item['walletBalance'];
                    final coins = item['coins'];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground(context),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow(context),
                        border: Border.all(
                          color: AppColors.border(context),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _getRankColor(rank).withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getRankColor(rank),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                color: _getRankColor(rank),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _currentType == 'wallet'
                                  ? '₹${walletBalance?.toStringAsFixed(2) ?? '0.00'}'
                                  : '$coins Trees',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.grey.shade400; // Default
  }
}
