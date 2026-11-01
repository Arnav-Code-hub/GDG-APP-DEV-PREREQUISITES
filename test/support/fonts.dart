import 'package:flutter/services.dart';

Future<void> loadOrbitFonts() async {
  for (final entry in {
    'Barlow': 'assets/fonts/Barlow-Regular.ttf',
    'BarlowCondensed': 'assets/fonts/BarlowCondensed-Bold.ttf',
  }.entries) {
    await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value))).load();
  }
}
