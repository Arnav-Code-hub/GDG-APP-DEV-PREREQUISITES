import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'motion.dart';
import 'theme.dart';

/// One clock for every screen, so the field does not jump when a route
/// changes.
final _clock = Stopwatch()..start();

/// A faint dot-matrix field behind a screen: a slow travelling ripple and an
/// occasional soft sweep, after the reference's dot-matrix figures.
///
/// Decoration only: it never takes input, is hidden from screen readers,
/// stays still under reduced motion, repaints at about 20 fps, and stops
/// whenever its route is covered or tickers are off (the app in the
/// background, an offstage route).
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, required this.child, this.strength = 1});

  final Widget child;

  /// Dims the field, e.g. behind questions that must stay easy to read.
  final double strength;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  static const _frame = Duration(milliseconds: 50);

  late final Ticker _ticker = createTicker(_tick);
  final _time = ValueNotifier<double>(0);
  Duration _lastPaint = Duration.zero;

  void _tick(Duration elapsed) {
    if (elapsed - _lastPaint < _frame) return;
    _lastPaint = elapsed;
    _time.value = _clock.elapsedMilliseconds / 1000;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (prefersReducedMotion(context)) {
      if (_ticker.isActive) _ticker.stop();
      _time.value = 0;
    } else if (!_ticker.isActive) {
      _time.value = _clock.elapsedMilliseconds / 1000;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: CustomPaint(painter: _FieldPainter(_time, widget.strength)),
          ),
        ),
      ),
      widget.child,
    ],
  );
}

class _FieldPainter extends CustomPainter {
  _FieldPainter(this.time, this.strength) : super(repaint: time);

  final ValueNotifier<double> time;
  final double strength;

  static const _spacing = 26.0;
  static const _levels = 6;

  // Reused between frames; cleared at the start of each paint.
  final _ink = List.generate(_levels, (_) => <double>[]);
  final _lit = <double>[];

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    // Dots are grouped by brightness so each group is one draw call.
    final ink = _ink;
    final lit = _lit..clear();
    for (final level in ink) {
      level.clear();
    }
    // The sweep crosses the screen diagonally about every 14 seconds.
    final travel = size.width + size.height;
    final sweep = (t * travel / 14) % (travel * 1.6) - travel * .3;
    for (var y = _spacing / 2; y < size.height; y += _spacing) {
      for (var x = _spacing / 2; x < size.width; x += _spacing) {
        final ripple =
            math.sin(x * .011 + t * .5) * math.cos(y * .008 - t * .35);
        final band = math.exp(-math.pow((x + y - sweep) / 90, 2));
        final v = (.3 + .35 * math.max(0, ripple) + .45 * band).clamp(0, 1);
        if (band > .6 && ripple > .3) {
          lit
            ..add(x)
            ..add(y);
        } else {
          final level = (v * (_levels - 1)).round();
          ink[level]
            ..add(x)
            ..add(y);
        }
      }
    }
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;
    for (var level = 0; level < _levels; level++) {
      if (ink[level].isEmpty) continue;
      paint.color = OrbitColors.ink.withValues(
        alpha: (.03 + .1 * level / (_levels - 1)) * strength,
      );
      canvas.drawRawPoints(
        PointMode.points,
        Float32List.fromList(ink[level]),
        paint,
      );
    }
    if (lit.isNotEmpty) {
      paint
        ..color = OrbitColors.accent.withValues(alpha: .28 * strength)
        ..strokeWidth = 2.2;
      canvas.drawRawPoints(PointMode.points, Float32List.fromList(lit), paint);
    }
  }

  @override
  bool shouldRepaint(_FieldPainter old) => old.strength != strength;
}
