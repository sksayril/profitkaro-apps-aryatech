import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'now_playing_screen.dart';

class MusicRulesScreen extends StatelessWidget {
  final String songTitle;
  final String artist;
  final int coins;

  const MusicRulesScreen({
    super.key,
    required this.songTitle,
    required this.artist,
    required this.coins,
  });

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
          'Music Earning Rules',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headphones image
                  _buildHeadphonesImage(context),
                  
                  // How to Earn Rewards
                  _buildHowToEarnSection(),
                  
                  // Core Rules
                  _buildCoreRulesSection(),
                  
                  // Why these rules
                  _buildWhyTheseRulesSection(context),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // Bottom button
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildHeadphonesImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Green glow effect
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withOpacity(0.3),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          // Headphones icon
          Icon(
            Icons.headphones,
            size: 100,
            color: Colors.grey.shade700,
          ),
          // Green accent lines
          Positioned(
            left: 80,
            child: Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 80,
            child: Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToEarnSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to Earn Rewards',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow these simple rules to ensure your earnings are credited instantly to your Profit Karo wallet.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreRulesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Core Rules',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'REQUIREMENT CHECKLIST',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          
          // Rule items
          _buildRuleItem(
            icon: Icons.timer,
            iconColor: AppColors.green,
            title: 'Min listening time',
            description: 'Listen for at least 30 seconds per track to qualify.',
            isRequired: true,
          ),
          const SizedBox(height: 16),
          
          _buildRuleItem(
            icon: Icons.smartphone,
            iconColor: AppColors.green,
            title: 'Screen must be ON',
            description: 'Keep the app visible while the music is playing.',
            isRequired: true,
          ),
          const SizedBox(height: 16),
          
          _buildRuleItem(
            icon: Icons.volume_up,
            iconColor: AppColors.green,
            title: 'Volume Requirement',
            description: 'Volume must be above 10% to track playback.',
            isRequired: true,
          ),
          const SizedBox(height: 16),
          
          _buildRuleItem(
            icon: Icons.block,
            iconColor: Colors.red,
            title: 'No Fake Listening',
            description: 'Scripts, bots, or VPNs will result in instant ban.',
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isRequired,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        
        // Text content
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
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        
        // Status indicator
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isRequired ? AppColors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildWhyTheseRulesSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.green,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why these rules?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Transparency is our priority. These metrics help us prove genuine listening to our music partners, ensuring we can keep paying high rewards to our honest community members.',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        border: Border(
          top: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to Now Playing screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NowPlayingScreen(
                    songTitle: songTitle,
                    artist: artist,
                    coins: coins,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'I Understand, Start Listening',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
