import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';

class NowPlayingScreen extends StatefulWidget {
  final String songTitle;
  final String artist;
  final int coins;

  const NowPlayingScreen({
    super.key,
    required this.songTitle,
    required this.artist,
    required this.coins,
  });

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  double _currentPosition = 84.0; // 1:24 out of 4:02
  double _totalDuration = 242.0; // 4:02 in seconds
  double _sessionProgress = 0.6; // 60% session progress
  double _earnedAmount = 2.40;
  int _nextPayoutSeconds = 45;
  
  late AnimationController _visualizerController;
  final List<double> _visualizerHeights = List.generate(20, (index) => 0);

  @override
  void initState() {
    super.initState();
    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();
    
    _visualizerController.addListener(() {
      setState(() {
        for (int i = 0; i < _visualizerHeights.length; i++) {
          _visualizerHeights[i] = math.Random().nextDouble() * 30 + 5;
        }
      });
    });
  }

  @override
  void dispose() {
    _visualizerController.dispose();
    super.dispose();
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Album Art with Progress Ring
                    _buildAlbumArtCard(),
                    const SizedBox(height: 24),
                    
                    // Song Information
                    _buildSongInfo(),
                    const SizedBox(height: 20),
                    
                    // Status Buttons
                    _buildStatusButtons(),
                    const SizedBox(height: 24),
                    
                    // Session Progress
                    _buildSessionProgress(),
                    const SizedBox(height: 30),
                    
                    // Music Player Controls
                    _buildPlayerControls(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Audio Visualizer
            _buildAudioVisualizer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROFIT KARO ACTIVE',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Text(
                  'Now Playing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                const Text(
                  '₹124.50',
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
    );
  }

  Widget _buildAlbumArtCard() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Progress Ring
        SizedBox(
          width: 280,
          height: 280,
          child: CircularProgressIndicator(
            value: _sessionProgress,
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
          ),
        ),
        
        // Album Art Card
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            color: const Color(0xFFF5E6D3), // Beige color
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Album Art
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CustomPaint(
                    painter: AlbumArtPainter(),
                  ),
                ),
              ),
              
              // Earning Badge
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.attach_money, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '+0.05',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSongInfo() {
    return Column(
      children: [
        Text(
          widget.songTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.artist} • Lofi Remix',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusButton(
            icon: Icons.volume_up,
            label: 'Volume OK',
            color: AppColors.green,
          ),
          _buildStatusButton(
            icon: Icons.lock_open,
            label: 'Unlocked',
            color: AppColors.green,
          ),
          _buildStatusButton(
            icon: Icons.visibility,
            label: 'In Focus',
            color: AppColors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Session Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₹$_earnedAmount Earned',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _sessionProgress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep app open to continue earning. Next payout in ${_nextPayoutSeconds}s.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Progress Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(_currentPosition),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _currentPosition,
                  min: 0,
                  max: _totalDuration,
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey.shade800,
                  onChanged: (value) {
                    setState(() {
                      _currentPosition = value;
                    });
                  },
                ),
              ),
              Text(
                _formatTime(_totalDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.shuffle, color: Colors.grey.shade400, size: 24),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.skip_previous, color: Colors.grey.shade400, size: 28),
                onPressed: () {},
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.skip_next, color: Colors.grey.shade400, size: 28),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.favorite, color: AppColors.green, size: 24),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioVisualizer() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          20,
          (index) => Container(
            width: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: _visualizerHeights[index],
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class AlbumArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw semi-circle (sun/moon)
    paint.color = const Color(0xFF90EE90);
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.2, size.width * 0.4, size.height * 0.4),
      math.pi,
      math.pi,
      false,
      paint,
    );
    
    // Draw landscape (undulating shape)
    paint.color = const Color(0xFFF5E6D3);
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.6,
      size.width * 0.5,
      size.height * 0.65,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.65,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
