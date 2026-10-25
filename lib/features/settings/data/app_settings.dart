import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Text size choices in «حسابي» (docs/design/screens/Settings.dc.html): a factor on the phone's own
/// text size.
enum TextSizeChoice {
  small(0.9),
  normal(1.0),
  large(1.15);

  const TextSizeChoice(this.factor);
  final double factor;
}

/// Appearance chosen on this device: theme mode and text size (saved locally, applied app-wide).
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.textSize = TextSizeChoice.normal});

  final ThemeMode themeMode;
  final TextSizeChoice textSize;
}

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _theme = 'app.themeMode';
  static const _text = 'app.textSize';

  late SharedPreferencesAsync _store;

  @override
  Future<AppSettings> build() async {
    _store = SharedPreferencesAsync();
    T pick<T extends Enum>(List<T> values, String? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    return AppSettings(
      themeMode: pick(ThemeMode.values, await _store.getString(_theme), ThemeMode.system),
      textSize: pick(TextSizeChoice.values, await _store.getString(_text), TextSizeChoice.normal),
    );
  }

  AppSettings get _now => state.value ?? const AppSettings();

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(AppSettings(themeMode: mode, textSize: _now.textSize));
    await _store.setString(_theme, mode.name);
  }

  Future<void> setTextSize(TextSizeChoice size) async {
    state = AsyncData(AppSettings(themeMode: _now.themeMode, textSize: size));
    await _store.setString(_text, size.name);
  }
}

final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);
