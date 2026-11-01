import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> focusWithTab(WidgetTester tester, Finder target) async {
  final element = target.evaluate().single;
  for (var attempt = 0; attempt < 8; attempt++) {
    var focused = false;
    FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
      ancestor,
    ) {
      if (ancestor == element) focused = true;
      return !focused;
    });
    if (focused) return;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('The requested control could not be reached with Tab.');
}
