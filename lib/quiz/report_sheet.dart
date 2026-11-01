import 'package:flutter/material.dart';

import '../account/account_button.dart';
import '../app/app_scope.dart';
import '../foundation/components.dart';
import '../foundation/theme.dart';
import 'report_repository.dart';

Future<void> showReportSheet(
  BuildContext context, {
  required String questionId,
  required String bankVersion,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (_) =>
      _ReportSheet(questionId: questionId, bankVersion: bankVersion),
);

enum _SendState { idle, sending, sent, failed }

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.questionId, required this.bankVersion});
  final String questionId;
  final String bankVersion;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? _reason;
  final _note = TextEditingController();
  _SendState _state = _SendState.idle;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send(ReportRepository reports, String ownerId) async {
    final reason = _reason;
    if (reason == null || _state == _SendState.sending) return;
    setState(() => _state = _SendState.sending);
    try {
      await reports.submit(
        ownerId: ownerId,
        report: QuestionReport(
          questionId: widget.questionId,
          bankVersion: widget.bankVersion,
          reason: reason,
          note: _note.text,
        ),
      );
      if (mounted) setState(() => _state = _SendState.sent);
    } catch (_) {
      if (mounted) setState(() => _state = _SendState.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final services = AppScope.of(context);
    final reports = services.reports;
    final account = services.account;
    final reasons = {
      ReportReason.wrongAnswer: l10n.reportWrong,
      ReportReason.unclear: l10n.reportUnclear,
      ReportReason.typo: l10n.reportTypo,
      ReportReason.other: l10n.reportOther,
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.reportTitle, style: orbitHeading(40)),
            ),
            const SizedBox(height: 20),
            if (reports == null || account == null)
              Text(
                l10n.reportUnavailable,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ListenableBuilder(
                listenable: account,
                builder: (context, _) {
                  final user = account.user;
                  if (user == null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reportSignIn,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        AccountButton(session: account),
                      ],
                    );
                  }
                  if (_state == _SendState.sent) {
                    return Semantics(
                      liveRegion: true,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: OrbitColors.correct,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.reportSent,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final MapEntry(key: reason, value: label)
                              in reasons.entries)
                            OrbitChip(
                              label: label,
                              selected: _reason == reason,
                              onTap: () => setState(() => _reason = reason),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _note,
                        maxLength: QuestionReport.maxNoteLength,
                        maxLines: 3,
                        minLines: 2,
                        decoration: InputDecoration(
                          labelText: l10n.reportNote,
                          filled: true,
                          fillColor: OrbitColors.raised,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              OrbitRadius.control,
                            ),
                            borderSide: const BorderSide(
                              color: OrbitColors.hairline,
                            ),
                          ),
                        ),
                      ),
                      if (_state == _SendState.failed) ...[
                        const SizedBox(height: 8),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            l10n.reportFailed,
                            style: const TextStyle(color: OrbitColors.accent),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      OrbitButton(
                        label: _state == _SendState.sending
                            ? l10n.reportSending
                            : l10n.reportSend,
                        icon: Icons.send_outlined,
                        onPressed:
                            _reason == null || _state == _SendState.sending
                            ? null
                            : () => _send(reports, user.uid),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
