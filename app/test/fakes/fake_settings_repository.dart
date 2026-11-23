// Fake settings repository that stores data in memory.
import 'package:fairfare/features/settings/domain/entities/app_settings.dart';
import 'package:fairfare/features/settings/domain/repositories/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  AppSettings load() => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }
}
