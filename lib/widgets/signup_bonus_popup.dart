import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class SignupBonusPopup extends StatefulWidget {
  final double signupBonusAmount;
  final String rewardType;
  final String description;
  final VoidCallback onClose;
  final Function(double, int) onBonusAdded;

  const SignupBonusPopup({
    super.key,
    required this.signupBonusAmount,
    required this.rewardType,
    required this.description,
    required this.onClose,
    required this.onBonusAdded,
  });

  @override
  State<SignupBonusPopup> createState() => _SignupBonusPopupState();
}

class _SignupBonusPopupState extends State<SignupBonusPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  
  List<Particle> _particles = [];
  bool _showBonus = false;
  double _animatedAmount = 0.0;
  int _animatedCoins = 0;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    _startAnimations();
  }

  void _startAnimations() {
    _scaleController.forward();
    _glowController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
      setState(() {
        _showBonus = true;
      });
      _startParticleAnimation();
      _animateAmount();
    });
  }

  void _animateAmount() {
    final targetAmount = widget.signupBonusAmount;
    final targetCoins = widget.signupBonusAmount.toInt();
    final isCoins = widget.rewardType.toLowerCase() == 'coins';
    
    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (mounted) {
        setState(() {
          if (isCoins) {
            if (_animatedCoins < targetCoins) {
              final increment = math.max(1, (targetCoins - _animatedCoins) ~/ 10);
              _animatedCoins = math.min(_animatedCoins + increment, targetCoins);
            } else {
              timer.cancel();
              _animatedCoins = targetCoins;
            }
          } else {
            if (_animatedAmount < targetAmount) {
              final increment = (targetAmount - _animatedAmount) / 10;
              _animatedAmount = math.min(_animatedAmount + increment, targetAmount);
            } else {
              timer.cancel();
              _animatedAmount = targetAmount;
            }
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startParticleAnimation() {
    final random = math.Random();
    _particles = List.generate(
      widget.rewardType.toLowerCase() == 'coins' ? 20 : 15,
      (index) => Particle(
        x: 0.5,
        y: 0.5,
        vx: (random.nextDouble() - 0.5) * 0.02,
        vy: (random.nextDouble() - 0.5) * 0.02 - 0.01,
        size: random.nextDouble() * 8 + 4,
        opacity: random.nextDouble() * 0.5 + 0.5,
      ),
    );
    
    _particleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleClaim() {
    final isCoins = widget.rewardType.toLowerCase() == 'coins';
    widget.onBonusAdded(
      isCoins ? 0.0 : widget.signupBonusAmount,
      isCoins ? widget.signupBonusAmount.toInt() : 0,
    );
    Navigator.of(context).pop();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final isCoins = widget.rewardType.toLowerCase() == 'coins';
    final glowColor = isCoins ? Colors.amber : Colors.greenAccent;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final dialogMaxWidth = math.min(constraints.maxWidth * 0.88, 380.0);
        final dialogHeight = constraints.maxHeight * 0.55; // ~half screen

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogMaxWidth,
                  maxHeight: dialogHeight,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1F3A47),
                        Color(0xFF1A2F3D),
                        Color(0xFF0F1E2E),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Particle effects
                      if (_showBonus)
                        AnimatedBuilder(
                          animation: _particleController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: ParticlePainter(
                                particles: _particles,
                                progress: _particleController.value,
                                isCoins: isCoins,
                              ),
                              child: const SizedBox.expand(),
                            );
                          },
                        ),

                      // Content (scrollable in case of small screens)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                        child: Column(
                          children: [
                            // Close button
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, color: Colors.white70),
                                onPressed: _handleClaim,
                              ),
                            ),

                            // Middle section
                            Expanded(
                              child: Center(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 4),

                                      // Icon
                                      AnimatedBuilder(
                                        animation: _glowController,
                                        builder: (context, child) {
                                          final t = _glowAnimation.value;
                                          return Container(
                                            width: 82,
                                            height: 82,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: isCoins
                                                    ? [
                                                        Colors.amber.shade400,
                                                        Colors.orange.shade600
                                                      ]
                                                    : [
                                                        Colors.green.shade400,
                                                        Colors.teal.shade600
                                                      ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: glowColor.withValues(
                                                    alpha: 0.18 + (0.34 * t),
                                                  ),
                                                  blurRadius: 16 + (20 * t),
                                                  spreadRadius: 2 + (7 * t),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              isCoins
                                                  ? Icons.monetization_on
                                                  : Icons.account_balance_wallet,
                                              size: 42,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 14),

                                      // Title
                                      const Text(
                                        'Welcome Bonus',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),

                                      const SizedBox(height: 12),

                                      // Bonus Amount
                                      FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: AnimatedBuilder(
                                          animation: _glowController,
                                          builder: (context, child) {
                                            final t = _glowAnimation.value;
                                            return Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 18,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.10),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: glowColor.withValues(
                                                    alpha: 0.42 + (0.35 * t),
                                                  ),
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: glowColor.withValues(
                                                      alpha: 0.10 + (0.22 * t),
                                                    ),
                                                    blurRadius: 12 + (18 * t),
                                                    spreadRadius: 1 + (5 * t),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    isCoins ? '🪙' : '₹',
                                                    style: const TextStyle(fontSize: 26),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    isCoins
                                                        ? _animatedCoins.toString()
                                                        : _animatedAmount.toStringAsFixed(2),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 30,
                                                      fontWeight: FontWeight.bold,
                                                      shadows: [
                                                        Shadow(
                                                          blurRadius: 10,
                                                          color: Color(0x66000000),
                                                          offset: Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isCoins) ...[
                                                    const SizedBox(width: 4),
                                                    const Text(
                                                      'Coins',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // Description
                                      Text(
                                        widget.description,
                                        style: TextStyle(
                                          color: Colors.grey.shade300,
                                          fontSize: 13,
                                          height: 1.3,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Claim Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleClaim,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  elevation: 8,
                                ),
                                child: const Text(
                                  'Claim Bonus',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final bool isCoins;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.isCoins,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      final x = (particle.x + particle.vx * progress * 50) * size.width;
      final y = (particle.y + particle.vy * progress * 50) * size.height;
      final opacity = (1 - progress) * particle.opacity;

      paint.color = (isCoins ? Colors.amber : Colors.green)
          .withValues(alpha: opacity);

      if (isCoins) {
        // Draw coin shape
        canvas.drawCircle(
          Offset(x, y),
          particle.size,
          paint,
        );
        // Draw coin inner circle
        paint.color = Colors.orange.withValues(alpha: opacity * 0.5);
        canvas.drawCircle(
          Offset(x, y),
          particle.size * 0.6,
          paint,
        );
      } else {
        // Draw balance/money symbol
        canvas.drawCircle(
          Offset(x, y),
          particle.size,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
