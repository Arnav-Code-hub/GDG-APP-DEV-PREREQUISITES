import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_orbit/app/app_scope.dart';
import 'package:quiz_orbit/app/device_services.dart';
import 'package:quiz_orbit/app/result_sharer.dart';
import 'package:quiz_orbit/app/settings.dart';
import 'package:quiz_orbit/foundation/theme.dart';
import 'package:quiz_orbit/l10n/app_localizations.dart';
import 'package:quiz_orbit/quiz/question_repository.dart';

import 'quiz_fakes.dart';

/// Test services: the fake bank in a fixed order, silent feedback and no
/// platform sharing. Override what a test needs.
AppServices testServices({
  QuestionRepository? questions,
  FakeAttemptRepository? attempts,
  FakeAccountSession? account,
  FakeReportRepository? reports,
  AppSettings? settings,
  QuizFeedback feedback = const SilentFeedback(),
  ResultSharer? sharer,
}) => AppServices(
  questions: questions ?? FakeQuestionRepository(() async => testBank()),
  settings: settings ?? AppSettings.memory(),
  attempts: attempts,
  account:
      account ?? (attempts == null ? null : FakeAccountSession(uid: 'user-a')),
  reports: reports,
  feedback: feedback,
  sharer: sharer ?? FakeSharer(),
  pickPractice: inOrder,
);

/// The scope sits above MaterialApp, as in the app, so pushed routes see it.
Widget testApp({
  required Widget home,
  AppServices? services,
  Locale? locale,
  TransitionBuilder? builder,
}) => AppScope(
  services: services ?? testServices(),
  child: MaterialApp(
    theme: orbitTheme,
    locale: locale,
    builder: builder,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  ),
);

/// Taps Submit quiz and confirms it in the dialog.
Future<void> submitQuiz(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Submit quiz');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TextButton, 'Submit quiz'));
  await tester.pumpAndSettle();
}
