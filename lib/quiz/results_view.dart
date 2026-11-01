import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../account/account_button.dart';
import '../app/app_scope.dart';
import '../foundation/components.dart';
import '../foundation/motion.dart';
import '../foundation/theme.dart';
import 'answer_review.dart';
import 'attempt_repository.dart';
import 'models.dart';

/// Final score, save status, sharing and answer review for one finished
/// attempt.
class ResultsView extends StatefulWidget {
  const ResultsView({
    super.key,
    required this.result,
    required this.saver,
    required this.onExit,
    this.onRetry,
    this.onPractice,
    this.onOpenHistory,
  });

  final QuizResult result;
  final AttemptSaver saver;
  final VoidCallback onExit;

  /// Practice only: plays a fresh set of questions.
  final VoidCallback? onRetry;

  /// Daily only: the challenge is one go, so offer practice instead.
  final VoidCallback? onPractice;

  /// Shown once the result is saved, when history is available.
  final VoidCallback? onOpenHistory;

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  final _card = GlobalKey();
  bool _sharing = false;

  String _verdict(BuildContext context) {
    final l10n = context.l10n;
    final ratio = widget.result.score / widget.result.total;
    if (ratio == 1) return l10n.verdictPerfect;
    if (ratio >= .7) return l10n.verdictGreat;
    if (ratio >= .4) return l10n.verdictOkay;
    return l10n.verdictLow;
  }

