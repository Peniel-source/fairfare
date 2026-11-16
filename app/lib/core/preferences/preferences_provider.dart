// Gives the app one SharedPreferences instance, loaded before the first frame
// (D3).
//
// main.dart awaits SharedPreferences.getInstance() and overrides this
// provider, so everything that reads preferences can do it synchronously and
// the app starts in the saved state (theme included) with no flicker.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() with the instance '
    'from SharedPreferences.getInstance().',
  );
});
