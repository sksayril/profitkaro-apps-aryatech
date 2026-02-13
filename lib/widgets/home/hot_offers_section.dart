import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../screens/task_offers/task_offers_screen.dart';

class HotOffersSection extends StatelessWidget {
  const HotOffersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text(
                  'Hot Offers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  '🔥',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TaskOffersScreen()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Hot offer cards
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _HotOfferCard1(),
              SizedBox(width: 12),
              _HotOfferCard2(),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotOfferCard1 extends StatelessWidget {
  const _HotOfferCard1();

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Coming Soon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'This feature is coming soon!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showComingSoonDialog(context),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // 3D Pills/Capsules icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF3D5A6A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cyan cylinder (top)
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Container(
                        width: 50,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4DD0E1), Color(0xFF00BCD4)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                  // Orange cylinder (middle)
                  Positioned(
                    top: 32,
                    left: 20,
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Container(
                        width: 45,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  // Yellow cylinder (bottom)
                  Positioned(
                    bottom: 12,
                    left: 18,
                    child: Transform.rotate(
                      angle: -0.1,
                      child: Container(
                        width: 48,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFEB3B), Color(0xFFFBC02D)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '2x Reward',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Double Bonus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get 2x rewards on surveys',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotOfferCard2 extends StatelessWidget {
  const _HotOfferCard2();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Hand holding phone icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF7BCDC0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Phone
                Positioned(
                  top: 10,
                  child: Container(
                    width: 32,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Hand
                Positioned(
                  bottom: 5,
                  right: 10,
                  child: Container(
                    width: 30,
                    height: 25,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0B69E),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(8),
                      ),
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
