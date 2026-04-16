import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_preferences.dart';

final uiSettingsProvider =
    NotifierProvider<UiSettingsNotifier, UiSettingsState>(
      UiSettingsNotifier.new,
    );

class UiSettingsState {
  const UiSettingsState({
    required this.themeMode,
    required this.seedColor,
    required this.textScale,
  });

  final ThemeMode themeMode;
  final Color seedColor;
  final double textScale;

  UiSettingsState copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
    double? textScale,
  }) {
    return UiSettingsState(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      textScale: textScale ?? this.textScale,
    );
  }
}

class UiSettingsNotifier extends Notifier<UiSettingsState> {
  @override
  UiSettingsState build() {
    return UiSettingsState(
      themeMode: _modeFromValue(AppPreferences.getThemeMode()),
      seedColor: Color(AppPreferences.getThemeSeed()),
      textScale: AppPreferences.getTextScale(),
    );
  }

  static ThemeMode _modeFromValue(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _modeToValue(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await AppPreferences.setThemeMode(_modeToValue(mode));
  }

  Future<void> setSeedColor(Color color) async {
    state = state.copyWith(seedColor: color);
    await AppPreferences.setThemeSeed(color.toARGB32());
  }

  Future<void> setTextScale(double scale) async {
    state = state.copyWith(textScale: scale.clamp(0.85, 1.5));
    await AppPreferences.setTextScale(state.textScale);
  }
}
