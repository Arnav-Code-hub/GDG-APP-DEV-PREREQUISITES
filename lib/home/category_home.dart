import 'package:flutter/material.dart';

import '../foundation/ambient_background.dart';

import '../account/account_button.dart';
import '../account/account_session.dart';
import '../app/app_scope.dart';
import '../app/settings_screen.dart';
import '../foundation/category_mark.dart';
import '../foundation/components.dart';
import '../foundation/motion.dart';
import '../foundation/orbit_emblem.dart';
import '../foundation/theme.dart';
import '../quiz/history_screen.dart';
import '../quiz/models.dart';
import '../quiz/question_repository.dart';
import '../quiz/quiz_screen.dart';

/// Landing-page copy for each category. Kept here because it is
/// presentation, not quiz data.
extension on BuildContext {
  String description(QuizCategory category) => switch (category) {
    QuizCategory.anime => l10n.animeDescription,
    QuizCategory.sports => l10n.sportsDescription,
  };
  String detail(QuizCategory category) => switch (category) {
    QuizCategory.anime => l10n.animeDetail,
    QuizCategory.sports => l10n.sportsDetail,
  };
}

class CategoryHome extends StatefulWidget {
  const CategoryHome({super.key});

  @override
  State<CategoryHome> createState() => _CategoryHomeState();
}

class _CategoryHomeState extends State<CategoryHome> {
  final _categoriesKey = GlobalKey();
  final _animeFocus = FocusNode(debugLabel: 'Anime category');
  final _dailyKey = GlobalKey<_DailyChallengeState>();

  Future<void> _chooseCategories() async {
    final section = _categoriesKey.currentContext;
    if (section == null) return;
    await Scrollable.ensureVisible(
      section,
      duration: prefersReducedMotion(context)
          ? Duration.zero
          : OrbitMotion.route,
      curve: Curves.easeOutCubic,
    );
    if (mounted) _animeFocus.requestFocus();
  }

  Future<void> _play(QuizSetup setup) async {
    await Navigator.of(context).push(quizRoute(setup));
    _dailyKey.currentState?.refresh();
  }

  @override
  void dispose() {
    _animeFocus.dispose();
    super.dispose();
  }

