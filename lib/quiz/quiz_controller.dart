import 'dart:math';

import 'package:flutter/foundation.dart';

import 'models.dart';

/// Owns one quiz attempt: current question, selection, submissions, score,
/// completion and reset. All state is private; widgets observe it through
/// read-only getters and change it only through the guarded actions below.
class QuizController extends ChangeNotifier {
  QuizController({
    required this.category,
    required List<Question> questions,
    required this.questionSetVersion,
    this.topicId,
    this.mode = QuizMode.practice,
    this.timed = false,
    String? fixedAttemptId,
    String Function()? newAttemptId,
    DateTime Function()? clock,
  }) : questions = List.unmodifiable(questions),
       _answers = List.filled(questions.length, null),
       _newAttemptId = fixedAttemptId != null
           ? (() => fixedAttemptId)
           : newAttemptId ?? randomAttemptId,
       _clock = clock ?? DateTime.now {
    if (questions.isEmpty) {
      throw ArgumentError.value(questions, 'questions', 'must not be empty');
    }
    if (questions.any((question) => question.category != category)) {
      throw ArgumentError('Every question must belong to ${category.name}.');
    }
  }

  final QuizCategory category;
  final List<Question> questions;
  final String questionSetVersion;
  final String? topicId;
  final QuizMode mode;

  /// Timed mode only changes how the screen behaves; scoring is identical
  /// and a timeout simply records no answer.
  final bool timed;
  final String Function() _newAttemptId;
  final DateTime Function() _clock;

  /// The chosen option per question, null while unanswered and
  /// [AnswerRecord.timedOut] when the timer ran out. Nothing is scored or
  /// revealed until [finish].
  final List<int?> _answers;

  /// Timed mode only: questions that can no longer change (moved past, or
  /// their time ran out).
  final Set<int> _locked = {};
  int _index = 0;
  QuizResult? _result;

  int get index => _index;
  int get total => questions.length;
  Question get current => questions[_index];
  int? get selectedIndex => _answers[_index];
  bool get timedOut => selectedIndex == AnswerRecord.timedOut;
  bool get isAnswered => selectedIndex != null;
  bool get isLocked => _result != null || _locked.contains(_index);
  bool get isLastQuestion => _index == total - 1;
  int get answeredCount => _answers.where((answer) => answer != null).length;
  bool get allAnswered => !_answers.contains(null);
  int get score => [
    for (final (i, answer) in _answers.indexed)
      if (answer != null && questions[i].isCorrect(answer)) 1,
  ].length;

  /// Whether the user has started answering and would lose progress by leaving.
  bool get hasProgress => _result == null && answeredCount > 0;

  /// Untimed quizzes let players revisit earlier answers before submitting.
  bool get canGoBack => _result == null && !timed && _index > 0;
  bool get canAdvance => _result == null && isAnswered && !isLastQuestion;
  bool get canFinish => _result == null && allAnswered;
  QuizResult? get result => _result;

  /// Chooses or changes the answer to the current question.
  void select(int optionIndex) {
    if (isLocked) return;
    RangeError.checkValidIndex(optionIndex, current.options, 'optionIndex');
    if (_answers[_index] == optionIndex) return;
    _answers[_index] = optionIndex;
    notifyListeners();
  }

  /// The current question's time ran out: an unanswered question is
  /// recorded as no answer, and the question locks either way.
  void timeOut() {
    if (isLocked) return;
    _answers[_index] ??= AnswerRecord.timedOut;
    _locked.add(_index);
    notifyListeners();
  }

  void next() {
    if (!canAdvance) return;
    if (timed) _locked.add(_index);
    _index++;
    notifyListeners();
  }

  void previous() {
    if (!canGoBack) return;
    _index--;
    notifyListeners();
  }

  /// Completes the attempt once. Repeated calls return the same result and
  /// attempt ID, so a double tap cannot create a second attempt.
  QuizResult? finish() {
    if (_result != null) return _result;
    if (!canFinish) return null;
    _result = QuizResult(
      attemptId: _newAttemptId(),
      category: category,
      topicId: topicId,
      mode: mode,
      timed: timed,
      questionSetVersion: questionSetVersion,
      completedAt: _clock(),
      answers: [
        for (final (i, question) in questions.indexed)
          AnswerRecord(question: question, selectedIndex: _answers[i]!),
      ],
    );
    notifyListeners();
    return _result;
  }
}

final _random = Random.secure();
const _idAlphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

/// A 20-character random ID in the same shape Firestore generates.
String randomAttemptId() => String.fromCharCodes([
  for (var i = 0; i < 20; i++)
    _idAlphabet.codeUnitAt(_random.nextInt(_idAlphabet.length)),
]);
