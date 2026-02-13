import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import 'task_details_screen.dart';

class TaskOffersScreen extends StatefulWidget {
  const TaskOffersScreen({super.key});

  @override
  State<TaskOffersScreen> createState() => _TaskOffersScreenState();
}

class _TaskOffersScreenState extends State<TaskOffersScreen> with SingleTickerProviderStateMixin {
  int _selectedFilter = 0;
  final List<String> _filters = ['All Offers', 'Highest Paying', 'Easiest'];
  List<dynamic> _apps = [];
  bool _isLoading = true;
  String _lastUpdated = 'Just now';
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _fetchApps();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _fetchApps() async {
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

      String? filter;
      if (_selectedFilter == 1) {
        filter = 'highest';
      } else if (_selectedFilter == 2) {
        filter = 'easiest';
      }

      final result = await ApiService.getApps(
        token: token,
        filter: filter,
      );

      if (result['success'] && result['data'] != null) {
        setState(() {
          _apps = result['data']['apps'] ?? [];
          _isLoading = false;
          _lastUpdated = 'Just now';
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch apps'),
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

  Future<void> _handleFilterChange(int index) async {
    setState(() {
      _selectedFilter = index;
    });
    await _fetchApps();
  }


  String _getButtonText(String userStatus, bool canSubmit) {
    if (userStatus == 'approved') {
      return 'Completed';
    } else if (userStatus == 'pending') {
      return 'Pending Review';
    } else if (userStatus == 'rejected') {
      return 'Resubmit';
    } else if (canSubmit) {
      return 'Start Task';
    }
    return 'Not Available';
  }

  Color _getButtonColor(String userStatus, bool canSubmit) {
    if (userStatus == 'approved') {
      return AppColors.green;
    } else if (userStatus == 'pending') {
      return Colors.orange;
    } else if (userStatus == 'rejected' || canSubmit) {
      return AppColors.primary;
    }
    return Colors.grey;
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
          'Task Offers',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchApps,
          ),
        ],
      ),
      body: Column(
        children: [
          // Updated text
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Text(
                'Updated $_lastUpdated',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          // Filter tabs
          _buildFilterTabs(),
          
          // Task cards
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoaders()
                : _apps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apps,
                              size: 64,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No apps available',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchApps,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ..._apps.map((app) => _buildAppCard(app)),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_filters.length, (index) {
          bool isSelected = _selectedFilter == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < _filters.length - 1 ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () => _handleFilterChange(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.cardBackground(context),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index == 1 && !isSelected)
                        const Icon(Icons.local_fire_department, color: AppColors.orange, size: 16),
                      if (index == 1 && !isSelected) const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAppCard(Map<String, dynamic> app) {
    final appName = app['appName'] ?? 'Unknown App';
    final appImage = app['appImage'] ?? '';
    final rewardCoins = app['rewardCoins'] ?? 0;
    final difficulty = app['difficulty'] ?? 'Easy';
    final description = app['description'] ?? '';
    final userStatus = (app['userStatus'] ?? 'available').toString().toLowerCase();
    final canSubmit = app['canSubmit'] ?? false;

    final buttonText = _getButtonText(userStatus, canSubmit);
    final buttonColor = _getButtonColor(userStatus, canSubmit);
    final isApproved = userStatus == 'approved';
    final isPending = userStatus == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App info row
          Row(
            children: [
              // App icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade800,
                ),
                clipBehavior: Clip.antiAlias,
                child: appImage.isNotEmpty
                    ? Image.network(
                        appImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.apps,
                          color: Colors.white,
                          size: 30,
                        ),
                      )
                    : const Icon(
                        Icons.apps,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$difficulty',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• $description',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Status badge if pending or approved
          if (isPending || isApproved) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isApproved
                    ? AppColors.green.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isApproved ? 'Approved' : 'Pending Review',
                style: TextStyle(
                  color: isApproved ? AppColors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Action button and reward
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: canSubmit && !isApproved && !isPending
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailsScreen(app: app),
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.yellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '\$',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+ $rewardCoins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoaders() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSkeletonCard(),
          const SizedBox(height: 16),
          _buildSkeletonCard(),
          const SizedBox(height: 16),
          _buildSkeletonCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
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
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App info row skeleton
                Row(
                  children: [
                    // App icon skeleton
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App name skeleton
                          Container(
                            height: 18,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Category skeleton
                          Container(
                            height: 14,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Button row skeleton
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 100,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
