import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> {
  bool _isLoading = true;
  bool _isClaiming = false;
  bool _isScratched = false;
  bool _isClaimed = false;
  String? _currentDay;
  int? _todayAmount;
  String? _rewardType;
  Map<String, dynamic>? _allDays;
  Set<Offset> _scratchedPoints = {};
  final GlobalKey _scratchKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchScratchCard();
  }

  Future<void> _fetchScratchCard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await ApiService.getScratchCard(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          _currentDay = data['currentDay'] ?? '';
          // Handle todayAmount - can be int or double
          final todayAmountValue = data['todayAmount'];
          if (todayAmountValue is int) {
            _todayAmount = todayAmountValue;
          } else if (todayAmountValue is double) {
            _todayAmount = todayAmountValue.toInt();
          } else {
            _todayAmount = 0;
          }
          _rewardType = data['rewardType'] ?? 'Coins';
          _isClaimed = data['isClaimed'] ?? false;
          _isScratched = _isClaimed; // If already claimed, show as scratched
          _allDays = data['allDays'] ?? {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch scratch card'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _claimReward() async {
    if (_isClaimed || _isClaiming) return;

    setState(() {
      _isClaiming = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isClaiming = false;
        });
        return;
      }

      final result = await ApiService.claimScratchCard(token: token);

      if (result['success'] && result['data'] != null) {
        setState(() {
          _isClaimed = true;
          _isClaiming = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Reward claimed successfully!'),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _isClaiming = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to claim reward'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isClaiming = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isClaimed || _isScratched) return;

    final RenderBox? renderBox = _scratchKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;

    if (localPosition.dx < 0 ||
        localPosition.dx > size.width ||
        localPosition.dy < 0 ||
        localPosition.dy > size.height) {
      return;
    }

    setState(() {
      // Add points in a radius around the touch point
      for (int dx = -15; dx <= 15; dx += 3) {
        for (int dy = -15; dy <= 15; dy += 3) {
          final point = Offset(
            (localPosition.dx + dx).clamp(0.0, size.width),
            (localPosition.dy + dy).clamp(0.0, size.height),
          );
          if ((point - localPosition).distance <= 15) {
            _scratchedPoints.add(point);
          }
        }
      }

      // Check if scratched area is significant (more than 30% of card)
      final totalArea = size.width * size.height;
      final scratchedArea = _scratchedPoints.length * 9; // Approximate area per point
      if (scratchedArea / totalArea > 0.3) {
        _isScratched = true;
      }
    });
  }

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
          'Scratch & Win',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to history screen
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Current Day Info
                    if (_currentDay != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Today: $_currentDay',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 30),

                    // Scratch Card
                    _buildScratchCard(),

                    const SizedBox(height: 30),

                    // Claim Button
                    if (_isScratched && !_isClaimed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isClaiming ? null : _claimReward,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37), // Gold
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isClaiming
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Claim Reward',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                    if (_isClaimed)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.green,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reward Claimed!',
                              style: const TextStyle(
                                color: AppColors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Weekly Rewards Preview
                    if (_allDays != null) _buildWeeklyPreview(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildScratchCard() {
    return Container(
      key: _scratchKey,
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
            blurRadius: 25,
            spreadRadius: 3,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        child: Stack(
          children: [
            // Reward Content (Background) - Purple with Golden accents
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF9C27B0), // Purple
                    const Color(0xFF7B1FA2), // Darker purple
                    const Color(0xFF6A1B9A), // Deep purple
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CustomPaint(
                  painter: _ScratchPainter(_scratchedPoints),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Stack(
                      children: [
                        // Sparkles and confetti
                        ..._buildSparkles(),
                        // Cloud-like shapes (white blobs)
                        ..._buildCloudShapes(),
                        // Main content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Gift Box Icon with Ring
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer ring
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                // Inner ring
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                // Gift icon
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.card_giftcard,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Cloud shapes around number
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Left cloud
                                Positioned(
                                  left: 20,
                                  child: _buildCloudBlob(80, 40),
                                ),
                                // Right cloud
                                Positioned(
                                  right: 20,
                                  child: _buildCloudBlob(80, 40),
                                ),
                                // Number
                                Text(
                                  _isScratched || _isClaimed
                                      ? '${_todayAmount ?? 0}'
                                      : '???',
                                  style: TextStyle(
                                    fontSize: _isScratched || _isClaimed ? 64 : 48,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD4AF37), // Golden color
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                      Shadow(
                                        color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Coins text
                            Text(
                              _rewardType ?? 'Coins',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                  Shadow(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                            if (!_isScratched && !_isClaimed) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Scratch to reveal!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFFD4AF37),
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Scratch Layer (Foreground) - Golden/Purple gradient
            if (!_isScratched && !_isClaimed)
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CustomPaint(
                  painter: _ScratchLayerPainter(_scratchedPoints),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF7B1FA2),
                          const Color(0xFF6A1B9A),
                          const Color(0xFF4A148C),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Gift box icon on scratch layer
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.card_giftcard,
                                  size: 56,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Scratch Here',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD4AF37),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use your finger to scratch',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudBlob(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSparkles() {
    return [
      // Sparkles around gift icon
      Positioned(
        top: 50,
        left: 50,
        child: Icon(
          Icons.star,
          size: 12,
          color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
        ),
      ),
      Positioned(
        top: 70,
        right: 50,
        child: Icon(
          Icons.star,
          size: 10,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
      Positioned(
        top: 90,
        left: 80,
        child: Icon(
          Icons.star,
          size: 8,
          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
        ),
      ),
      Positioned(
        top: 110,
        right: 70,
        child: Icon(
          Icons.star,
          size: 14,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      // Sparkles around number
      Positioned(
        top: 200,
        left: 40,
        child: Icon(
          Icons.star,
          size: 10,
          color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
        ),
      ),
      Positioned(
        top: 220,
        right: 50,
        child: Icon(
          Icons.star,
          size: 12,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      Positioned(
        top: 240,
        left: 60,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: 250,
        right: 40,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: 50,
        child: Icon(
          Icons.star,
          size: 14,
          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
        ),
      ),
      Positioned(
        bottom: 120,
        right: 60,
        child: Icon(
          Icons.star,
          size: 10,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    ];
  }

  List<Widget> _buildCloudShapes() {
    return [
      // Cloud-like white blobs around the number area
      Positioned(
        top: 180,
        left: 30,
        child: _buildCloudBlob(60, 35),
      ),
      Positioned(
        top: 190,
        right: 30,
        child: _buildCloudBlob(60, 35),
      ),
      Positioned(
        top: 200,
        left: 50,
        child: _buildCloudBlob(50, 30),
      ),
      Positioned(
        top: 210,
        right: 50,
        child: _buildCloudBlob(50, 30),
      ),
    ];
  }

  Widget _buildWeeklyPreview() {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dayAbbr = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Rewards',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final day = days[index];
              final amount = _allDays![day] ?? 0;
              final isToday = day == _currentDay;
              final isClaimedToday = isToday && _isClaimed;

              return Column(
                children: [
                  Text(
                    dayAbbr[index],
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isToday
                          ? (isClaimedToday ? AppColors.green : const Color(0xFFD4AF37))
                          : AppColors.cardBackgroundLight(context),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(
                              color: isClaimedToday ? AppColors.green : const Color(0xFFD4AF37),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: isClaimedToday
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : Text(
                              '$amount',
                              style: TextStyle(
                                color: isToday ? Colors.white : Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// Custom painter for scratch layer
class _ScratchLayerPainter extends CustomPainter {
  final Set<Offset> scratchedPoints;

  _ScratchLayerPainter(this.scratchedPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    for (final point in scratchedPoints) {
      canvas.drawCircle(point, 20, paint);
    }
  }

  @override
  bool shouldRepaint(_ScratchLayerPainter oldDelegate) {
    return oldDelegate.scratchedPoints != scratchedPoints;
  }
}

// Custom painter for scratch effect
class _ScratchPainter extends CustomPainter {
  final Set<Offset> scratchedPoints;

  _ScratchPainter(this.scratchedPoints);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw scratched areas with a subtle effect
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    for (final point in scratchedPoints) {
      canvas.drawCircle(point, 20, paint);
    }
  }

  @override
  bool shouldRepaint(_ScratchPainter oldDelegate) {
    return oldDelegate.scratchedPoints != scratchedPoints;
  }
}

// Custom painter for confetti streamers
class _ConfettiStreamerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.3, size.width * 0.6, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.7, size.width, size.height);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConfettiStreamerPainter oldDelegate) => false;
}
