// SettingsRepository backed by shared_preferences (D3).
//
// Each AppSettings field is stored under its own key. Enums are stored by
// name, so reordering an enum never changes a saved value. Unknown or missing
// values fall back to the AppSettings defaults.
import 'package:shared_preferences/shared_preferences.dart';

import '../../report/domain/entities/report_enums.dart';
import '../domain/entities/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const keyThemeMode = 'settings.themeMode';
  static const keyOnboardingSeen = 'settings.onboardingSeen';
  static const keyDefaultTimeSegment = 'settings.defaultTimeSegment';
  static const keyLastCorridorId = 'settings.lastCorridorId';

  @override
  AppSettings load() {
    const defaults = AppSettings();
    return AppSettings(
      themeMode: _byName(
        ThemeModeOption.values,
        _prefs.getString(keyThemeMode),
        defaults.themeMode,
      ),
      onboardingSeen:
          _prefs.getBool(keyOnboardingSeen) ?? defaults.onboardingSeen,
      defaultTimeSegment: _byName(
        TimeSegment.values,
        _prefs.getString(keyDefaultTimeSegment),
        defaults.defaultTimeSegment,
      ),
      lastCorridorId: _prefs.getString(keyLastCorridorId),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _prefs.setString(keyThemeMode, settings.themeMode.name),
      _prefs.setBool(keyOnboardingSeen, settings.onboardingSeen),
      _prefs.setString(keyDefaultTimeSegment, settings.defaultTimeSegment.name),
      if (settings.lastCorridorId == null)
        _prefs.remove(keyLastCorridorId)
      else
        _prefs.setString(keyLastCorridorId, settings.lastCorridorId!),
    ]);
  }

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
