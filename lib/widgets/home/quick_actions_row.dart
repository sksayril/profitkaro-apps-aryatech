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
            backgroundColor: const Color(0xFFBBDEFB), // Light Blue
            buttonColor: const Color(0xFF1976D2), // Dark Blue
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
            backgroundColor: const Color(0xFFDCEDC8), // Light Green
            buttonColor: const Color(0xFF558B2F), // Dark Green
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
            backgroundColor: const Color(0xFFFFE0B2), // Light Orange
            buttonColor: const Color(0xFFE64A19), // Dark Orange
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
    return Image.asset(
      'assets/images/claimbonus.png',
      width: 55,
      height: 55,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to custom icon if image fails to load
        return Stack(
          alignment: Alignment.center,
          children: [
            // Box
            Container(
              width: 54, // Scaled 1.5x
              height: 45, // Scaled 1.5x
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F),
                borderRadius: BorderRadius.circular(6),
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
              width: 12,
              height: 45,
              color: const Color(0xFFFFA000),
            ),
            // Horizontal Ribbon
            Container(
              width: 54,
              height: 9,
              color: const Color(0xFFFFA000),
            ),
            // Bow
            Positioned(
              top: -9,
              child: Icon(Icons.emergency, color: const Color(0xFFFFA000), size: 24),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarIcon() {
    return Image.asset(
      'assets/images/calender.png',
      width: 55,
      height: 55,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: const Color(0xFF66BB6A),
            borderRadius: BorderRadius.circular(8),
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
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
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
                padding: const EdgeInsets.all(5.0),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
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
      },
    );
  }

  Widget _buildRing() {
    return Container(
      width: 6,
      height: 9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildMegaphoneIcon() {
    return Image.asset(
      'assets/images/referearn.png',
      width: 55,
      height: 55,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Transform.rotate(
          angle: -0.3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cone
              Icon(Icons.campaign, size: 60, color: const Color(0xFFFF7043)),
              // Detail
              Positioned(
                right: 15,
                child: Icon(Icons.circle, size: 10, color: const Color(0xFFD84315)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color buttonColor;
  final VoidCallback onTap;
  final Widget Function() iconBuilder;

  const _QuickActionCard({
    required this.title,
    required this.backgroundColor,
    required this.buttonColor,
    required this.onTap,
    required this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: iconBuilder(),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
