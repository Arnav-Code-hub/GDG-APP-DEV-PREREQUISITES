import 'package:flutter/material.dart';

abstract final class OrbitColors {
  static const background = Color(0xFF0B0B0B);
  static const surface = Color(0xFF141414);
  static const raised = Color(0xFF1D1D1D);
  static const ink = Color(0xFFF1F0E9);
  static const muted = Color(0xFFA6A69E);
  static const line = Color(0xFF363632);

  /// Card edges: quieter than [line] so layered surfaces read as depth,
  /// not as boxes drawn around boxes.
  static const hairline = Color(0xFF262624);
  static const accent = Color(0xFFFF4938);

  /// Tinted fills behind the accent. Never used for text.
  static const accentSoft = Color(0x29FF4938);

  /// Correct-answer feedback. Always paired with text, never color alone.
  static const correct = Color(0xFF5BD68A);
  static const correctSoft = Color(0x225BD68A);
}

abstract final class OrbitSpace {
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const section = 48.0;
  static const maxWidth = 1280.0;
}

/// One radius per nesting level: controls inside cards are rounder-looking
/// only because they are smaller, never because they use a new value.
abstract final class OrbitRadius {
  static const control = 16.0;
  static const card = 24.0;
  static const sheet = 28.0;
}

abstract final class OrbitMotion {
  static const press = Duration(milliseconds: 120);
  static const question = Duration(milliseconds: 200);
  static const route = Duration(milliseconds: 350);
  static const entrance = Duration(milliseconds: 800);
  static const result = Duration(milliseconds: 600);
  static const orbit = Duration(seconds: 24);
}

TextStyle orbitHeading(double size, {Color color = OrbitColors.ink}) =>
    TextStyle(
      fontFamily: 'BarlowCondensed',
      fontWeight: FontWeight.w700,
      fontSize: size,
      // Hallmark 55a: uppercase heads that can wrap need 1.0 or more.
      height: 1.02,
      letterSpacing: -.5,
      color: color,
    );

/// Small supporting text: the body face a step smaller, sentence case and
/// untracked (Hallmark 64 and 67: no monospace or tracked-caps costume).
const orbitLabel = TextStyle(
  fontFamily: 'Barlow',
  fontSize: 14,
  height: 1.5,
  letterSpacing: 0,
  color: OrbitColors.muted,
);

/// Button text: the bundled condensed bold, so no weight is synthesised.
const orbitAction = TextStyle(
  fontFamily: 'BarlowCondensed',
  fontWeight: FontWeight.w700,
  fontSize: 19,
  letterSpacing: .2,
);

const _pill = StadiumBorder();

final orbitTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Barlow',
  brightness: Brightness.dark,
  scaffoldBackgroundColor: OrbitColors.background,
  colorScheme: const ColorScheme.dark(
    primary: OrbitColors.accent,
    onPrimary: OrbitColors.background,
    secondary: OrbitColors.ink,
    onSecondary: OrbitColors.background,
    surface: OrbitColors.surface,
    onSurface: OrbitColors.ink,
    error: OrbitColors.accent,
  ),
  dividerColor: OrbitColors.hairline,
  dividerTheme: const DividerThemeData(color: OrbitColors.hairline, space: 1),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 18, height: 1.6, color: OrbitColors.ink),
    bodyMedium: TextStyle(fontSize: 16, height: 1.6, color: OrbitColors.muted),
  ),
  tooltipTheme: const TooltipThemeData(
    textStyle: TextStyle(color: OrbitColors.background),
    decoration: BoxDecoration(
      color: OrbitColors.ink,
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: OrbitColors.surface,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    dragHandleColor: OrbitColors.line,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(OrbitRadius.sheet),
      ),
    ),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: OrbitColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(OrbitRadius.sheet)),
    ),
  ),
  snackBarTheme: const SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: OrbitColors.raised,
    contentTextStyle: TextStyle(color: OrbitColors.ink, fontSize: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(OrbitRadius.control)),
    ),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: OrbitColors.raised,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(OrbitRadius.control)),
      side: BorderSide(color: OrbitColors.hairline),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: OrbitColors.accent,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 56),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      shape: _pill,
      disabledBackgroundColor: OrbitColors.raised,
      disabledForegroundColor: OrbitColors.muted,
      textStyle: orbitAction,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: OrbitColors.ink,
      minimumSize: const Size(48, 48),
      shape: _pill,
      textStyle: orbitAction.copyWith(fontSize: 17),
    ),
  ),
);
