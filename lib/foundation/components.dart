import 'package:flutter/material.dart';

import 'ambient_background.dart';

import '../l10n/app_localizations.dart';
import 'theme.dart';

AppLocalizations _l10n(BuildContext context) =>
    AppLocalizations.of(context) ?? lookupAppLocalizations(const Locale('en'));

class OrbitLabel extends StatelessWidget {
  const OrbitLabel(this.text, {super.key, this.color = OrbitColors.muted});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: orbitLabel.copyWith(color: color));
}

/// The one primary action style: a solid accent pill. Depth comes from
/// lightness, not a coloured glow (Hallmark 29).
class OrbitButton extends StatelessWidget {
  const OrbitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Only where it adds meaning; no stock arrow (Hallmark 63).
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(label, textAlign: TextAlign.center)),
        if (icon != null) ...[
          const SizedBox(width: 10),
          ExcludeSemantics(child: Icon(icon, size: 20)),
        ],
      ],
    ),
  );
}

/// Secondary pill on a raised surface, shared by cards, sheets and quiz
/// screens. Focus shows an accent ring immediately.
final orbitOutlinedStyle =
    OutlinedButton.styleFrom(
      foregroundColor: OrbitColors.ink,
      minimumSize: const Size(48, 56),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: const StadiumBorder(),
      textStyle: orbitAction,
    ).copyWith(
      animationDuration: OrbitMotion.press,
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused) ||
                states.contains(WidgetState.pressed)
            ? OrbitColors.line
            : OrbitColors.raised,
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? const BorderSide(color: OrbitColors.accent, width: 2)
            : const BorderSide(color: OrbitColors.hairline),
      ),
    );

class OrbitOutlinedButton extends StatelessWidget {
  const OrbitOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.focusNode,
  });
  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Only where it adds meaning; no stock arrow (Hallmark 63).
  final IconData? icon;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    focusNode: focusNode,
    style: orbitOutlinedStyle,
    child: Row(
      children: [
        Expanded(child: Text(label)),
        if (icon != null) ...[
          const SizedBox(width: 12),
          ExcludeSemantics(child: Icon(icon, size: 20)),
        ],
      ],
    ),
  );
}

/// Round icon control on a raised disc, like the reference's close button.
class OrbitIconButton extends StatelessWidget {
  const OrbitIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 22),
    style: IconButton.styleFrom(
      backgroundColor: OrbitColors.raised,
      foregroundColor: OrbitColors.ink,
      minimumSize: const Size(48, 48),
      side: const BorderSide(color: OrbitColors.hairline),
    ),
  );
}

/// Pill filter/stat chip with an optional count, after the reference's
/// "Active 11" tabs. Selected chips use a filled accent, not just a tint.
class OrbitChip extends StatelessWidget {
  const OrbitChip({
    super.key,
    required this.label,
    this.count,
    this.selected = false,
    this.onTap,
    this.color = OrbitColors.accent,
  });
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;
    // Display-only chips are tinted badges, not filled pills, so they never
    // look like controls.
    final fill = !selected
        ? OrbitColors.raised
        : interactive
        ? color
        : color.withAlpha(0x22);
    final foreground = selected && interactive
        ? OrbitColors.background
        : selected
        ? color
        : OrbitColors.ink;
    final chip = AnimatedContainer(
      duration: OrbitMotion.press,
      constraints: BoxConstraints(minHeight: interactive ? 48 : 36),
      padding: EdgeInsets.symmetric(
        horizontal: interactive ? 18 : 14,
        vertical: interactive ? 10 : 6,
      ),
      decoration: ShapeDecoration(
        color: fill,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected && interactive ? color : OrbitColors.hairline,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: foreground,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: orbitLabel.copyWith(
                color: selected ? foreground : OrbitColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        type: MaterialType.transparency,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: chip),
      ),
    );
  }
}

class OrbitProgress extends StatelessWidget {
  const OrbitProgress({
    super.key,
    required this.completed,
    required this.total,
    this.current,
  }) : assert(total > 0),
       assert(completed >= 0 && completed <= total);

  final int completed;
  final int total;

  /// The question on screen, when it differs from the completed count.
  final int? current;

  @override
  Widget build(BuildContext context) => Semantics(
    label: _l10n(context).progressLabel,
    value: _l10n(context).progressValue(completed, total),
    child: ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrbitLabel(
            _l10n(context).questionProgress(current ?? completed, total),
          ),
          const SizedBox(height: OrbitSpace.small),
          LinearProgressIndicator(
            value: completed / total,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: OrbitColors.raised,
            color: OrbitColors.accent,
          ),
        ],
      ),
    ),
  );
}

/// Layered card surface. [raised] lifts nested content one step; cards are
/// never drawn inside cards.
class OrbitPanel extends StatelessWidget {
  const OrbitPanel({
    super.key,
    required this.child,
    this.borderColor = OrbitColors.hairline,
    this.padding = const EdgeInsets.all(24),
    this.raised = false,
  });
  final Widget child;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final bool raised;

  /// A Material surface, so ink from list tiles and buttons inside it is
  /// drawn on the card rather than hidden beneath it.
  @override
  Widget build(BuildContext context) => Material(
    color: raised ? OrbitColors.raised : OrbitColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(OrbitRadius.card),
      side: BorderSide(color: borderColor),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

/// A secondary screen: round back button, large title, scrollable body with
/// the app's reading width and gutters.
class OrbitPage extends StatelessWidget {
  const OrbitPage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 48 : 20,
                    16,
                    wide ? 48 : 20,
                    48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OrbitIconButton(
                          icon: Icons.arrow_back,
                          tooltip: _l10n(context).back,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(title, style: orbitHeading(56)),
                      ),
                      const SizedBox(height: 24),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An empty or error state: a short heading, one sentence, optional action.
class OrbitMessage extends StatelessWidget {
  const OrbitMessage({
    super.key,
    required this.title,
    required this.body,
    this.action,
  });
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => OrbitPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(title, style: orbitHeading(36)),
        ),
        const SizedBox(height: 12),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
        if (action != null) ...[const SizedBox(height: 24), action!],
      ],
    ),
  );
}

class OrbitLoading extends StatelessWidget {
  const OrbitLoading({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: label,
    child: const ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
  );
}
