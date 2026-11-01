import 'models.dart';

class CategoryStats {
  const CategoryStats({
    required this.attempts,
    required this.bestScore,
    required this.averageAccuracy,
  });
  final int attempts;
  final int bestScore;
  final double averageAccuracy;
}

/// Personal statistics computed only from the player's own saved attempts,
/// so every number can be traced to real results.
class PlayerStats {
  const PlayerStats({
    required this.attempts,
    required this.accuracy,
    required this.currentStreak,
    required this.bestStreak,
    required this.byCategory,
    required this.recent,
  });

  factory PlayerStats.from(List<SavedAttempt> attempts, {DateTime? now}) {
    final today = _day((now ?? DateTime.now()).toLocal());
    final byCategory = <QuizCategory, CategoryStats>{};
    for (final category in QuizCategory.values) {
      final mine = [
        for (final a in attempts)
          if (a.category == category) a,
      ];
      if (mine.isEmpty) continue;
      byCategory[category] = CategoryStats(
        attempts: mine.length,
        bestScore: mine.map((a) => a.score).reduce((a, b) => a > b ? a : b),
        averageAccuracy:
            mine.map((a) => a.accuracy).reduce((a, b) => a + b) / mine.length,
      );
    }

    final days = {for (final a in attempts) _day(a.completedAt.toLocal())};
    final sorted = days.toList()..sort();
    var best = 0, run = 0;
    DateTime? previous;
    for (final day in sorted) {
      run = previous != null && _daysBetween(previous, day) == 1 ? run + 1 : 1;
      if (run > best) best = run;
      previous = day;
    }
    // A streak stays alive until a whole day is missed: playing yesterday
    // but not yet today still counts.
    var current = 0;
    var cursor = days.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    while (days.contains(cursor)) {
      current++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    final chronological = [...attempts]
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    final totalScore = attempts.fold(0, (sum, a) => sum + a.score);
    final totalQuestions = attempts.fold(0, (sum, a) => sum + a.total);
    return PlayerStats(
      attempts: attempts.length,
      accuracy: totalQuestions == 0 ? 0 : totalScore / totalQuestions,
      currentStreak: current,
      bestStreak: best,
      byCategory: byCategory,
      recent: chronological.reversed.take(10).toList().reversed.toList(),
    );
  }

  final int attempts;
  final double accuracy;
  final int currentStreak;
  final int bestStreak;
  final Map<QuizCategory, CategoryStats> byCategory;

  /// Up to the last ten attempts, oldest first, for the trend chart.
  final List<SavedAttempt> recent;

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Calendar days between two local dates, safe across daylight-saving
  /// changes because both are midnight-normalised.
  static int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}
