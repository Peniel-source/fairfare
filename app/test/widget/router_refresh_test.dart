// Checks that the router re-runs its redirect when the auth state changes
// (refreshListenable), without any manual navigation.
import 'package:fairfare/features/auth/data/fake_auth_repository.dart';
import 'package:fairfare/features/auth/presentation/auth_providers.dart';
import 'package:fairfare/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fairfare/features/settings/data/fake_settings_repository.dart';
import 'package:fairfare/features/settings/presentation/settings_providers.dart';
import 'package:fairfare/core/theme/app_theme.dart';

void main() {
  testWidgets('sign in and sign out move the app without manual navigation', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) =>
              MaterialApp.router(
                  theme: AppTheme.light(useGoogleFonts: false),
                  routerConfig: ref.watch(routerProvider)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);

    // Signing in only changes the auth stream; the router must react.
    // Not awaited: the fake's delay runs on the test clock, which only moves
    // when we pump.
    auth.signInWithEmail('a@example.com', 'secret123');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('How much do you pay?'), findsOneWidget);

    auth.signOut();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);
  });
}
