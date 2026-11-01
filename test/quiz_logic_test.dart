import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_orbit/quiz/attempt_repository.dart';
import 'package:quiz_orbit/quiz/models.dart';
import 'package:quiz_orbit/quiz/question_repository.dart';
import 'package:quiz_orbit/quiz/quiz_controller.dart';

import 'support/quiz_fakes.dart';

QuizController controllerFor(QuizCategory category, {QuestionBank? bank}) {
  final source = bank ?? testBank();
  var next = 0;
  return QuizController(
    category: category,
    questions: source
        .questionsFor(category)
        .take(QuizFormat.questionsPerQuiz)
        .toList(),
    questionSetVersion: source.version,
    newAttemptId: () => 'attempt-${next++}',
  );
}

/// Answers every question, choosing the correct option when [correct] says so.
void play(QuizController quiz, bool Function(int index) correct) {
  for (var i = 0; i < quiz.total; i++) {
    final answer = quiz.current.correctIndex;
    quiz.select(correct(i) ? answer : (answer + 1) % 4);
    if (!quiz.isLastQuestion) quiz.next();
  }
}

void main() {
  group('bundled question bank', () {
    test('passes validation with 100+ questions per category', () {
      final bank = QuestionBank.fromJson(
        jsonDecode(File('assets/questions/questions.json').readAsStringSync()),
      );
      for (final category in QuizCategory.values) {
        final questions = bank.questionsFor(category);
        expect(questions.length, greaterThanOrEqualTo(100));
        expect(questions.every((q) => q.category == category), isTrue);
        final topics = bank.topicsFor(category);
        expect(topics.length, greaterThanOrEqualTo(3));
        for (final topic in topics) {
          expect(
            bank.questionsFor(category, topic: topic).length,
            greaterThanOrEqualTo(QuizFormat.questionsPerQuiz),
          );
        }
      }
    });
  });

  group('question validation rejects', () {
    Map<String, Object?> withFirst(Map<String, Object?> replacement) {
      final json = bankJson();
      (json['questions']! as List)[0] = replacement;
      return json;
    }

    final cases = <String, Object?>{
      'non-object data': [],
      'missing version': {'questions': []},
      'an empty question list': {'version': 'v', 'questions': []},
      'an unknown category': withFirst(questionJson('anime-0', 'music')),
      'an out-of-range answer index': withFirst(
        questionJson('anime-0', 'anime', correctIndex: 4),
      ),
      'a negative answer index': withFirst(
        questionJson('anime-0', 'anime', correctIndex: -1),
      ),
      'three options': withFirst(
        questionJson('anime-0', 'anime', options: ['A', 'B', 'C']),
      ),
      'duplicate options': withFirst(
        questionJson('anime-0', 'anime', options: ['A', 'B', 'C', 'a']),
      ),
      'a blank option': withFirst(
        questionJson('anime-0', 'anime', options: ['A', 'B', 'C', ' ']),
      ),
      'a blank prompt': withFirst({
        ...questionJson('anime-0', 'anime'),
        'prompt': '',
      }),
      'a duplicate ID': withFirst(questionJson('anime-1', 'anime')),
      'a category short of questions': {
        ...bankJson(),
        'questions': (bankJson()['questions']! as List).skip(1).toList(),
      },
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      test(key, () {
        expect(
          () => QuestionBank.fromJson(value),
          throwsA(isA<QuestionDataException>()),
        );
      });
    }
  });

  group('QuizController', () {
    test('scores all-right, all-wrong and mixed attempts', () {
      for (final (pattern, expected) in [
        ((int i) => true, 10),
        ((int i) => false, 0),
        ((int i) => i.isEven, 5),
      ]) {
        final quiz = controllerFor(QuizCategory.anime);
        play(quiz, pattern);
        final result = quiz.finish()!;
        expect((result.score, result.total), (expected, 10));
      }
    });

    test('cannot move on or submit without answering', () {
      final quiz = controllerFor(QuizCategory.anime);
      quiz.next();
      expect((quiz.index, quiz.canAdvance, quiz.canFinish), (0, false, false));
    });

    test('answers stay changeable, also after going back, until submitted', () {
      final quiz = controllerFor(QuizCategory.anime);
      quiz
        ..select(1)
        ..select(0);
      expect(quiz.selectedIndex, 0);
      quiz
        ..next()
        ..select(3)
        ..previous();
      expect((quiz.index, quiz.selectedIndex), (0, 0));
      quiz.select(2);
      expect(quiz.selectedIndex, 2);
      play(quiz, (_) => true);
      quiz.finish();
      quiz.select(1);
      expect(
        quiz.result!.answers.last.selectedIndex,
        quiz.current.correctIndex,
      );
    });

    test('a rapid double Next advances only one answered question', () {
      final quiz = controllerFor(QuizCategory.anime)
        ..select(0)
        ..next()
        ..next();
      expect(quiz.index, 1, reason: 'Next needs an answer each time');
    });

    test('the score is only exposed through the result after submitting', () {
      final quiz = controllerFor(QuizCategory.anime);
      play(quiz, (_) => true);
      expect(quiz.result, isNull);
      expect(quiz.finish()!.score, 10);
    });

    test('the last question finishes instead of advancing past the end', () {
      final quiz = controllerFor(QuizCategory.sports);
      play(quiz, (_) => true);
      expect(quiz.isLastQuestion, isTrue);
      quiz.next();
      expect(quiz.index, quiz.total - 1);
      expect(quiz.canFinish, isTrue);
    });

    test('finish needs every answer and is idempotent', () {
      final quiz = controllerFor(QuizCategory.anime);
      expect(quiz.finish(), isNull);
      play(quiz, (_) => true);
      final first = quiz.finish();
      final second = quiz.finish();
      expect(identical(first, second), isTrue);
      expect(first!.attemptId, 'attempt-0');
      quiz.select(0);
      expect(quiz.hasProgress, isFalse);
    });

    test('categories are isolated attempts', () {
      final anime = controllerFor(QuizCategory.anime);
      final sports = controllerFor(QuizCategory.sports);
      anime.select(anime.current.correctIndex);
      expect((sports.score, sports.answeredCount), (0, 0));
      expect(
        () => QuizController(
          category: QuizCategory.sports,
          questions: testBank().questionsFor(QuizCategory.anime),
          questionSetVersion: 'v',
        ),
        throwsArgumentError,
      );
    });

    test('result answer lists cannot be edited from outside', () {
      final quiz = controllerFor(QuizCategory.anime);
      play(quiz, (_) => true);
      final result = quiz.finish()!;
      expect(() => result.answers.clear(), throwsUnsupportedError);
      expect(() => quiz.questions.clear(), throwsUnsupportedError);
    });

    test('generated attempt IDs are distinct', () {
      final ids = {for (var i = 0; i < 200; i++) randomAttemptId()};
      expect(ids, hasLength(200));
    });
  });

  group('AttemptSaver', () {
    QuizResult finished() {
      final quiz = controllerFor(QuizCategory.sports);
      play(quiz, (i) => i < 7);
      return quiz.finish()!;
    }

    test('reports saved only after the write is acknowledged', () async {
      final repository = FakeAttemptRepository()..pending = Completer();
      final saver = AttemptSaver(
        result: finished(),
        repository: repository,
        ownerId: 'user-a',
      );
      expect(saver.status, SaveStatus.saving);
      await pumpEventQueue();
      expect(saver.status, SaveStatus.saving);
      repository.pending!.complete();
      await pumpEventQueue();
      expect(saver.status, SaveStatus.saved);
      expect(repository.records['user-a']!.values.single.score, 7);
    });

    test(
      'a failed save keeps the result and retries with the same ID',
      () async {
        final repository = FakeAttemptRepository()..fail = true;
        final result = finished();
        final saver = AttemptSaver(
          result: result,
          repository: repository,
          ownerId: 'user-a',
        );
        await pumpEventQueue();
        expect(saver.status, SaveStatus.failed);
        expect(saver.result.score, 7);
        repository.fail = false;
        saver
          ..retry()
          ..retry();
        await pumpEventQueue();
        expect(saver.status, SaveStatus.saved);
        expect(repository.calls.map((c) => c.attemptId).toSet(), {
          result.attemptId,
        });
        expect(repository.calls, hasLength(2));
        expect(repository.records['user-a'], hasLength(1));
      },
    );

    test('an owned save cannot be claimed by another account', () async {
      final repository = FakeAttemptRepository()..fail = true;
      final saver = AttemptSaver(
        result: finished(),
        repository: repository,
        ownerId: 'user-a',
      );
      await pumpEventQueue();
      repository.fail = false;
      saver
        ..claim('user-b')
        ..retry();
      await pumpEventQueue();
      expect(repository.records.keys, ['user-a']);
    });

    test(
      'a signed-out result waits, then saves for whoever signs in',
      () async {
        final repository = FakeAttemptRepository();
        final saver = AttemptSaver(result: finished(), repository: repository);
        expect(saver.status, SaveStatus.signedOut);
        expect(repository.calls, isEmpty);
        saver
          ..claim('user-b')
          ..claim('user-c');
        await pumpEventQueue();
        expect(saver.status, SaveStatus.saved);
        expect(repository.records.keys, ['user-b']);
      },
    );

    test('a second daily attempt says already played, not retry', () async {
      final repository = FakeAttemptRepository();
      QuizResult daily() {
        final quiz = QuizController(
          category: QuizCategory.anime,
          questions: testBank()
              .questionsFor(QuizCategory.anime)
              .take(QuizFormat.questionsPerQuiz)
              .toList(),
          questionSetVersion: 'v',
          mode: QuizMode.daily,
          fixedAttemptId: 'daily-anime-20261101',
        );
        play(quiz, (_) => true);
        return quiz.finish()!;
      }

      AttemptSaver(result: daily(), repository: repository, ownerId: 'user-a');
      await pumpEventQueue();
      final second = AttemptSaver(
        result: daily(),
        repository: repository,
        ownerId: 'user-a',
      );
      await pumpEventQueue();
      expect(second.status, SaveStatus.alreadyPlayed);
      second.retry();
      expect(second.status, SaveStatus.alreadyPlayed);
      expect(repository.records['user-a'], hasLength(1));
    });

    test('is truthful when storage is unavailable', () {
      final saver = AttemptSaver(result: finished(), repository: null)
        ..claim('user-a');
      expect(saver.status, SaveStatus.unavailable);
    });
  });
}
