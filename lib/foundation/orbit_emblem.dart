import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../l10n/app_localizations.dart';
import 'motion.dart';
import 'theme.dart';

/// Original geometry is painted once; rotation reuses its isolated layer.
class OrbitEmblem extends StatefulWidget {
  const OrbitEmblem({super.key});

  @override
  State<OrbitEmblem> createState() => _OrbitEmblemState();
}

class _OrbitEmblemState extends State<OrbitEmblem>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _rotation;
  ScrollPosition? _scrollPosition;
  bool _paused = false;
  bool _reduced = false;
  bool _routeCurrent = true;
  bool _tickersEnabled = true;
  bool _foreground = true;
  bool _syncQueued = false;

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(vsync: this, duration: OrbitMotion.orbit);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = prefersReducedMotion(context);
    _routeCurrent = ModalRoute.isCurrentOf(context) != false;
    _tickersEnabled = TickerMode.valuesOf(context).enabled;
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _scrollPosition) {
      _scrollPosition?.removeListener(_queueSync);
      _scrollPosition = position;
      _scrollPosition?.addListener(_queueSync);
    }
    _syncAnimation();
    _queueSync();
  }

  bool get _visible {
    final box = context.findRenderObject();
    final position = _scrollPosition;
    if (box is! RenderBox ||
        !box.hasSize ||
        position == null ||
        !position.hasContentDimensions) {
      return false;
    }
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return true;
    final top = viewport.getOffsetToReveal(box, 0).offset;
    return top + box.size.height > position.pixels &&
        top < position.pixels + position.viewportDimension;
  }

  void _queueSync() {
    if (_syncQueued) return;
    _syncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncQueued = false;
      if (mounted) _syncAnimation();
    });
  }

  void _syncAnimation() {
    final shouldRun =
        !_paused &&
        !_reduced &&
        _routeCurrent &&
        _tickersEnabled &&
        _foreground &&
        _visible;
    if (shouldRun && !_rotation.isAnimating) {
      _rotation.repeat();
    } else if (!shouldRun) {
      _rotation.stop();
      if (_reduced) _rotation.value = 0;
    }
  }

  @override
  void didChangeAccessibilityFeatures() {
    setState(() => _reduced = prefersReducedMotion(context));
    _syncAnimation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncAnimation();
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    _syncAnimation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollPosition?.removeListener(_queueSync);
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Recheck visibility after resize/text reflow, without a visibility package.
    _queueSync();
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 1.12,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned.fill(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _OrbitBackdropPainter()),
                ),
              ),
            ),
            Positioned.fill(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _rotation,
                  child: const RepaintBoundary(
                    child: CustomPaint(painter: _OrbitPainter()),
                  ),
                  builder: (context, child) => Transform.rotate(
                    key: const ValueKey('orbit-ring-rotation'),
                    alignment: const Alignment(0, -.1),
                    angle: _rotation.value * math.pi * 2,
                    child: child,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (!_reduced)
                    Tooltip(
                      message: _paused
                          ? _l10n(context).ringResumeTooltip
                          : _l10n(context).ringPauseTooltip,
                      excludeFromSemantics: true,
                      child: TextButton.icon(
                        onPressed: _togglePause,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: OrbitColors.muted,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: const RoundedRectangleBorder(),
                        ),
                        icon: ExcludeSemantics(
                          child: Icon(
                            _paused ? Icons.play_arrow : Icons.pause,
                            size: 16,
                          ),
                        ),
                        label: Text(
                          _paused
                              ? _l10n(context).ringPlay
                              : _l10n(context).ringPause,
                          semanticsLabel: _paused
                              ? _l10n(context).ringResumeTooltip
                              : _l10n(context).ringPauseTooltip,
                          style: orbitLabel,
                        ),
                      ),
                    )
                  else
                    const ExcludeSemantics(
                      child: Text('[ Q ]', style: orbitLabel),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitBackdropPainter extends CustomPainter {
  const _OrbitBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .45);
    final radius = size.shortestSide * .36;
    final grain = Paint()..color = OrbitColors.ink.withValues(alpha: .06);
    for (var x = 4.0; x < size.width; x += 8) {
      for (var y = 4.0; y < size.height - 48; y += 8) {
        canvas.drawCircle(Offset(x, y), .45, grain);
      }
    }
    final guide = Paint()
      ..color = OrbitColors.line
      ..strokeWidth = .7
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), guide);
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height - 48),
      guide,
    );
    canvas.drawCircle(center, radius * 1.12, guide);

    final marker = Paint()..color = OrbitColors.ink;
    for (final point in [
      Offset(center.dx, center.dy - radius * 1.12),
      Offset(center.dx, center.dy + radius * 1.12),
      Offset(center.dx - radius * 1.12, center.dy),
      Offset(center.dx + radius * 1.12, center.dy),
    ]) {
      canvas.drawRect(
        Rect.fromCenter(center: point, width: 4, height: 4),
        marker,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitBackdropPainter oldDelegate) => false;
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .45);
    final radius = size.shortestSide * .36;

    Offset project(double u, double v) {
      final ring = .72 + .28 * math.cos(v);
      final x = ring * math.cos(u);
      final y = ring * math.sin(u);
      final z = .28 * math.sin(v);
      final tiltedY = y * math.cos(.95) - z * math.sin(.95);
      final depth = y * math.sin(.95) + z * math.cos(.95);
      final turnedX = x * math.cos(.35) + depth * math.sin(.35);
      const angle = -.42;
      return center +
          Offset(
            (turnedX * math.cos(angle) - tiltedY * math.sin(angle)) * radius,
            (turnedX * math.sin(angle) + tiltedY * math.cos(angle)) * radius,
          );
    }

    final wire = Paint()
      ..color = OrbitColors.accent
      ..strokeWidth = .85
      ..style = PaintingStyle.stroke;
    for (var ring = 0; ring < 48; ring++) {
      final path = Path();
      for (var step = 0; step <= 48; step++) {
        final p = project(ring * math.pi / 24, step * math.pi / 24);
        if (step == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, wire);
    }
    for (var ring = 0; ring < 12; ring++) {
      final path = Path();
      for (var step = 0; step <= 96; step++) {
        final p = project(step * math.pi / 48, ring * math.pi / 6);
        if (step == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, wire);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => false;
}

AppLocalizations _l10n(BuildContext context) =>
    AppLocalizations.of(context) ?? lookupAppLocalizations(const Locale('en'));
