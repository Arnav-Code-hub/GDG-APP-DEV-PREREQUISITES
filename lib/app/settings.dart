import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key-value storage for preferences. The app uses SharedPreferences; tests
/// use [MemorySettingsStore].
abstract interface class SettingsStore {
  bool? getBool(String key);
  String? getString(String key);
  int? getInt(String key);
  Future<void> setBool(String key, bool value);
  Future<void> setString(String key, String? value);
  Future<void> setInt(String key, int value);
}

class SharedPreferencesStore implements SettingsStore {
  SharedPreferencesStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  bool? getBool(String key) => _prefs.getBool(key);
  @override
  String? getString(String key) => _prefs.getString(key);
  @override
  int? getInt(String key) => _prefs.getInt(key);
  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  @override
  Future<void> setString(String key, String? value) => value == null
      ? _prefs.remove(key).then((_) {})
      : _prefs.setString(key, value).then((_) {});
  @override
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
}

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([Map<String, Object>? values]) : _values = {...?values};
  final Map<String, Object> _values;

  @override
  bool? getBool(String key) => _values[key] as bool?;
  @override
  String? getString(String key) => _values[key] as String?;
  @override
  int? getInt(String key) => _values[key] as int?;
  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;
  @override
  Future<void> setString(String key, String? value) async =>
      value == null ? _values.remove(key) : _values[key] = value;
  @override
  Future<void> setInt(String key, int value) async => _values[key] = value;
}

/// Player preferences and the few counters the app keeps on the device.
/// Nothing here is sent to Firebase.
class AppSettings extends ChangeNotifier {
  AppSettings(this._store);

  /// In-memory settings, used by tests and when storage is unavailable.
  /// The intro counts as seen so it does not cover the app unexpectedly.
  factory AppSettings.memory({bool introSeen = true}) =>
      AppSettings(MemorySettingsStore({_introSeen: introSeen}));

  final SettingsStore _store;

  static const _sound = 'sound';
  static const _haptics = 'haptics';
  static const _reminders = 'reminders';
  static const _locale = 'locale';
  static const _introSeen = 'introSeen';
  static const _completed = 'completedQuizzes';
  static const _reviewAskedAt = 'reviewAskedAt';

  bool get sound => _store.getBool(_sound) ?? true;
  bool get haptics => _store.getBool(_haptics) ?? true;
  bool get reminders => _store.getBool(_reminders) ?? false;

  /// "en", "hi", or null to follow the device language.
  String? get localeCode => _store.getString(_locale);
  bool get introSeen => _store.getBool(_introSeen) ?? false;
  int get completedQuizzes => _store.getInt(_completed) ?? 0;
  DateTime? get reviewAskedAt => switch (_store.getInt(_reviewAskedAt)) {
    null => null,
    final ms => DateTime.fromMillisecondsSinceEpoch(ms),
  };

  Future<void> setSound(bool value) =>
      _set(() => _store.setBool(_sound, value));
  Future<void> setHaptics(bool value) =>
      _set(() => _store.setBool(_haptics, value));
  Future<void> setReminders(bool value) =>
      _set(() => _store.setBool(_reminders, value));
  Future<void> setLocaleCode(String? value) =>
      _set(() => _store.setString(_locale, value));
  Future<void> setIntroSeen(bool value) =>
      _set(() => _store.setBool(_introSeen, value));
  Future<void> recordCompletedQuiz() =>
      _set(() => _store.setInt(_completed, completedQuizzes + 1));
  Future<void> recordReviewAsked(DateTime at) =>
      _set(() => _store.setInt(_reviewAskedAt, at.millisecondsSinceEpoch));

  Future<void> _set(Future<void> Function() write) async {
    await write();
    notifyListeners();
  }
}
