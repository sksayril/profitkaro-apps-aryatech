import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/coin_reward_popup.dart';

class MathQuizScreen extends StatefulWidget {
  const MathQuizScreen({super.key});

  @override
  State<MathQuizScreen> createState() => _MathQuizScreenState();
}

class _MathQuizScreenState extends State<MathQuizScreen> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int? _selectedAnswer;
  bool _isAnswered = false;
  bool _isQuizComplete = false;
  List<Map<String, dynamic>> _questions = [];
  int _earnedCoins = 0; // Coins earned from correct answers
  int _pendingCoins = 0; // Coins waiting to be added after ad watch
  int _questionsAnswered = 0; // Track questions answered to show ad on 5th question
  int _totalCoinsAdded = 0; // Total coins added at the end (for showing in results)
  int? _lastCoinAmount = null; // Track last coin amount to avoid duplicates
  
  // AdMob Configuration
  static const String _adAppId = 'ca-app-pub-4532355113190688~4971485294';
  static const String _rewardedAdUnitId = 'ca-app-pub-4532355113190688/5923175121';
  
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  
  // Confetti Animation
  late AnimationController _confettiController;
  List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAds();
    _generateQuestions();
    
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
      setState(() {
        for (var particle in _particles) {
          particle.update();
        }
      });
    });
  }

  void _initializeAds() {
    MobileAds.instance.initialize().then((status) {
      _loadRewardedAd();
    });
  }

  void _loadRewardedAd() {
    if (_isAdLoading) return;
    
    setState(() {
      _isAdLoading = true;
      _isAdLoaded = false;
    });

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (mounted) {
            setState(() {
              _rewardedAd = ad;
              _isAdLoaded = true;
              _isAdLoading = false;
            });
            
            // Set full screen content callback
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                ad.dispose();
                if (mounted) {
                  setState(() {
                    _rewardedAd = null;
                    _isAdLoaded = false;
                  });
                }
                // Load next ad after a short delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _loadRewardedAd();
                  }
                });
              },
              onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
                ad.dispose();
                if (mounted) {
                  setState(() {
                    _rewardedAd = null;
                    _isAdLoaded = false;
                  });
                }
                // Retry loading ad after a delay
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    _loadRewardedAd();
                  }
                });
              },
            );
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (mounted) {
            setState(() {
              _isAdLoading = false;
              _isAdLoaded = false;
            });
            // Retry loading ad after a delay
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                _loadRewardedAd();
              }
            });
          }
        },
      ),
    );
  }

  void _showRewardedAd({required VoidCallback onAdWatched}) {
    if (_rewardedAd != null && _isAdLoaded) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // User watched the ad, now add coins
          onAdWatched();
        },
      );
    } else {
      // If ad not loaded, try to load it first
      if (!_isAdLoading) {
        _loadRewardedAd();
      }
      
      // Show message and proceed after a delay
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad is loading. Please wait...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Wait a bit for ad to load, then proceed
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            if (_rewardedAd != null && _isAdLoaded) {
              _rewardedAd!.show(
                onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
                  onAdWatched();
                },
              );
            } else {
              // If still not loaded, proceed anyway
              onAdWatched();
            }
          }
        });
      } else {
        // If not mounted, just proceed
        onAdWatched();
      }
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final random = math.Random();
    _questions = List.generate(20, (index) {
      final num1 = random.nextInt(20) + 1;
      final num2 = random.nextInt(20) + 1;
      final operation = random.nextInt(4); // 0: +, 1: -, 2: *, 3: /
      
      int correctAnswer;
      String question;
      
      switch (operation) {
        case 0: // Addition
          correctAnswer = num1 + num2;
          question = '$num1 + $num2 = ?';
          break;
        case 1: // Subtraction
          correctAnswer = num1 > num2 ? num1 - num2 : num2 - num1;
          question = num1 > num2 ? '$num1 - $num2 = ?' : '$num2 - $num1 = ?';
          break;
        case 2: // Multiplication
          correctAnswer = num1 * num2;
          question = '$num1 × $num2 = ?';
          break;
        default: // Division
          final product = num1 * num2;
          correctAnswer = num2;
          question = '$product ÷ $num1 = ?';
          break;
      }
      
      // Generate wrong answers
      final wrongAnswers = <int>[];
      while (wrongAnswers.length < 3) {
        final wrong = correctAnswer + random.nextInt(20) - 10;
        if (wrong != correctAnswer && wrong > 0 && !wrongAnswers.contains(wrong)) {
          wrongAnswers.add(wrong);
        }
      }
      
      // Shuffle answers
      final allAnswers = [correctAnswer, ...wrongAnswers]..shuffle(random);
      final correctIndex = allAnswers.indexOf(correctAnswer);
      
      return {
        'question': question,
        'answers': allAnswers,
        'correctAnswer': correctAnswer,
        'correctIndex': correctIndex,
      };
    });
  }

  void _selectAnswer(int index) {
    if (_isAnswered) return;
    
    setState(() {
      _selectedAnswer = index;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null || _isAnswered) return;

    final question = _questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswer == question['correctIndex'];
    
    // Calculate coins for this answer if correct
    // Random coins between 3-10, but cannot be same as previous coin amount
    int coinsForThisAnswer = 0;
    if (isCorrect) {
      final random = math.Random();
      
      // Generate random coin between 3-10, ensuring it's different from last coin
      do {
        coinsForThisAnswer = random.nextInt(8) + 3; // Random between 3 and 10 (inclusive)
      } while (coinsForThisAnswer == _lastCoinAmount && _lastCoinAmount != null);
      
      // Update last coin amount for next time
      _lastCoinAmount = coinsForThisAnswer;
    }

    setState(() {
      _isAnswered = true;
      _questionsAnswered++;
      
      if (isCorrect) {
        _correctAnswers++;
        _earnedCoins += coinsForThisAnswer;
        _pendingCoins += coinsForThisAnswer;
      } else {
        _wrongAnswers++;
        // Wrong answer = no coin, just move to next question
      }
    });
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      // If answer is correct and coin is earned, show coin popup immediately
      if (isCorrect && coinsForThisAnswer > 0) {
        // Show coin reward popup for the earned coins
        _addCoinAndShowPopup(coinsForThisAnswer, () {
          // After popup is closed and ad is watched, proceed to next question
          _proceedAfterCoinPopup();
        });
      } else {
        // Wrong answer or no coin earned, proceed directly
        _proceedAfterCoinPopup();
      }
    });
  }

  void _proceedAfterCoinPopup() {
    // Show rewarded ad after questions 1, 5, 10, 15, and 20
    // This applies to both correct and wrong answers
    if (_questionsAnswered == 1 || 
        _questionsAnswered == 5 || 
        _questionsAnswered == 10 || 
        _questionsAnswered == 15 || 
        _questionsAnswered == 20) {
      _showAdDuringQuiz();
    } else {
      _nextQuestion();
    }
  }

  void _showAdDuringQuiz() {
    // Show rewarded ad after specific questions (1st, 5th, 10th, 15th, 20th)
    // Works for both correct and wrong answers
    _showRewardedAd(
      onAdWatched: () {
        // After ad is watched, continue to next question
        _nextQuestion();
      },
    );
  }

  // Add coin and show popup immediately (used during quiz for each coin earned)
  Future<void> _addCoinAndShowPopup(int coins, VoidCallback onClose) async {
    if (coins <= 0) {
      onClose();
      return;
    }
    
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to earn coins'),
              backgroundColor: Colors.red,
            ),
          );
        }
        onClose();
        return;
      }
      
      final result = await ApiService.addCoins(
        token: token,
        coins: coins,
      );
      
      if (mounted) {
        if (result['success'] == true) {
          // Update pending coins (subtract the coins we just added)
          _pendingCoins -= coins;
          // Store total coins added for showing in results
          _totalCoinsAdded += coins;
          // Show attractive popup modal with earned coins
          _showCoinRewardPopup(coins, onClose);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to add coins'),
                backgroundColor: Colors.red,
              ),
            );
          }
          onClose();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      onClose();
    }
  }

  // Add coins and show popup (used at end of quiz)
  Future<void> _addPendingCoinsToWallet() async {
    if (_pendingCoins <= 0) return;
    
    final coinsToAdd = _pendingCoins; // Store before reset
    
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to earn coins'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final result = await ApiService.addCoins(
        token: token,
        coins: _pendingCoins,
      );
      
      if (mounted) {
        if (result['success'] == true) {
          // Store total coins added for showing in results
          _totalCoinsAdded += coinsToAdd;
          // Reset pending coins after successful addition
          _pendingCoins = 0;
          // Show attractive popup modal
          _showCoinRewardPopup(coinsToAdd, () {
            // After popup is closed, show results screen
            if (!_isQuizComplete) {
              _showResults();
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to add coins'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
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

  void _showCoinRewardPopup(int coins, [VoidCallback? onClose]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CoinRewardPopup(
          coins: coins,
          onClose: () {
            // Call the provided onClose callback if available
            onClose?.call();
          },
          // No ads on "Add Wallet" button click - ads only after specific questions
        );
      },
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
      });
    } else {
      _completeQuiz();
    }
  }

  void _completeQuiz() {
    // After all 20 questions are completed, add remaining coins and show popup
    // Ads will show when "Add Wallet" button is clicked in the popup
    if (_pendingCoins > 0) {
      // Add all remaining pending coins and show popup
      _addPendingCoinsToWallet();
      // Results will be shown after popup is closed (in onClose callback)
    } else {
      // No pending coins (all already added), just show results
      _showResults();
    }
  }

  void _showResults() {
    _generateParticles();
    _confettiController.forward(from: 0);
    
    setState(() {
      _isQuizComplete = true;
    });
    
    // Show reward popup on results screen if coins were earned
    if (_totalCoinsAdded > 0) {
      // Show popup after a short delay to let results screen render
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _showCoinRewardPopupOnResults(_totalCoinsAdded);
        }
      });
    }
  }
  
  void _showCoinRewardPopupOnResults(int coins) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CoinRewardPopup(
          coins: coins,
          // No ads on "Add Wallet" button click - ads only after specific questions
        );
      },
    );
  }
  
  void _generateParticles() {
    _particles.clear();
    final random = math.Random();
    for (int i = 0; i < 100; i++) {
      _particles.add(ConfettiParticle(random));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isQuizComplete) {
      return _buildResultsScreen();
    }
    
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          backgroundColor: AppColors.background(context),
          title: const Text('Math Quiz'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final question = _questions[_currentQuestionIndex];
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Show warning if there are pending coins
            if (_pendingCoins > 0) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Exit Quiz?'),
                  content: Text('You have $_pendingCoins coin${_pendingCoins > 1 ? 's' : ''} pending. Watch an ad to add them to your wallet.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Stay'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Math Quiz',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentQuestionIndex + 1} / ${_questions.length}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_earnedCoins > 0)
                  Text(
                    'Coins: $_earnedCoins',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Question Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6C5CE7),
                      Color(0xFF8B7AE8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Question
                    Text(
                      question['question'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Answer Options
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final answer = question['answers'][index];
                        final isSelected = _selectedAnswer == index;
                        final isCorrect = index == question['correctIndex'];
                        final showResult = _isAnswered && (isSelected || isCorrect);
                        
                        Color backgroundColor;
                        if (showResult) {
                          backgroundColor = isCorrect 
                              ? Colors.green 
                              : (isSelected ? Colors.red : const Color(0xFF8B7AE8));
                        } else {
                          backgroundColor = isSelected 
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.2);
                        }
                        
                        return GestureDetector(
                          onTap: () => _selectAnswer(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.white 
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                answer.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_selectedAnswer != null && !_isAnswered) ? _submitAnswer : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6C5CE7),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isAnswered 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
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
    );
  }

  Widget _buildResultsScreen() {
    final totalQuestions = _questions.length;
    final percentage = (_correctAnswers / totalQuestions * 100).round();
    
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        title: const Text('Quiz Results'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Result Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.green.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 80,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Score
                Text(
                  '$_correctAnswers / $totalQuestions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$percentage% Correct',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Stats
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow('Correct Answers', _correctAnswers.toString(), Colors.green),
                      const Divider(color: Colors.grey),
                      _buildStatRow('Wrong Answers', _wrongAnswers.toString(), Colors.red),
                      const Divider(color: Colors.grey),
                      _buildStatRow('Coins Earned', '$_earnedCoins Coins', AppColors.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Confetti Animation Overlay
          if (_confettiController.isAnimating || _confettiController.isCompleted)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ConfettiPainter(_particles),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiParticle {
  double x;
  double y;
  double size;
  double velocity;
  double angle;
  double angularVelocity;
  Color color;

  ConfettiParticle(math.Random random)
      : x = random.nextDouble() * 400,
        y = -random.nextDouble() * 500,
        size = random.nextDouble() * 8 + 6,
        velocity = random.nextDouble() * 4 + 3,
        angle = random.nextDouble() * 2 * math.pi,
        angularVelocity = (random.nextDouble() - 0.5) * 0.2,
        color = [
          Colors.amber,
          Colors.orange,
          Colors.yellow,
          Colors.blue,
          Colors.green,
          Colors.red,
          Colors.purple,
        ][random.nextInt(7)];

  void update() {
    y += velocity;
    angle += angularVelocity;
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      if (particle.y > size.height + 20) continue;

      final paint = Paint()..color = particle.color;
      
      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.angle);
      
      canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}
