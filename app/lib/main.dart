import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

// Hook for D3: load preferences before the first frame.
// When D3 is ready, call this before runApp to seed the saved theme.
Future<void> _loadPreferences() async {
  // TODO(D3): load AppSettings from shared_preferences here
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _loadPreferences();
  runApp(const ProviderScope(child: FairFareApp()));
}
