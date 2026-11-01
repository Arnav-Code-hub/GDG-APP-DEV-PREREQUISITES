import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_orbit/main.dart';

import 'support/fonts.dart';
import 'support/keyboard.dart';

List<double> ringTransform(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const ValueKey('orbit-ring-rotation')))
    .transform
    .storage
    .toList();

double headingOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(find.byKey(const ValueKey('hero-heading-reveal')))
    .opacity
    .value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadOrbitFonts);
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets('manual pause survives a desktop to phone resize', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MainApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('Pause ring animation'));
    await tester.pump();
    final paused = ringTransform(tester);
    tester.view.physicalSize = const Size(375, 812);
    await tester.pump();
    expect(find.byTooltip('Resume ring animation'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(ringTransform(tester), paused);
    expect(tester.takeException(), isNull);
  });

  testWidgets('motion control is accessible at large text on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: const MainApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.ensureVisible(find.byTooltip('Pause ring animation'));
      await tester.pump();
      final node = tester.getSemantics(
        find.bySemanticsLabel('Pause ring animation'),
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      expect(find.byTooltip('Resume ring animation'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(tester.takeException(), isNull);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('ring pause control supports keyboard activation', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await tester.ensureVisible(find.byTooltip('Pause ring animation'));
    await focusWithTab(tester, find.byTooltip('Pause ring animation'));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byTooltip('Resume ring animation'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(find.byTooltip('Pause ring animation'), findsOneWidget);
  });

  testWidgets(
    'category sheets pause ring motion without replaying the heading',
    (tester) async {
      // Tall enough that the ring and the category cards are both on
      // screen, so a paused ring proves route coverage, not scrolling.
      tester.view.physicalSize = const Size(1440, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MainApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final explore = find.bySemanticsLabel('Explore Anime');
      expect(tester.getRect(explore).bottom, lessThan(1800));
      await tester.tap(explore);
      await tester.pump(const Duration(milliseconds: 500));
      final behindSheet = ringTransform(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(ringTransform(tester), behindSheet);
      await tester.tap(find.byTooltip('Close category details'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(ringTransform(tester), isNot(behindSheet));
      expect(headingOpacity(tester), 1);
    },
  );

  testWidgets('TickerMode stops rotation without skipping ahead on resume', (
    tester,
  ) async {
    await tester.pumpWidget(const TickerMode(enabled: true, child: MainApp()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const TickerMode(enabled: false, child: MainApp()));
    final stopped = ringTransform(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(ringTransform(tester), stopped);
    await tester.pumpWidget(const TickerMode(enabled: true, child: MainApp()));
    await tester.pump();
    expect(ringTransform(tester), stopped);
    await tester.pump(const Duration(seconds: 1));
    expect(ringTransform(tester), isNot(stopped));
  });

  testWidgets('heading reveals once while preserving its layout', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    expect(headingOpacity(tester), lessThan(1));
    final size = tester.getSize(
      find.byKey(const ValueKey('hero-heading-reveal')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(headingOpacity(tester), greaterThan(0));
    expect(headingOpacity(tester), lessThan(1));
    await tester.pump(const Duration(milliseconds: 650));
    expect(headingOpacity(tester), 1);
    expect(
      tester.getSize(find.byKey(const ValueKey('hero-heading-reveal'))),
      size,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(headingOpacity(tester), 1);
  });

  testWidgets('ring rotates, pauses in place and resumes', (tester) async {
    await tester.pumpWidget(const MainApp());
    await tester.pump();
    final initial = ringTransform(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(ringTransform(tester), isNot(initial));
    await tester.ensureVisible(find.byTooltip('Pause ring animation'));
    await tester.tap(find.byTooltip('Pause ring animation'));
    await tester.pump();
    final paused = ringTransform(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(ringTransform(tester), paused);
    await tester.tap(find.byTooltip('Resume ring animation'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(ringTransform(tester), isNot(paused));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  for (final preference in [
    const FakeAccessibilityFeatures(disableAnimations: true),
    const FakeAccessibilityFeatures(reduceMotion: true),
  ]) {
    testWidgets('honors reduced motion: $preference', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = preference;
      await tester.pumpWidget(const MainApp());
      await tester.pump();
      expect(headingOpacity(tester), 1);
      expect(find.byTooltip('Pause ring animation'), findsNothing);
      final still = ringTransform(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(ringTransform(tester), still);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }

  testWidgets('ring responds to motion preference changes at runtime', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await tester.pump(const Duration(seconds: 1));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    await tester.pump();
    final still = ringTransform(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(ringTransform(tester), still);
    expect(find.byTooltip('Pause ring animation'), findsNothing);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(ringTransform(tester), isNot(still));
    expect(find.byTooltip('Pause ring animation'), findsOneWidget);
  });

  testWidgets('ring stops offscreen and resumes when visible again', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await tester.pump(const Duration(seconds: 1));
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    final offscreen = ringTransform(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(ringTransform(tester), offscreen);
    position.jumpTo(0);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(ringTransform(tester), isNot(offscreen));
  });

  testWidgets(
    'ring pauses for background and preserves manual pause on return',
    (tester) async {
      await tester.pumpWidget(const MainApp());
      await tester.pump(const Duration(seconds: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final background = ringTransform(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(ringTransform(tester), background);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(ringTransform(tester), isNot(background));
      await tester.ensureVisible(find.byTooltip('Pause ring animation'));
      await tester.tap(find.byTooltip('Pause ring animation'));
      await tester.pump();
      final manualPause = ringTransform(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      expect(ringTransform(tester), manualPause);
      expect(find.byTooltip('Resume ring animation'), findsOneWidget);
    },
  );
}