  void _showCategory(QuizCategory category) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => _CategorySheet(
        category: category,
        onStart: (setup) {
          Navigator.pop(context);
          _play(setup);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: SelectionArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: OrbitSpace.maxWidth,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 800;
                      final gutter = wide ? 48.0 : 24.0;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: gutter),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Masthead(),
                            const SizedBox(height: 24),
                            _Hero(
                              wide: wide,
                              onChooseCategory: _chooseCategories,
                            ),
                            const SizedBox(height: 40),
                            _DailyChallenge(
                              key: _dailyKey,
                              wide: wide,
                              onPlay: _play,
                            ),
                            const SizedBox(height: 40),
                            const Divider(height: 1),
                            const SizedBox(height: 24),
                            SizedBox(
                              key: const ValueKey('category-section'),
                              width: double.infinity,
                              child: Wrap(
                                key: _categoriesKey,
                                spacing: 24,
                                runSpacing: 12,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      l10n.chooseCategoryHeading,
                                      style: orbitHeading(32),
                                    ),
                                  ),
                                  OrbitLabel(l10n.categorySectionNote),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (wide)
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (final category
                                        in QuizCategory.values) ...[
                                      if (category.index > 0)
                                        const SizedBox(width: 24),
                                      Expanded(
                                        child: _CategoryCard(
                                          category: category,
                                          focusNode:
                                              category == QuizCategory.anime
                                              ? _animeFocus
                                              : null,
                                          onExplore: () =>
                                              _showCategory(category),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            else
                              for (final category in QuizCategory.values) ...[
                                _CategoryCard(
                                  category: category,
                                  focusNode: category == QuizCategory.anime
                                      ? _animeFocus
                                      : null,
                                  onExplore: () => _showCategory(category),
                                ),
                                const SizedBox(height: 16),
                              ],
                            const SizedBox(height: 48),
                            const _Footer(),
                          ],
                        ),
                      );
                    },
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

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final account = services.account;
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Phones: the name moves into the menu so it is never cut off.
          final compact = constraints.maxWidth < 520;
          final accountButton = account == null
              ? null
              : AccountButton(
                  session: account,
                  compact: compact,
                  menuItems: [
                    if (services.attempts != null)
                      AccountMenuItem(
                        icon: Icons.history,
                        label: l10n.yourAttempts,
                        onSelected: (user) => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => HistoryScreen(ownerId: user.uid),
                          ),
                        ),
                      ),
                  ],
                );
          return Row(
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.blur_on, color: OrbitColors.accent, size: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.appTitle,
                  overflow: TextOverflow.ellipsis,
                  style: orbitHeading(30),
                ),
              ),
              if (accountButton != null)
                compact ? accountButton : Flexible(child: accountButton),
              const SizedBox(width: 8),
              OrbitIconButton(
                icon: Icons.tune,
                tooltip: l10n.settings,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Hero extends StatefulWidget {
  const _Hero({required this.wide, required this.onChooseCategory});
  final bool wide;
  final VoidCallback onChooseCategory;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _entrance;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: OrbitMotion.entrance,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  void _syncMotion() {
    if (prefersReducedMotion(context)) {
      _entrance.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _entrance.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didChangeAccessibilityFeatures() => _syncMotion();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TextEntrance(
          id: 'hero-heading-reveal',
          animation: _entrance.drive(
            CurveTween(
              curve: const Interval(.12, .84, curve: Curves.easeOutCubic),
            ),
          ),
          distance: 0,
          child: Semantics(
            header: true,
            label: l10n.heroSemantic,
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRect(
                  child: _TextEntrance(
                    id: 'hero-line-one',
                    animation: _entrance.drive(
                      CurveTween(
                        curve: const Interval(
                          .06,
                          .62,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                    distance: 28,
                    child: Text(
                      l10n.heroLineOne,
                      style: orbitHeading(widget.wide ? 112 : 64),
                    ),
                  ),
                ),
                ClipRect(
                  child: _TextEntrance(
                    id: 'hero-line-two',
                    animation: _entrance.drive(
                      CurveTween(
                        curve: const Interval(
                          .24,
                          .88,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                    distance: 28,
                    child: Text(
                      l10n.heroLineTwo,
                      style: orbitHeading(
                        widget.wide ? 112 : 64,
                        color: OrbitColors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _TextEntrance(
          id: 'hero-copy-reveal',
          animation: _entrance.drive(
            CurveTween(
              curve: const Interval(.4, 1, curve: Curves.easeOutCubic),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              l10n.heroBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 24),
        OrbitButton(
          label: l10n.chooseCategoryAction,
          onPressed: widget.onChooseCategory,
        ),
      ],
    );
    return Flex(
      direction: widget.wide ? Axis.horizontal : Axis.vertical,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.wide
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Flexible(flex: widget.wide ? 6 : 0, fit: FlexFit.tight, child: title),
        SizedBox(width: widget.wide ? 24 : 0, height: widget.wide ? 0 : 24),
        Flexible(
          flex: widget.wide ? 5 : 0,
          fit: FlexFit.tight,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.wide ? double.infinity : 280,
              ),
              child: const OrbitEmblem(),
            ),
          ),
        ),
      ],
    );
  }
}

class _TextEntrance extends StatelessWidget {
  const _TextEntrance({
    required this.id,
    required this.animation,
    required this.child,
    this.distance = 16,
  });
  final String id;
  final Animation<double> animation;
  final Widget child;
  final double distance;

  @override
  Widget build(BuildContext context) => FadeTransition(
    key: ValueKey(id),
    opacity: animation,
    alwaysIncludeSemantics: true,
    child: AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, distance * (1 - animation.value)),
        child: child,
      ),
    ),
  );
}

/// Today's challenge: one fixed set per category per day. Signed-in players
/// see whether they have done it; the stored record's ID enforces one go.
class _DailyChallenge extends StatefulWidget {
  const _DailyChallenge({super.key, required this.wide, required this.onPlay});
  final bool wide;
  final ValueChanged<QuizSetup> onPlay;

  @override
  State<_DailyChallenge> createState() => _DailyChallengeState();
}

class _DailyChallengeState extends State<_DailyChallenge> {
  Future<Map<QuizCategory, SavedAttempt>>? _done;
  String? _forUser;
  AccountSession? _account;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final account = AppScope.of(context).account;
    if (!identical(account, _account)) {
      _account?.removeListener(_accountChanged);
      _account = account?..addListener(_accountChanged);
    }
    _done ??= _load(_forUser = _account?.user?.uid);
  }

  /// Reloads only when the signed-in player actually changes.
  void _accountChanged() {
    final uid = _account?.user?.uid;
    if (uid == _forUser) return;
    _forUser = uid;
    refresh();
  }

  @override
  void dispose() {
    _account?.removeListener(_accountChanged);
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void refresh() {
    if (!mounted) return;
    setState(() {
      _done = _load(_forUser);
    });
  }

  Future<Map<QuizCategory, SavedAttempt>> _load(String? uid) async {
    final attempts = AppScope.of(context).attempts;
    if (uid == null || attempts == null) return const {};
    final found = <QuizCategory, SavedAttempt>{};
    for (final category in QuizCategory.values) {
      try {
        final saved = await attempts.find(
          uid,
          dailyAttemptId(category, _today),
        );
        if (saved != null) found[category] = saved;
      } catch (_) {
        // Unknown counts as not done; the database still allows only one.
      }
    }
    return found;
  }

  Future<void> _review(SavedAttempt attempt) async {
    final bank = await AppScope.of(context).questions.load();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttemptReviewScreen(
          attempt: attempt,
          questions: bank.questionsFor(attempt.category),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final account = AppScope.of(context).account;
    return ListenableBuilder(
      listenable: account ?? const AlwaysStoppedAnimation(0),
      builder: (context, _) {
        final uid = account?.user?.uid;
        return OrbitPanel(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder(
            future: _done,
            builder: (context, snapshot) {
              final done = snapshot.data ?? const {};
              final loading = snapshot.connectionState != ConnectionState.done;
              final actions = [
                for (final category in QuizCategory.values)
                  if (done[category] case final saved?)
                    OrbitOutlinedButton(
                      label:
                          '${context.categoryName(category)}  '
                          '${l10n.dailyDone(saved.score, saved.total)}',
                      icon: Icons.visibility_outlined,
                      onPressed: () => _review(saved),
                    )
                  else
                    OrbitOutlinedButton(
                      label: l10n.dailyPlay(context.categoryName(category)),
                      icon: Icons.play_arrow_rounded,
                      onPressed: loading
                          ? null
                          : () => widget.onPlay(
                              QuizSetup(
                                category: category,
                                mode: QuizMode.daily,
                                day: _today,
                              ),
                            ),
                    ),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.wb_sunny_outlined,
                          color: OrbitColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.dailyHeading,
                            style: orbitHeading(32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.dailyBody,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (account != null && uid == null) ...[
                    const SizedBox(height: 4),
                    OrbitLabel(l10n.dailySignInNote),
                  ],
                  const SizedBox(height: 20),
                  if (widget.wide)
                    Row(
                      children: [
                        for (final (i, action) in actions.indexed) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: action),
                        ],
                      ],
                    )
                  else
                    for (final (i, action) in actions.indexed) ...[
                      if (i > 0) const SizedBox(height: 12),
                      action,
                    ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Category details: topic, timed mode and a real Start action.
class _CategorySheet extends StatefulWidget {
  const _CategorySheet({required this.category, required this.onStart});
  final QuizCategory category;
  final ValueChanged<QuizSetup> onStart;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  Future<QuestionBank>? _bank;
  QuizTopic? _topic;
  bool _timed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bank ??= AppScope.of(context).questions.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final category = widget.category;
    final name = context.categoryName(category);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OrbitIconButton(
                  icon: Icons.close,
                  tooltip: l10n.closeCategory,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.inFocus(name), style: orbitHeading(44)),
            const SizedBox(height: 16),
            Text(
              context.detail(category),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            FutureBuilder(
              future: _bank,
              builder: (context, snapshot) {
                final topics = snapshot.data?.topicsFor(category) ?? const [];
                if (topics.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrbitLabel(l10n.topicLabel),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OrbitChip(
                          label: l10n.allTopics,
                          selected: _topic == null,
                          onTap: () => setState(() => _topic = null),
                        ),
                        for (final topic in topics)
                          OrbitChip(
                            label: topic.name,
                            selected: _topic?.id == topic.id,
                            onTap: () => setState(() => _topic = topic),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            OrbitLabel(l10n.howItWorks),
            const SizedBox(height: 12),
            OrbitPanel(
              raised: true,
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormatRow(
                    icon: Icons.quiz_outlined,
                    text: l10n.questionsCount(QuizFormat.questionsPerQuiz),
                  ),
                  _FormatRow(
                    icon: Icons.checklist_rounded,
                    text: l10n.choicesPerQuestion(
                      QuizFormat.optionsPerQuestion,
                    ),
                  ),
                  _FormatRow(
                    icon: Icons.star_outline_rounded,
                    text: l10n.onePointRule,
                  ),
                  const Divider(endIndent: 12),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.only(right: 12),
                    secondary: const Icon(
                      Icons.timer_outlined,
                      color: OrbitColors.accent,
                    ),
                    title: Text(l10n.timedMode),
                    subtitle: Text(
                      l10n.timedModeHint(QuizFormat.secondsPerQuestion),
                      style: const TextStyle(color: OrbitColors.muted),
                    ),
                    value: _timed,
                    activeThumbColor: OrbitColors.background,
                    activeTrackColor: OrbitColors.accent,
                    onChanged: (value) => setState(() => _timed = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OrbitButton(
              label: l10n.startQuiz(name),
              onPressed: () => widget.onStart(
                QuizSetup(category: category, topic: _topic, timed: _timed),
              ),
            ),
            const SizedBox(height: 12),
            OrbitOutlinedButton(
              label: l10n.backToCategories,
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onExplore,
    this.focusNode,
  });
  final QuizCategory category;
  final VoidCallback onExplore;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = context.categoryName(category);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.categoryGroupLabel(name),
      child: OrbitPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          name.toUpperCase(),
                          style: orbitHeading(54),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (MediaQuery.textScalerOf(context).scale(1) <= 1.3)
                  CategoryMark(sports: category == QuizCategory.sports),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.description(category),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Semantics(
              label: l10n.exploreCategory(name),
              button: true,
              onTap: onExplore,
              excludeSemantics: true,
              child: SizedBox(
                width: double.infinity,
                child: OrbitOutlinedButton(
                  label: l10n.exploreCategory(name),
                  onPressed: onExplore,
                  focusNode: focusNode,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 24, bottom: 32),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: OrbitColors.hairline)),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 32,
      runSpacing: 12,
      children: [
        OrbitLabel(context.l10n.appTitle, color: OrbitColors.ink),
        Text(context.l10n.footerTagline, style: orbitLabel),
      ],
    ),
  );
}

class _FormatRow extends StatelessWidget {
  const _FormatRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        ExcludeSemantics(
          child: Icon(icon, size: 20, color: OrbitColors.accent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}
