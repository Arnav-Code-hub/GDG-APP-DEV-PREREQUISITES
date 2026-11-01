import 'dart:math';

import 'models.dart';

/// Chooses which questions an attempt uses. Practice draws a fresh random
/// set each time; the daily challenge is seeded by category and date so
/// every player gets the same set that day, on every platform.
abstract final class QuizPicker {
  static List<Question> practice(List<Question> pool, {Random? random}) {
    final shuffled = [...pool]..shuffle(random ?? Random());
    return shuffled.take(QuizFormat.questionsPerQuiz).toList();
  }

  static List<Question> daily(
    List<Question> pool,
    QuizCategory category,
    DateTime day,
  ) {
    // Sort first so the result depends only on which questions exist, not on
    // the order a download returned them in.
    final sorted = [...pool]..sort((a, b) => a.id.compareTo(b.id));
    final rng = _SeededRandom(_fnv1a('${category.id}|${dayKey(day)}'));
    for (var i = sorted.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final swap = sorted[i];
      sorted[i] = sorted[j];
      sorted[j] = swap;
    }
    return sorted.take(QuizFormat.questionsPerQuiz).toList();
  }

  /// 32-bit FNV-1a: identical on the Dart VM and on the web.
  static int _fnv1a(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = _imul(hash, 0x01000193);
    }
    return hash;
  }
}

/// Mulberry32. Dart's own seeded Random is not guaranteed to produce the
/// same sequence on every platform, which the daily challenge needs.
class _SeededRandom {
  _SeededRandom(this._state);
  int _state;

  int nextInt(int max) {
    _state = (_state + 0x6d2b79f5) & 0xffffffff;
    var t = _state;
    t = _imul(t ^ (t >>> 15), t | 1);
    t ^= (t + _imul(t ^ (t >>> 7), t | 61)) & 0xffffffff;
    final value = (t ^ (t >>> 14)) & 0xffffffff;
    return value % max;
  }
}

/// 32-bit multiply that stays exact on the web, where ints are doubles.
int _imul(int a, int b) {
  final aHi = (a >>> 16) & 0xffff, aLo = a & 0xffff;
  final bHi = (b >>> 16) & 0xffff, bLo = b & 0xffff;
  final cross = ((aHi * bLo + aLo * bHi) & 0xffff) * 0x10000;
  return (aLo * bLo + cross) & 0xffffffff;
}
