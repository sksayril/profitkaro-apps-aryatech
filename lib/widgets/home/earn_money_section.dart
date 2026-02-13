import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../screens/music/music_screen.dart';
import '../../screens/surveys/survey_tasks_screen.dart';
import '../../screens/games/games_screen.dart';
import '../../screens/captcha/captcha_screen.dart';
import '../../screens/spin_wheel/spin_wheel_screen.dart';
import '../../screens/task_offers/task_offers_screen.dart';

class EarnMoneySection extends StatelessWidget {
  const EarnMoneySection({super.key});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earn Money',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            EarnMoneyCard(
              icon: Icons.assignment_outlined,
              iconBgColor: AppColors.iconBgBlue,
              iconColor: AppColors.primary,
              title: 'Surveys',
              subtitle: 'Up to ₹50',
              subtitleColor: AppColors.green,
              isComingSoon: true,
              onTap: () {
                _showComingSoonDialog(context);
              },
            ),
            EarnMoneyCard(
              icon: Icons.download_rounded,
              iconBgColor: AppColors.iconBgOrange,
              iconColor: AppColors.orange,
              title: 'App Install',
              subtitle: 'High Reward',
              subtitleColor: AppColors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TaskOffersScreen()),
                );
              },
            ),
            EarnMoneyCard(
              icon: Icons.headphones_rounded,
              iconBgColor: AppColors.iconBgPurple,
              iconColor: AppColors.purple,
              title: 'Music',
              subtitle: 'Listen & Earn',
              subtitleColor: Colors.grey.shade500,
              isComingSoon: true,
              onTap: () {
                _showComingSoonDialog(context);
              },
            ),
            EarnMoneyCard(
              icon: Icons.sports_esports_rounded,
              iconBgColor: AppColors.iconBgPink,
              iconColor: AppColors.pink,
              title: 'Games',
              subtitle: 'Play & Win',
              subtitleColor: Colors.grey.shade500,
              isComingSoon: true,
              onTap: () {
                _showComingSoonDialog(context);
              },
            ),
            EarnMoneyCard(
              icon: Icons.star_rounded,
              iconBgColor: AppColors.iconBgYellow,
              iconColor: AppColors.yellow,
              title: 'Spin Wheel',
              subtitle: 'Daily Jackpot',
              subtitleColor: Colors.grey.shade500,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SpinWheelScreen()),
                );
              },
            ),
            EarnMoneyCard(
              icon: Icons.keyboard_rounded,
              iconBgColor: AppColors.iconBgTeal,
              iconColor: AppColors.teal,
              title: 'Captcha',
              subtitle: 'Easy Type',
              subtitleColor: Colors.grey.shade500,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CaptchaScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class EarnMoneyCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final VoidCallback? onTap;
  final bool isComingSoon;

  const EarnMoneyCard({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    this.onTap,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon in circular container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
