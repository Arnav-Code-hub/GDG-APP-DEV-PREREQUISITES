import 'package:flutter/material.dart';

import '../foundation/components.dart';
import '../foundation/theme.dart';
import 'app_scope.dart';
import 'intro_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _changingReminder = false;

  Future<void> _setReminder(bool on) async {
    final services = AppScope.of(context);
    final reminders = services.reminders;
    if (reminders == null || _changingReminder) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _changingReminder = true);
    try {
      if (on) {
        final granted = await reminders.enable(
          title: l10n.reminderTitle,
          body: l10n.reminderBody,
        );
        if (!granted) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.remindersDenied)));
          return;
        }
      } else {
        await reminders.disable();
      }
      await services.settings.setReminders(on);
    } finally {
      if (mounted) setState(() => _changingReminder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final services = AppScope.of(context);
    final settings = services.settings;
    return OrbitPage(
      title: l10n.settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Group(
              children: [
                _Switch(
                  icon: Icons.volume_up_outlined,
                  label: l10n.soundEffects,
                  value: settings.sound,
                  onChanged: settings.setSound,
                ),
                _Switch(
                  icon: Icons.vibration,
                  label: l10n.vibration,
                  value: settings.haptics,
                  onChanged: settings.setHaptics,
                ),
                if (services.reminders != null)
                  _Switch(
                    icon: Icons.notifications_outlined,
                    label: l10n.dailyReminder,
                    hint: l10n.dailyReminderHint,
                    value: settings.reminders,
                    onChanged: _changingReminder ? null : _setReminder,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Semantics(
                header: true,
                child: OrbitLabel(l10n.language, color: OrbitColors.ink),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (code, label) in [
                  (null, l10n.deviceLanguage),
                  ('en', l10n.english),
                  ('hi', l10n.hindi),
                ])
                  OrbitChip(
                    label: label,
                    selected: settings.localeCode == code,
                    onTap: () => settings.setLocaleCode(code),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: OrbitLabel(l10n.languageNote),
            ),
            const SizedBox(height: 32),
            OrbitOutlinedButton(
              label: l10n.showIntro,
              icon: Icons.slideshow_outlined,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const IntroScreen(replay: true),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OrbitOutlinedButton(
              label: l10n.licenses,
              icon: Icons.description_outlined,
              onPressed: () => showLicensePage(
                context: context,
                applicationName: l10n.appTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => OrbitPanel(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const Divider(indent: 20, endIndent: 20),
          child,
        ],
      ],
    ),
  );
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });
  final IconData icon;
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    secondary: Icon(icon, color: OrbitColors.muted),
    title: Text(label, style: const TextStyle(fontSize: 17)),
    subtitle: hint == null
        ? null
        : Text(hint!, style: const TextStyle(color: OrbitColors.muted)),
    value: value,
    activeThumbColor: OrbitColors.background,
    activeTrackColor: OrbitColors.accent,
    onChanged: onChanged,
  );
}
