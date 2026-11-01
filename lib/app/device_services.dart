import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:in_app_review/in_app_review.dart';

import '../quiz/models.dart';
import 'settings.dart';

/// Touch and sound feedback during a quiz. Feedback only reports what the
/// controller already decided; it never affects scoring. Answers are not
/// judged until the quiz is submitted, so there is one result signal.
abstract interface class QuizFeedback {
  void selection();
  void finished({required bool good});
}

class SilentFeedback implements QuizFeedback {
  const SilentFeedback();
  @override
  void selection() {}
  @override
  void finished({required bool good}) {}
}

/// Haptics through the platform and two short original tones, each behind
/// its own setting. Failures are ignored: feedback is never essential.
class DeviceFeedback implements QuizFeedback {
  DeviceFeedback(this._settings);
  final AppSettings _settings;
  final _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  @override
  void selection() {
    if (_settings.haptics) HapticFeedback.selectionClick();
  }

  @override
  void finished({required bool good}) {
    if (_settings.haptics) {
      good ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    }
    if (_settings.sound) {
      _player
          .play(AssetSource(good ? 'sounds/correct.wav' : 'sounds/wrong.wav'))
          .catchError((Object _) {});
    }
  }
}

/// A once-a-day local reminder for the daily challenge. Android only; the
/// web build has no reminder setting.
abstract interface class ReminderScheduler {
  /// Returns false when the player declines notification permission.
  Future<bool> enable({required String title, required String body});
  Future<void> disable();
}

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler._(this._plugin);

  static const _id = 1;
  final FlutterLocalNotificationsPlugin _plugin;

  /// Null on platforms without reminders.
  static Future<ReminderScheduler?> create() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    return LocalReminderScheduler._(plugin);
  }

  @override
  Future<bool> enable({required String title, required String body}) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission() ?? true;
    if (!granted) return false;
    // Inexact daily repeat: no exact-alarm permission, which Play audits.
    await _plugin.periodicallyShow(
      id: _id,
      title: title,
      body: body,
      repeatInterval: RepeatInterval.daily,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_challenge',
          'Daily challenge',
          channelDescription: 'A daily reminder that a new challenge is ready',
          importance: Importance.defaultImportance,
        ),
      ),
    );
    return true;
  }

  @override
  Future<void> disable() => _plugin.cancel(id: _id);
}

/// Asks for a Play Store rating at a good moment: a score of 8 or more,
/// after at least three finished quizzes, at most once every 60 days. Play
/// itself also limits how often the dialog may appear.
abstract interface class ReviewPrompter {
  Future<void> afterResult(QuizResult result);
}

class NoReviewPrompter implements ReviewPrompter {
  const NoReviewPrompter();
  @override
  Future<void> afterResult(QuizResult result) async {}
}

class PlayReviewPrompter implements ReviewPrompter {
  PlayReviewPrompter(this._settings, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final AppSettings _settings;
  final DateTime Function() _clock;

  static bool shouldAsk({
    required int score,
    required int completedQuizzes,
    required DateTime? lastAsked,
    required DateTime now,
  }) =>
      score >= 8 &&
      completedQuizzes >= 3 &&
      (lastAsked == null || now.difference(lastAsked).inDays >= 60);

  @override
  Future<void> afterResult(QuizResult result) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final now = _clock();
    if (!shouldAsk(
      score: result.score,
      completedQuizzes: _settings.completedQuizzes,
      lastAsked: _settings.reviewAskedAt,
      now: now,
    )) {
      return;
    }
    final review = InAppReview.instance;
    if (!await review.isAvailable()) return;
    await _settings.recordReviewAsked(now);
    await review.requestReview();
  }
}
