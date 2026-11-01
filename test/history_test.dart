import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_orbit/firebase/firestore_attempt_repository.dart';
import 'package:quiz_orbit/foundation/components.dart';
import 'package:quiz_orbit/main.dart';
import 'package:quiz_orbit/quiz/history_screen.dart';
import 'package:quiz_orbit/quiz/models.dart';
import 'package:quiz_orbit/quiz/quiz_controller.dart';

import 'support/app.dart';
import 'support/fonts.dart';
import 'support/quiz_fakes.dart';

QuizResult finished(QuizCategory category, {int right = 7}) {
  final bank = testBank();
  final quiz = QuizController(
    category: category,
    questions: bank
        .questionsFor(category)
        .take(QuizFormat.questionsPerQuiz)
        .toList(),
    questionSetVersion: bank.version,
  );
  for (var i = 0; i < quiz.total; i++) {
    final answer = quiz.current.correctIndex;
    quiz.select(i < right ? answer : (answer + 1) % 4);
    if (!quiz.isLastQuestion) quiz.next();
  }
  return quiz.finish()!;
}

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadOrbitFonts);

  group('Firestore record', () {
    test('round-trips a completed attempt with its answers', () {
      final result = finished(QuizCategory.anime);
      final record = FirestoreAttemptRepository.toRecord(result);
      expect(record.keys.toSet(), {
        'categoryId',
        'topicId',
        'mode',
        'timed',
        'score',
        'total',
        'questionSetVersion',
        'completedAt',
        'questionIds',
        'selectedIndices',
      });
      final saved = FirestoreAttemptRepository.fromRecord(
        result.attemptId,
        record,
      )!;
      expect(
        (saved.score, saved.total, saved.category),
        (7, 10, QuizCategory.anime),
      );
      final review = saved.review(testBank().questionsFor(QuizCategory.anime));
      expect(review.where((answer) => answer!.isCorrect), hasLength(7));
    });

    test('skips records the app cannot read instead of failing', () {
      final good = FirestoreAttemptRepository.toRecord(
        finished(QuizCategory.sports),
      );
      for (final bad in [
        {...good, 'categoryId': 'music'},
        {...good, 'score': '7'},
        {...good, 'completedAt': '2026-11-01'},
        {
          ...good,
          'selectedIndices': ['a'],
        },
        {
          ...good,
          'questionIds': ['x'],
        },
        <String, dynamic>{},
      ]) {
        expect(FirestoreAttemptRepository.fromRecord('id', bad), isNull);
      }
      expect(
        FirestoreAttemptRepository.fromRecord('id', {
          ...good,
          'completedAt': Timestamp.now(),
        }),
        isNotNull,
      );
    });
  });

  test('review marks questions that have left the bank', () {
    final saved = SavedAttempt.fromResult(finished(QuizCategory.anime));
    final remaining = testBank()
        .questionsFor(QuizCategory.anime)
        .skip(1)
        .toList();
    final review = saved.review(remaining);
    expect(review.first, isNull);
    expect(review.skip(1).every((answer) => answer != null), isTrue);
  });

  group('history screens', () {
    setUp(() {
      TestWidgetsFlutterBinding
          .instance
          .platformDispatcher
          .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
    });
    tearDown(
      () => TestWidgetsFlutterBinding.instance.platformDispatcher
          .clearAccessibilityFeaturesTestValue(),
    );

    testWidgets('signed-in players filter and review their attempts', (
      tester,
    ) async {
      final attempts = FakeAttemptRepository();
      for (final result in [
        finished(QuizCategory.anime, right: 9),
        finished(QuizCategory.sports, right: 4),
      ]) {
        await attempts.save(ownerId: 'user-a', result: result);
      }
      await tester.pumpWidget(
        MainApp(
          services: testServices(
            attempts: attempts,
            account: FakeAccountSession(uid: 'user-a'),
          ),
        ),
      );
      await tapText(tester, 'user-a'); // opens the account menu
      await tapText(tester, 'Your attempts');
      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.text('9/10'), findsOneWidget);
      expect(find.text('4/10'), findsOneWidget);
      await tester.tap(find.widgetWithText(OrbitChip, 'Sports'));
      await tester.pumpAndSettle();
      expect(find.text('9/10'), findsNothing);
      await tester.tap(find.text('4/10'));
      await tester.pumpAndSettle();
      expect(find.text('Sports review'), findsOneWidget);
      expect(find.bySemanticsLabel('Score: 4 out of 10'), findsOneWidget);
      expect(find.textContaining('You chose'), findsNWidgets(6));
    });

    testWidgets('history shows empty and error states truthfully', (
      tester,
    ) async {
      final attempts = FakeAttemptRepository();
      Widget screen() => testApp(
        services: testServices(attempts: attempts),
        home: const HistoryScreen(ownerId: 'user-a'),
      );
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text('Nothing here yet.'), findsOneWidget);

      attempts.historyFailure = StateError('offline');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text('History didn’t load.'), findsOneWidget);
      attempts.historyFailure = null;
      await tapText(tester, 'Try again');
      expect(find.text('Nothing here yet.'), findsOneWidget);
    });

    testWidgets('a saved result links straight to the history', (tester) async {
      final attempts = FakeAttemptRepository();
      await tester.pumpWidget(
        MainApp(
          services: testServices(
            attempts: attempts,
            account: FakeAccountSession(uid: 'user-a'),
          ),
        ),
      );
      await tapText(tester, 'Explore Anime');
      await tapText(tester, 'Start Anime quiz');
      const options = ['Alpha', 'Bravo', 'Charlie', 'Delta'];
      for (var i = 0; i < 10; i++) {
        await tapText(tester, options[i % 4]);
        if (i == 9) {
          await submitQuiz(tester);
        } else {
          await tapText(tester, 'Next question');
        }
      }
      await tapText(tester, 'See all your attempts');
      expect(find.text('Anime'), findsWidgets);
      expect(find.text('10/10'), findsOneWidget);
    });
  });
}
