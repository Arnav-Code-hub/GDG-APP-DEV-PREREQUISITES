import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_orbit/main.dart';

import 'support/fonts.dart';
import 'support/keyboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadOrbitFonts);
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets(
    'hero action reaches categories and hands keyboard focus to the first one',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pumpWidget(const MainApp());
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(position.pixels, 0);
      await focusWithTab(
        tester,
        find.widgetWithText(FilledButton, 'Choose your category'),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      final section = tester.getRect(
        find.byKey(const ValueKey('category-section')),
      );
      expect(section.overlaps(Offset.zero & tester.view.physicalSize), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Anime, in focus.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'headline lines reveal in sequence without hiding its accessible name',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(const MainApp());
        expect(find.bySemanticsLabel('Know it? Prove it.'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 180));
        final first = tester
            .widget<FadeTransition>(find.byKey(const ValueKey('hero-line-one')))
            .opacity
            .value;
        final second = tester
            .widget<FadeTransition>(find.byKey(const ValueKey('hero-line-two')))
            .opacity
            .value;
        expect(first, greaterThan(second));
        await tester.pump(const Duration(milliseconds: 800));
        expect(
          tester
              .widget<FadeTransition>(
                find.byKey(const ValueKey('hero-line-two')),
              )
              .opacity
              .value,
          1,
        );
        expect(find.bySemanticsLabel('Know it? Prove it.'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );
}
