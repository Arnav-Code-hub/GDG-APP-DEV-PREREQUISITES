import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quiz_orbit/account/account_session.dart';
import 'package:quiz_orbit/app/device_services.dart';
import 'package:quiz_orbit/app/result_sharer.dart';
import 'package:quiz_orbit/quiz/report_repository.dart';

import 'package:quiz_orbit/quiz/attempt_repository.dart';
import 'package:quiz_orbit/quiz/models.dart';
import 'package:quiz_orbit/quiz/question_repository.dart';

Map<String, Object?> questionJson(
  String id,
  String category, {
  int correctIndex = 0,
  List<Object?>? options,
  String? topic,
}) => {
  'id': id,
  'category': category,
  'topic': topic ?? '$category-a',
  'prompt': 'Prompt for $id?',
  'options': options ?? ['Alpha', 'Bravo', 'Charlie', 'Delta'],
  'correctIndex': correctIndex,
  'explanation': 'Explanation for $id.',
};

/// A valid bank: two topics of ten per category. The answer to question i
/// is option i % 4, and topic "-a" holds questions 0-9.
Map<String, Object?> bankJson({String version = 'test-1'}) => {
  'version': version,
  'topics': [
    for (final category in QuizCategory.values)
      for (final suffix in ['a', 'b'])
        {
          'id': '${category.id}-$suffix',
          'category': category.id,
          'name': 'Topic ${suffix.toUpperCase()}',
        },
  ],
  'questions': [
    for (final category in QuizCategory.values)
      for (var i = 0; i < 2 * QuizFormat.questionsPerQuiz; i++)
        questionJson(
          '${category.id}-$i',
          category.id,
          correctIndex: i % 4,
          topic: '${category.id}-${i < 10 ? 'a' : 'b'}',
        ),
  ],
};

/// Keeps the pool's order so flow tests know which question comes next.
List<Question> inOrder(List<Question> pool) =>
    pool.take(QuizFormat.questionsPerQuiz).toList();

QuestionBank testBank() => QuestionBank.fromJson(bankJson());

class FakeQuestionRepository implements QuestionRepository {
  FakeQuestionRepository(this._load);
  final Future<QuestionBank> Function() _load;
  int loads = 0;

  @override
  Future<QuestionBank> load() {
    loads++;
    return _load();
  }
}

/// In-memory stand-in for the Firestore repository, used only in tests.
class FakeAttemptRepository implements CompletedAttemptRepository {
  /// Keyed by owner, then attempt ID — the same shape as
  /// users/{uid}/attempts/{attemptId}.
  final records = <String, Map<String, QuizResult>>{};
  final calls = <({String ownerId, String attemptId})>[];
  Completer<void>? pending;
  bool fail = false;

  @override
  Future<void> save({required String ownerId, required QuizResult result}) {
    calls.add((ownerId: ownerId, attemptId: result.attemptId));
    Future<void> write() async {
      if (fail) throw StateError('offline');
      final existing = records[ownerId]?[result.attemptId];
      if (existing != null && !identical(existing, result)) {
        throw StateError('permission-denied');
      }
      (records[ownerId] ??= {})[result.attemptId] = result;
    }

    final gate = pending;
    return gate == null ? write() : gate.future.then((_) => write());
  }

  Object? historyFailure;

  @override
  Future<SavedAttempt?> find(String ownerId, String attemptId) async {
    final result = records[ownerId]?[attemptId];
    return result == null ? null : SavedAttempt.fromResult(result);
  }

  @override
  Future<List<SavedAttempt>> history(String ownerId) async {
    if (historyFailure != null) throw historyFailure!;
    final saved = (records[ownerId] ?? {}).values
        .map(SavedAttempt.fromResult)
        .toList();
    return saved..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }
}

/// In-memory stand-in for Google sign-in, used only in tests.
class FakeAccountSession extends ChangeNotifier implements AccountSession {
  FakeAccountSession({String? uid, this.nextUid = 'user-a'})
    : _user = uid == null ? null : AccountUser(uid: uid, displayName: uid);

  AccountUser? _user;

  /// The account the next sign-in returns; null simulates cancelling.
  String? nextUid;
  SignInException? failure;

  @override
  AccountUser? get user => _user;

  @override
  Future<AccountUser?> signIn() async {
    if (failure != null) throw failure!;
    if (nextUid == null) return null;
    _user = AccountUser(uid: nextUid!, displayName: nextUid);
    notifyListeners();
    return _user;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }
}

class FakeReportRepository implements ReportRepository {
  final sent = <({String ownerId, QuestionReport report})>[];
  bool fail = false;

  @override
  Future<void> submit({
    required String ownerId,
    required QuestionReport report,
  }) async {
    if (fail) throw StateError('offline');
    sent.add((ownerId: ownerId, report: report));
  }
}

class RecordingFeedback implements QuizFeedback {
  final events = <String>[];
  @override
  void selection() => events.add('select');
  @override
  void finished({required bool good}) => events.add(good ? 'good' : 'poor');
}

class FakeSharer implements ResultSharer {
  final shared = <({int bytes, String text})>[];
  @override
  Future<void> share({required Uint8List png, required String text}) async =>
      shared.add((bytes: png.length, text: text));
}
