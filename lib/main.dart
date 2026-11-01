import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_scope.dart';
import 'app/device_services.dart';
import 'app/intro_screen.dart';
import 'app/settings.dart';
import 'firebase/bootstrap.dart';
import 'foundation/theme.dart';
import 'home/category_home.dart';
import 'l10n/app_localizations.dart';
import 'quiz/question_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: OrbitColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  // The bundled fonts' OFL notices appear on Settings > Open-source licences.
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in [
      ('Barlow', 'Barlow-OFL.txt'),
      ('Barlow Condensed', 'BarlowCondensed-OFL.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString('assets/fonts/$file'));
    }
  });
  final settings = await _loadSettings();
  final firebase = await connectFirebase();
  ReminderScheduler? reminders;
  try {
    reminders = await LocalReminderScheduler.create();
  } catch (_) {
    reminders = null;
  }
  runApp(
    MainApp(
      services: AppServices(
        questions: LayeredQuestionRepository(
          bundled: const AssetQuestionRepository(),
          remote: firebase?.publishedQuestions,
        ),
        settings: settings,
        account: firebase?.account,
        attempts: firebase?.attempts,
        reports: firebase?.reports,
        feedback: DeviceFeedback(settings),
        reminders: reminders,
        reviews: PlayReviewPrompter(settings),
      ),
    ),
  );
}

/// Falls back to in-memory settings if device storage is unavailable, so a
/// storage problem never stops the quiz from opening.
Future<AppSettings> _loadSettings() async {
  try {
    return AppSettings(
      SharedPreferencesStore(await SharedPreferences.getInstance()),
    );
  } catch (_) {
    return AppSettings.memory(introSeen: false);
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, this.services});

  /// Everything the screens need. Defaults to the bundled questions and
  /// in-memory settings with no Firebase, which is also what the results
  /// screen then reports truthfully.
  final AppServices? services;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final AppServices _services =
      widget.services ??
      AppServices(
        questions: const AssetQuestionRepository(),
        settings: AppSettings.memory(),
      );
  AppSettings get _settings => _services.settings;

  @override
  Widget build(BuildContext context) => AppScope(
    services: _services,
    child: ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        theme: orbitTheme,
        locale: switch (_settings.localeCode) {
          null => null,
          final code => Locale(code),
        },
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: _settings.introSeen ? const CategoryHome() : const IntroScreen(),
      ),
    ),
  );
}
