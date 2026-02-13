import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'music_rules_screen.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['Short Songs', 'High Reward', 'New', 'Popular'];

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
          'Available Songs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.green, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '\$',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '1,250',
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
          _buildFilterTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                SongCard(
                  title: 'Tum Tum',
                  artist: 'Sri Vardhini',
                  duration: '30s',
                  coins: 50,
                  imageColor: const Color(0xFFE57373),
                  isLocked: false,
                  onPlay: () => _navigateToRules(context, 'Tum Tum', 'Sri Vardhini', 50),
                ),
                const SizedBox(height: 12),
                SongCard(
                  title: 'Kesariya',
                  artist: 'Arijit Singh',
                  duration: '60s',
                  coins: 100,
                  imageColor: const Color(0xFF5D4037),
                  isLocked: false,
                  onPlay: () => _navigateToRules(context, 'Kesariya', 'Arijit Singh', 100),
                ),
                const SizedBox(height: 12),
                SongCard(
                  title: 'Pasoori',
                  artist: 'Ali Sethi',
                  duration: '30s',
                  coins: 50,
                  imageColor: const Color(0xFFF5E6D3),
                  isLocked: false,
                  onPlay: () => _navigateToRules(context, 'Pasoori', 'Ali Sethi', 50),
                ),
                const SizedBox(height: 12),
                SongCard(
                  title: 'Excuses',
                  artist: 'AP Dhillon',
                  duration: '45s',
                  coins: 75,
                  imageColor: const Color(0xFF8D6E63),
                  isLocked: false,
                  onPlay: () => _navigateToRules(context, 'Excuses', 'AP Dhillon', 75),
                ),
                const SizedBox(height: 12),
                SongCard(
                  title: 'Premium Track',
                  artist: 'Unlock at Level 5',
                  duration: '',
                  coins: 250,
                  imageColor: const Color(0xFF424242),
                  isLocked: true,
                  onPlay: null,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRules(BuildContext context, String title, String artist, int coins) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicRulesScreen(
          songTitle: title,
          artist: artist,
          coins: coins,
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedFilter == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.green : AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.green : AppColors.border(context),
                  width: 1,
                ),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SongCard extends StatelessWidget {
  final String title;
  final String artist;
  final String duration;
  final int coins;
  final Color imageColor;
  final bool isLocked;
  final VoidCallback? onPlay;

  const SongCard({
    super.key,
    required this.title,
    required this.artist,
    required this.duration,
    required this.coins,
    required this.imageColor,
    required this.isLocked,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: imageColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLocked
                ? const Icon(Icons.lock, color: Colors.grey, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isLocked ? Colors.grey : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration.isNotEmpty ? '$artist • $duration' : artist,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.add_circle,
                      color: isLocked ? Colors.grey : AppColors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'EARN $coins COINS',
                      style: TextStyle(
                        color: isLocked ? Colors.grey : AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isLocked ? null : onPlay,
            child: !isLocked
                ? Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
