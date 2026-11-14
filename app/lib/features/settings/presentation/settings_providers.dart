// Riverpod providers for the settings feature.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/fake_settings_repository.dart';
import '../domain/entities/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

/// Provider for the SettingsRepository implementation.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  if (AppConstants.useFakeData) {
    return FakeSettingsRepository();
  }
  // TODO(D3): return SharedPrefsSettingsRepository() when shared_preferences wiring is ready.
  throw UnimplementedError('SharedPrefsSettingsRepository not yet implemented');
});

/// Provider for the current AppSettings state.
/// Loads settings from the repository when first accessed.
final settingsProvider = StateProvider<AppSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).load();
});
