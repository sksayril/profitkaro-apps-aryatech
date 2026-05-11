/// Server: GET /users/quiz/settings/public
///
/// - [dailyLimit]: max **completed quiz runs** per calendar day (local app count).
/// - [questionsPerQuiz]: how many questions **one run** contains. Prefer setting this
///   explicitly. If omitted, the app may use [dailyLimit] as the run length when that
///   is set (see `MathQuizScreen`); for many runs per day with 20 questions each, send
///   `QuestionsPerQuiz: 20` explicitly.
class QuizPublicSettings {
  final bool isActive;
  final bool adsEnabled;
  final int? dailyLimit;
  /// Questions in a single quiz session (`QuestionsPerQuiz` in JSON).
  final int? questionsPerQuiz;
  final int? coinsPerTask;

  const QuizPublicSettings({
    required this.isActive,
    this.adsEnabled = true,
    this.dailyLimit,
    this.questionsPerQuiz,
    this.coinsPerTask,
  });

  static QuizPublicSettings fallback() => const QuizPublicSettings(
        isActive: true,
        adsEnabled: true,
        dailyLimit: null,
        questionsPerQuiz: null,
        coinsPerTask: null,
      );

  factory QuizPublicSettings.fromJson(Map<String, dynamic> json) {
    int? pickInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    return QuizPublicSettings(
      isActive: json['IsActive'] == true,
      adsEnabled: json['AdsEnabled'] != false,
      dailyLimit: pickInt(json['DailyLimit'] ?? json['dailyLimit']),
      questionsPerQuiz: pickInt(
        json['QuestionsPerQuiz'] ??
            json['questionsPerQuiz'] ??
            json['questions_per_quiz'],
      ),
      coinsPerTask: pickInt(json['CoinsPerTask'] ?? json['coinsPerTask']),
    );
  }
}
