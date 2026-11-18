import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/settings/presentation/settings_providers.dart';
import 'router.dart';

/// Root widget for FairFare. Uses MaterialApp.router with go_router.
/// The theme comes from D1; the theme mode is the saved setting from D3 and
/// changes live when the passenger picks another one.
class FairFareApp extends ConsumerWidget {
  const FairFareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FairFare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
