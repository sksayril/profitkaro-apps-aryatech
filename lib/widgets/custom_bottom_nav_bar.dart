import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/social_links_public.dart';
import '../../core/services/social_links_public_service.dart';
import '../../core/services/social_rewards_service.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Force dark background for the nav bar to match the design
    final backgroundColor = const Color(0xFF0D0D1A);
    
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Only show social media links on home screen (index 0)
          if (currentIndex == 0) const _SocialLinksRow(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildNavItem(
                context,
                index: 0,
                selectedIcon: Icons.home_rounded,
                unselectedIcon: Icons.home_outlined,
                label: 'Home',
              ),
              _buildNavItem(
                context,
                index: 1,
                selectedIcon: Icons.account_balance_wallet_rounded,
                unselectedIcon: Icons.account_balance_wallet_outlined,
                label: 'Wallet',
              ),
              _buildCenterAnnouncementItem(context, index: 2),
              _buildNavItem(
                context,
                index: 3,
                selectedIcon: Icons.history_rounded,
                unselectedIcon: Icons.history_outlined,
                label: 'History',
              ),
              _buildNavItem(
                context,
                index: 4,
                selectedIcon: Icons.person_rounded,
                unselectedIcon: Icons.person_outline_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenterAnnouncementItem(BuildContext context, {required int index}) {
    final isSelected = currentIndex == index;
    const purpleColor = Color(0xFF5B4FCF);
    const purpleGlow = Color(0xFF7C6FE0);

    return GestureDetector(
      onTap: () => onTap(index),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? purpleGlow : purpleColor,
                  boxShadow: [
                    BoxShadow(
                      color: purpleColor.withOpacity(isSelected ? 0.7 : 0.45),
                      blurRadius: isSelected ? 20 : 12,
                      spreadRadius: isSelected ? 3 : 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedRotation(
                  turns: isSelected ? 0.03 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: AnimatedScale(
                    scale: isSelected ? 1.16 : 1.0,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.elasticOut,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF59D), Color(0xFFFFD54F), Color(0xFFFFB300)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: const Color(0xFFFFE082),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withOpacity(isSelected ? 0.7 : 0.45),
                            blurRadius: isSelected ? 14 : 8,
                            spreadRadius: isSelected ? 2 : 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFF8D5B00),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -14),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? purpleGlow : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontFamily: 'Inter',
                ),
                child: const Text('Hot Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData selectedIcon,
    required IconData unselectedIcon,
    required String label,
    String? iconAssetPath,
  }) {
    final isSelected = currentIndex == index;
    final selectedColor = AppColors.primary;
    final unselectedColor = Colors.grey.shade600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        splashColor: selectedColor.withOpacity(0.1),
        highlightColor: selectedColor.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 1.0,
                  end: isSelected ? 1.0 : 0.0,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, isSelected ? -2 : 0),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 1.0,
                        end: isSelected ? 1.2 : 1.0,
                      ),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        final iconColor =
                            isSelected ? selectedColor : unselectedColor;
                        return Transform.scale(
                          scale: scale,
                          child: iconAssetPath != null
                              ? ImageIcon(
                                  AssetImage(iconAssetPath),
                                  color: iconColor,
                                  size: 24,
                                )
                              : Icon(
                                  isSelected ? selectedIcon : unselectedIcon,
                                  color: iconColor,
                                  size: 24,
                                ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? selectedColor : unselectedColor,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontFamily: 'Inter',
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLinksRow extends StatefulWidget {
  const _SocialLinksRow();

  @override
  State<_SocialLinksRow> createState() => _SocialLinksRowState();
}

class _SocialLinksRowState extends State<_SocialLinksRow> {
  SocialLinksPublic _links = SocialLinksPublic.defaults();
  bool _telegramAvailable = true;
  bool _youtubeAvailable = true;
  bool _instagramAvailable = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bootstrapLinks();
  }

  Future<void> _bootstrapLinks() async {
    final cached = await SocialLinksPublicService.instance.loadCachedOrDefaults();
    if (!mounted) return;
    setState(() => _links = cached);
    await _loadAvailability();

    final fresh =
        await SocialLinksPublicService.instance.fetchAndRefreshCache();
    if (!mounted || fresh == null) return;
    setState(() => _links = fresh);
    await _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final telegram = await SocialRewardsService.canClaim(SocialPlatform.telegram);
    final youtube = await SocialRewardsService.canClaim(SocialPlatform.youtube);
    final instagram = await SocialRewardsService.canClaim(SocialPlatform.instagram);

    if (!mounted) return;
    setState(() {
      _telegramAvailable = telegram;
      _youtubeAvailable = youtube;
      _instagramAvailable = instagram;
    });
  }

  Future<void> _handleTap(
    BuildContext context, {
    required SocialPlatform platform,
    required String url,
    required String name,
  }) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $name link'),
            backgroundColor: Colors.red,
          ),
        );
      }

      final result = await SocialRewardsService.claimReward(platform);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'You earned 10 coins!'),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        final message = result['message'] as String? ?? 'Unable to add coins';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await _loadAvailability();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_links.isActive || !_links.hasAnyLink) {
      return const SizedBox.shrink();
    }

    final tgUrl = _links.telegramLink.trim();
    final ytUrl = _links.youtubeLink.trim();
    final igUrl = _links.instagramLink.trim();

    final children = <Widget>[
      if (tgUrl.isNotEmpty)
        _buildSocialButton(
          context,
          icon: Icons.send_rounded,
          color: const Color(0xFF29B6F6),
          label: 'Telegram',
          coinsLabel: _telegramAvailable ? '+10 Coins' : 'Claimed',
          enabled: _telegramAvailable && tgUrl.isNotEmpty,
          onTap: () => _handleTap(
            context,
            platform: SocialPlatform.telegram,
            url: tgUrl,
            name: 'Telegram',
          ),
        ),
      if (ytUrl.isNotEmpty)
        _buildSocialButton(
          context,
          icon: Icons.play_circle_fill_rounded,
          color: const Color(0xFFFF5252),
          label: 'YouTube',
          coinsLabel: _youtubeAvailable ? '+10 Coins' : 'Claimed',
          enabled: _youtubeAvailable && ytUrl.isNotEmpty,
          onTap: () => _handleTap(
            context,
            platform: SocialPlatform.youtube,
            url: ytUrl,
            name: 'YouTube',
          ),
        ),
      if (igUrl.isNotEmpty)
        _buildSocialButton(
          context,
          icon: Icons.camera_alt_rounded,
          color: const Color(0xFFFFA726),
          label: 'Instagram',
          coinsLabel: _instagramAvailable ? '+10 Coins' : 'Claimed',
          enabled: _instagramAvailable && igUrl.isNotEmpty,
          onTap: () => _handleTap(
            context,
            platform: SocialPlatform.instagram,
            url: igUrl,
            name: 'Instagram',
          ),
        ),
    ];

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF141426),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String coinsLabel,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final textColor = enabled ? Colors.white : Colors.grey.shade500;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: enabled ? color.withOpacity(0.15) : const Color(0xFF1E1E30),
              shape: BoxShape.circle,
            ),
            child: _buildPlatformIcon(
              icon: icon,
              label: label,
              color: color,
              enabled: enabled,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                coinsLabel,
                style: TextStyle(
                  color: enabled ? AppColors.yellow : Colors.grey.shade600,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformIcon({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
  }) {
    // Custom YouTube-style icon
    if (label == 'YouTube') {
      final bgColor =
          enabled ? const Color(0xFFFF0000) : Colors.grey.shade700;
      return Center(
        child: Container(
          width: 20,
          height: 14,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            size: 14,
            color: Colors.white,
          ),
        ),
      );
    }

    // Custom Instagram-style icon
    if (label == 'Instagram') {
      final gradient = LinearGradient(
        colors: const [
          Color(0xFFF58529),
          Color(0xFFDD2A7B),
          Color(0xFF8134AF),
          Color(0xFF515BD4),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

      return Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: enabled ? gradient : null,
            color: enabled ? null : Colors.grey.shade700,
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Center(
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Default circular icon (used for Telegram)
    return Icon(
      icon,
      size: 18,
      color: enabled ? color : Colors.grey.shade600,
    );
  }
}
