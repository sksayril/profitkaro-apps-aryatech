import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int _selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),
            
            // Live Activity Card
            _buildLiveActivityCard(),
            const SizedBox(height: 20),
            
            // Game Categories
            _buildGameCategories(),
            const SizedBox(height: 20),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hot Right Now
                    _buildHotRightNowSection(context),
                    const SizedBox(height: 24),
                    
                    // All Games
                    _buildAllGamesSection(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8C4A8),
                ),
                child: const Icon(Icons.person, color: Colors.grey, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Namaste, User',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.yellow,
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
                  '2,450',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveActivityCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A3D5A), Color(0xFF4A2A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bolt,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE ACTIVITY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '450 coins today',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You're in the top 10% of earners!",
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF5A4A7A),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.75,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Goal: 600 coins',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCategories() {
    final categories = [
      {'icon': Icons.auto_awesome, 'label': 'Boosted', 'color': Colors.brown},
      {'icon': Icons.sports_cricket, 'label': 'Cricket', 'color': Colors.green},
      {'icon': Icons.grid_view, 'label': 'Ludo', 'color': AppColors.primary},
      {'icon': Icons.map, 'label': 'Strategy', 'color': Colors.orange},
      {'icon': Icons.star, 'label': 'All', 'color': AppColors.yellow},
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          bool isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (category['color'] as Color).withOpacity(0.3)
                          : AppColors.cardBackground(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? category['color'] as Color
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: category['color'] as Color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHotRightNowSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text(
                  'Hot Right Now',
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
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildHotGameCard(
                context: context,
                title: 'Battle Royale Pro',
                genre: 'Action • Multiplayer',
                earning: '120/min',
                yield: '2x Yield',
                hasLive: true,
                imageColor: const Color(0xFF1A3D5A),
              ),
              const SizedBox(width: 12),
              _buildHotGameCard(
                context: context,
                title: '8 Ball',
                genre: 'Sports',
                earning: '80/min',
                yield: null,
                hasLive: false,
                imageColor: const Color(0xFF2A5A3A),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHotGameCard({
    required BuildContext context,
    required String title,
    required String genre,
    required String earning,
    String? yield,
    required bool hasLive,
    required Color imageColor,
  }) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Game image
          Stack(
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: imageColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.sports_esports,
                    size: 38,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
              if (hasLive)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (yield != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      yield,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.yellow,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '\$',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          earning,
                          style: const TextStyle(
                            color: AppColors.yellow,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'Play Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  Widget _buildAllGamesSection(BuildContext context) {
    final games = [
      {
        'title': 'Galaxy Shooter',
        'genre': 'Arcade',
        'earning': '40 coins/min',
        'tag': 'Easy',
        'tagColor': AppColors.green,
        'imageColor': const Color(0xFF6A2A8A),
      },
      {
        'title': 'Ludo Supreme',
        'genre': 'Board',
        'earning': '60 coins/min',
        'tag': null,
        'tagColor': null,
        'imageColor': const Color(0xFF8B6F47),
      },
      {
        'title': 'Speed Racer 3D',
        'genre': 'Racing',
        'earning': '90 coins/min',
        'tag': 'NEW',
        'tagColor': AppColors.yellow,
        'imageColor': const Color(0xFF4A90D9),
      },
      {
        'title': 'Rummy Circle',
        'genre': 'Card',
        'earning': '45 coins/min',
        'tag': null,
        'tagColor': null,
        'imageColor': const Color(0xFFE8C4A8),
      },
      {
        'title': 'Candy Crush Saga',
        'genre': 'Puzzle',
        'earning': '30 coins/min',
        'tag': null,
        'tagColor': null,
        'imageColor': const Color(0xFFFFB6C1),
      },
      {
        'title': 'FIFA Mobile',
        'genre': 'Sports',
        'earning': '55 coins/min',
        'tag': null,
        'tagColor': null,
        'imageColor': const Color(0xFF2A2A2A),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Games',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return _buildGameCard(
              context: context,
              title: game['title'] as String,
              genre: game['genre'] as String,
              earning: game['earning'] as String,
              tag: game['tag'] as String?,
              tagColor: game['tagColor'] as Color?,
              imageColor: game['imageColor'] as Color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required String genre,
    required String earning,
    String? tag,
    Color? tagColor,
    required Color imageColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game image
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: imageColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.sports_esports,
                      size: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
                if (tag != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Game info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        genre,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Earn $earning',
                        style: TextStyle(
                          color: AppColors.yellow,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Play',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
