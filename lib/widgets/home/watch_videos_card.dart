import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../screens/watch_videos/watch_videos_screen.dart';
import 'home_promo_card.dart';

class WatchVideosCard extends StatelessWidget {
  const WatchVideosCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HomePromoCard(
      gradientColors: const [Color(0xFFF39C12), Color(0xFFD35400)],
      leading: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 34),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD54F),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6D4C41),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      title: 'Watch Videos',
      subtitle: 'Earn Tree 🌴  Unlock rewards on every view!',
      buttonText: 'Watch Now',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WatchVideosScreen(),
          ),
        );
      },
    );
  }
}

