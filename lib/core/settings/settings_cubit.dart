import 'dart:ui' show PlatformDispatcher;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
    required this.locale,
    required this.firstLaunchCompleted,
  });

  final ThemeMode themeMode;
  final Locale locale;
  final bool firstLaunchCompleted;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? firstLaunchCompleted,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      firstLaunchCompleted: firstLaunchCompleted ?? this.firstLaunchCompleted,
    );
  }

  @override
  List<Object?> get props =>
      [themeMode, locale.languageCode, firstLaunchCompleted];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit()
      : super(
          const SettingsState(
            themeMode: ThemeMode.light,
            locale: Locale('en'),
            firstLaunchCompleted: false,
          ),
        );

  static const _keyTheme = 'settings_theme_mode';
  static const _keyLocale = 'settings_locale';
  static const _keyFirstLaunch = 'settings_first_launch_completed';

  Future<void> hydrate() async {
    try {
      final p = await SharedPreferences.getInstance();
      final themeIndex = p.getInt(_keyTheme);
      final lang = p.getString(_keyLocale);
      final firstDone = p.getBool(_keyFirstLaunch) ?? false;
      final completedWelcome =
          firstDone && lang != null && lang.isNotEmpty;
      final mode = _themeModeFromStoredIndex(themeIndex);
      if (themeIndex == null ||
          themeIndex < 0 ||
          themeIndex >= ThemeMode.values.length ||
          ThemeMode.values[themeIndex] == ThemeMode.system) {
        await p.setInt(_keyTheme, mode.index);
      }
      emit(
        SettingsState(
          themeMode: mode,
          locale: Locale((lang != null && lang.isNotEmpty) ? lang : 'en'),
          firstLaunchCompleted: completedWelcome,
        ),
      );
    } on PlatformException catch (e, st) {
      assert(() {
        debugPrint('SettingsCubit.hydrate PlatformException: $e\n$st');
        return true;
      }());
    } catch (e, st) {
      assert(() {
        debugPrint('SettingsCubit.hydrate: $e\n$st');
        return true;
      }());
    }
  }

  /// Persists the current theme and locale, then marks the welcome step
  /// completed. Splash and routing treat [firstLaunchCompleted] as invalid
  /// unless a locale was stored (see [hydrate]).
  Future<bool> persistWelcomeSelectionsAndComplete() async {
    try {
      final p = await SharedPreferences.getInstance();
      final mode =
          state.themeMode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
      final code = state.locale.languageCode;
      await p.setInt(_keyTheme, mode.index);
      await p.setString(_keyLocale, code);
      await p.setBool(_keyFirstLaunch, true);
      emit(
        state.copyWith(
          firstLaunchCompleted: true,
          themeMode: mode,
        ),
      );
      return true;
    } on PlatformException catch (e, st) {
      assert(() {
        debugPrint(
          'SettingsCubit.persistWelcomeSelectionsAndComplete: $e\n$st',
        );
        return true;
      }());
      return false;
    } catch (e, st) {
      assert(() {
        debugPrint(
          'SettingsCubit.persistWelcomeSelectionsAndComplete: $e\n$st',
        );
        return true;
      }());
      return false;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final next = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    emit(state.copyWith(themeMode: next));
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_keyTheme, next.index);
    } on PlatformException catch (e, st) {
      assert(() {
        debugPrint('SettingsCubit.setThemeMode: $e\n$st');
        return true;
      }());
    }
  }

  Future<void> setLocale(Locale locale) async {
    emit(state.copyWith(locale: locale));
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_keyLocale, locale.languageCode);
    } on PlatformException catch (e, st) {
      assert(() {
        debugPrint('SettingsCubit.setLocale: $e\n$st');
        return true;
      }());
    }
  }

  ThemeMode _themeModeFromStoredIndex(int? index) {
    if (index == null || index < 0 || index >= ThemeMode.values.length) {
      return ThemeMode.light;
    }

    final mode = ThemeMode.values[index];
    if (mode != ThemeMode.system) return mode;

    final platformBrightness = PlatformDispatcher.instance.platformBrightness;
    return platformBrightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
  }
}
