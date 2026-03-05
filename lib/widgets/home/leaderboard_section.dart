import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../screens/leaderboard/leaderboard_screen.dart';

class LeaderboardSection extends StatefulWidget {
  const LeaderboardSection({Key? key}) : super(key: key);

  @override
  State<LeaderboardSection> createState() => _LeaderboardSectionState();
}

class _LeaderboardSectionState extends State<LeaderboardSection> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _topUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchTopUsers();
  }

  Future<void> _fetchTopUsers() async {
    if (!mounted) return;
    
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    final result = await ApiService.getLeaderboard(
      token: token,
      type: 'wallet',
      limit: 5,
      page: 1,
    );

    if (mounted) {
      if (result['success'] == true && result['data'] != null) {
        final data = result['data']['leaderboard'] as List;
        setState(() {
          _topUsers = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink(); 
    }
    
    if (_topUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Earners',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LeaderboardScreen(),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _topUsers.length,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, index) {
              final user = _topUsers[index];
              final rank = user['rank'];
              
              return GestureDetector(
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LeaderboardScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow(context),
                    border: Border.all(
                      color: AppColors.border(context), 
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Container(
                          width: 36,
                          height: 36,
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
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        user['userName'] ?? user['UserName'] ?? 'User',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${user['walletBalance']?.toStringAsFixed(0) ?? '0'}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

   Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return AppColors.primary; // Default
  }
}
