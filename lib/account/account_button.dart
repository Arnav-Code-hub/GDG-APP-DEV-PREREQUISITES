import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../foundation/theme.dart';
import 'account_session.dart';

/// Google sign-in control. Signed out, it is a pill that starts sign-in and
/// prevents double taps while the sign-in window is open. Signed in, it is
/// an avatar pill whose menu holds the account actions, so the masthead
/// never wraps into a second row on phones.
class AccountButton extends StatefulWidget {
  const AccountButton({
    super.key,
    required this.session,
    this.onSignedIn,
    this.menuItems = const [],
    this.signInLabel,
    this.compact = false,
  });

  final AccountSession session;
  final ValueChanged<AccountUser>? onSignedIn;

  /// Extra entries above Sign out in the signed-in menu.
  final List<AccountMenuItem> menuItems;

  /// Defaults to "Sign in with Google".
  final String? signInLabel;

  /// Narrow screens: avatar only, with the full name at the top of the menu
  /// instead of an ellipsised name in the bar.
  final bool compact;

  @override
  State<AccountButton> createState() => _AccountButtonState();
}

class AccountMenuItem {
  const AccountMenuItem({
    required this.icon,
    required this.label,
    required this.onSelected,
  });
  final IconData icon;
  final String label;
  final ValueChanged<AccountUser> onSelected;
}

class _AccountButtonState extends State<AccountButton> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on SignInException catch (error) {
      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(switch (error.reason) {
              SignInFailure.network => l10n.signInNetworkError,
              SignInFailure.popupBlocked => l10n.signInPopupBlocked,
              SignInFailure.other => l10n.signInFailed,
            }),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() => _run(() async {
    final user = await widget.session.signIn();
    if (user != null) widget.onSignedIn?.call(user);
  });

  static final _pillStyle = TextButton.styleFrom(
    backgroundColor: OrbitColors.raised,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    side: const BorderSide(color: OrbitColors.hairline),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final user = widget.session.user;
        if (user == null) {
          return TextButton.icon(
            style: _pillStyle,
            onPressed: _busy ? null : _signIn,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login, size: 18),
            label: Text(
              _busy
                  ? l10n.signingIn
                  : widget.signInLabel ?? l10n.signInWithGoogle,
            ),
          );
        }
        final name = user.label ?? l10n.signedInFallback;
        return PopupMenuButton<int>(
          tooltip: l10n.accountMenu(name),
          position: PopupMenuPosition.under,
          enabled: !_busy,
          onSelected: (index) => index < widget.menuItems.length
              ? widget.menuItems[index].onSelected(user)
              : _run(widget.session.signOut),
          itemBuilder: (context) => [
            if (widget.compact)
              PopupMenuItem(
                enabled: false,
                value: -1,
                child: ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(color: OrbitColors.ink),
                  ),
                  subtitle: user.email == null || user.email == name
                      ? null
                      : Text(user.email!),
                ),
              ),
            for (final (i, item) in widget.menuItems.indexed)
              PopupMenuItem(
                value: i,
                child: ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                ),
              ),
            PopupMenuItem(
              value: widget.menuItems.length,
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.signOut),
              ),
            ),
          ],
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, maxWidth: 220),
            padding: EdgeInsets.fromLTRB(6, 6, widget.compact ? 10 : 16, 6),
            decoration: const ShapeDecoration(
              color: OrbitColors.raised,
              shape: StadiumBorder(
                side: BorderSide(color: OrbitColors.hairline),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: OrbitColors.accent,
                    foregroundColor: OrbitColors.background,
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: orbitAction.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                if (!widget.compact) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        color: OrbitColors.ink,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(
                  Icons.expand_more,
                  size: 18,
                  color: OrbitColors.muted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
