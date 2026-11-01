import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_orbit/app/device_services.dart';
import 'package:quiz_orbit/app/settings.dart';
import 'package:quiz_orbit/foundation/ambient_background.dart';
import 'package:quiz_orbit/firebase/firestore_attempt_repository.dart';
import 'package:quiz_orbit/main.dart';
import 'package:quiz_orbit/quiz/models.dart';
import 'package:quiz_orbit/quiz/question_repository.dart';
import 'package:quiz_orbit/quiz/quiz_controller.dart';
import 'package:quiz_orbit/quiz/quiz_picker.dart';
import 'package:quiz_orbit/quiz/quiz_screen.dart';
import 'package:quiz_orbit/quiz/report_repository.dart';
import 'package:quiz_orbit/quiz/stats.dart';

import 'support/app.dart';
import 'support/fonts.dart';
import 'support/quiz_fakes.dart';

const _options = ['Alpha', 'Bravo', 'Charlie', 'Delta'];

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Plays ten in-order test questions, answering correctly when [right] says.
Future<void> playTen(WidgetTester tester, bool Function(int) right) async {
  for (var i = 0; i < 10; i++) {
    await tapText(tester, _options[right(i) ? i % 4 : (i + 1) % 4]);
    if (i == 9) {
      await submitQuiz(tester);
    } else {
      await tapText(tester, 'Next question');
    }
  }
}

