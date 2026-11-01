import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../account/account_session.dart';

/// Google sign-in through Firebase Authentication: a popup on the web and
/// Firebase's browser-based provider flow on Android.
class FirebaseAccountSession extends ChangeNotifier implements AccountSession {
  FirebaseAccountSession(this._auth) {
    _subscription = _auth.authStateChanges().listen((_) => notifyListeners());
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;

  static const _cancelCodes = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'web-context-canceled',
    'canceled',
  };

  @override
  AccountUser? get user => switch (_auth.currentUser) {
    null => null,
    final user => AccountUser(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
    ),
  };

  @override
  Future<AccountUser?> signIn() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(provider);
      } else {
        await _auth.signInWithProvider(provider);
      }
      return user;
    } on FirebaseAuthException catch (error) {
      if (_cancelCodes.contains(error.code)) return null;
      throw SignInException(switch (error.code) {
        'network-request-failed' => SignInFailure.network,
        'popup-blocked' => SignInFailure.popupBlocked,
        _ => SignInFailure.other,
      });
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
