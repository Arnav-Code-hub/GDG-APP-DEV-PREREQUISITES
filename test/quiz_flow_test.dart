import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_orbit/account/account_session.dart';
import 'package:quiz_orbit/main.dart';
import 'package:quiz_orbit/quiz/models.dart';
import 'package:quiz_orbit/quiz/question_repository.dart';
import 'package:quiz_orbit/quiz/quiz_screen.dart';

import 'support/app.dart';
import 'support/fonts.dart';
import 'support/quiz_fakes.dart';

const _options = ['Alpha', 'Bravo', 'Charlie', 'Delta'];

Future<void> pumpQuiz(
  WidgetTester tester, {
  QuizCategory category = QuizCategory.anime,
  FakeAttemptRepository? attempts,
  FakeQuestionRepository? questions,
  FakeAccountSession? account,
}) async {
  await tester.pumpWidget(
    testApp(
      services: testServices(
        questions: questions,
        attempts: attempts,
        account: account ?? FakeAccountSession(uid: 'user-a'),
      ),
      home: QuizScreen(setup: QuizSetup(category: category)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Plays the current question; in the test bank question i's answer is i % 4.
Future<void> answer(
  WidgetTester tester,
  int index, {
  required bool right,
}) async {
  await tapText(tester, _options[right ? index % 4 : (index + 1) % 4]);
  if (index == QuizFormat.questionsPerQuiz - 1) {
    await submitQuiz(tester);
  } else {
    await tapText(tester, 'Next question');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadOrbitFonts);
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

  testWidgets('a category starts from the landing page and plays to a score', (
    tester,
  ) async {
    final questions = FakeQuestionRepository(() async => testBank());
    await tester.pumpWidget(
      MainApp(services: testServices(questions: questions)),
    );
    await tapText(tester, 'Explore Sports');
    await tapText(tester, 'Start Sports quiz');
    expect(find.text('Prompt for sports-0?'), findsOneWidget);
    for (var i = 0; i < 10; i++) {
      await answer(tester, i, right: i < 6);
    }
    expect(find.bySemanticsLabel('Score: 6 out of 10'), findsOneWidget);
    final missed = find.ancestor(
      of: find.text('Missed'),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(of: missed.first, matching: find.text('4')),
      findsOneWidget,
    );
    expect(
      find.textContaining('isn’t connected in this build'),
      findsOneWidget,
      reason: 'Without storage the result must not claim it was saved',
    );
    await tapText(tester, 'Choose another category');
    expect(find.text('Choose your category.'), findsOneWidget);
  });

  testWidgets('nothing is judged until the whole quiz is submitted', (
    tester,
  ) async {
    await pumpQuiz(tester);
    final action = find.widgetWithText(FilledButton, 'Choose an answer');
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
    await tapText(tester, 'Charlie');
    await tapText(tester, 'Bravo');
    expect(find.textContaining('Correct'), findsNothing);
    expect(find.textContaining('The answer is'), findsNothing);
    await tapText(tester, 'Next question');
    expect(find.text('Prompt for anime-1?'), findsOneWidget);
    expect(find.text('Question 2 of 10'), findsOneWidget);

    // Go back and change the first answer before submitting.
    await tester.tap(find.byTooltip('Previous question'));
    await tester.pumpAndSettle();
    expect(find.text('Prompt for anime-0?'), findsOneWidget);
    await tapText(tester, 'Alpha');
    await tapText(tester, 'Next question');
    for (var i = 1; i < 10; i++) {
      await answer(tester, i, right: true);
    }
    expect(find.bySemanticsLabel('Score: 10 out of 10'), findsOneWidget);
    expect(find.textContaining('Explanation for anime-0'), findsOneWidget);
  });

  testWidgets('the submit dialog can return to the answers', (tester) async {
    final attempts = FakeAttemptRepository();
    await pumpQuiz(tester, attempts: attempts);
    for (var i = 0; i < 9; i++) {
      await answer(tester, i, right: true);
    }
    await tapText(tester, 'Alpha');
    await tester.tap(find.widgetWithText(FilledButton, 'Submit quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Submit your answers?'), findsOneWidget);
    await tapText(tester, 'Review answers');
    expect(find.text('Prompt for anime-9?'), findsOneWidget);
    expect(attempts.calls, isEmpty, reason: 'nothing is saved before submit');
  });

  testWidgets('a rapid double tap on Next advances only one question', (
    tester,
  ) async {
    await pumpQuiz(tester);
    await tapText(tester, 'Alpha');
    final next = find.text('Next question');
    await tester.tap(next);
    await tester.tap(next, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Prompt for anime-1?'), findsOneWidget);
  });

  testWidgets('leaving mid-quiz asks first and writes nothing', (tester) async {
    final attempts = FakeAttemptRepository();
    await tester.pumpWidget(
      testApp(
        services: testServices(attempts: attempts),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(quizRoute(const QuizSetup(category: QuizCategory.anime))),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tapText(tester, 'open');
    await answer(tester, 0, right: true);
    await tester.tap(find.byTooltip('Leave quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Leave this quiz?'), findsOneWidget);
    await tapText(tester, 'Keep playing');
    expect(find.text('Prompt for anime-1?'), findsOneWidget);

    // System back is guarded the same way.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tapText(tester, 'Discard and leave');
    expect(find.text('open'), findsOneWidget);
    expect(attempts.calls, isEmpty);
  });

  testWidgets('a failed save keeps the score and retries the same attempt', (
    tester,
  ) async {
    final attempts = FakeAttemptRepository()..fail = true;
    await pumpQuiz(tester, attempts: attempts);
    for (var i = 0; i < 10; i++) {
      await answer(tester, i, right: true);
    }
    expect(find.text('Couldn’t save'), findsOneWidget);
    expect(find.bySemanticsLabel('Score: 10 out of 10'), findsOneWidget);
    attempts.fail = false;
    await tapText(tester, 'Retry save');
    expect(find.text('Saved'), findsOneWidget);
    expect(attempts.records['user-a'], hasLength(1));
    expect(attempts.calls.map((c) => c.attemptId).toSet(), hasLength(1));
  });

  testWidgets('signing out before a retry keeps the original owner', (
    tester,
  ) async {
    final attempts = FakeAttemptRepository()..fail = true;
    final account = FakeAccountSession(uid: 'user-a');
    await pumpQuiz(tester, attempts: attempts, account: account);
    for (var i = 0; i < 10; i++) {
      await answer(tester, i, right: i.isOdd);
    }
    expect(find.text('Couldn’t save'), findsOneWidget);
    // Switch accounts while the save is still unsaved.
    await account.signOut();
    account.nextUid = 'user-b';
    await account.signIn();
    attempts.fail = false;
    await tapText(tester, 'Retry save');
    expect(attempts.records.keys, ['user-a']);
  });

  testWidgets('a signed-out result can be saved by signing in on Results', (
    tester,
  ) async {
    final attempts = FakeAttemptRepository();
    final account = FakeAccountSession(nextUid: 'user-b');
    await pumpQuiz(tester, attempts: attempts, account: account);
    for (var i = 0; i < 10; i++) {
      await answer(tester, i, right: true);
    }
    expect(find.textContaining('weren’t signed in'), findsOneWidget);
    expect(attempts.calls, isEmpty);
    await tapText(tester, 'Sign in to save');
    expect(find.text('Saved'), findsOneWidget);
    expect(attempts.records['user-b'], hasLength(1));
  });

  testWidgets('landing sign-in handles success, cancel and failure', (
    tester,
  ) async {
    final account = FakeAccountSession(nextUid: null);
    await tester.pumpWidget(MainApp(services: testServices(account: account)));
    await tapText(tester, 'Sign in with Google');
    expect(find.text('Sign in with Google'), findsOneWidget, reason: 'cancel');
    account.failure = const SignInException(SignInFailure.network);
    await tapText(tester, 'Sign in with Google');
    expect(
      find.text('No connection. Check your network and try again.'),
      findsOneWidget,
    );
    account
      ..failure = null
      ..nextUid = 'Ada';
    await tapText(tester, 'Sign in with Google');
    expect(find.text('Ada'), findsOneWidget);
    await tapText(tester, 'Ada'); // opens the account menu
    await tapText(tester, 'Sign out');
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('try again starts clean and saves a separate attempt', (
    tester,
  ) async {
    final attempts = FakeAttemptRepository();
    await pumpQuiz(tester, attempts: attempts);
    for (var i = 0; i < 10; i++) {
      await answer(tester, i, right: true);
    }
    expect(find.text('Saved'), findsOneWidget);
    await tapText(tester, 'Try again');
    expect(find.text('Question 1 of 10'), findsOneWidget);
    expect(find.text('Choose an answer'), findsOneWidget);
    for (var i = 0; i < 10; i++) {
      await answer(tester, i, right: false);
    }
    expect(find.bySemanticsLabel('Score: 0 out of 10'), findsOneWidget);
    expect(attempts.records['user-a'], hasLength(2));
  });

  testWidgets('a loading failure shows an error with a working retry', (
    tester,
  ) async {
    var broken = true;
    final questions = FakeQuestionRepository(() async {
      if (broken) throw const QuestionDataException('bad data');
      return testBank();
    });
    await pumpQuiz(tester, questions: questions);
    expect(find.text('Questions didn’t load.'), findsOneWidget);
    broken = false;
    await tapText(tester, 'Try again');
    expect(find.text('Prompt for anime-0?'), findsOneWidget);
    expect(questions.loads, 2);
  });

  testWidgets('the bundled question file plays in the real app', (
    tester,
  ) async {
    // Assets over 50 KB decode on a background isolate, which only runs
    // outside the test's fake clock.
    final bank = (await tester.runAsync(
      () => const AssetQuestionRepository().load(),
    ))!;
    await pumpQuiz(tester, questions: FakeQuestionRepository(() async => bank));
    expect(find.textContaining('Nine-Tailed Fox'), findsOneWidget);
  });

  testWidgets('taps during a question fade still score correctly', (
    tester,
  ) async {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
    final attempts = FakeAttemptRepository();
    await tester.pumpWidget(
      testApp(
        services: testServices(attempts: attempts),
        home: const QuizScreen(setup: QuizSetup(category: QuizCategory.anime)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 0; i < 10; i++) {
      // Each tap lands 50 ms into the 200 ms fade of a new question.
      await tester.ensureVisible(find.text(_options[i % 4]));
      await tester.tap(find.text(_options[i % 4]));
      await tester.pump();
      await tester.tap(find.text(i == 9 ? 'Submit quiz' : 'Next question'));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Submit quiz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // The spoken score is complete before the 600 ms reveal finishes.
    expect(find.bySemanticsLabel('Score: 10 out of 10'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(attempts.records['user-a']!.values.single.score, 10);
  });

  for (final size in [const Size(320, 640), const Size(844, 390)]) {
    testWidgets('quiz and results fit $size at 2x text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        testApp(
          services: testServices(
            attempts: FakeAttemptRepository()..fail = true,
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const QuizScreen(
            setup: QuizSetup(category: QuizCategory.anime),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Alpha');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tapText(tester, 'Next question');
      // Previous and Next share the pinned bar at 2x text.
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      for (var i = 1; i < 10; i++) {
        await answer(tester, i, right: true);
      }
      await tester.ensureVisible(find.text('Retry save'));
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  }
}
