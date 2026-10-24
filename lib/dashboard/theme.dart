import 'package:flutter/material.dart';

import '../app/theme.dart';

/// The app's theme (tokens.css) with buttons sized to their content: the app's buttons fill the
/// phone's width, while the dashboard places several side by side (005 research R9).
ThemeData dashboardTheme(Brightness brightness) {
  final base = buildTheme(brightness);
  const size = Size(64, 44);
  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(style: base.filledButtonTheme.style?.copyWith(minimumSize: const WidgetStatePropertyAll(size))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: base.outlinedButtonTheme.style?.copyWith(minimumSize: const WidgetStatePropertyAll(size))),
    elevatedButtonTheme: ElevatedButtonThemeData(style: base.elevatedButtonTheme.style?.copyWith(minimumSize: const WidgetStatePropertyAll(size))),
    textButtonTheme: TextButtonThemeData(style: base.textButtonTheme.style?.copyWith(minimumSize: const WidgetStatePropertyAll(Size(48, 40)))),
  );
}
