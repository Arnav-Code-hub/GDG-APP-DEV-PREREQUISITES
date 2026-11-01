import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_orbit/foundation/components.dart';
import 'package:quiz_orbit/foundation/theme.dart';
import 'package:quiz_orbit/main.dart';

import 'support/fonts.dart';
import 'support/keyboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadOrbitFonts);
  setUp(() {
    TestWidgetsFlutterBinding
        .instance
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );
  testWidgets('both categories open their own readable details', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    for (final category in ['Anime', 'Sports']) {
      final button = find.bySemanticsLabel('Explore $category');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('$category, in focus.'), findsOneWidget);
      expect(find.text('10 questions'), findsOneWidget);
      expect(find.text('4 choices per question'), findsOneWidget);
      await tester.tap(find.byTooltip('Close category details'));
      await tester.pumpAndSettle();
      expect(find.text('$category, in focus.'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 640),
    const Size(375, 812),
    const Size(844, 390),
    const Size(1440, 1000),
  ]) {
    testWidgets('content stays reachable at $size and large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const MainApp(),
        ),
      );
      await tester.pumpAndSettle();
      final sports = find.bySemanticsLabel('Explore Sports');
      await tester.ensureVisible(sports);
      await tester.tap(sports);
      await tester.pumpAndSettle();
      expect(find.text('Sports, in focus.'), findsOneWidget);
      final back = find.text('Back to categories');
      await tester.ensureVisible(back);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.text('Sports, in focus.'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('category controls meet Android touch and label guidelines', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const MainApp());
      await tester.ensureVisible(find.bySemanticsLabel('Explore Anime'));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('screen-reader activation opens the matching category preview', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const MainApp());
      for (final category in ['Anime', 'Sports']) {
        final control = find.bySemanticsLabel('Explore $category');
        await tester.ensureVisible(control);
        final node = tester.getSemantics(control);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        // Use the same semantic action a screen reader sends, not a pointer tap.
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(find.text('$category, in focus.'), findsOneWidget);
        await tester.tap(find.byTooltip('Close category details'));
        await tester.pumpAndSettle();
      }
    } finally {
      handle.dispose();
    }
  });

  testWidgets('keyboard can open and dismiss a category preview', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await tester.ensureVisible(find.bySemanticsLabel('Explore Anime'));
    await focusWithTab(tester, find.bySemanticsLabel('Explore Anime'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Anime, in focus.'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Anime, in focus.'), findsNothing);
  });

  testWidgets('each category keeps its spoken details in one group', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const MainApp());
      for (final category in ['Anime', 'Sports']) {
        final group = find.bySemanticsLabel('$category category');
        expect(group, findsOneWidget);
        expect(
          find.descendant(
            of: group,
            matching: find.bySemanticsLabel('Explore $category'),
          ),
          findsOneWidget,
        );
      }
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
    'progress conveys the completed count visually and semantically',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: OrbitProgress(completed: 3, total: 10)),
          ),
        );
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          .3,
        );
        expect(
          tester.getSemantics(find.byType(OrbitProgress)).value,
          '3 of 10 questions completed',
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  test(
    'normal text colors meet contrast requirements on both app surfaces',
    () {
      for (final foreground in [
        OrbitColors.ink,
        OrbitColors.muted,
        OrbitColors.accent,
        OrbitColors.correct,
      ]) {
        for (final background in [
          OrbitColors.background,
          OrbitColors.surface,
        ]) {
          final contrast =
              (foreground.computeLuminance() + .05) /
              (background.computeLuminance() + .05);
          expect(contrast, greaterThanOrEqualTo(4.5));
        }
      }
    },
  );
}