  /// Renders the score card itself to a PNG, so what is shared is exactly
  /// what the player sees.
  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final text = l10n.shareText(
      widget.result.score,
      widget.result.total,
      context.categoryName(widget.result.category),
    );
    try {
      final boundary =
          _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await services.sharer.share(png: data!.buffer.asUint8List(), text: text);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = widget.result;
    final category = context.categoryName(result.category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _card,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: OrbitColors.raised,
              borderRadius: BorderRadius.circular(OrbitRadius.card),
              border: Border.all(color: OrbitColors.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScoreReveal(score: result.score, total: result.total),
                  OrbitLabel(l10n.finalScore(category)),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      _verdict(context).toUpperCase(),
                      style: orbitHeading(44),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OrbitChip(
                        label: l10n.correctChip,
                        count: result.score,
                        selected: true,
                        color: OrbitColors.correct,
                      ),
                      OrbitChip(
                        label: l10n.missedChip,
                        count: result.total - result.score,
                      ),
                      if (result.mode == QuizMode.daily)
                        OrbitChip(label: l10n.dailyBadge),
                      if (result.timed) OrbitChip(label: l10n.timedBadge),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.blur_on,
                          size: 18,
                          color: OrbitColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(l10n.appTitle, style: orbitHeading(18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OrbitOutlinedButton(
          label: l10n.shareResult,
          icon: Icons.ios_share,
          onPressed: _share,
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: widget.saver,
          builder: (context, _) => _SaveStatusPanel(
            saver: widget.saver,
            onOpenHistory: widget.onOpenHistory,
          ),
        ),
        const SizedBox(height: 24),
        if (widget.onRetry != null)
          OrbitButton(
            label: l10n.tryAgain,
            icon: Icons.refresh,
            onPressed: widget.onRetry,
          ),
        if (widget.onPractice != null) ...[
          Text(
            l10n.dailyComeBack,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OrbitButton(
            label: l10n.playPractice,
            icon: Icons.play_arrow_rounded,
            onPressed: widget.onPractice,
          ),
        ],
        const SizedBox(height: 12),
        OrbitOutlinedButton(
          label: l10n.chooseAnotherCategory,
          icon: Icons.grid_view_rounded,
          onPressed: widget.onExit,
        ),
        const SizedBox(height: 48),
        Semantics(
          header: true,
          child: Text(l10n.yourAnswers, style: orbitHeading(36)),
        ),
        const SizedBox(height: 16),
        AnswerReviewList(
          answers: result.answers,
          bankVersion: result.questionSetVersion,
        ),
      ],
    );
  }
}

/// Counts the score up over 600 ms. The spoken score is complete from the
/// first frame; only the visible digits animate.
class _ScoreReveal extends StatefulWidget {
  const _ScoreReveal({required this.score, required this.total});
  final int score;
  final int total;

  @override
  State<_ScoreReveal> createState() => _ScoreRevealState();
}

class _ScoreRevealState extends State<_ScoreReveal>
    with SingleTickerProviderStateMixin {
  late final _reveal = AnimationController(
    vsync: this,
    duration: OrbitMotion.result,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (prefersReducedMotion(context)) {
      _reveal.value = 1;
    } else if (!_reveal.isAnimating && _reveal.value == 0) {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width >= 800 ? 160.0 : 120.0;
    final curve = CurvedAnimation(parent: _reveal, curve: Curves.easeOutCubic);
    return Semantics(
      label: context.l10n.scoreSemantic(widget.score, widget.total),
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: curve,
        builder: (context, _) => Opacity(
          opacity: .25 + .75 * curve.value,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${(widget.score * curve.value).round()}',
                  style: orbitHeading(size),
                ),
                TextSpan(
                  text: '/${widget.total}',
                  style: orbitHeading(size, color: OrbitColors.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveStatusPanel extends StatelessWidget {
  const _SaveStatusPanel({required this.saver, this.onOpenHistory});
  final AttemptSaver saver;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final account = AppScope.of(context).account;
    final (
      String label,
      String message,
      Color color,
      IconData icon,
    ) = switch (saver.status) {
      SaveStatus.unavailable => (
        l10n.notSaved,
        l10n.unavailableBody,
        OrbitColors.muted,
        Icons.cloud_off_outlined,
      ),
      SaveStatus.signedOut => (
        l10n.notSaved,
        l10n.signedOutBody,
        OrbitColors.muted,
        Icons.cloud_off_outlined,
      ),
      SaveStatus.saving => (
        l10n.saving,
        l10n.savingBody,
        OrbitColors.muted,
        Icons.cloud_upload_outlined,
      ),
      SaveStatus.saved => (
        l10n.saved,
        l10n.savedBody,
        OrbitColors.correct,
        Icons.cloud_done_outlined,
      ),
      SaveStatus.alreadyPlayed => (
        l10n.alreadyPlayed,
        l10n.alreadyPlayedBody,
        OrbitColors.muted,
        Icons.event_available_outlined,
      ),
      SaveStatus.failed => (
        l10n.couldntSave,
        l10n.failedBody,
        OrbitColors.accent,
        Icons.error_outline,
      ),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: OrbitPanel(
        raised: true,
        padding: const EdgeInsets.all(20),
        borderColor: saver.status == SaveStatus.failed
            ? OrbitColors.accent
            : OrbitColors.hairline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (saver.status == SaveStatus.saving)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ExcludeSemantics(child: Icon(icon, size: 20, color: color)),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    style: orbitAction.copyWith(color: color, fontSize: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            if (saver.status == SaveStatus.signedOut && account != null) ...[
              const SizedBox(height: 16),
              AccountButton(
                session: account,
                signInLabel: l10n.signInToSave,
                onSignedIn: (user) => saver.claim(user.uid),
              ),
            ],
            if (saver.status == SaveStatus.failed) ...[
              const SizedBox(height: 16),
              OrbitOutlinedButton(
                label: l10n.retrySave,
                icon: Icons.refresh,
                onPressed: saver.retry,
              ),
            ],
            if ((saver.status == SaveStatus.saved ||
                    saver.status == SaveStatus.alreadyPlayed) &&
                onOpenHistory != null) ...[
              const SizedBox(height: 16),
              OrbitOutlinedButton(
                label: l10n.seeAllAttempts,
                icon: Icons.history,
                onPressed: onOpenHistory!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
