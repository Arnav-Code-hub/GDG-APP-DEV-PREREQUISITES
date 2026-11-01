import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../foundation/components.dart';
import '../foundation/theme.dart';
import 'models.dart';
import 'stats.dart';

/// Personal stats from the attempts already loaded for History.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.attempts, this.now});
  final List<SavedAttempt> attempts;

  /// Overridable for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (attempts.isEmpty) {
      return OrbitPage(
        title: l10n.yourStats,
        child: OrbitMessage(title: l10n.nothingHere, body: l10n.statsEmpty),
      );
    }
    final stats = PlayerStats.from(attempts, now: now);
    String percent(double value) => '${(value * 100).round()}%';
    return OrbitPage(
      title: l10n.yourStats,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Figure(
                icon: Icons.local_fire_department_outlined,
                value: l10n.streakDays(stats.currentStreak),
                label: l10n.currentStreak,
                highlight: stats.currentStreak > 0,
              ),
              _Figure(
                icon: Icons.emoji_events_outlined,
                value: l10n.streakDays(stats.bestStreak),
                label: l10n.bestStreak,
              ),
              _Figure(
                icon: Icons.quiz_outlined,
                value: '${stats.attempts}',
                label: l10n.quizzesPlayed,
              ),
              _Figure(
                icon: Icons.track_changes_outlined,
                value: percent(stats.accuracy),
                label: l10n.overallAccuracy,
              ),
            ],
          ),
          const SizedBox(height: 32),
          for (final category in QuizCategory.values)
            if (stats.byCategory[category] case final s?) ...[
              OrbitPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.categoryName(category),
                      style: orbitHeading(32),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OrbitChip(
                          label: l10n.bestScore,
                          count: s.bestScore,
                          selected: true,
                          color: OrbitColors.correct,
                        ),
                        OrbitChip(
                          label:
                              '${l10n.averageScore} ${percent(s.averageAccuracy)}',
                        ),
                        OrbitChip(label: l10n.quizzesPlayed, count: s.attempts),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(l10n.recentScores, style: orbitHeading(32)),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: l10n.recentScoresSemantic(
              stats.recent.length,
              stats.recent.map((a) => '${a.score}/${a.total}').join(', '),
            ),
            excludeSemantics: true,
            child: OrbitPanel(
              child: SizedBox(
                height: 160,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ScoreBars([
                    for (final a in stats.recent) a.accuracy,
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OrbitLabel(l10n.statsBasis(attempts.length)),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150),
      child: OrbitPanel(
        raised: true,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: orbitHeading(36)),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: highlight ? OrbitColors.accent : OrbitColors.muted,
                ),
                const SizedBox(width: 6),
                Flexible(child: OrbitLabel(label)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// One rounded bar per recent attempt. Full marks are drawn in the success
/// color; the spoken summary carries the same numbers.
class _ScoreBars extends CustomPainter {
  _ScoreBars(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const gap = 10.0;
    final width = (size.width - gap * (values.length - 1)) / values.length;
    final barWidth = width.clamp(6.0, 36.0);
    final guide = Paint()
      ..color = OrbitColors.hairline
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      guide,
    );
    for (final (i, value) in values.indexed) {
      final x = i * (width + gap) + (width - barWidth) / 2;
      final h = (size.height - 4) * value.clamp(.04, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, barWidth, h),
          const Radius.circular(6),
        ),
        Paint()..color = value == 1 ? OrbitColors.correct : OrbitColors.accent,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreBars old) => old.values != values;
}
