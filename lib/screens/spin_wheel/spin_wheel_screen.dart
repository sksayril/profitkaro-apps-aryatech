import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _coinController;
  late Animation<double> _rotationAnimation;
  Animation<double>? _coinAnimation;
  bool _isSpinning = false;
  double _currentRotation = 0;
  int _coins = 0;
  bool _isLoadingCoins = true;
  
  final List<WheelSegment> _segments = [
    WheelSegment(value: '10', coins: 10, color: const Color(0xFF2196F3), text: '10 Coins'),
    WheelSegment(value: '50', coins: 50, color: const Color(0xFF9C27B0), text: '50 Coins'),
    WheelSegment(value: '100', coins: 100, color: const Color(0xFFFF9800), text: '100 Coins'),
    WheelSegment(value: 'Next Time', coins: 0, color: const Color(0xFFE91E63), text: 'Next Time'),
    WheelSegment(value: '10', coins: 10, color: const Color(0xFF4CAF50), text: '10 Coins'),
    WheelSegment(value: '50', coins: 50, color: const Color(0xFF00BCD4), text: '50 Coins'),
    WheelSegment(value: '100', coins: 100, color: const Color(0xFFFF5722), text: '100 Coins'),
    WheelSegment(value: 'Next Time', coins: 0, color: const Color(0xFF9E9E9E), text: 'Next Time'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );
    
    _coinAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _coinController, curve: Curves.linear),
    );
    
    _controller.addListener(() {
      setState(() {});
    });
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
        });
        _coinController.stop();
        _showResult();
      }
    });
    
    _fetchWalletBalance();
  }

  @override
  void dispose() {
    _controller.dispose();
    _coinController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletBalance() async {
    setState(() {
      _isLoadingCoins = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingCoins = false;
        });
        return;
      }

      final result = await ApiService.getWalletBalance(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          final coinsValue = data['Coins'];
          if (coinsValue is int) {
            _coins = coinsValue;
          } else if (coinsValue is double) {
            _coins = coinsValue.toInt();
          } else if (coinsValue is String) {
            _coins = int.tryParse(coinsValue) ?? 0;
          } else {
            _coins = 0;
          }
          _isLoadingCoins = false;
        });
      } else {
        setState(() {
          _isLoadingCoins = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingCoins = false;
      });
    }
  }

  void _spinWheel() {
    if (_isSpinning) return;
    
    setState(() {
      _isSpinning = true;
    });
    
    // Start coin animation
    _coinController.repeat();
    
    // Random number of rotations (4-6 full rotations)
    final random = math.Random();
    final rotations = 4 + random.nextDouble() * 2;
    final targetRotation = rotations * 2 * math.pi;
    
    _currentRotation += targetRotation;
    
    _controller.reset();
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: targetRotation,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );
    
    _controller.forward();
  }

  Future<void> _addCoinsToWallet(int coins) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final result = await ApiService.addCoins(token: token, coins: coins);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          final currentCoins = data['currentCoins'];
          if (currentCoins is int) {
            _coins = currentCoins;
          } else if (currentCoins is double) {
            _coins = currentCoins.toInt();
          } else if (currentCoins is String) {
            _coins = int.tryParse(currentCoins) ?? _coins;
          }
        });
      }
    } catch (e) {
      // Handle error silently or show message
    }
  }

  void _showResult() {
    // Calculate which segment won based on rotation
    final normalizedRotation = _currentRotation % (2 * math.pi);
    final segmentAngle = (2 * math.pi) / _segments.length;
    final pointerAngle = 0.0; // Pointer is at top (0 degrees)
    
    // Find the segment that the pointer is pointing to
    int winningSegment = ((normalizedRotation + pointerAngle) / segmentAngle).floor() % _segments.length;
    final wonSegment = _segments[winningSegment];
    
    // Add coins if won
    if (wonSegment.coins > 0) {
      _addCoinsToWallet(wonSegment.coins);
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              wonSegment.coins > 0 ? Icons.celebration : Icons.sentiment_dissatisfied,
              color: wonSegment.coins > 0 ? AppColors.yellow : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              wonSegment.coins > 0 ? 'Congratulations!' : 'Better Luck Next Time!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (wonSegment.coins > 0) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: wonSegment.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: wonSegment.color,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You won ${wonSegment.coins} Coins!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Coins have been added to your wallet',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.grey,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Try again tomorrow!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchWalletBalance();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A0D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0D2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Spin & Win',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _coinController,
                  builder: (context, child) {
                    final angle = _coinAnimation?.value ?? 0.0;
                    return Transform.rotate(
                      angle: angle,
                      child: Icon(Icons.monetization_on, color: AppColors.yellow, size: 18),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _isLoadingCoins
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        '$_coins',
                        style: const TextStyle(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Daily Luck Draw Title
            const Text(
              'Daily Luck Draw',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Spin the wheel to win instant coins!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Spinning Wheel
            _buildSpinningWheel(),
            const SizedBox(height: 30),
            
            // Free Spins Section
            _buildFreeSpinsSection(),
            const SizedBox(height: 20),
            
            // Spin Button
            GestureDetector(
              onTap: _isSpinning ? null : _spinWheel,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isSpinning 
                        ? [Colors.grey.shade600, Colors.grey.shade700]
                        : [AppColors.green, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isSpinning ? null : [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSpinning) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        _isSpinning ? 'SPINNING...' : 'SPIN NOW',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Watch Ad Option
            Text(
              'Watch an ad for 2 extra spins',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSpinningWheel() {
    final wheelSize = MediaQuery.of(context).size.width * 0.85;
    
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Pointer at top with glow effect
        Positioned(
          top: -10,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              width: 0,
              height: 0,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.transparent, width: 20),
                  right: BorderSide(color: Colors.transparent, width: 20),
                  top: BorderSide(color: Colors.white, width: 25),
                ),
              ),
            ),
          ),
        ),
        // Wheel with glow effect
        Container(
          width: wheelSize,
          height: wheelSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Transform.rotate(
            angle: _currentRotation + (_rotationAnimation.value * (2 * math.pi)),
            child: Container(
              width: wheelSize,
              height: wheelSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 4,
                ),
              ),
              child: CustomPaint(
                painter: WheelPainter(_segments),
              ),
            ),
          ),
        ),
        // Center Button with glow
        Positioned(
          top: wheelSize / 2 - 35,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: GestureDetector(
              onTap: _isSpinning ? null : _spinWheel,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFreeSpinsSection() {
    const freeSpins = 3;
    const totalSpins = 10;
    final progress = freeSpins / totalSpins;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.refresh, color: AppColors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Free Spins Left',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$freeSpins/$totalSpins',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY LIMIT',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'NEXT SPIN IN 2H 45M',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WheelSegment {
  final String value;
  final int coins;
  final Color color;
  final String text;

  WheelSegment({
    required this.value,
    required this.coins,
    required this.color,
    required this.text,
  });
}

class WheelPainter extends CustomPainter {
  final List<WheelSegment> segments;

  WheelPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;
      final endAngle = (i + 1) * segmentAngle - math.pi / 2;

      // Draw segment with gradient effect
      final paint = Paint()
        ..color = segments[i].color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Draw text (rotated to match segment)
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + math.pi / 2);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: segments[i].text,
          style: TextStyle(
            color: Colors.white,
            fontSize: segments[i].text.length > 8 ? 16 : 20,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          -textPainter.width / 2,
          -textPainter.height / 2,
        ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
