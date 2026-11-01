/// Immutable quiz data. Widgets read these; only [QuizController] creates
/// results, and only the question repository creates questions.
library;

enum QuizCategory {
  anime('anime', 'Anime'),
  sports('sports', 'Sports');

  const QuizCategory(this.id, this.name);

  /// Stable identifier used in question data and saved attempts.
  final String id;
  final String name;

  static QuizCategory? byId(String id) {
    for (final category in values) {
      if (category.id == id) return category;
    }
    return null;
  }
}

/// A sub-category such as Shōnen or Cricket. Topics come from the question
/// data, so new ones can ship without an app update.
class QuizTopic {
  const QuizTopic({
    required this.id,
    required this.category,
    required this.name,
  });
  final String id;
  final QuizCategory category;
  final String name;
}

/// The shape of every quiz. The question repository rejects data that
/// cannot fill it, so the UI can state it truthfully.
abstract final class QuizFormat {
  static const questionsPerQuiz = 10;
  static const optionsPerQuestion = 4;

  /// Seconds per question in timed mode.
  static const secondsPerQuestion = 20;
}

enum QuizMode {
  /// Ten random questions; play as often as you like.
  practice('practice'),

  /// The same ten questions for every player on a given day, once per day.
  daily('daily');

  const QuizMode(this.id);
  final String id;

  static QuizMode? byId(String id) {
    for (final mode in values) {
      if (mode.id == id) return mode;
    }
    return null;
  }
}

/// What the player chose before starting.
class QuizSetup {
  const QuizSetup({
    required this.category,
    this.topic,
    this.mode = QuizMode.practice,
    this.timed = false,
    this.day,
  }) : assert(mode != QuizMode.daily || day != null);

  final QuizCategory category;

  /// Null means every topic in the category.
  final QuizTopic? topic;
  final QuizMode mode;
  final bool timed;

  /// The challenge day for [QuizMode.daily], as a local calendar date.
  final DateTime? day;

  /// A daily attempt has a fixed ID per category and day, so the database
  /// itself allows only one completed daily attempt per player per day.
  String? get fixedAttemptId =>
      mode == QuizMode.daily ? dailyAttemptId(category, day!) : null;
}

String dayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}'
    '${day.month.toString().padLeft(2, '0')}'
    '${day.day.toString().padLeft(2, '0')}';

String dailyAttemptId(QuizCategory category, DateTime day) =>
    'daily-${category.id}-${dayKey(day)}';

class Question {
  Question({
    required this.id,
    required this.category,
    required this.topicId,
    required this.prompt,
    required List<String> options,
    required this.correctIndex,
    required this.explanation,
  }) : options = List.unmodifiable(options);

  final String id;
  final QuizCategory category;
  final String topicId;
  final String prompt;
  final List<String> options;

  /// Correctness is decided by index, never by matching display text.
  final int correctIndex;
  final String explanation;

  bool isCorrect(int optionIndex) => optionIndex == correctIndex;
}

/// One submitted answer within a finished attempt.
class AnswerRecord {
  const AnswerRecord({required this.question, required this.selectedIndex});

  /// Stored when the timer ran out before an answer was submitted.
  static const timedOut = -1;

  final Question question;
  final int selectedIndex;
  bool get isTimedOut => selectedIndex == timedOut;
  bool get isCorrect => question.isCorrect(selectedIndex);
}

/// A finished attempt. [attemptId] is created once when the user presses
/// Finish, so retrying a failed save reuses it instead of duplicating it.
class QuizResult {
  QuizResult({
    required this.attemptId,
    required this.category,
    required this.questionSetVersion,
    required this.completedAt,
    required List<AnswerRecord> answers,
    this.topicId,
    this.mode = QuizMode.practice,
    this.timed = false,
  }) : answers = List.unmodifiable(answers);

  final String attemptId;
  final QuizCategory category;
  final String? topicId;
  final QuizMode mode;
  final bool timed;
  final String questionSetVersion;
  final DateTime completedAt;
  final List<AnswerRecord> answers;

  int get score => answers.where((answer) => answer.isCorrect).length;
  int get total => answers.length;
}

/// A completed attempt as stored in the player's history. Answers are kept
/// as question IDs and chosen indices; [review] matches them back to the
/// current question bank.
class SavedAttempt {
  SavedAttempt({
    required this.attemptId,
    required this.category,
    required this.score,
    required this.total,
    required this.questionSetVersion,
    required this.completedAt,
    required List<String> questionIds,
    required List<int> selectedIndices,
    this.topicId,
    this.mode = QuizMode.practice,
    this.timed = false,
  }) : questionIds = List.unmodifiable(questionIds),
       selectedIndices = List.unmodifiable(selectedIndices) {
    if (questionIds.length != selectedIndices.length) {
      throw ArgumentError('Each saved answer needs its question ID.');
    }
  }

  factory SavedAttempt.fromResult(QuizResult result) => SavedAttempt(
    attemptId: result.attemptId,
    category: result.category,
    topicId: result.topicId,
    mode: result.mode,
    timed: result.timed,
    score: result.score,
    total: result.total,
    questionSetVersion: result.questionSetVersion,
    completedAt: result.completedAt,
    questionIds: [for (final answer in result.answers) answer.question.id],
    selectedIndices: [
      for (final answer in result.answers) answer.selectedIndex,
    ],
  );

  final String attemptId;
  final QuizCategory category;
  final String? topicId;
  final QuizMode mode;
  final bool timed;
  final int score;
  final int total;
  final String questionSetVersion;
  final DateTime completedAt;
  final List<String> questionIds;
  final List<int> selectedIndices;

  double get accuracy => total == 0 ? 0 : score / total;

  /// Pairs each saved answer with its question. A question removed from the
  /// bank since this attempt yields null, so the review can say so instead
  /// of guessing.
  List<AnswerRecord?> review(List<Question> questions) {
    final byId = {for (final question in questions) question.id: question};
    return [
      for (final (i, id) in questionIds.indexed)
        switch (byId[id]) {
          final question?
              when selectedIndices[i] == AnswerRecord.timedOut ||
                  (selectedIndices[i] >= 0 &&
                      selectedIndices[i] < question.options.length) =>
            AnswerRecord(question: question, selectedIndex: selectedIndices[i]),
          _ => null,
        },
    ];
  }
}
