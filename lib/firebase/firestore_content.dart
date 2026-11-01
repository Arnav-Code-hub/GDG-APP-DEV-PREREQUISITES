import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../quiz/question_repository.dart';
import '../quiz/report_repository.dart';

/// The published question bank at `questionBanks/current`, written only by
/// `tool/publish_questions.mjs` with admin credentials. Players can read it;
/// nobody can write it from the app.
class FirestoreQuestionSource implements RemoteQuestionSource {
  FirestoreQuestionSource(
    this._db, {
    this.timeout = const Duration(seconds: 6),
  });

  final FirebaseFirestore _db;
  final Duration timeout;

  @override
  Future<QuestionBank?> fetch() async {
    final doc = await _db
        .collection('questionBanks')
        .doc('current')
        .get()
        .timeout(timeout);
    final json = doc.data()?['json'];
    if (json is! String) return null;
    try {
      return QuestionBank.fromJson(jsonDecode(json));
    } on QuestionDataException {
      return null; // A bad publish must never break play.
    } on FormatException {
      return null;
    }
  }
}

/// Writes question reports to `questionReports/{uid}_{questionId}`. The
/// fixed ID means one report per player per question; the rules allow
/// creating it once and nothing else (no reading, editing or deleting).
/// shortcut: no App Check yet, so this caps spam per account rather than
/// stopping scripted accounts; enable App Check before launch.
class FirestoreReportRepository implements ReportRepository {
  FirestoreReportRepository(
    this._db, {
    this.timeout = const Duration(seconds: 15),
  });

  final FirebaseFirestore _db;
  final Duration timeout;

  @override
  Future<void> submit({
    required String ownerId,
    required QuestionReport report,
  }) async {
    try {
      await _db
          .collection('questionReports')
          .doc('${ownerId}_${report.questionId}')
          .set({
            'uid': ownerId,
            'questionId': report.questionId,
            'bankVersion': report.bankVersion,
            'reason': report.reason.id,
            'note': report.note,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(timeout);
    } on FirebaseException catch (error) {
      // The only write the rules refuse for a signed-in player sending a
      // well-formed report is a repeat: this question is already reported.
      if (error.code != 'permission-denied') rethrow;
    }
  }
}
