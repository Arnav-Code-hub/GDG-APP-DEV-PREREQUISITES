import 'package:flutter/foundation.dart';

class AccountUser {
  const AccountUser({required this.uid, this.displayName, this.email});
  final String uid;
  final String? displayName;
  final String? email;

  /// Display name, then email; null when the account has neither.
  String? get label =>
      displayName?.trim().isNotEmpty == true ? displayName : email;
}

enum SignInFailure { network, popupBlocked, other }

/// A sign-in that failed for a reason worth telling the player. Cancelling
/// is not a failure and does not throw.
class SignInException implements Exception {
  const SignInException(this.reason);
  final SignInFailure reason;
}

/// The signed-in account. Screens depend on this contract; the app uses
/// Firebase Authentication and tests use an in-memory implementation.
abstract interface class AccountSession implements Listenable {
  AccountUser? get user;

  /// Returns the user, or null when the player cancels. Throws
  /// [SignInException] with a readable message on failure.
  Future<AccountUser?> signIn();
  Future<void> signOut();
}
