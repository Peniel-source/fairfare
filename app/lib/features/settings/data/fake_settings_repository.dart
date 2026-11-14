// Fake settings repository that stores data in memory.
import '../domain/entities/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  AppSettings load() => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }
}
