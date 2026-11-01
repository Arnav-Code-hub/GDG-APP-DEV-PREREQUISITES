import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../foundation/components.dart';
import '../foundation/theme.dart';
import 'models.dart';
import 'report_sheet.dart';

String optionLabel(Question question, int index) =>
    '${String.fromCharCode(65 + index)}. ${question.options[index]}';

/// Answer-by-answer review shared by Results and saved attempts. A null
/// entry is an answer whose question has left the question bank.
class AnswerReviewList extends StatelessWidget {
  const AnswerReviewList({
    super.key,
    required this.answers,
    required this.bankVersion,
  });
  final List<AnswerRecord?> answers;

  /// Sent with any report, so a fix targets the right edition.
  final String bankVersion;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, answer) in answers.indexed) ...[
        _ReviewCard(number: i + 1, answer: answer, bankVersion: bankVersion),
        if (i < answers.length - 1) const SizedBox(height: 12),
      ],
    ],
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.number,
    required this.answer,
    required this.bankVersion,
  });
  final int number;
  final AnswerRecord? answer;
  final String bankVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final answer = this.answer;
    final correct = answer?.isCorrect ?? false;
    final tone = answer == null
        ? OrbitColors.muted
        : correct
        ? OrbitColors.correct
        : OrbitColors.accent;
    return MergeSemantics(
      child: OrbitPanel(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: answer == null
                    ? OrbitColors.raised
                    : correct
                    ? OrbitColors.correctSoft
                    : OrbitColors.accentSoft,
                shape: const CircleBorder(),
              ),
              child: ExcludeSemantics(
                child: answer == null
                    ? Text('$number', style: orbitLabel)
                    : Icon(
                        correct
                            ? Icons.check
                            : answer.isTimedOut
                            ? Icons.timer_off_outlined
                            : Icons.close,
                        size: 18,
                        color: tone,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrbitLabel(l10n.questionNumber(number)),
                  const SizedBox(height: 4),
                  if (answer == null)
                    Text(
                      l10n.noLongerInQuiz,
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else ...[
                    Text(
                      answer.question.prompt,
                      style: Theme.of(context).textTheme.bodyMedium!
                          .copyWith(color: OrbitColors.ink),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      correct
                          ? l10n.correctOption(
                              optionLabel(
                                answer.question,
                                answer.selectedIndex,
                              ),
                            )
                          : answer.isTimedOut
                          ? l10n.timeRanOut
                          : l10n.youChose(
                              optionLabel(
                                answer.question,
                                answer.selectedIndex,
                              ),
                            ),
                      style: orbitLabel.copyWith(color: tone),
                    ),
                    if (!correct)
                      Text(
                        l10n.answerOption(
                          optionLabel(
                            answer.question,
                            answer.question.correctIndex,
                          ),
                        ),
                        style: orbitLabel.copyWith(color: OrbitColors.ink),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      answer.question.explanation,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: OrbitColors.muted,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(fontSize: 15),
                      ),
                      onPressed: () => showReportSheet(
                        context,
                        questionId: answer.question.id,
                        bankVersion: bankVersion,
                      ),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: Text(l10n.reportQuestion),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
