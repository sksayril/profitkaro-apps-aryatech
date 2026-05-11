import 'package:flutter/material.dart';
import '../../core/constants/gamepix_game_icons.dart';
import '../../screens/games/gamepix_embed_screen.dart';

/// Home row: Games carousel (Strike Galaxy Attack, Hungry Squirrel, Stickman Fighter).
class HomeGamesSection extends StatelessWidget {
  const HomeGamesSection({super.key});

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFF1C1440);
    const borderCol = Color(0xFF4A3478);
    const ctaPurple = Color(0xFF3D2E6A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.sports_esports_rounded,
              color: Colors.white.withValues(alpha: 0.95),
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'Games',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 252,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _GameCard(
                title: 'Strike Galaxy Attack',
                coins: '10',
                minutes: '90',
                gradientColors: const [Color(0xFF1A237E), Color(0xFF0D1642)],
                iconUrl: GamepixGameIcons.strikeGalaxyAttack,
                embedUrl: GamepixGameEmbeds.strikeGalaxyAttack,
                borderColor: borderCol,
                cardColor: cardBg,
                ctaColor: ctaPurple,
              ),
              const SizedBox(width: 14),
              _GameCard(
                title: 'Hungry Squirrel',
                coins: '10',
                minutes: '90',
                gradientColors: const [Color(0xFF6D4C41), Color(0xFF3E2723)],
                iconUrl: GamepixGameIcons.hungrySquirrel,
                embedUrl: GamepixGameEmbeds.hungrySquirrel,
                borderColor: borderCol,
                cardColor: cardBg,
                ctaColor: ctaPurple,
              ),
              const SizedBox(width: 14),
              _GameCard(
                title: 'Stickman Fighter',
                coins: '10',
                minutes: '90',
                gradientColors: const [Color(0xFF37474F), Color(0xFF1C2529)],
                iconUrl: GamepixGameIcons.stickmanFighterMegaBrawl,
                embedUrl: GamepixGameEmbeds.stickmanFighterMegaBrawl,
                borderColor: borderCol,
                cardColor: cardBg,
                ctaColor: ctaPurple,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String coins;
  final String minutes;
  final List<Color> gradientColors;
  final String iconUrl;
  final String embedUrl;
  final Color borderColor;
  final Color cardColor;
  final Color ctaColor;

  const _GameCard({
    required this.title,
    required this.coins,
    required this.minutes,
    required this.gradientColors,
    required this.iconUrl,
    required this.embedUrl,
    required this.borderColor,
    required this.cardColor,
    required this.ctaColor,
  });

  void _openEmbed(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamepixEmbedScreen(title: title, embedUrl: embedUrl),
      ),
    );
  }

  static const double _thumbSize = 92;
  static const double _overlap = 36;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: _overlap),
            child: Container(
              width: 152,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      color: cardColor,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: _thumbSize - _overlap + 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.monetization_on_rounded,
                                color: Colors.amber.shade400,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                coins,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: Colors.white.withValues(alpha: 0.85),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                minutes,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    ClipPath(
                      clipper: _CtaNotchClipper(),
                      child: Material(
                        color: ctaColor,
                        child: InkWell(
                          onTap: () => _openEmbed(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: const Text(
                              'PLAY NOW',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.9,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openEmbed(context),
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      iconUrl,
                      width: _thumbSize,
                      height: _thumbSize,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Container(
                        width: _thumbSize,
                        height: _thumbSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                        ),
                        child: Icon(
                          Icons.sports_esports_rounded,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: _thumbSize,
                          height: _thumbSize,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                          ),
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Curved top edge on the PLAY NOW bar (notch into the stats area).
class _CtaNotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const dip = 9.0;
    path.moveTo(0, dip);
    path.quadraticBezierTo(size.width * 0.5, 0, size.width, dip);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
