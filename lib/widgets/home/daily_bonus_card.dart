import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../screens/daily_bonus/daily_bonus_screen.dart';

class DailyBonusCard extends StatelessWidget {
  const DailyBonusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DailyBonusScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A3D8A), Color(0xFF2A2050)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Gift icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: AppColors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Bonus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Claim your daily rewards & streaks!',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