SavedAttempt saved(DateTime at, {int score = 5, QuizCategory? category}) =>
    SavedAttempt(
      attemptId: 'a${at.millisecondsSinceEpoch}',
      category: category ?? QuizCategory.anime,
      score: score,
      total: 10,
      questionSetVersion: 'v',
      completedAt: at,
      questionIds: List.filled(10, 'q'),
      selectedIndices: List.filled(10, 0),
    );

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

  group('picker', () {
    final pool = testBank().questionsFor(QuizCategory.anime);

    test('practice draws ten distinct questions from the pool', () {
      final picked = QuizPicker.practice(pool);
      expect(picked, hasLength(10));
      expect(picked.map((q) => q.id).toSet(), hasLength(10));
      expect(picked.every(pool.contains), isTrue);
    });

    test('daily is the same set for the same day, whatever the order', () {
      final day = DateTime(2026, 11, 1);
      final a = QuizPicker.daily(pool, QuizCategory.anime, day);
      final b = QuizPicker.daily(
        pool.reversed.toList(),
        QuizCategory.anime,
        day,
      );
      expect(a.map((q) => q.id), b.map((q) => q.id));
      final tomorrow = QuizPicker.daily(
        pool,
        QuizCategory.anime,
        DateTime(2026, 11, 2),
      );
      expect(tomorrow.map((q) => q.id), isNot(a.map((q) => q.id)));
      expect(a.map((q) => q.id).toSet(), hasLength(10));
    });

    test('daily attempt IDs are fixed per category and day', () {
      expect(
        dailyAttemptId(QuizCategory.sports, DateTime(2026, 1, 9)),
        'daily-sports-20260109',
      );
    });
  });

  group('topics and published content', () {
    test('rejects a topic with fewer than ten questions', () {
      final json = bankJson();
      (json['questions']! as List).removeAt(0);
      expect(
        () => QuestionBank.fromJson(json),
        throwsA(isA<QuestionDataException>()),
      );
    });

    test('rejects a question whose topic belongs to another category', () {
      final json = bankJson();
      (json['questions']! as List)[0] = questionJson(
        'anime-0',
        'anime',
        topic: 'sports-a',
      );
      expect(
        () => QuestionBank.fromJson(json),
        throwsA(isA<QuestionDataException>()),
      );
    });

    test('topic filtering only returns that topic', () {
      final bank = testBank();
      final topic = bank.topicsFor(QuizCategory.sports).last;
      final questions = bank.questionsFor(QuizCategory.sports, topic: topic);
      expect(questions, hasLength(10));
      expect(questions.every((q) => q.topicId == topic.id), isTrue);
    });

    Future<String> chosen(Future<QuestionBank?> Function() remote) =>
        LayeredQuestionRepository(
          bundled: FakeQuestionRepository(
            () async =>
                QuestionBank.fromJson(bankJson(version: '2026-11-01.2')),
          ),
          remote: _Remote(remote),
        ).load().then((bank) => bank.version);

    test(
      'a newer published bank wins; older, missing or failing does not',
      () async {
        expect(
          await chosen(
            () async =>
                QuestionBank.fromJson(bankJson(version: '2026-11-01.10')),
          ),
          '2026-11-01.10',
        );
        expect(
          await chosen(
            () async =>
                QuestionBank.fromJson(bankJson(version: '2026-10-01.9')),
          ),
          '2026-11-01.2',
        );
        expect(await chosen(() async => null), '2026-11-01.2');
        expect(await chosen(() => Future.error('offline')), '2026-11-01.2');
      },
    );

    test('old saved records without topic or mode read as practice', () {
      final record = FirestoreAttemptRepository.toRecord(
        QuizResult(
          attemptId: 'x',
          category: QuizCategory.anime,
          questionSetVersion: 'v',
          completedAt: DateTime(2026),
          answers: [],
        ),
      )..removeWhere((k, _) => ['topicId', 'mode', 'timed'].contains(k));
      record['completedAt'] = Timestamp.now();
      final attempt = FirestoreAttemptRepository.fromRecord('id', record)!;
      expect(
        (attempt.mode, attempt.timed, attempt.topicId),
        (QuizMode.practice, false, null),
      );
    });
  });

  group('timer', () {
    QuizController quiz() => QuizController(
      category: QuizCategory.anime,
      questions: inOrder(testBank().questionsFor(QuizCategory.anime)),
      questionSetVersion: 'v',
      timed: true,
    );

    test('a timeout records no answer and keeps a real one, then locks', () {
      final q = quiz()..timeOut();
      expect((q.isLocked, q.timedOut, q.score), (true, true, 0));
      q
        ..select(2)
        ..next()
        ..select(1)
        ..timeOut()
        ..select(3);
      expect((q.timedOut, q.selectedIndex, q.score), (false, 1, 1));
      expect(q.canGoBack, isFalse, reason: 'timed answers are final');
    });

    testWidgets('timed mode locks an unanswered question after 20 s', (
      tester,
    ) async {
      final attempts = FakeAttemptRepository();
      await tester.pumpWidget(
        testApp(
          services: testServices(attempts: attempts),
          home: const QuizScreen(
            setup: QuizSetup(category: QuizCategory.anime, timed: true),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('20s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 19));
      expect(find.text('Prompt for anime-0?'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      // Time ran out: recorded as no answer and the quiz moves on.
      expect(find.text('Prompt for anime-1?'), findsOneWidget);
      expect(find.byTooltip('Previous question'), findsNothing);
    });
  });

  group('daily challenge', () {
    testWidgets('plays once a day and then offers review instead', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final attempts = FakeAttemptRepository();
      await tester.pumpWidget(
        MainApp(
          services: testServices(
            attempts: attempts,
            account: FakeAccountSession(uid: 'user-a'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Play today’s Anime');
      // Answer whatever the daily set contains, always choosing option A.
      for (var i = 0; i < 10; i++) {
        await tapText(tester, 'Alpha');
        if (i == 9) {
          await submitQuiz(tester);
        } else {
          await tapText(tester, 'Next question');
        }
      }
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Play a practice quiz'), findsOneWidget);
      final now = DateTime.now();
      final id = dailyAttemptId(
        QuizCategory.anime,
        DateTime(now.year, now.month, now.day),
      );
      expect(attempts.records['user-a']!.keys, [id]);
      expect(attempts.records['user-a']![id]!.mode, QuizMode.daily);

      await tapText(tester, 'Choose another category');
      expect(find.textContaining('Done today'), findsOneWidget);
      expect(find.text('Play today’s Anime'), findsNothing);
      expect(find.text('Play today’s Sports'), findsOneWidget);
    });
  });

  group('stats', () {
    test(
      'streaks count consecutive days and survive until a day is missed',
      () {
        final now = DateTime(2026, 11, 10, 9);
        final stats = PlayerStats.from([
          saved(DateTime(2026, 11, 9, 20), score: 10),
          saved(DateTime(2026, 11, 8, 8), score: 6),
          saved(DateTime(2026, 11, 8, 18), score: 4),
          saved(
            DateTime(2026, 11, 7, 12),
            score: 8,
            category: QuizCategory.sports,
          ),
          saved(DateTime(2026, 11, 1, 12), score: 2),
        ], now: now);
        expect(stats.currentStreak, 3, reason: 'played 7th–9th, not yet today');
        expect(stats.bestStreak, 3);
        expect(stats.attempts, 5);
        expect(stats.accuracy, closeTo(30 / 50, 1e-9));
        expect(stats.byCategory[QuizCategory.anime]!.bestScore, 10);
        expect(stats.byCategory[QuizCategory.sports]!.attempts, 1);
        expect(stats.recent.first.score, 2, reason: 'oldest first');
        expect(
          PlayerStats.from([
            saved(DateTime(2026, 11, 7)),
          ], now: now).currentStreak,
          0,
        );
      },
    );
  });

  group('reporting, sharing and feedback', () {
    testWidgets('a signed-in player reports a question once', (tester) async {
      final reports = FakeReportRepository();
      final feedback = RecordingFeedback();
      final sharer = FakeSharer();
      await tester.pumpWidget(
        testApp(
          services: testServices(
            attempts: FakeAttemptRepository(),
            reports: reports,
            feedback: feedback,
            sharer: sharer,
          ),
          home: const QuizScreen(
            setup: QuizSetup(category: QuizCategory.anime),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Bravo');
      await tapText(tester, 'Alpha');
      expect(feedback.events, ['select', 'select']);
      await tapText(tester, 'Next question');
      for (var i = 1; i < 10; i++) {
        await tapText(tester, _options[i % 4]);
        if (i == 9) {
          await submitQuiz(tester);
        } else {
          await tapText(tester, 'Next question');
        }
      }
      expect(feedback.events.last, 'good');

      await tapText(tester, 'Report this question');
      final send = find.widgetWithText(FilledButton, 'Send report');
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      await tapText(tester, 'The answer is wrong');
      await tester.enterText(find.byType(TextField), '  Typo in option B  ');
      await tapText(tester, 'Send report');
      expect(find.text('Thanks. We’ll check this question.'), findsOneWidget);
      final report = reports.sent.single;
      expect(report.ownerId, 'user-a');
      expect(report.report.questionId, 'anime-0');
      expect(report.report.reason, ReportReason.wrongAnswer);
      expect(report.report.note, 'Typo in option B');
    });

    testWidgets('signed-out players are asked to sign in to report', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          services: testServices(
            reports: FakeReportRepository(),
            account: FakeAccountSession(),
          ),
          home: const QuizScreen(
            setup: QuizSetup(category: QuizCategory.anime),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 10; i++) {
        await tapText(tester, _options[i % 4]);
        if (i == 9) {
          await submitQuiz(tester);
        } else {
          await tapText(tester, 'Next question');
        }
      }
      await tapText(tester, 'Report this question');
      expect(find.text('Sign in to report a question.'), findsOneWidget);
      expect(find.text('Send report'), findsNothing);
    });

    testWidgets('the result card is shared as an image with a caption', (
      tester,
    ) async {
      final sharer = FakeSharer();
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testApp(
            services: testServices(sharer: sharer),
            home: const QuizScreen(
              setup: QuizSetup(category: QuizCategory.sports),
            ),
          ),
        );
      });
      await tester.pumpAndSettle();
      await playTen(tester, (i) => i < 7);
      await tester.ensureVisible(find.text('Share result'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Share result'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      expect(sharer.shared, hasLength(1));
      expect(sharer.shared.single.bytes, greaterThan(1000));
      expect(sharer.shared.single.text, contains('7/10 in Sports'));
    });
  });

  group('ambient background', () {
    Widget field({bool tickers = true}) => TickerMode(
      enabled: tickers,
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: AmbientBackground(child: SizedBox.expand()),
      ),
    );

    testWidgets('stays still under reduced motion', (tester) async {
      await tester.pumpWidget(field());
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('moves normally and stops when tickers are off', (
      tester,
    ) async {
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pumpWidget(field());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(field(tickers: false));
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('account on phones', () {
    for (final (width, scale) in [(390.0, 1.0), (320.0, 2.0)]) {
      testWidgets('the name is never cut off at ${width}px, ${scale}x text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, 844),
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: MainApp(
              services: testServices(
                attempts: FakeAttemptRepository(),
                account: FakeAccountSession(uid: 'Arnav Sharma'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Arnav Sharma'), findsNothing, reason: 'avatar only');
        await tester.tap(find.byTooltip('Account: Arnav Sharma'));
        await tester.pumpAndSettle();
        expect(find.text('Arnav Sharma'), findsOneWidget);
        expect(find.text('Your attempts'), findsOneWidget);
        expect(find.text('Sign out'), findsOneWidget);
      });
    }
  });

  group('settings, language and intro', () {
    testWidgets('the intro shows once and can be skipped', (tester) async {
      final settings = AppSettings.memory(introSeen: false);
      await tester.pumpWidget(
        MainApp(services: testServices(settings: settings)),
      );
      await tester.pumpAndSettle();
      expect(find.text('KNOW IT? PROVE IT.'), findsOneWidget);
      await tapText(tester, 'Next');
      expect(find.text('COME BACK DAILY.'), findsOneWidget);
      await tapText(tester, 'Get started');
      expect(settings.introSeen, isTrue);
      expect(find.text('Choose your category.'), findsOneWidget);
    });

    testWidgets('settings switch language to Hindi and persist toggles', (
      tester,
    ) async {
      final store = MemorySettingsStore({'introSeen': true});
      final settings = AppSettings(store);
      await tester.pumpWidget(
        MainApp(services: testServices(settings: settings)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Sound effects');
      expect(store.getBool('sound'), isFalse);
      await tapText(tester, 'हिन्दी');
      expect(store.getString('locale'), 'hi');
      expect(find.text('सेटिंग्स'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('वापस'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('वापस'));
      await tester.pumpAndSettle();
      expect(find.text('जानते हो?'), findsOneWidget);
      expect(find.text('साबित करो।'), findsOneWidget);
    });

    test('the review prompt waits for a good score and enough play', () {
      final now = DateTime(2026, 11, 1);
      bool ask(int score, int played, DateTime? last) =>
          PlayReviewPrompter.shouldAsk(
            score: score,
            completedQuizzes: played,
            lastAsked: last,
            now: now,
          );
      expect(ask(8, 3, null), isTrue);
      expect(ask(7, 3, null), isFalse);
      expect(ask(10, 2, null), isFalse);
      expect(ask(10, 9, now.subtract(const Duration(days: 30))), isFalse);
      expect(ask(10, 9, now.subtract(const Duration(days: 61))), isTrue);
    });
  });
}

class _Remote implements RemoteQuestionSource {
  _Remote(this._fetch);
  final Future<QuestionBank?> Function() _fetch;
  @override
  Future<QuestionBank?> fetch() => _fetch();
}
