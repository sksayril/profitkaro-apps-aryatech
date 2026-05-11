import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/quiz_public_settings.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/task_completion_ads_service.dart';
import '../../widgets/coin_reward_popup.dart';

class MathQuizScreen extends StatefulWidget {
  const MathQuizScreen({super.key});

  @override
  State<MathQuizScreen> createState() => _MathQuizScreenState();
}

class _MathQuizScreenState extends State<MathQuizScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const String _quizCooldownKey = 'math_quiz_next_available_at';
  static const String _completionsDayKey = 'math_quiz_completions_calendar_day';
  static const String _completionsCountKey = 'math_quiz_completions_count_today';
  static const String _lockKindStorageKey = 'math_quiz_lock_kind';

  // ---- Keys for resuming an in-progress quiz across navigation/relaunch ----
  // Once the user has started a quiz run (answered at least one question or
  // had questions generated for them), the run is persisted so that backing
  // out and re-entering will resume it instead of starting fresh.
  static const String _inProgressQuestionsKey = 'math_quiz_in_progress_questions';
  static const String _inProgressIndexKey = 'math_quiz_in_progress_index';
  static const String _inProgressCorrectKey = 'math_quiz_in_progress_correct';
  static const String _inProgressWrongKey = 'math_quiz_in_progress_wrong';
  static const String _inProgressEarnedKey = 'math_quiz_in_progress_earned';
  static const String _inProgressTotalAddedKey = 'math_quiz_in_progress_total_added';
  static const String _inProgressLastCoinKey = 'math_quiz_in_progress_last_coin';

  QuizPublicSettings _quizSettings = QuizPublicSettings.fallback();
  bool _quizDisabledByServer = false;
  /// `dailyLimit` = reset at midnight; `cooldown` = random-length wait after finishing.
  String _lockKind = 'cooldown';

  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int? _selectedAnswer;
  bool _isAnswered = false;
  bool _isQuizComplete = false;
  List<Map<String, dynamic>> _questions = [];
  int _earnedCoins = 0; // Coins earned from correct answers
  int _pendingCoins = 0; // Coins waiting to be added after ad watch
  int _totalCoinsAdded = 0; // Total coins added at the end (for showing in results)
  int? _lastCoinAmount; // Track last coin amount to avoid duplicates
  bool _isQuizLocked = false;
  bool _isInitializingQuizGate = true;
  DateTime? _nextQuizAvailableAt;
  String _quizCountdownText = '';
  Timer? _quizCountdownTimer;

  /// Full quiz completions counted for today's calendar date (may update after finishing a run).
  int _completionsToday = 0;
  
  // Confetti Animation
  late AnimationController _confettiController;
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeQuizGate();
    
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _quizCountdownTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumedRefreshGate();
    }
  }

  /// After midnight (or cooldown end), unlock without leaving the screen.
  Future<void> _onAppResumedRefreshGate() async {
    if (!_isQuizLocked || _nextQuizAvailableAt == null) return;
    if (DateTime.now().isBefore(_nextQuizAvailableAt!)) {
      _updateQuizCountdownText();
      return;
    }
    await _unlockQuizAfterCooldown();
  }

  String _calendarDayString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _nextLocalMidnight() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).add(const Duration(days: 1));
  }

  /// After a quiz run is completed, the next quiz unlocks exactly **24 hours**
  /// later. The unlock instant is persisted to local storage as an absolute
  /// epoch millisecond timestamp (`_quizCooldownKey`), so the countdown keeps
  /// ticking correctly across app restarts and device reboots.
  static const Duration _postCompletionCooldown = Duration(hours: 24);

  DateTime _cooldownUntil() => DateTime.now().add(_postCompletionCooldown);

  Future<int> _getCompletionsToday() async {
    final today = _calendarDayString(DateTime.now());
    final storedDay = await StorageService.getString(_completionsDayKey);
    if (storedDay != today) return 0;
    return await StorageService.getInt(_completionsCountKey) ?? 0;
  }

  Future<int> _incrementCompletionsToday() async {
    final today = _calendarDayString(DateTime.now());
    final storedDay = await StorageService.getString(_completionsDayKey);
    final prev =
        storedDay == today ? (await StorageService.getInt(_completionsCountKey) ?? 0) : 0;
    final next = prev + 1;
    await StorageService.saveString(_completionsDayKey, today);
    await StorageService.saveInt(_completionsCountKey, next);
    return next;
  }

  Future<void> _initializeQuizGate() async {
    final apiResult = await ApiService.getQuizSettingsPublic();
    var settings = QuizPublicSettings.fallback();
    if (apiResult['success'] == true &&
        apiResult['data'] != null &&
        apiResult['data'] is Map) {
      try {
        settings = QuizPublicSettings.fromJson(
          Map<String, dynamic>.from(apiResult['data'] as Map),
        );
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _quizSettings = settings;
    });

    if (!settings.isActive) {
      setState(() {
        _quizDisabledByServer = true;
        _isInitializingQuizGate = false;
      });
      return;
    }

    final completedToday = await _getCompletionsToday();
    if (!mounted) return;
    setState(() => _completionsToday = completedToday);

    final limit = settings.dailyLimit;
    final now = DateTime.now();

    if (limit != null && completedToday < limit) {
      await StorageService.saveInt(_quizCooldownKey, 0);
    }

    if (limit != null && completedToday >= limit) {
      // Check if there's already a stored cooldown timestamp
      final existingMs = await StorageService.getInt(_quizCooldownKey);
      final until = (existingMs != null && existingMs > 0 &&
              DateTime.fromMillisecondsSinceEpoch(existingMs).isAfter(DateTime.now()))
          ? DateTime.fromMillisecondsSinceEpoch(existingMs)
          : _cooldownUntil();
      await StorageService.saveInt(_quizCooldownKey, until.millisecondsSinceEpoch);
      await StorageService.saveString(_lockKindStorageKey, 'dailyLimit');
      if (!mounted) return;
      setState(() {
        _quizDisabledByServer = false;
        _isQuizLocked = true;
        _lockKind = 'dailyLimit';
        _nextQuizAvailableAt = until;
        _isInitializingQuizGate = false;
      });
      _updateQuizCountdownText();
      _startQuizCountdown();
      return;
    }

    final storedMs = await StorageService.getInt(_quizCooldownKey);
    if (storedMs != null && storedMs > 0) {
      final nextAvailableAt = DateTime.fromMillisecondsSinceEpoch(storedMs);
      if (nextAvailableAt.isAfter(now)) {
        if (!mounted) return;
        final storedKind = await StorageService.getString(_lockKindStorageKey);
        final kind = storedKind == 'dailyLimit' ? 'dailyLimit' : 'cooldown';
        setState(() {
          _isQuizLocked = true;
          _lockKind = kind;
          _nextQuizAvailableAt = nextAvailableAt;
          _isInitializingQuizGate = false;
        });
        _updateQuizCountdownText();
        _startQuizCountdown();
        return;
      }
      final expiredKind = await StorageService.getString(_lockKindStorageKey);
      if (expiredKind == 'dailyLimit') {
        final today = _calendarDayString(DateTime.now());
        await StorageService.saveString(_completionsDayKey, today);
        await StorageService.saveInt(_completionsCountKey, 0);
      }
    }

    await StorageService.saveInt(_quizCooldownKey, 0);
    await StorageService.saveString(_lockKindStorageKey, '');
    if (!mounted) return;
    setState(() {
      _quizDisabledByServer = false;
      _isQuizLocked = false;
      _nextQuizAvailableAt = null;
      _lockKind = 'cooldown';
      _isInitializingQuizGate = false;
    });
    // Resume an in-progress quiz if one was saved (user backed out without
    // finishing). Otherwise, start a fresh run. Either way the quiz cannot
    // be "restarted" early — daily-limit / cooldown is the gate.
    final resumed = await _loadInProgressState();
    if (!resumed) {
      _prepareFreshQuiz();
    }
  }

  Future<void> _markQuizCompletedAndLock() async {
    final completedCount = await _incrementCompletionsToday();

    final limit = _quizSettings.dailyLimit;

    if (!mounted) return;
    setState(() => _completionsToday = completedCount);

    if (limit != null && completedCount >= limit) {
      // Daily limit reached — lock for 24 hours from now
      final until = _cooldownUntil();
      await StorageService.saveInt(_quizCooldownKey, until.millisecondsSinceEpoch);
      await StorageService.saveString(_lockKindStorageKey, 'dailyLimit');
      if (!mounted) return;
      setState(() {
        _isQuizLocked = true;
        _lockKind = 'dailyLimit';
        _nextQuizAvailableAt = until;
      });
      _updateQuizCountdownText();
      _startQuizCountdown();
      return;
    }

    // More quizzes remaining today — no lock needed
    await StorageService.saveInt(_quizCooldownKey, 0);
  }

  void _startQuizCountdown() {
    _quizCountdownTimer?.cancel();
    _quizCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_nextQuizAvailableAt == null) {
        timer.cancel();
        return;
      }

      if (DateTime.now().isAfter(_nextQuizAvailableAt!)) {
        timer.cancel();
        _unlockQuizAfterCooldown();
        return;
      }

      _updateQuizCountdownText();
    });
  }

  Future<void> _unlockQuizAfterCooldown() async {
    final wasDailyLimit = _lockKind == 'dailyLimit';
    await StorageService.saveInt(_quizCooldownKey, 0);
    await StorageService.saveString(_lockKindStorageKey, '');
    if (wasDailyLimit) {
      final today = _calendarDayString(DateTime.now());
      await StorageService.saveString(_completionsDayKey, today);
      await StorageService.saveInt(_completionsCountKey, 0);
    }
    if (!mounted) return;

    final todayCount = await _getCompletionsToday();
    if (!mounted) return;

    setState(() {
      _isQuizLocked = false;
      _nextQuizAvailableAt = null;
      _quizCountdownText = '';
      _completionsToday = todayCount;
    });
    // After cooldown, any old in-progress data is stale (it belonged to a
    // prior, already-completed run) — clear it before starting fresh.
    await _clearInProgressState();
    _prepareFreshQuiz();
  }

  void _updateQuizCountdownText() {
    if (_nextQuizAvailableAt == null) {
      if (mounted) {
        setState(() {
          _quizCountdownText = '';
        });
      }
      return;
    }

    final now = DateTime.now();
    final remaining = _nextQuizAvailableAt!.difference(now);
    if (remaining.isNegative) {
      if (mounted) {
        setState(() {
          _quizCountdownText = '00:00:00';
        });
      }
      return;
    }

    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        _quizCountdownText = '$hours:$minutes:$seconds';
      });
    }
  }

  int _questionsInThisRun() {
    final explicit = _quizSettings.questionsPerQuiz;
    if (explicit != null && explicit >= 1) {
      return explicit.clamp(1, 100);
    }
    final fromDaily = _quizSettings.dailyLimit;
    if (fromDaily != null && fromDaily >= 1) {
      return fromDaily.clamp(1, 100);
    }
    return 1;
  }

  // ---- In-progress quiz persistence -----------------------------------------

  /// Save the current run (questions + counters) so that backing out and
  /// returning resumes the same quiz instead of starting fresh. Called after
  /// every state change that the user could lose (new run, answer submitted,
  /// question advanced, coins credited).
  Future<void> _persistInProgressState() async {
    if (_questions.isEmpty) return;
    try {
      // Each entry is already a JSON-friendly map (`question`, `answers`,
      // `correctAnswer`, `correctIndex`).
      await StorageService.saveString(
        _inProgressQuestionsKey,
        jsonEncode(_questions),
      );
      await StorageService.saveInt(_inProgressIndexKey, _currentQuestionIndex);
      await StorageService.saveInt(_inProgressCorrectKey, _correctAnswers);
      await StorageService.saveInt(_inProgressWrongKey, _wrongAnswers);
      await StorageService.saveInt(_inProgressEarnedKey, _earnedCoins);
      await StorageService.saveInt(_inProgressTotalAddedKey, _totalCoinsAdded);
      await StorageService.saveInt(
        _inProgressLastCoinKey,
        _lastCoinAmount ?? -1,
      );
    } catch (_) {
      // Best-effort persistence; never block the UI on storage failures.
    }
  }

  /// Try to restore a previously saved in-progress run. Returns `true` when a
  /// valid run was restored (UI state was updated and questions are loaded);
  /// returns `false` otherwise (caller should generate a fresh run).
  Future<bool> _loadInProgressState() async {
    try {
      final raw = await StorageService.getString(_inProgressQuestionsKey);
      if (raw == null || raw.isEmpty) return false;

      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.isEmpty) return false;

      final questions = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map) {
          questions.add(Map<String, dynamic>.from(item));
        }
      }
      if (questions.isEmpty) return false;

      // If the saved quiz has a different question count than current API
      // settings, discard it and start fresh.
      final expectedCount = _questionsInThisRun();
      if (questions.length != expectedCount) {
        await _clearInProgressState();
        return false;
      }

      final savedIndex =
          (await StorageService.getInt(_inProgressIndexKey)) ?? 0;
      final savedCorrect =
          (await StorageService.getInt(_inProgressCorrectKey)) ?? 0;
      final savedWrong = (await StorageService.getInt(_inProgressWrongKey)) ?? 0;
      final savedEarned =
          (await StorageService.getInt(_inProgressEarnedKey)) ?? 0;
      final savedTotalAdded =
          (await StorageService.getInt(_inProgressTotalAddedKey)) ?? 0;
      final savedLastCoinRaw =
          await StorageService.getInt(_inProgressLastCoinKey);

      final clampedIndex = savedIndex.clamp(0, questions.length - 1);

      // If every question has already been answered, treat as completed and
      // wipe — the lock/cooldown is the source of truth from here on.
      if (savedIndex >= questions.length) {
        await _clearInProgressState();
        return false;
      }

      if (!mounted) return false;
      setState(() {
        _questions = questions;
        _currentQuestionIndex = clampedIndex;
        _correctAnswers = savedCorrect;
        _wrongAnswers = savedWrong;
        _earnedCoins = savedEarned;
        _totalCoinsAdded = savedTotalAdded;
        _lastCoinAmount =
            (savedLastCoinRaw == null || savedLastCoinRaw < 0)
                ? null
                : savedLastCoinRaw;
        _selectedAnswer = null;
        _isAnswered = false;
        _isQuizComplete = false;
        _pendingCoins = 0;
      });
      return true;
    } catch (_) {
      // Corrupted payload — fall back to a fresh run.
      await _clearInProgressState();
      return false;
    }
  }

  /// Wipe any persisted in-progress run. Called when a run completes
  /// successfully or when stored data is found to be corrupted.
  Future<void> _clearInProgressState() async {
    try {
      await StorageService.saveString(_inProgressQuestionsKey, '');
      await StorageService.saveInt(_inProgressIndexKey, 0);
      await StorageService.saveInt(_inProgressCorrectKey, 0);
      await StorageService.saveInt(_inProgressWrongKey, 0);
      await StorageService.saveInt(_inProgressEarnedKey, 0);
      await StorageService.saveInt(_inProgressTotalAddedKey, 0);
      await StorageService.saveInt(_inProgressLastCoinKey, -1);
    } catch (_) {
      // ignore
    }
  }

  // ---- Quiz lifecycle -------------------------------------------------------

  void _prepareFreshQuiz() {
    _generateQuestions();
    if (!mounted) return;
    setState(() {
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _wrongAnswers = 0;
      _selectedAnswer = null;
      _isAnswered = false;
      _isQuizComplete = false;
      _earnedCoins = 0;
      _pendingCoins = 0;
      _totalCoinsAdded = 0;
      _lastCoinAmount = null;
    });
    // Persist the freshly generated run so that, if the user backs out before
    // submitting any answer, returning to the screen resumes the same set of
    // questions instead of regenerating new ones.
    unawaited(_persistInProgressState());
  }

  void _generateQuestions() {
    final random = math.Random();
    final count = _questionsInThisRun();
    final ops = [0, 1, 2, 3]; // +, -, ×, ÷

    _questions = List.generate(count, (index) {
      final difficulty = index < (count * 0.3).ceil()
          ? 0 // easy
          : index < (count * 0.7).ceil()
              ? 1 // medium
              : 2; // hard

      final operation = ops[index % ops.length];

      int num1, num2, correctAnswer;
      String question;

      switch (operation) {
        case 0: // Addition
          num1 = _randForDifficulty(random, difficulty);
          num2 = _randForDifficulty(random, difficulty);
          correctAnswer = num1 + num2;
          question = '$num1 + $num2 = ?';
          break;
        case 1: // Subtraction — always larger - smaller so answer >= 0
          num1 = _randForDifficulty(random, difficulty);
          num2 = _randForDifficulty(random, difficulty);
          final big = math.max(num1, num2);
          final small = math.min(num1, num2);
          correctAnswer = big - small;
          question = '$big - $small = ?';
          break;
        case 2: // Multiplication — keep numbers small so answers are reasonable
          num1 = random.nextInt(difficulty == 0 ? 6 : difficulty == 1 ? 10 : 13) + 2;
          num2 = random.nextInt(difficulty == 0 ? 6 : difficulty == 1 ? 10 : 13) + 2;
          correctAnswer = num1 * num2;
          question = '$num1 × $num2 = ?';
          break;
        default: // Division — construct so the answer is always a clean integer
          num2 = random.nextInt(difficulty == 0 ? 6 : difficulty == 1 ? 10 : 13) + 2;
          correctAnswer = random.nextInt(difficulty == 0 ? 10 : difficulty == 1 ? 15 : 20) + 1;
          final dividend = num2 * correctAnswer;
          question = '$dividend ÷ $num2 = ?';
          break;
      }

      final wrongAnswers = _generateWrongAnswers(random, correctAnswer);
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

  int _randForDifficulty(math.Random random, int difficulty) {
    switch (difficulty) {
      case 0:
        return random.nextInt(15) + 1; // 1–15
      case 1:
        return random.nextInt(40) + 10; // 10–49
      default:
        return random.nextInt(80) + 20; // 20–99
    }
  }

  List<int> _generateWrongAnswers(math.Random random, int correct) {
    final offsets = <int>{};
    final maxAttempts = 50;
    var attempts = 0;

    while (offsets.length < 3 && attempts < maxAttempts) {
      attempts++;
      int offset;
      if (correct <= 10) {
        offset = random.nextInt(7) + 1; // small spread for small answers
      } else {
        final spread = (correct * 0.3).ceil().clamp(2, 20);
        offset = random.nextInt(spread) + 1;
      }
      final sign = random.nextBool() ? 1 : -1;
      final wrong = correct + offset * sign;
      if (wrong > 0 && wrong != correct && !offsets.contains(wrong)) {
        offsets.add(wrong);
      }
    }

    // Fallback if not enough unique wrong answers generated
    var fallback = correct + 1;
    while (offsets.length < 3) {
      if (fallback != correct && fallback > 0 && !offsets.contains(fallback)) {
        offsets.add(fallback);
      }
      fallback++;
    }

    return offsets.toList();
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

    final perTaskCoins = _quizSettings.coinsPerTask;
    int coinsForThisAnswer = 0;
    if (isCorrect) {
      if (perTaskCoins != null && perTaskCoins > 0) {
        coinsForThisAnswer = perTaskCoins;
      } else {
        final random = math.Random();
        do {
          coinsForThisAnswer = random.nextInt(8) + 3;
        } while (coinsForThisAnswer == _lastCoinAmount && _lastCoinAmount != null);
      }
    }

    setState(() {
      _isAnswered = true;
    });

    Future<void>(() async {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      if (!isCorrect) {
        setState(() {
          _wrongAnswers++;
        });
        unawaited(_persistInProgressState());
        _nextQuestion();
        return;
      }

      setState(() {
        _correctAnswers++;
        if (coinsForThisAnswer > 0) {
          _lastCoinAmount = coinsForThisAnswer;
          _earnedCoins += coinsForThisAnswer;
        }
      });
      unawaited(_persistInProgressState());

      // Flow: correct answer → rewarded ad → add coins → next question
      _showRewardedAdThenCredit(coinsForThisAnswer);
    });
  }

  /// Show rewarded ad first, then credit coins and move to next question.
  void _showRewardedAdThenCredit(int coins) {
    if (!mounted) return;

    if (!_quizSettings.adsEnabled) {
      _creditCoinsAndProceed(coins);
      return;
    }

    TaskCompletionAdsService.instance.runAfterTaskCompleted(
      () {
        if (mounted) _creditCoinsAndProceed(coins);
      },
      taskType: 'Quiz',
    );
  }

  void _creditCoinsAndProceed(int coins) {
    if (!mounted) return;
    if (coins > 0) {
      _addCoinAndShowPopup(coins, _nextQuestion);
    } else {
      _nextQuestion();
    }
  }

  // Credit `coins` to the wallet and show the reward popup. The popup's
  // close callback always fires (success or failure) so the quiz never gets
  // stuck on a question.
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

      if (!mounted) return;

      if (result['success'] == true) {
        _totalCoinsAdded += coins;
        // Persist so totals survive the user backing out before the popup is
        // dismissed.
        unawaited(_persistInProgressState());
        _showCoinRewardPopup(coins, onClose);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add coins'),
            backgroundColor: Colors.red,
          ),
        );
        onClose();
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

  // Settle any leftover pending coins (defensive — should be 0 in the
  // happy path because coins are credited per correct answer). Always
  // continues to the results screen so the user is never stuck.
  Future<void> _addPendingCoinsToWallet() async {
    if (_pendingCoins <= 0) {
      if (!_isQuizComplete) _showResults();
      return;
    }

    final coinsToAdd = _pendingCoins;

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
        if (!_isQuizComplete) _showResults();
        return;
      }

      final result = await ApiService.addCoins(
        token: token,
        coins: coinsToAdd,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _totalCoinsAdded += coinsToAdd;
        _pendingCoins = 0;
        _showCoinRewardPopup(coinsToAdd, () {
          if (!_isQuizComplete) _showResults();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add coins'),
            backgroundColor: Colors.red,
          ),
        );
        if (!_isQuizComplete) _showResults();
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
      if (!_isQuizComplete) _showResults();
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
      // Persist the new index so backing out resumes on this question, not
      // the previous one.
      unawaited(_persistInProgressState());
    } else {
      unawaited(_completeQuiz());
    }
  }

  Future<void> _completeQuiz() async {
    await _markQuizCompletedAndLock();
    if (!mounted) return;
    // The run is finished — wipe the in-progress snapshot so a future quiz
    // (after the cooldown / next-day reset) starts fresh.
    await _clearInProgressState();
    if (!mounted) return;
    // After all questions in this run are completed, add remaining coins and show popup.
    // Ads were shown after each correct answer; this is purely a safety net
    // for any coins that didn't get credited per-question (network failure
    // mid-quiz, etc.).
    if (_pendingCoins > 0) {
      _addPendingCoinsToWallet();
    } else {
      _showResults();
    }
  }

  void _showResults() {
    if (mounted) _triggerResults();
  }

  void _triggerResults() {
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
    if (_isInitializingQuizGate) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          backgroundColor: AppColors.background(context),
          title: const Text('Math Quiz'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_quizDisabledByServer) {
      return _buildQuizDisabledScreen();
    }

    if (_isQuizComplete) {
      return _buildResultsScreen();
    }

    if (_isQuizLocked) {
      return _buildQuizLockedScreen();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Math Quiz',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              height: kToolbarHeight,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_currentQuestionIndex + 1} / ${_questions.length}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.1,
                        ),
                      ),
                      if (_quizSettings.dailyLimit != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            'Today: $_completionsToday/${_quizSettings.dailyLimit}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (_earnedCoins > 0)
                        Text(
                          'Coins: $_earnedCoins',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
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

  Widget _buildQuizDisabledScreen() {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        title: const Text('Math Quiz'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.quiz_outlined, color: Colors.grey.shade500, size: 52),
                const SizedBox(height: 14),
                const Text(
                  'Math Quiz unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This feature is turned off right now. Please check again later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
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
          ),
        ),
      ),
    );
  }

  Widget _buildQuizLockedScreen() {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        title: const Text('Math Quiz'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock, color: Colors.orange, size: 52),
                const SizedBox(height: 14),
                const Text(
                  'Daily limit reached',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You have completed today's quiz limit ($_completionsToday/${_quizSettings.dailyLimit ?? '∞'}). Next quiz will be available after 24 hours.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (_nextQuizAvailableAt != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Unlocks: ${DateFormat('EEE, MMM d • h:mm a').format(_nextQuizAvailableAt!)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'Time until next quiz',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _quizCountdownText.isEmpty ? '00:00:00' : _quizCountdownText,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
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
