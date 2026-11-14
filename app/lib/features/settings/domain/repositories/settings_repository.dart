// Repository for app settings stored in shared_preferences.
import '../entities/app_settings.dart';

abstract class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings settings);
}
