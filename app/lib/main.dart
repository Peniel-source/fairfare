import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/preferences/preferences_provider.dart';
import 'firebase_options.dart';

/// D3: loads shared_preferences before the first frame, so the app starts in
/// the saved state (theme, default time of day, last corridor).
Future<SharedPreferences> _loadPreferences() => SharedPreferences.getInstance();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await _loadPreferences();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FairFareApp(),
    ),
  );
}
