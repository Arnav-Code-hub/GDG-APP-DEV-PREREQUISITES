enum ReportReason {
  wrongAnswer('wrong-answer'),
  unclear('unclear'),
  typo('typo'),
  other('other');

  const ReportReason(this.id);
  final String id;
}

/// A player's report that a question is wrong or unclear.
class QuestionReport {
  QuestionReport({
    required this.questionId,
    required this.bankVersion,
    required this.reason,
    String note = '',
  }) : note = note.trim().length > maxNoteLength
           ? note.trim().substring(0, maxNoteLength)
           : note.trim();

  static const maxNoteLength = 300;

  final String questionId;
  final String bankVersion;
  final ReportReason reason;
  final String note;
}

abstract interface class ReportRepository {
  /// Completes after the backend accepts the report.
  Future<void> submit({
    required String ownerId,
    required QuestionReport report,
  });
}
