import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../screens/daily_bonus/daily_bonus_screen.dart';
import '../../screens/refer/refer_earn_screen.dart';
import '../../screens/task_offers/task_offers_screen.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            title: 'Claim Bonus',
            color1: const Color(0xFF42A5F5), // Light Blue
            color2: const Color(0xFF1976D2), // Dark Blue
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DailyBonusScreen()),
              );
            },
            iconBuilder: () => _buildGiftIcon(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            title: 'Daily Deals',
            color1: const Color(0xFF9CCC65), // Light Green
            color2: const Color(0xFF689F38), // Dark Green
            onTap: () {
              // Navigate to offers screen as "Daily Deals"
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TaskOffersScreen()),
              );
            },
            iconBuilder: () => _buildCalendarIcon(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            title: 'Refer & Earn',
            color1: const Color(0xFFFFCC80), // Light Orange
            color2: const Color(0xFFEF5350), // Red/Pink
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReferEarnScreen()),
              );
            },
            iconBuilder: () => _buildMegaphoneIcon(),
          ),
        ),
      ],
    );
  }

  Widget _buildGiftIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Box
        Container(
          width: 36,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD54F),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        // Vertical Ribbon
        Container(
          width: 8,
          height: 30,
          color: const Color(0xFFFFA000),
        ),
        // Horizontal Ribbon
        Container(
          width: 36,
          height: 6,
          color: const Color(0xFFFFA000),
        ),
        // Bow
        Positioned(
          top: -6,
          child: Icon(Icons.emergency, color: const Color(0xFFFFA000), size: 16),
        ),
      ],
    );
  }

  Widget _buildCalendarIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF66BB6A),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top bar with rings
          Container(
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRing(),
                _buildRing(),
                _buildRing(),
              ],
            ),
          ),
          // Grid
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              padding: EdgeInsets.zero,
              children: List.generate(
                6,
                (index) => Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFAED581),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRing() {
    return Container(
      width: 4,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildMegaphoneIcon() {
    return Transform.rotate(
      angle: -0.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cone
          Icon(Icons.campaign, size: 48, color: const Color(0xFFFF7043)),
          // Detail
          Positioned(
            right: 12,
            child: Icon(Icons.circle, size: 8, color: const Color(0xFFD84315)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final Color color1;
  final Color color2;
  final VoidCallback onTap;
  final Widget Function() iconBuilder;

  const _QuickActionCard({
    required this.title,
    required this.color1,
    required this.color2,
    required this.onTap,
    required this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110, // Square-ish aspect ratio
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color2.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Center(
                child: iconBuilder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13, // Slightly smaller to fit
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
