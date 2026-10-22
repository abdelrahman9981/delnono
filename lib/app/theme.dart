import 'package:flutter/material.dart';

const _fontFamily = 'ReadexPro';

/// Design tokens from docs/design/tokens.css, available to widgets through
/// `Theme.of(context).extension<AppColors>()!`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.blue,
    required this.blueDeep,
    required this.blueSoft,
    required this.pink,
    required this.pinkSoft,
    required this.yellow,
    required this.yellowSoft,
    required this.green,
    required this.greenSoft,
    required this.canvas,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.dangerBg,
    required this.dangerText,
  });

  final Color blue;
  final Color blueDeep;
  final Color blueSoft;
  final Color pink;
  final Color pinkSoft;
  final Color yellow;
  final Color yellowSoft;
  final Color green;
  final Color greenSoft;
  final Color canvas;
  final Color surface;
  final Color text;
  final Color muted;
  final Color border;
  final Color dangerBg;
  final Color dangerText;

  /// `:root` in tokens.css.
  static const light = AppColors(
    blue: Color(0xFF3A9AD9),
    blueDeep: Color(0xFF237DB8),
    blueSoft: Color(0xFFE9F5FC),
    pink: Color(0xFFF08AA3),
    pinkSoft: Color(0xFFFFF0F4),
    yellow: Color(0xFFF5C04A),
    yellowSoft: Color(0xFFFFF8DF),
    green: Color(0xFF4FBF9F),
    greenSoft: Color(0xFFE9F8F3),
    canvas: Color(0xFFF7F4EE),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF16324B),
    muted: Color(0xFF5F6F7E),
    border: Color(0xFFE8E6E1),
    dangerBg: Color(0xFFFDECEA),
    dangerText: Color(0xFF8A2F20),
  );

  /// `.dark` in tokens.css (Figma Make prototype). Accent colours are not overridden there, so they
  /// keep their `:root` values; `blueDeep` (text on `blueSoft`) is `.dark .blue-pill`.
  static const dark = AppColors(
    blue: Color(0xFF3A9AD9),
    blueDeep: Color(0xFF8FCBF0),
    blueSoft: Color(0xFF173B52),
    pink: Color(0xFFF08AA3),
    pinkSoft: Color(0xFF462B38),
    yellow: Color(0xFFF5C04A),
    yellowSoft: Color(0xFF44391F),
    green: Color(0xFF4FBF9F),
    greenSoft: Color(0xFF183F39),
    canvas: Color(0xFF0F1D28),
    surface: Color(0xFF172938),
    text: Color(0xFFEFF7FB),
    muted: Color(0xFF9DAFBB),
    border: Color(0xFF294050),
    dangerBg: Color(0xFF432723),
    dangerText: Color(0xFFFFC3B9),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 || other == null ? this : other;
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? AppColors.light : AppColors.dark;
  // `.btn-primary` text is white in both modes.
  const onBlue = Colors.white;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.blue,
    onPrimary: onBlue,
    primaryContainer: c.blueSoft,
    onPrimaryContainer: c.blueDeep,
    secondary: c.pink,
    onSecondary: onBlue,
    secondaryContainer: c.pinkSoft,
    onSecondaryContainer: c.text,
    tertiary: c.green,
    onTertiary: onBlue,
    tertiaryContainer: c.greenSoft,
    onTertiaryContainer: c.text,
    error: c.dangerText,
    onError: c.surface,
    errorContainer: c.dangerBg,
    onErrorContainer: c.dangerText,
    surface: c.surface,
    onSurface: c.text,
    onSurfaceVariant: c.muted,
    outline: c.border,
    outlineVariant: c.border,
  );

  // BRD text scale: body 13–15, small 11, titles 20–30 (docs/design/README.md).
  final textTheme = TextTheme(
    displaySmall: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
    headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: const TextStyle(fontSize: 15),
    bodyMedium: const TextStyle(fontSize: 13, height: 1.6),
    bodySmall: TextStyle(fontSize: 11, color: c.muted),
    labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    labelMedium: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
  ).apply(fontFamily: _fontFamily, bodyColor: c.text, displayColor: c.text);

  const radiusSm = BorderRadius.all(Radius.circular(14));
  const radius = BorderRadius.all(Radius.circular(18));
  const buttonSize = Size.fromHeight(48);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: _fontFamily,
    textTheme: textTheme,
    scaffoldBackgroundColor: c.canvas,
    extensions: [c],
    appBarTheme: AppBarTheme(
      backgroundColor: c.canvas,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: c.border)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        backgroundColor: c.blue,
        foregroundColor: onBlue,
        textStyle: textTheme.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: radiusSm),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        backgroundColor: c.surface,
        foregroundColor: c.text,
        side: BorderSide(color: c.border),
        textStyle: textTheme.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: radiusSm),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.blue, textStyle: textTheme.labelMedium),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      labelStyle: textTheme.labelMedium,
      helperStyle: textTheme.bodySmall,
      errorStyle: textTheme.bodySmall?.copyWith(color: c.dangerText),
      border: OutlineInputBorder(borderRadius: radiusSm, borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(borderRadius: radiusSm, borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(borderRadius: radiusSm, borderSide: BorderSide(color: c.blue, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: radiusSm, borderSide: BorderSide(color: c.dangerText)),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      side: BorderSide(color: c.border, width: 1.5),
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
  );
}
