import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../account/account_session.dart';
import '../firebase_options.dart';
import '../quiz/attempt_repository.dart';
import '../quiz/question_repository.dart';
import '../quiz/report_repository.dart';
import 'firebase_account_session.dart';
import 'firestore_attempt_repository.dart';
import 'firestore_content.dart';

/// `--dart-define=USE_FIREBASE_EMULATORS=true` runs against the local
/// Emulator Suite instead of a real project.
const useFirebaseEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');

/// Use 10.0.2.2 for the Android emulator.
const _emulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);

/// Emulator-only options. The `demo-` project prefix makes the emulators
/// refuse to contact any real Firebase project.
const _emulatorOptions = FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:000000000000:web:0000000000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'demo-quizorbit',
);

class FirebaseServices {
  const FirebaseServices({
    required this.account,
    required this.attempts,
    required this.reports,
    required this.publishedQuestions,
  });
  final AccountSession account;
  final CompletedAttemptRepository attempts;
  final ReportRepository reports;
  final RemoteQuestionSource publishedQuestions;
}

/// Returns null when Firebase has no options for this platform or fails to
/// start; the app then runs without account features and tells the player.
Future<FirebaseServices?> connectFirebase() async {
  try {
    // Throws UnsupportedError on platforms flutterfire was not run for.
    final options = useFirebaseEmulators
        ? _emulatorOptions
        : DefaultFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(options: options);
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;
    if (useFirebaseEmulators) {
      await auth.useAuthEmulator(_emulatorHost, 9099);
      db.useFirestoreEmulator(_emulatorHost, 8080);
    }
    return FirebaseServices(
      account: FirebaseAccountSession(auth),
      attempts: FirestoreAttemptRepository(db),
      reports: FirestoreReportRepository(db),
      publishedQuestions: FirestoreQuestionSource(db),
    );
  } catch (error) {
    debugPrint('Firebase unavailable: $error');
    return null;
  }
}
