import 'package:flutter/widgets.dart';

import '../account/account_session.dart';
import '../l10n/app_localizations.dart';
import '../quiz/attempt_repository.dart';
import '../quiz/models.dart';
import '../quiz/question_repository.dart';
import '../quiz/quiz_picker.dart';
import '../quiz/report_repository.dart';
import 'device_services.dart';
import 'result_sharer.dart';
import 'settings.dart';

/// Everything screens depend on, created once in `main` (or by a test) and
/// handed down the widget tree. Optional services are null when the
/// platform or the build does not provide them, and screens say so.
class AppServices {
  const AppServices({
    required this.questions,
    required this.settings,
    this.attempts,
    this.account,
    this.reports,
    this.feedback = const SilentFeedback(),
    this.reminders,
    this.reviews = const NoReviewPrompter(),
    this.sharer = const PlatformResultSharer(),
    this.pickPractice = QuizPicker.practice,
  });

  final QuestionRepository questions;
  final AppSettings settings;
  final CompletedAttemptRepository? attempts;
  final AccountSession? account;
  final ReportRepository? reports;
  final QuizFeedback feedback;
  final ReminderScheduler? reminders;
  final ReviewPrompter reviews;
  final ResultSharer sharer;

  /// Chooses practice questions; random in the app, fixed in tests.
  final List<Question> Function(List<Question> pool) pickPractice;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this widget.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      !identical(services, oldWidget.services);
}

extension Localized on BuildContext {
  /// Falls back to English where no localizations are installed, such as a
  /// widget pumped on its own in a test.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));

  String categoryName(QuizCategory category) => switch (category) {
    QuizCategory.anime => l10n.categoryAnime,
    QuizCategory.sports => l10n.categorySports,
  };
}
