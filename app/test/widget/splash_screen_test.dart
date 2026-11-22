// The splash plays once, then hands over to wherever authRedirect sends the
// passenger. With animations turned off it moves on after a short hold.
import 'package:fairfare/core/theme/app_theme.dart';
import 'package:fairfare/features/auth/data/fake_auth_repository.dart';
import 'package:fairfare/features/auth/presentation/auth_providers.dart';
import 'package:fairfare/features/settings/data/fake_settings_repository.dart';
import 'package:fairfare/features/settings/presentation/settings_providers.dart';
import 'package:fairfare/features/splash/presentation/splash_screen.dart';
import 'package:fairfare/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _splashLabel = 'FairFare. Fair moto fares in Kigali';

Future<void> _pumpApp(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: AppTheme.light(useGoogleFonts: false),
          routerConfig: ref.watch(routerProvider),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('plays, then a signed-out passenger lands on Landing', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.pump();
    expect(find.bySemanticsLabel(_splashLabel), findsOneWidget);

    // Still on the splash halfway through.
    await tester.pump(kSplashDuration ~/ 2);
    expect(find.bySemanticsLabel(_splashLabel), findsOneWidget);

    await tester.pump(kSplashDuration);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(_splashLabel), findsNothing);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('with animations off it shows the final frame, then moves on', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await _pumpApp(tester);
    await tester.pump();
    expect(find.text('FAIR MOTO FARES · KIGALI'), findsOneWidget);

    await tester.pump(kSplashReducedMotionHold);
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);
  });
}
