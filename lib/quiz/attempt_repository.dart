import 'package:flutter/foundation.dart';

import 'models.dart';

/// Stores and lists completed attempts. Only finished [QuizResult]s reach this
/// contract; there is no API for drafts or partial progress.
abstract interface class CompletedAttemptRepository {
  /// Writes [result] under [ownerId] using `result.attemptId` as the record
  /// key, so repeating a save overwrites the same record instead of adding
  /// another. Completes only after the backend acknowledges the write.
  Future<void> save({required String ownerId, required QuizResult result});

  /// The owner's completed attempts, newest first.
  Future<List<SavedAttempt>> history(String ownerId);

  /// One saved attempt, or null when it does not exist. Used to tell whether
  /// today's daily challenge is already done.
  Future<SavedAttempt?> find(String ownerId, String attemptId);
}

enum SaveStatus {
  /// No account storage is configured in this build.
  unavailable,

  /// Storage exists but nobody was signed in when the quiz finished.
  signedOut,
  saving,
  saved,
  failed,

  /// Today's daily challenge was already saved, e.g. from another device;
  /// the database keeps the first one, so retrying cannot help.
  alreadyPlayed,
}

/// Tracks saving one completed result. The owner is fixed when the result
/// is created (or when a signed-out player signs in on the Results screen),
/// so a later sign-out or account switch cannot redirect a pending or
/// retried write into another account.
class AttemptSaver extends ChangeNotifier {
  AttemptSaver({
    required this.result,
    CompletedAttemptRepository? repository,
    String? ownerId,
  }) : _repository = repository,
       _ownerId = ownerId {
    _status = repository == null
        ? SaveStatus.unavailable
        : ownerId == null
        ? SaveStatus.signedOut
        : SaveStatus.saving;
    if (_status == SaveStatus.saving) _write();
  }

  final QuizResult result;
  final CompletedAttemptRepository? _repository;
  String? _ownerId;
  late SaveStatus _status;
  bool _disposed = false;

  SaveStatus get status => _status;
  String? get ownerId => _ownerId;

  /// Saves a result finished while signed out, once its player signs in.
  /// Ignored once an owner is set.
  void claim(String ownerId) {
    if (_status != SaveStatus.signedOut) return;
    _ownerId = ownerId;
    _setStatus(SaveStatus.saving);
    _write();
  }

  /// Retries a failed save with the same owner and attempt ID.
  void retry() {
    if (_status != SaveStatus.failed) return;
    _setStatus(SaveStatus.saving);
    _write();
  }

  Future<void> _write() async {
    try {
      await _repository!.save(ownerId: _ownerId!, result: result);
      _setStatus(SaveStatus.saved);
    } catch (_) {
      _setStatus(
        await _alreadySaved() ? SaveStatus.alreadyPlayed : SaveStatus.failed,
      );
    }
  }

  /// A daily attempt has a fixed ID, so a rejected write may mean today's
  /// challenge already has a record.
  Future<bool> _alreadySaved() async {
    if (result.mode != QuizMode.daily) return false;
    try {
      return await _repository!.find(_ownerId!, result.attemptId) != null;
    } catch (_) {
      return false;
    }
  }

  void _setStatus(SaveStatus status) {
    if (_disposed) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
