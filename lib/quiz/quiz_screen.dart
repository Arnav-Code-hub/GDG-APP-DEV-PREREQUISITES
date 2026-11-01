import 'dart:async';

import 'package:flutter/material.dart';

import '../foundation/ambient_background.dart';

import '../app/app_scope.dart';
import '../foundation/components.dart';
import '../foundation/motion.dart';
import '../foundation/theme.dart';
import 'attempt_repository.dart';
import 'history_screen.dart';
import 'models.dart';
import 'question_repository.dart';
import 'quiz_controller.dart';
import 'quiz_picker.dart';
import 'results_view.dart';

/// Category entry: a short fade-and-rise, or an instant switch under reduced
/// motion.
Route<void> quizRoute(QuizSetup setup) => PageRouteBuilder<void>(
  settings: RouteSettings(name: '/quiz/${setup.category.id}'),
  transitionDuration: OrbitMotion.route,
  reverseTransitionDuration: OrbitMotion.question,
  pageBuilder: (context, _, _) => QuizScreen(setup: setup),
  transitionsBuilder: (context, animation, _, child) {
    if (prefersReducedMotion(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
);

/// Loads questions for one setup, runs its [QuizController], and shows the
/// result.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.setup});

  final QuizSetup setup;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Future<(QuizController, QuestionBank)>? _loading;
  QuizController? _quiz;
  AttemptSaver? _saver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading ??= _load();
  }

  Future<(QuizController, QuestionBank)> _load() async {
    final setup = widget.setup;
    final services = AppScope.of(context);
    final bank = await services.questions.load();
    final pool = bank.questionsFor(setup.category, topic: setup.topic);
    if (pool.length < QuizFormat.questionsPerQuiz) throw const _NoQuestions();
    final picked = setup.mode == QuizMode.daily
        ? QuizPicker.daily(
            bank.questionsFor(setup.category),
            setup.category,
            setup.day!,
          )
        : services.pickPractice(pool);
    _quiz?.dispose();
    final quiz = _quiz = QuizController(
      category: setup.category,
      questions: picked,
      questionSetVersion: bank.version,
      topicId: setup.topic?.id,
      mode: setup.mode,
      timed: setup.timed,
      fixedAttemptId: setup.fixedAttemptId,
    );
    return (quiz, bank);
  }

  void _finish() {
    final quiz = _quiz!;
    if (quiz.result != null) return;
    final result = quiz.finish();
    if (result == null) return;
    final services = AppScope.of(context);
    setState(() {
      // The owner is fixed now; signing out later cannot move this save.
      _saver = AttemptSaver(
        result: result,
        repository: services.attempts,
        ownerId: services.account?.user?.uid,
      );
    });
    services.feedback.finished(good: result.score * 2 >= result.total);
    services.settings.recordCompletedQuiz().then(
      (_) => services.reviews.afterResult(result),
      onError: (Object _) {},
    );
  }

  /// A practice retry draws a fresh set of questions.
  void _retry() {
    setState(() {
      _saver?.dispose();
      _saver = null;
      _loading = _load();
    });
  }

  void _practiceInstead() {
    Navigator.of(context)
        .pushReplacement(quizRoute(QuizSetup(category: widget.setup.category)));
  }

  Future<void> _confirmLeave() async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveTitle, style: orbitHeading(36)),
        content: Text(
          l10n.leaveBody,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepPlaying),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: OrbitColors.accent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.discardAndLeave),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  /// Opens the owner's history once this result has an owner and storage.
  VoidCallback? _historyOpener() {
    final owner = _saver?.ownerId;
    if (owner == null || AppScope.of(context).attempts == null) return null;
    return () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => HistoryScreen(ownerId: owner)),
    );
  }

  @override
  void dispose() {
    _saver?.dispose();
    _quiz?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final setup = widget.setup;
    final name = context.categoryName(setup.category);
    final title = setup.mode == QuizMode.daily
        ? l10n.dailyQuizTitle(name)
        : setup.topic == null
        ? l10n.quizTitle(name)
        : '${l10n.quizTitle(name)}: ${setup.topic!.name}';
    return FutureBuilder(
      future: _loading,
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        if (loaded == null ||
            snapshot.connectionState != ConnectionState.done) {
          return _Frame(
            title: title,
            closeLabel: l10n.backToCategories,
            onClose: () => Navigator.of(context).pop(),
            body: snapshot.hasError
                ? _LoadProblem(
                    empty: snapshot.error is _NoQuestions,
                    onRetry: () => setState(() {
                      _loading = _load();
                    }),
                  )
                : const _Loading(),
          );
        }
        final (quiz, bank) = loaded;
        return ListenableBuilder(
          listenable: quiz,
          builder: (context, _) {
            final result = quiz.result;
            return PopScope(
              canPop: !quiz.hasProgress,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) _confirmLeave();
              },
              child: _Frame(
                title: title,
                closeLabel: result == null
                    ? l10n.leaveQuiz
                    : l10n.backToCategories,
                onClose: () => Navigator.maybePop(context),
                progress: result == null
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: OrbitProgress(
                              completed: quiz.answeredCount,
                              current: quiz.index + 1,
                              total: quiz.total,
                            ),
                          ),
                          if (quiz.timed && !quiz.isLocked) ...[
                            const SizedBox(width: 16),
                            _QuestionTimer(
                              key: ValueKey('timer-${quiz.index}'),
                              onExpired: () {
                                quiz.timeOut();
                                if (quiz.canAdvance) quiz.next();
                              },
                            ),
                          ],
                        ],
                      )
                    : null,
                pageKey: ValueKey(result?.attemptId ?? quiz.index),
                body: result == null
                    ? _QuestionView(quiz: quiz)
                    : ResultsView(
                        result: result,
                        saver: _saver!,
                        onRetry: result.mode == QuizMode.practice
                            ? _retry
                            : null,
                        onPractice: result.mode == QuizMode.daily
                            ? _practiceInstead
                            : null,
                        onExit: () => Navigator.of(context).pop(),
                        onOpenHistory: _historyOpener(),
                      ),
                action: result == null
                    ? _QuizAction(quiz: quiz, onFinish: _finish)
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _NoQuestions implements Exception {
  const _NoQuestions();
}

/// Counts down one question in timed mode. A plain [Timer] drives it, so
/// expiry is an explicit action rather than the end of an animation, and it
/// pauses while the app is in the background.
class _QuestionTimer extends StatefulWidget {
  const _QuestionTimer({super.key, required this.onExpired});
  final VoidCallback onExpired;

  @override
  State<_QuestionTimer> createState() => _QuestionTimerState();
}

class _QuestionTimerState extends State<_QuestionTimer>
    with WidgetsBindingObserver {
  int _left = QuizFormat.secondsPerQuestion;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left <= 1) {
        _timer?.cancel();
        setState(() => _left = 0);
        widget.onExpired();
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_left == 0) return;
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _left <= 5;
    final color = urgent ? OrbitColors.accent : OrbitColors.ink;
    return Semantics(
      liveRegion: urgent,
      label: context.l10n.secondsLeftSemantic(_left),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: ShapeDecoration(
          color: urgent ? OrbitColors.accentSoft : OrbitColors.raised,
          shape: StadiumBorder(
            side: BorderSide(
              color: urgent ? OrbitColors.accent : OrbitColors.hairline,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              context.l10n.secondsLeft(_left),
              style: orbitLabel.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared page structure: top bar, scrollable centered body and an optional
/// pinned action that stays in the same place on every question.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.title,
    required this.onClose,
    required this.closeLabel,
    required this.body,
    this.progress,
    this.action,
    this.pageKey,
  });

  /// A new key starts the page fresh at the top, e.g. for each question.
  final Key? pageKey;
  final String title;
  final VoidCallback onClose;
  final String closeLabel;
  final Widget body;
  final Widget? progress;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AmbientBackground(
      strength: .6,
      child: SafeArea(
        bottom: action == null,
        child: Column(
          children: [
            _Bounded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    OrbitIconButton(
                      icon: Icons.close,
                      tooltip: closeLabel,
                      onPressed: onClose,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: orbitAction.copyWith(color: OrbitColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: pageKey,
                child: _Bounded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (progress != null) ...[
                          progress!,
                          const SizedBox(height: 32),
                        ],
                        body,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (action != null)
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: OrbitColors.background,
                  border: Border(top: BorderSide(color: OrbitColors.hairline)),
                ),
                child: SafeArea(
                  top: false,
                  child: _Bounded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: action,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Caps reading width and applies the app's phone/desktop gutters.
class _Bounded extends StatelessWidget {
  const _Bounded({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 24),
          child: child,
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: context.l10n.loadingQuestions,
    child: ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Flexible(child: OrbitLabel(context.l10n.loadingQuestions)),
          ],
        ),
      ),
    ),
  );
}

class _LoadProblem extends StatelessWidget {
  const _LoadProblem({required this.empty, required this.onRetry});
  final bool empty;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrbitLabel(
          empty ? l10n.noQuestions : l10n.somethingWrong,
          color: OrbitColors.accent,
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            empty ? l10n.quizEmpty : l10n.questionsDidntLoad,
            style: orbitHeading(48),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          empty ? l10n.quizEmptyBody : l10n.questionsErrorBody,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        if (!empty) ...[
          OrbitButton(
            label: l10n.tryAgain,
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
          const SizedBox(height: 12),
        ],
        OrbitOutlinedButton(
          label: l10n.backToCategories,
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _QuestionView extends StatefulWidget {
  const _QuestionView({required this.quiz});
  final QuizController quiz;

  @override
  State<_QuestionView> createState() => _QuestionViewState();
}

/// Each question is keyed, so it gets fresh state and fades in over 200 ms.
/// Answer targets never move and stay tappable throughout; the fade is
/// decoration only.
class _QuestionViewState extends State<_QuestionView>
    with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(
    vsync: this,
    duration: OrbitMotion.question,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (prefersReducedMotion(context)) {
      _fade.value = 1;
    } else if (!_fade.isAnimating && _fade.value == 0) {
      _fade.forward();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final question = quiz.current;
    final feedback = AppScope.of(context).feedback;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
      alwaysIncludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            label: context.l10n.questionSemantic(
              quiz.index + 1,
              quiz.total,
              question.prompt,
            ),
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.prompt,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.35,
                    color: OrbitColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          for (final (i, option) in question.options.indexed) ...[
            _OptionTile(
              letter: String.fromCharCode(65 + i),
              text: option,
              selected: quiz.selectedIndex == i,
              locked: quiz.isLocked,
              onTap: () {
                if (quiz.selectedIndex != i) feedback.selection();
                quiz.select(i);
              },
            ),
            const SizedBox(height: 12),
          ],
          if (quiz.timedOut)
            Semantics(
              liveRegion: true,
              child: OrbitLabel(
                context.l10n.timeRanOut,
                color: OrbitColors.accent,
              ),
            ),
        ],
      ),
    );
  }
}

/// One answer choice. During the quiz it only shows what is selected;
/// right and wrong are revealed on the Results screen after submitting.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final edge = selected ? OrbitColors.accent : OrbitColors.hairline;
    final duration = prefersReducedMotion(context)
        ? Duration.zero
        : OrbitMotion.press;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      child: AnimatedContainer(
        duration: duration,
        decoration: BoxDecoration(
          color: selected ? OrbitColors.raised : OrbitColors.surface,
          borderRadius: BorderRadius.circular(OrbitRadius.control),
          border: Border.all(color: edge, width: selected ? 2 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(OrbitRadius.control),
            onTap: locked ? null : onTap,
            focusColor: OrbitColors.raised,
            hoverColor: OrbitColors.raised,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: duration,
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: selected
                            ? OrbitColors.accent
                            : OrbitColors.raised,
                        shape: CircleBorder(side: BorderSide(color: edge)),
                      ),
                      child: Text(
                        letter,
                        style: orbitLabel.copyWith(
                          color: selected
                              ? OrbitColors.background
                              : OrbitColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.35,
                          color: locked && !selected
                              ? OrbitColors.muted
                              : OrbitColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pinned controls: Previous (untimed only) and one primary action whose
/// position never changes, Next question and then Submit quiz.
class _QuizAction extends StatelessWidget {
  const _QuizAction({required this.quiz, required this.onFinish});
  final QuizController quiz;
  final VoidCallback onFinish;

  Future<void> _confirmSubmit(BuildContext context) async {
    final l10n = context.l10n;
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.submitTitle, style: orbitHeading(36)),
        content: Text(
          l10n.submitBody,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.reviewAnswers),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: OrbitColors.accent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.submitQuiz),
          ),
        ],
      ),
    );
    if (submit == true) onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (
      String label,
      VoidCallback? action,
      IconData? icon,
    ) = !quiz.isAnswered
        ? (l10n.chooseAnswer, null, null)
        : quiz.isLastQuestion
        ? (
            l10n.submitQuiz,
            quiz.canFinish ? () => _confirmSubmit(context) : null,
            Icons.done_all,
          )
        : (
            l10n.nextQuestion,
            quiz.canAdvance ? quiz.next : null,
            Icons.arrow_forward,
          );
    return Row(
      children: [
        if (quiz.canGoBack) ...[
          OrbitIconButton(
            icon: Icons.arrow_back,
            tooltip: l10n.previousQuestion,
            onPressed: quiz.previous,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: OrbitButton(label: label, onPressed: action, icon: icon),
        ),
      ],
    );
  }
}
