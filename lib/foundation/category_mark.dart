import 'package:flutter/material.dart';

import 'theme.dart';

class CategoryMark extends StatelessWidget {
  const CategoryMark({super.key, required this.sports});

  final bool sports;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: 104,
          child: CustomPaint(painter: _CategoryMarkPainter(sports: sports)),
        ),
      ),
    ),
  );
}

class _CategoryMarkPainter extends CustomPainter {
  const _CategoryMarkPainter({required this.sports});

  final bool sports;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 104, size.height / 104);
    final stroke = Paint()
      ..color = sports
          ? OrbitColors.ink.withValues(alpha: .65)
          : OrbitColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.miter;

    if (sports) {
      canvas.drawPath(
        Path()
          ..moveTo(16, 51)
          ..lineTo(63, 33)
          ..lineTo(91, 70)
          ..lineTo(43, 88)
          ..close()
          ..moveTo(29.5, 69.5)
          ..lineTo(77, 51.5)
          ..moveTo(29, 46)
          ..lineTo(39, 60)
          ..lineTo(59, 52)
          ..lineTo(49, 38)
          ..moveTo(53, 84)
          ..lineTo(43, 71)
          ..lineTo(63, 63)
          ..lineTo(73, 77),
        stroke,
      );
      canvas.save();
      canvas.translate(53.3, 60.5);
      canvas.rotate(-.37);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 22, height: 12),
        stroke,
      );
      canvas.restore();
      canvas.drawCircle(const Offset(79, 17), 12, stroke);
      canvas.drawPath(
        Path()
          ..moveTo(68, 12)
          ..quadraticBezierTo(79, 20, 90, 22)
          ..moveTo(83, 6)
          ..quadraticBezierTo(74, 17, 75, 28)
          ..moveTo(72, 7)
          ..quadraticBezierTo(86, 10, 89, 24),
        stroke,
      );
    } else {
      canvas.save();
      canvas.translate(52, 52);
      canvas.rotate(-.58);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 88, height: 30),
        Paint()
          ..color = OrbitColors.accent.withValues(alpha: .4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.restore();
      canvas.drawPath(
        Path()
          ..moveTo(58, 13)
          ..lineTo(60, 39)
          ..lineTo(89, 41)
          ..lineTo(64, 55)
          ..lineTo(55, 87)
          ..lineTo(47, 62)
          ..lineTo(18, 68)
          ..lineTo(42, 46)
          ..close()
          ..moveTo(50, 42)
          ..lineTo(57, 52)
          ..lineTo(50, 63)
          ..moveTo(23, 24)
          ..lineTo(31, 32)
          ..moveTo(79, 78)
          ..lineTo(87, 86),
        stroke,
      );
      canvas.drawRect(
        const Rect.fromLTWH(85, 19, 4, 4),
        Paint()..color = OrbitColors.accent,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CategoryMarkPainter oldDelegate) =>
      sports != oldDelegate.sports;
}
