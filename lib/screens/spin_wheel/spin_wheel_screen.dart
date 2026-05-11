import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/services/task_completion_ads_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/coin_reward_popup.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _isSpinning = false;
  double _currentRotation = 0;
  int _winningIndex = 0;

  double _walletBalance = 0.0;
  bool _isBalanceLoading = true;
  
  // Daily Spin State
  int _dailySpinLimit = 10;
  int _spinsUsedToday = 0;
  int _spinsRemainingToday = 0;
  int _totalSpins = 0;
  bool _isStatusLoading = true;
  
  int _spinCount = 0;
  
  final List<WheelSegment> _segments = [
    WheelSegment(value: '5', color: const Color(0xFF81C784), text: '5 Coins'), // Light Green
    WheelSegment(value: '6', color: const Color(0xFFE57373), text: '6 Coins'), // Soft Red
    WheelSegment(value: '7', color: const Color(0xFFFFD54F), text: '7 Coins'), // Amber/Yellow
    WheelSegment(value: '8', color: const Color(0xFF66BB6A), text: '8 Coins'), // Green
    WheelSegment(value: '9', color: const Color(0xFF29B6F6), text: '9 Coins'), // Light Blue
    WheelSegment(value: '10', color: const Color(0xFFBA68C8), text: '10 Coins'), // Purple
    WheelSegment(value: '5', color: const Color(0xFFFFB74D), text: '5 Coins'), // Orange/Yellow
    WheelSegment(value: '6', color: const Color(0xFF4FC3F7), text: '6 Coins'), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );
    
    _controller.addListener(() {
      setState(() {});
    });
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
        });
        _showResult();
      }
    });

    _loadSpinCount();
    _fetchWalletBalance();
    _fetchDailySpinStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSpinCount() async {
    final count = await StorageService.getInt('spin_wheel_count');
    setState(() {
      _spinCount = count ?? 0;
    });
  }

  Future<void> _saveSpinCount(int count) async {
    await StorageService.saveInt('spin_wheel_count', count);
    setState(() {
      _spinCount = count;
    });
  }

  String _formatCurrency(double amount) {
    // Format as coins instead of currency
    return '${amount.toInt()} Coins';
  }

  Future<void> _fetchWalletBalance() async {
    if (!mounted) return;
    setState(() => _isBalanceLoading = true);

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() => _isBalanceLoading = false);
        return;
      }

      final result = await ApiService.getWalletBalance(token: token);

      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];

        final balanceValue = data['WalletBalance'];
        double parsedBalance = 0.0;
        if (balanceValue is double) {
          parsedBalance = balanceValue;
        } else if (balanceValue is int) {
          parsedBalance = balanceValue.toDouble();
        } else if (balanceValue is String) {
          parsedBalance = double.tryParse(balanceValue) ?? 0.0;
        }

        setState(() {
          _walletBalance = parsedBalance;
          _isBalanceLoading = false;
        });
      } else {
        setState(() => _isBalanceLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isBalanceLoading = false);
    }
  }
  Future<void> _fetchDailySpinStatus() async {
    if (!mounted) return;
    setState(() => _isStatusLoading = true);

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() => _isStatusLoading = false);
        return;
      }

      final result = await ApiService.getDailySpinStatus(token: token);

      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        setState(() {
          _dailySpinLimit = data['dailySpinLimit'] ?? 10;
          _spinsUsedToday = data['spinsUsedToday'] ?? 0;
          _spinsRemainingToday = data['spinsRemainingToday'] ?? 0;
          _totalSpins = data['totalSpins'] ?? 0;
          _isStatusLoading = false;
        });
      } else {
        setState(() => _isStatusLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isStatusLoading = false);
    }
  }

  Future<void> _recordSpinUsage() async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) return;

      final result = await ApiService.useDailySpin(token: token, spinCount: 1);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        setState(() {
          _dailySpinLimit = data['dailySpinLimit'] ?? _dailySpinLimit;
          _spinsUsedToday = data['spinsUsedToday'] ?? _spinsUsedToday;
          _spinsRemainingToday = data['spinsRemainingToday'] ?? _spinsRemainingToday;
          _totalSpins = data['totalSpins'] ?? _totalSpins;
        });
      }
    } catch (e) {
      debugPrint('Error recording spin usage: $e');
    }
  }

  void _spinWheel() async {
    if (_isSpinning) return;
    
    // Check if spins are remaining
    if (_spinsRemainingToday <= 0 && !_isStatusLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily spin limit reached! Watch an ad or come back tomorrow.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // No ads before spinning - ads will show when "Add Wallet" button is clicked
    // Directly perform spin
    _performSpin();
  }

  void _performSpin() {
    final random = math.Random();
    // 1. Pre-determine winning segment
    _winningIndex = random.nextInt(_segments.length);
    
    final segmentAngle = (2 * math.pi) / _segments.length;
    
    // 2. Calculate the specific angle needed to bring _winningIndex to the top.
    // The top pointer is at -pi/2 in the painter's coordinate system.
    // Target rotation (R) should satisfy: (winningIndex + 0.5) * step + R = 0 (mod 2*pi)
    double currentMod = _currentRotation % (2 * math.pi);
    double targetMod = (2 * math.pi - (_winningIndex + 0.5) * segmentAngle);
    
    // Add random variation within the segment (30% to 70% of segment width)
    double randomOffset = (random.nextDouble() - 0.5) * (segmentAngle * 0.4);
    targetMod += randomOffset;
    
    double diff = targetMod - currentMod;
    if (diff <= 0) diff += 2 * math.pi;
    
    // Total spin: 5 full rotations + the difference to target
    double totalSpinAngle = (5 * 2 * math.pi) + diff;
    
    double startAngle = _currentRotation;
    double endAngle = _currentRotation + totalSpinAngle;

    setState(() {
      _isSpinning = true;
    });
    
    _controller.reset();
    _rotationAnimation = Tween<double>(
      begin: startAngle,
      end: endAngle,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCirc),
    );
    
    _currentRotation = endAngle; // Prepare for next spin base
    _controller.forward();
    
    // Call the API to record usage immediately when spin starts
    
    // Increment spin count after starting spin
    final newCount = _spinCount + 1;
    _saveSpinCount(newCount);
    
    // Record spin usage
    _recordSpinUsage();
  }

  void _showResult() async {
    // winningIndex is already determined when the spin starts
    int winningSegmentIndex = _winningIndex;
    final winningValueStr = _segments[winningSegmentIndex].value;
    final winningAmount = int.tryParse(winningValueStr) ?? 0;

    if (winningAmount > 0) {
      try {
        final token = await StorageService.getToken();
        if (token != null && token.isNotEmpty) {
          // Call addCoins API instead of addWallet
          final result = await ApiService.addCoins(token: token, coins: winningAmount);
          if (result['success'] == true && result['data'] != null) {
            // Refresh wallet balance after adding coins
            _fetchWalletBalance();
          } else {
            // Show error message if API call failed
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Failed to add coins'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error adding coins: $e');
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
    
    if (!mounted) return;

    TaskCompletionAdsService.instance.runAfterTaskCompleted(
      () {
        if (!mounted) return;
        _showCoinRewardPopup(winningAmount);
      },
      taskType: 'DailySpin',
    );
  }

  void _showCoinRewardPopup(int coins) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CoinRewardPopup(coins: coins);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7E34D9), // Vibrant purple background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF7E34D9),
              const Color(0xFF5E27A1),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background patterns
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: List.generate(
                      10,
                      (i) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          10,
                          (j) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Icon(
                              (i + j) % 3 == 0
                                  ? Icons.videogame_asset
                                  : (i + j) % 3 == 1
                                      ? Icons.sports_esports
                                      : Icons.gamepad,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildCustomAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Spin the wheel to win instant coins!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          
                          // Spinning Wheel
                          _buildSpinningWheel(),
                          const SizedBox(height: 40),
                          
                          // Free Spins Section
                          _buildFreeSpinsSection(),
                          const SizedBox(height: 20),
                          
                          // Spin Button
                          _buildSpinButton(),
                          const SizedBox(height: 16),
                          
                          // Watch Ad Option
                          _buildWatchAdText(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Spin & Win',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          _buildBalanceIndicator(),
        ],
      ),
    );
  }

  Widget _buildBalanceIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: _isBalanceLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  _formatCurrency(_walletBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSpinButton() {
    return GestureDetector(
      onTap: _isSpinning ? null : _spinWheel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            _isSpinning ? 'SPINNING...' : 'SPIN NOW',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchAdText() {
    return Text(
      'Watch an ad for 2 extra spins',
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSpinningWheel() {
    final wheelSize = MediaQuery.of(context).size.width * 0.85;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Wheel
        Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: wheelSize,
            height: wheelSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  offset: const Offset(0, 10),
                  blurRadius: 20,
                ),
              ],
            ),
            child: CustomPaint(
              painter: WheelPainter(_segments),
            ),
          ),
        ),
        
        // Outer White Ring (Non-rotating)
        Container(
          width: wheelSize + 10,
          height: wheelSize + 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
        ),
        
        // Center Button & Pointer
        GestureDetector(
          onTap: _isSpinning ? null : _spinWheel,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pointer Triangle (White)
              Transform.translate(
                offset: const Offset(0, -45),
                child: CustomPaint(
                  size: const Size(30, 40),
                  painter: TrianglePainter(color: Colors.white),
                ),
              ),
              // Center Circular Button
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'start',
                    style: TextStyle(
                      color: Color(0xFFE57373),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Hand Icon
        if (!_isSpinning)
          Positioned(
            right: wheelSize / 2 - 80,
            bottom: wheelSize / 2 - 80,
            child: Transform.rotate(
              angle: -0.5,
              child: const Icon(
                Icons.touch_app,
                color: Colors.white,
                size: 50,
                shadows: [
                  Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFreeSpinsSection() {
    final progress = _dailySpinLimit > 0 ? (_spinsRemainingToday / _dailySpinLimit) : 0.0;
    
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          // Decorative Image
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/500notes.png',
                width: 100,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.refresh, color: Color(0xFF81C784), size: 20),
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
                    _isStatusLoading 
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white54)))
                      : Text(
                          '$_spinsRemainingToday/$_dailySpinLimit',
                          style: const TextStyle(
                            color: Color(0xFF81C784),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF81C784)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LIFETIME SPINS: $_totalSpins',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      'REFRESHES DAILY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color;
    var path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WheelSegment {
  final String value;
  final Color color;
  final String text;

  WheelSegment({
    required this.value,
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

      // Draw segment
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
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Draw text (rotated to match segment)
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.7; // Moved text further out
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + math.pi / 2); // Rotate text to match segment
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: segments[i].text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20, // Slightly smaller font to fit 8 segments better
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2),
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
