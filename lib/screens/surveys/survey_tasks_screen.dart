import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SurveyTasksScreen extends StatefulWidget {
  const SurveyTasksScreen({super.key});

  @override
  State<SurveyTasksScreen> createState() => _SurveyTasksScreenState();
}

class _SurveyTasksScreenState extends State<SurveyTasksScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'High Paying', 'Under 5 mins', 'New'];

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
          'Survey Tasks',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '450.00',
                  style: TextStyle(
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
      body: Column(
        children: [
          // Filter tabs
          _buildFilterTabs(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium/Featured Task
                  _buildPremiumTask(),
                  const SizedBox(height: 24),
                  
                  // Available Tasks
                  _buildAvailableTasksSection(),
                  const SizedBox(height: 20),
                  
                  // Information Box
                  _buildInfoBox(),
                  const SizedBox(height: 20),
                  
                  // Footer
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedFilter == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumTask() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3D5A), Color(0xFF0D1F2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: AppColors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Recommended',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Market Research Global',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey.shade400, size: 16),
              const SizedBox(width: 6),
              Text(
                '15 mins',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.star, color: AppColors.yellow, size: 16),
              const SizedBox(width: 6),
              Text(
                '4.8',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '₹50.00',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Start Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AVAILABLE TASKS',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        _buildTaskCard(
          icon: Icons.music_note,
          iconColor: AppColors.purple,
          title: 'Music Feedback',
          duration: '2 mins',
          tag: 'Fun',
          tagColor: AppColors.purple,
          reward: '₹5.00',
          isLocked: false,
        ),
        const SizedBox(height: 12),
        _buildTaskCard(
          icon: Icons.shopping_cart,
          iconColor: AppColors.green,
          title: 'Shopping Habits',
          duration: '7 mins',
          tag: 'Easy',
          tagColor: AppColors.green,
          reward: '₹12.00',
          isLocked: false,
        ),
        const SizedBox(height: 12),
        _buildTaskCard(
          icon: Icons.sports_esports,
          iconColor: Colors.grey,
          title: 'Gaming Preference',
          duration: '10 mins',
          tag: 'Coming soon',
          tagColor: Colors.grey,
          reward: '₹25.00',
          isLocked: true,
        ),
      ],
    );
  }

  Widget _buildTaskCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String duration,
    required String tag,
    required Color tagColor,
    required String reward,
    required bool isLocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey.shade500, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: tagColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                reward,
                style: TextStyle(
                  color: isLocked ? Colors.grey.shade600 : AppColors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (isLocked)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, color: Colors.grey, size: 18),
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Surveys are provided by third-party partners. Reward amounts may vary based on completion quality. Honest answers ensure future availability and higher payouts.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'Profit Karo © 2024 • v1.2.4',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 11,
        ),
      ),
    );
  }
}
