import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/services/task_completion_ads_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class ScratchCardDailyLimitScreen extends StatefulWidget {
  const ScratchCardDailyLimitScreen({super.key});

  @override
  State<ScratchCardDailyLimitScreen> createState() => _ScratchCardDailyLimitScreenState();
}

class _ScratchCardDailyLimitScreenState extends State<ScratchCardDailyLimitScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isClaiming = false;
  bool _isScratched = false;
  bool _isClaimed = false;
  List<List<Offset>> _scratchPaths = [];
  final GlobalKey _scratchKey = GlobalKey();
  
  // Animation
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // API data
  bool _isActive = false;
  int _dailyLimit = 0;
  double _rewardAmount = 0.0;
  int _rewardCoins = 0;
  int _claimsToday = 0;
  int _remainingClaims = 0;
  bool _canClaim = false;

  // Reward revealed
  double? _revealedAmount;
  int? _revealedCoins;

  @override
  void initState() {
    super.initState();
    _fetchDailyLimit();
    
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _fetchDailyLimit() async {
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

      final result = await ApiService.getScratchCardDailyLimit(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          _isActive = data['isActive'] ?? false;
          _dailyLimit = data['dailyLimit'] ?? 0;
          _rewardAmount = (data['rewardAmount'] ?? 0.0).toDouble();
          _rewardCoins = data['rewardCoins'] ?? 0;
          _claimsToday = data['claimsToday'] ?? 0;
          _remainingClaims = data['remainingClaims'] ?? 0;
          _canClaim = data['canClaim'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch scratch card info'),
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
    if (_isClaimed || _isClaiming || !_canClaim) return;
    _processClaim();
  }

  Future<void> _processClaim() async {
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

      final result = await ApiService.claimScratchCardDailyLimit(token: token);

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        final amountRevealed = data['amountAdded']?.toDouble() ?? _rewardAmount;
        final coinsRevealed = data['coinsAdded'] ?? _rewardCoins;
        
        setState(() {
          _isClaimed = true;
          _isClaiming = false;
          _claimsToday = data['claimsToday'] ?? _claimsToday;
          _remainingClaims = data['remainingClaims'] ?? _remainingClaims;
          _revealedAmount = amountRevealed;
          _revealedCoins = coinsRevealed;
        });
        
        if (mounted) {
          TaskCompletionAdsService.instance.runAfterTaskCompleted(
            () {
              if (!mounted) return;
              _showRewardPopup(amountRevealed, coinsRevealed);
            },
            taskType: 'ScratchCardDailyLimit',
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

  void _showRewardPopup(double amount, int coins) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E30),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA000).withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: Color(0xFFFFA000), size: 80),
              const SizedBox(height: 20),
              const Text(
                'CONGRATULATIONS!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You have successfully claimed your reward',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA000), Color(0xFFFFD54F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFA000).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.monetization_on, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '+$coins',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Coins Added',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (amount > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '+₹${amount.toStringAsFixed(2)} Added to Wallet',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetForNextCard();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text('Add Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForNextCard() {
    if (!mounted) return;
    
    setState(() {
      _isScratched = false;
      _isClaimed = false;
      _isClaiming = false;
      _scratchPaths.clear();
      _revealedAmount = null;
      _revealedCoins = null;
      _flipController.reset();
    });
    
    _fetchDailyLimit();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isClaimed || _isScratched || !_canClaim) return;
    
    final RenderBox? renderBox = _scratchKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _scratchPaths.add([localPosition]);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isClaimed || _isScratched || !_canClaim || _scratchPaths.isEmpty) return;

    final RenderBox? renderBox = _scratchKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;

    if (localPosition.dx < 0 || localPosition.dx > size.width || localPosition.dy < 0 || localPosition.dy > size.height) {
      return;
    }

    setState(() {
      _scratchPaths.last.add(localPosition);

      // Simple scratched area estimation
      // Each path point plus a radius estimate
      int pointsCount = 0;
      for (var path in _scratchPaths) {
        pointsCount += path.length;
      }
      
      // Threshold for reveal (~150 points for a significant scratch)
      if (pointsCount > 150 && !_isScratched) {
        _isScratched = true;
        _revealedAmount = _rewardAmount;
        _revealedCoins = _rewardCoins;
        _flipController.forward();
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
          'Scratch & Win Coins',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Try your luck! Scratch the card and get instant coins.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Daily Scratch Limit : $_claimsToday/$_dailyLimit Used',
                        style: const TextStyle(
                          color: Color(0xFF42A5F5),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildScratchCard(),
                    const SizedBox(height: 40),
                    if (_isScratched && !_isClaimed && _canClaim)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isClaiming ? null : _claimReward,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _isClaiming
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Claim Reward', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    if (_isClaimed)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Reward Claimed!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    if (!_canClaim && !_isLoading)
                      Text(
                        _remainingClaims == 0 ? 'Daily limit reached. Come back tomorrow!' : 'Scratch card feature is currently unavailable.',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildScratchCard() {
    return Center(
      child: Container(
        key: _scratchKey,
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          child: Stack(
            children: [
              // Reward Content (Background)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    children: [
                      CustomPaint(size: Size.infinite, painter: _RadialRaysPainter()),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isScratched || _isClaimed) ...[
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFA000), Color(0xFFFFD54F)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.monetization_on, color: Colors.white, size: 80),
                              ),
                              const SizedBox(height: 20),
                              const Text('You Received', style: TextStyle(color: Colors.white70, fontSize: 16)),
                              const SizedBox(height: 8),
                              if (_revealedCoins != null)
                                Text(
                                  '${_revealedCoins} Coins',
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                            ] else ...[
                              Icon(Icons.card_giftcard, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Scratch Layer
              if (!_isScratched && !_isClaimed && _canClaim)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: CustomPaint(
                      painter: _ScratchLayerPainter(_scratchPaths),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadialRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    
    const int raysCount = 12;
    final double rayAngle = (2 * math.pi) / raysCount;
    
    for (int i = 0; i < raysCount; i++) {
        final path = Path();
        path.moveTo(center.dx, center.dy);
        path.lineTo(
          center.dx + 500 * math.cos(i * rayAngle - rayAngle / 4),
          center.dy + 500 * math.sin(i * rayAngle - rayAngle / 4),
        );
        path.lineTo(
          center.dx + 500 * math.cos(i * rayAngle + rayAngle / 4),
          center.dy + 500 * math.sin(i * rayAngle + rayAngle / 4),
        );
        path.close();
        canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScratchLayerPainter extends CustomPainter {
  final List<List<Offset>> paths;
  _ScratchLayerPainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 1. Cover
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 2. Dots pattern
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.1);
    for (double i = 0; i < size.width; i += 20) {
      for (double j = 0; j < size.height; j += 20) {
        canvas.drawCircle(Offset(i, j), 1.5, dotPaint);
      }
    }

    // 3. Instruction Text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Scratch Here',
        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, size.height / 2 - 20));

    // 4. Eraser (Paths)
    final eraser = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeWidth = 60
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var pathPoints in paths) {
      if (pathPoints.length > 1) {
        final path = Path();
        path.moveTo(pathPoints[0].dx, pathPoints[0].dy);
        for (int i = 1; i < pathPoints.length; i++) {
          path.lineTo(pathPoints[i].dx, pathPoints[i].dy);
        }
        canvas.drawPath(path, eraser);
      } else if (pathPoints.isNotEmpty) {
        canvas.drawCircle(pathPoints[0], 30, eraser);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScratchLayerPainter oldDelegate) => true;
}

