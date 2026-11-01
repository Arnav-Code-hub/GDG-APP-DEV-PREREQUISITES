import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_scope.dart';
import '../foundation/components.dart';
import '../foundation/theme.dart';
import 'answer_review.dart';
import 'models.dart';
import 'question_repository.dart';
import 'stats_screen.dart';

/// "1 Nov 2026, 15:42" in the device's local time and the app's language.
String formatAttemptDate(BuildContext context, DateTime value) {
  final locale = Localizations.maybeLocaleOf(context)?.toLanguageTag() ?? 'en';
  final local = value.toLocal();
  return '${DateFormat.yMMMd(locale).format(local)}, '
      '${DateFormat.Hm(locale).format(local)}';
}

/// The signed-in player's completed attempts, newest first, filterable by
/// category. Each opens a full answer review.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.ownerId});

  final String ownerId;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<(List<SavedAttempt>, QuestionBank)>? _loading;
  QuizCategory? _filter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading ??= _load();
  }

  Future<(List<SavedAttempt>, QuestionBank)> _load() {
    final services = AppScope.of(context);
    return (
      services.attempts!.history(widget.ownerId),
      services.questions.load(),
    ).wait;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OrbitPage(
      title: l10n.yourAttempts,
      child: FutureBuilder(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return OrbitMessage(
              title: l10n.historyDidntLoad,
              body: l10n.checkConnection,
              action: OrbitButton(
                label: l10n.tryAgain,
                icon: Icons.refresh,
                onPressed: () => setState(() {
                  _loading = _load();
                }),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null ||
              snapshot.connectionState != ConnectionState.done) {
            return OrbitLoading(label: l10n.loadingAttempts);
          }
          final (attempts, bank) = data;
          if (attempts.isEmpty) {
            return OrbitMessage(
              title: l10n.nothingHere,
              body: l10n.nothingHereBody,
            );
          }
          final shown = [
            for (final attempt in attempts)
              if (_filter == null || attempt.category == _filter) attempt,
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OrbitOutlinedButton(
                label: l10n.yourStats,
                icon: Icons.insights_outlined,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StatsScreen(attempts: attempts),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OrbitChip(
                    label: l10n.filterAll,
                    count: attempts.length,
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final category in QuizCategory.values)
                    OrbitChip(
                      label: context.categoryName(category),
                      count: attempts
                          .where((attempt) => attempt.category == category)
                          .length,
                      selected: _filter == category,
                      onTap: () => setState(() => _filter = category),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (shown.isEmpty)
                Text(
                  l10n.noCategoryAttempts(context.categoryName(_filter!)),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              for (final attempt in shown) ...[
                _AttemptTile(
                  attempt: attempt,
                  topic: bank.topicById(attempt.topicId),
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AttemptReviewScreen(
                        attempt: attempt,
                        questions: bank.questionsFor(attempt.category),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt, required this.onOpen, this.topic});
  final SavedAttempt attempt;
  final QuizTopic? topic;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = context.categoryName(attempt.category);
    final date = formatAttemptDate(context, attempt.completedAt);
    return Semantics(
      button: true,
      label: l10n.attemptSemantic(name, attempt.score, attempt.total, date),
      excludeSemantics: true,
      onTap: onOpen,
      child: Material(
        color: OrbitColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OrbitRadius.card),
          side: const BorderSide(color: OrbitColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic == null ? name : '$name: ${topic!.name}',
                        style: orbitHeading(28),
                      ),
                      const SizedBox(height: 6),
                      OrbitLabel(date),
                      if (attempt.mode == QuizMode.daily || attempt.timed) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (attempt.mode == QuizMode.daily)
                              OrbitChip(label: l10n.dailyBadge),
                            if (attempt.timed)
                              OrbitChip(label: l10n.timedBadge),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${attempt.score}',
                        style: orbitHeading(40),
                      ),
                      TextSpan(
                        text: '/${attempt.total}',
                        style: orbitHeading(40, color: OrbitColors.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right, color: OrbitColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only review of one saved attempt.
class AttemptReviewScreen extends StatelessWidget {
  const AttemptReviewScreen({
    super.key,
    required this.attempt,
    required this.questions,
  });
  final SavedAttempt attempt;
  final List<Question> questions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OrbitPage(
      title: l10n.reviewTitle(context.categoryName(attempt.category)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrbitLabel(formatAttemptDate(context, attempt.completedAt)),
          const SizedBox(height: 12),
          Semantics(
            label: l10n.scoreSemantic(attempt.score, attempt.total),
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${attempt.score}', style: orbitHeading(96)),
                  TextSpan(
                    text: '/${attempt.total}',
                    style: orbitHeading(96, color: OrbitColors.accent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          AnswerReviewList(
            answers: attempt.review(questions),
            bankVersion: attempt.questionSetVersion,
          ),
        ],
      ),
    );
  }
}
