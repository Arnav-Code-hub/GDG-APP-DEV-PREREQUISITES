import 'package:cloud_firestore/cloud_firestore.dart';

import '../quiz/attempt_repository.dart';
import '../quiz/models.dart';

/// Reads and writes completed attempts at `users/{uid}/attempts/{attemptId}`.
///
/// `set` on a fixed document ID makes retries idempotent: the security
/// rules accept a repeat only when it is identical to the stored record.
class FirestoreAttemptRepository implements CompletedAttemptRepository {
  FirestoreAttemptRepository(
    this._db, {
    this.timeout = const Duration(seconds: 15),
  });

  final FirebaseFirestore _db;

  /// After this the UI offers Retry. Firestore may still deliver the queued
  /// write later; the retry targets the same document, so it cannot
  /// duplicate the attempt.
  final Duration timeout;

  CollectionReference<Map<String, dynamic>> _attempts(String ownerId) =>
      _db.collection('users').doc(ownerId).collection('attempts');

  static Map<String, Object?> toRecord(QuizResult result) {
    final saved = SavedAttempt.fromResult(result);
    return {
      'categoryId': saved.category.id,
      'topicId': saved.topicId,
      'mode': saved.mode.id,
      'timed': saved.timed,
      'score': saved.score,
      'total': saved.total,
      'questionSetVersion': saved.questionSetVersion,
      'completedAt': Timestamp.fromDate(saved.completedAt.toUtc()),
      'questionIds': saved.questionIds,
      'selectedIndices': saved.selectedIndices,
    };
  }

  /// Returns null for a record this version of the app cannot read, so one
  /// bad document cannot break the whole history list. Records saved before
  /// topics and modes existed read as untimed practice.
  static SavedAttempt? fromRecord(String id, Map<String, dynamic> data) {
    final category = QuizCategory.byId(data['categoryId'] as String? ?? '');
    final mode = switch (data['mode']) {
      null => QuizMode.practice,
      final String value => QuizMode.byId(value),
      _ => null,
    };
    final (score, total, version, completedAt, ids, indices) = (
      data['score'],
      data['total'],
      data['questionSetVersion'],
      data['completedAt'],
      data['questionIds'],
      data['selectedIndices'],
    );
    final (topicId, timed) = (data['topicId'], data['timed'] ?? false);
    if (category == null ||
        mode == null ||
        score is! int ||
        total is! int ||
        version is! String ||
        completedAt is! Timestamp ||
        (topicId != null && topicId is! String) ||
        timed is! bool ||
        ids is! List ||
        indices is! List ||
        ids.any((id) => id is! String) ||
        indices.any((index) => index is! int)) {
      return null;
    }
    try {
      return SavedAttempt(
        attemptId: id,
        category: category,
        topicId: topicId as String?,
        mode: mode,
        timed: timed,
        score: score,
        total: total,
        questionSetVersion: version,
        completedAt: completedAt.toDate(),
        questionIds: ids.cast<String>(),
        selectedIndices: indices.cast<int>(),
      );
    } on ArgumentError {
      return null;
    }
  }

  @override
  Future<void> save({required String ownerId, required QuizResult result}) =>
      _attempts(ownerId)
          .doc(result.attemptId)
          .set(toRecord(result))
          .timeout(timeout);

  @override
  Future<List<SavedAttempt>> history(String ownerId) async {
    final snapshot = await _attempts(ownerId)
        .orderBy('completedAt', descending: true)
        .limit(100)
        .get()
        .timeout(timeout);
    return [for (final doc in snapshot.docs) ?fromRecord(doc.id, doc.data())];
  }

  @override
  Future<SavedAttempt?> find(String ownerId, String attemptId) async {
    final doc = await _attempts(ownerId).doc(attemptId).get().timeout(timeout);
    final data = doc.data();
    return data == null ? null : fromRecord(doc.id, data);
  }
}
