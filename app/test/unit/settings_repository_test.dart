// D6: settings saved with shared_preferences (D3) survive an app restart.
import 'package:fairfare/core/preferences/preferences_provider.dart';
import 'package:fairfare/features/report/domain/entities/report_enums.dart';
import 'package:fairfare/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:fairfare/features/settings/domain/entities/app_settings.dart';
import 'package:fairfare/features/settings/presentation/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fresh repository over whatever is stored, like the app after a restart.
Future<SharedPrefsSettingsRepository> reopen() async =>
    SharedPrefsSettingsRepository(await SharedPreferences.getInstance());

void expectSettings(
  AppSettings actual, {
  required ThemeModeOption themeMode,
  required bool onboardingSeen,
  required TimeSegment defaultTimeSegment,
  required String? lastCorridorId,
}) {
  expect(actual.themeMode, themeMode);
  expect(actual.onboardingSeen, onboardingSeen);
  expect(actual.defaultTimeSegment, defaultTimeSegment);
  expect(actual.lastCorridorId, lastCorridorId);
}

void main() {
  group('SharedPrefsSettingsRepository', () {
    test('a first launch uses the defaults', () async {
      SharedPreferences.setMockInitialValues({});

      expectSettings(
        (await reopen()).load(),
        themeMode: ThemeModeOption.system,
        onboardingSeen: false,
        defaultTimeSegment: TimeSegment.morning,
        lastCorridorId: null,
      );
    });

    test('restores every saved value', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsSettingsRepository.keyThemeMode: 'dark',
        SharedPrefsSettingsRepository.keyOnboardingSeen: true,
        SharedPrefsSettingsRepository.keyDefaultTimeSegment: 'lateNight',
        SharedPrefsSettingsRepository.keyLastCorridorId: 'kacyiru-kimironko',
      });

      expectSettings(
        (await reopen()).load(),
        themeMode: ThemeModeOption.dark,
        onboardingSeen: true,
        defaultTimeSegment: TimeSegment.lateNight,
        lastCorridorId: 'kacyiru-kimironko',
      );
    });

    test('what is saved is still there after a restart', () async {
      SharedPreferences.setMockInitialValues({});
      await (await reopen()).save(
        const AppSettings(
          themeMode: ThemeModeOption.light,
          onboardingSeen: true,
          defaultTimeSegment: TimeSegment.evening,
          lastCorridorId: 'remera-nyabugogo',
        ),
      );

      expectSettings(
        (await reopen()).load(),
        themeMode: ThemeModeOption.light,
        onboardingSeen: true,
        defaultTimeSegment: TimeSegment.evening,
        lastCorridorId: 'remera-nyabugogo',
      );
      // Enums are stored by name, so reordering an enum never changes them.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(SharedPrefsSettingsRepository.keyThemeMode),
        'light',
      );
      expect(
        prefs.getString(SharedPrefsSettingsRepository.keyDefaultTimeSegment),
        'evening',
      );
    });

    test('unknown stored names fall back to the defaults', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsSettingsRepository.keyThemeMode: 'purple',
        SharedPrefsSettingsRepository.keyDefaultTimeSegment: 'brunch',
      });

      final settings = (await reopen()).load();

      expect(settings.themeMode, ThemeModeOption.system);
      expect(settings.defaultTimeSegment, TimeSegment.morning);
    });

    test('clearing the last corridor removes its key', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsSettingsRepository.keyLastCorridorId: 'kacyiru-kimironko',
      });

      await (await reopen()).save(const AppSettings());

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey(SharedPrefsSettingsRepository.keyLastCorridorId),
        isFalse,
      );
    });
  });

  group('SettingsController', () {
    Future<ProviderContainer> start() async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('a theme change applies at once and survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await start();
      expect(first.read(themeModeProvider), ThemeMode.system);

      await first
          .read(settingsProvider.notifier)
          .setThemeMode(ThemeModeOption.dark);
      expect(first.read(themeModeProvider), ThemeMode.dark);

      final afterRestart = await start();
      expect(afterRestart.read(themeModeProvider), ThemeMode.dark);
    });

    test('the default time of day is saved for the Report screen', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await start();

      await first
          .read(settingsProvider.notifier)
          .setDefaultTimeSegment(TimeSegment.evening);

      final afterRestart = await start();
      expect(
        afterRestart.read(settingsProvider).defaultTimeSegment,
        TimeSegment.evening,
      );
    });
  });
}
