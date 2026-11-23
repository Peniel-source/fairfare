// D6: Settings screen (D3) changes apply live, are saved, and logout (D2).
import 'dart:async';

import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/core/theme/app_theme.dart';
import 'package:fairfare/features/auth/domain/entities/auth_user.dart';
import 'package:fairfare/features/auth/domain/repositories/auth_repository.dart';
import 'package:fairfare/features/auth/presentation/auth_providers.dart';
import 'package:fairfare/features/report/domain/entities/report_enums.dart';

import '../fakes/fake_settings_repository.dart';

import 'package:fairfare/features/settings/domain/entities/app_settings.dart';
import 'package:fairfare/features/settings/presentation/settings_providers.dart';
import 'package:fairfare/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Signed in as a verified passenger; sign out can be made to fail.
class _Auth implements AuthRepository {
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? user = const AuthUser(
    id: 'alice',
    email: 'alice@example.com',
    displayName: 'Alice',
    emailVerified: true,
  );
  Failure? signOutFailure;
  int signOuts = 0;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield user;
    yield* _changes.stream;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    if (signOutFailure != null) throw signOutFailure!;
    user = null;
    _changes.add(null);
  }

  @override
  Future<void> registerWithEmail(String e, String p, String n) async {}
  @override
  Future<void> signInWithEmail(String e, String p) async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> sendPasswordReset(String e) async {}
  @override
  Future<void> sendEmailVerification() async {}
  @override
  Future<void> reloadUser() async {}

  void dispose() => _changes.close();
}

void main() {
  late _Auth auth;
  late FakeSettingsRepository settings;

  Future<ProviderContainer> pumpSettings(
    WidgetTester tester, {
    AppSettings saved = const AppSettings(),
  }) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    auth = _Auth();
    addTearDown(auth.dispose);
    settings = FakeSettingsRepository();
    await settings.save(saved);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          settingsRepositoryProvider.overrideWithValue(settings),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: AppTheme.light(useGoogleFonts: false),
            darkTheme: AppTheme.dark(useGoogleFonts: false),
            themeMode: ref.watch(themeModeProvider),
            home: const SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
  }

  testWidgets('the theme changes live and is saved', (tester) async {
    await pumpSettings(tester);
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.light,
    );

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
    expect(settings.load().themeMode, ThemeModeOption.dark);
  });

  testWidgets('the default time of day is saved', (tester) async {
    final container = await pumpSettings(tester);

    await tester.tap(find.text('Evening'));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsProvider).defaultTimeSegment,
      TimeSegment.evening,
    );
    expect(settings.load().defaultTimeSegment, TimeSegment.evening);
  });

  testWidgets('replay welcome shows the welcome screen again', (tester) async {
    await pumpSettings(tester, saved: const AppSettings(onboardingSeen: true));

    await tester.tap(find.text('Replay welcome'));
    await tester.pump();

    expect(settings.load().onboardingSeen, isFalse);
    expect(find.textContaining('welcome screen will show'), findsOneWidget);
  });

  testWidgets('shows the account and logs out after confirming', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(find.text('alice@example.com'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(auth.signOuts, 1);
    expect(find.text('Not signed in'), findsOneWidget);
  });

  testWidgets('cancelling the dialog keeps the passenger signed in', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(auth.signOuts, 0);
    expect(find.text('alice@example.com'), findsOneWidget);
  });

  testWidgets('a failed logout says why', (tester) async {
    await pumpSettings(tester);
    auth.signOutFailure = const NetworkFailure();

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('alice@example.com'), findsOneWidget);
  });
}
