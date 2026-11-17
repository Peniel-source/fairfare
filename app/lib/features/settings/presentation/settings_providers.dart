// Riverpod providers for the settings feature (D3).
//
// Other screens read settings like this:
//   final settings = ref.watch(settingsProvider);          // rebuilds on change
//   ref.read(settingsProvider.notifier).setLastCorridorId(id);   // A5
//   settings.defaultTimeSegment                            // C1 default
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_provider.dart';
import '../../report/domain/entities/report_enums.dart';
import '../data/shared_prefs_settings_repository.dart';
import '../domain/entities/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

/// Provider for the SettingsRepository implementation.
///
/// Settings are local to the phone and never touch Firestore, so this always
/// uses shared_preferences, whatever AppConstants.useFakeData says. Tests
/// override it with FakeSettingsRepository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SharedPrefsSettingsRepository(ref.watch(sharedPreferencesProvider));
});

/// The current AppSettings. Loaded once, synchronously, from the repository
/// (preferences are already in memory before the first frame).
final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

/// Holds the settings in memory and writes every change through the
/// repository, so it is still applied after the app restarts.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> setThemeMode(ThemeModeOption mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setDefaultTimeSegment(TimeSegment segment) =>
      _update(state.copyWith(defaultTimeSegment: segment));

  Future<void> setOnboardingSeen(bool seen) =>
      _update(state.copyWith(onboardingSeen: seen));

  Future<void> setLastCorridorId(String corridorId) =>
      _update(state.copyWith(lastCorridorId: corridorId));

  /// Updates the UI first, then saves. Screens rebuild instantly (the theme
  /// changes live) and the write finishes in the background.
  Future<void> _update(AppSettings next) {
    state = next;
    return ref.read(settingsRepositoryProvider).save(next);
  }
}

/// The Flutter ThemeMode for MaterialApp, derived from the saved option.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final option = ref.watch(settingsProvider.select((s) => s.themeMode));
  return switch (option) {
    ThemeModeOption.system => ThemeMode.system,
    ThemeModeOption.light => ThemeMode.light,
    ThemeModeOption.dark => ThemeMode.dark,
  };
});
