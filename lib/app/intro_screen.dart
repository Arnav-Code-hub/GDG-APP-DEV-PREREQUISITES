import 'package:flutter/material.dart';

import '../foundation/ambient_background.dart';

import '../foundation/category_mark.dart';
import '../foundation/components.dart';
import '../foundation/motion.dart';
import '../foundation/theme.dart';
import 'app_scope.dart';

/// Two-screen first-run intro. Skippable at any point; finishing or skipping
/// marks it seen so it does not return unless the player asks for it.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, this.replay = false});

  /// Opened from Settings: closing pops back instead of entering the app.
  final bool replay;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    await AppScope.of(context).settings.setIntroSeen(true);
    if (mounted && widget.replay) Navigator.of(context).pop();
  }

  void _next() {
    if (_page == 1) {
      _done();
      return;
    }
    if (prefersReducedMotion(context)) {
      _pages.jumpToPage(1);
    } else {
      _pages.nextPage(duration: OrbitMotion.route, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      (
        l10n.introOneTitle,
        l10n.introOneBody,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryMark(sports: false),
            SizedBox(width: 24),
            CategoryMark(sports: true),
          ],
        ),
      ),
      (
        l10n.introTwoTitle,
        l10n.introTwoBody,
        const Icon(
          Icons.local_fire_department_outlined,
          size: 96,
          color: OrbitColors.accent,
        ),
      ),
    ];
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _done,
                        child: Text(l10n.introSkip),
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pages,
                        onPageChanged: (page) => setState(() => _page = page),
                        children: [
                          for (final (i, (title, body, art)) in pages.indexed)
                            Semantics(
                              label: l10n.introPage(i + 1, pages.length),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 48),
                                    ExcludeSemantics(child: art),
                                    const SizedBox(height: 48),
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        title.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: orbitHeading(52),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      body,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(color: OrbitColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ExcludeSemantics(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < pages.length; i++)
                            AnimatedContainer(
                              duration: OrbitMotion.press,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == _page ? 24 : 8,
                              height: 8,
                              decoration: ShapeDecoration(
                                color: i == _page
                                    ? OrbitColors.accent
                                    : OrbitColors.line,
                                shape: const StadiumBorder(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OrbitButton(
                        label: _page == 1 ? l10n.introStart : l10n.introNext,
                        icon: _page == 1
                            ? Icons.arrow_outward
                            : Icons.arrow_forward,
                        onPressed: _next,
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
