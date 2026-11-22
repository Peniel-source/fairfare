import '../fakes/fake_data_overrides.dart';

import 'dart:async';

import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/core/theme/app_theme.dart';

import '../fakes/fake_auth_repository.dart';

import 'package:fairfare/features/auth/presentation/auth_providers.dart';

import '../fakes/fake_settings_repository.dart';

import 'package:fairfare/features/settings/presentation/settings_providers.dart';
import 'package:fairfare/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthRepository extends FakeAuthRepository {
  Object? failure;
  Completer<void>? pending;
  int signInCalls = 0;
  int registerCalls = 0;
  int verificationEmails = 0;
  bool verified = false;
  String? emailUsed;
  String? nameUsed;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    signInCalls++;
    await pending?.future;
    if (failure != null) throw failure!;
    await super.signInWithEmail(email, password);
  }

  @override
  Future<void> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    registerCalls++;
    emailUsed = email;
    nameUsed = displayName;
    await super.registerWithEmail(email, password, displayName);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (failure != null) throw failure!;
    emailUsed = email;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (failure != null) throw failure!;
    verificationEmails++;
  }

  @override
  Future<void> reloadUser() async {
    if (verified) await super.reloadUser();
  }
}

void main() {
  late _AuthRepository repository;

  setUp(() => repository = _AuthRepository());

  Future<ProviderContainer> pumpAuth(
    WidgetTester tester, {
    String path = '/login',
    bool dark = false,
    double textScale = 1,
  }) async {
    final container = ProviderContainer(
      overrides: [
        ...fakeDataOverrides(),
        authRepositoryProvider.overrideWithValue(repository),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
      ],
    );
    addTearDown(repository.dispose);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    router.go(path);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: dark
              ? AppTheme.dark(useGoogleFonts: false)
              : AppTheme.light(useGoogleFonts: false),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Finder field(String label) => find.ancestor(
    of: find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    ),
    matching: find.byType(TextFormField),
  );

  Future<void> press(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pump();
  }

  Future<void> enterLogin(WidgetTester tester) async {
    await tester.enterText(field('Email'), 'passenger@example.com');
    await tester.enterText(field('Password'), 'pass1234');
  }

  testWidgets('empty login validates without calling authentication', (
    tester,
  ) async {
    await pumpAuth(tester);
    await press(tester, 'Sign in');
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(repository.signInCalls, 0);
  });

  testWidgets(
    'wrong password is shown, clears when edited, and login can succeed',
    (tester) async {
      final container = await pumpAuth(tester);
      await enterLogin(tester);
      repository.failure = const WrongPasswordFailure();
      await press(tester, 'Sign in');
      await tester.pumpAndSettle();
      expect(find.text(const WrongPasswordFailure().message), findsOneWidget);
      await tester.enterText(field('Password'), 'correct123');
      await tester.pump();
      expect(find.text(const WrongPasswordFailure().message), findsNothing);
      repository.failure = null;
      await press(tester, 'Sign in');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        kHomeRoute,
      );
    },
  );

  testWidgets('pending login disables repeat submission and navigation', (
    tester,
  ) async {
    await pumpAuth(tester);
    await enterLogin(tester);
    repository.pending = Completer<void>();
    await press(tester, 'Sign in');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Create account'))
          .onPressed,
      isNull,
    );
    expect(tester.widget<TextFormField>(field('Email')).enabled, isFalse);
    expect(repository.signInCalls, 1);
    repository.pending!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'registration validates password confirmation before creating an account',
    (tester) async {
      await pumpAuth(tester, path: '/register');
      await enterLogin(tester);
      await tester.enterText(field('Display name'), 'Menes');
      await tester.enterText(field('Confirm password'), 'different123');
      await press(tester, 'Create account');
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(repository.registerCalls, 0);
    },
  );

  testWidgets('register, resend and check verification follow router state', (
    tester,
  ) async {
    final container = await pumpAuth(tester, path: '/register');
    await tester.enterText(field('Display name'), ' Menes ');
    await tester.enterText(field('Email'), ' passenger@example.com ');
    await tester.enterText(field('Password'), 'pass1234');
    await tester.enterText(field('Confirm password'), 'pass1234');
    await press(tester, 'Create account');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Verify your email'), findsOneWidget);
    expect(repository.emailUsed, 'passenger@example.com');
    expect(repository.nameUsed, 'Menes');
    container.read(routerProvider).go('/home/wallet');
    await tester.pumpAndSettle();
    expect(find.text('Verify your email'), findsOneWidget);

    repository.failure = const TooManyAttemptsFailure();
    await press(tester, 'Resend email');
    await tester.pumpAndSettle();
    expect(find.text(const TooManyAttemptsFailure().message), findsOneWidget);
    repository.failure = null;
    await press(tester, 'Resend email');
    await tester.pumpAndSettle();
    expect(repository.verificationEmails, 1);

    await press(tester, 'I’ve verified my email');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Your email is not verified yet.'),
      findsOneWidget,
    );
    repository.verified = true;
    await press(tester, 'I’ve verified my email');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      kHomeRoute,
    );

    container.read(routerProvider).go('/verify-email');
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      kHomeRoute,
    );
  });

  testWidgets('an unverified passenger can sign out', (tester) async {
    await pumpAuth(tester, path: '/register');
    await tester.enterText(field('Display name'), 'Menes');
    await enterLogin(tester);
    await tester.enterText(field('Confirm password'), 'pass1234');
    await press(tester, 'Create account');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await press(tester, 'Sign out');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Verify your email'), findsNothing);
  });

  testWidgets(
    'password reset handles errors and shows a neutral confirmation',
    (tester) async {
      await pumpAuth(tester);
      await press(tester, 'Forgot password?');
      await tester.pumpAndSettle();
      await tester.enterText(field('Email'), ' passenger@example.com ');
      repository.failure = const NetworkFailure();
      await press(tester, 'Send reset link');
      await tester.pumpAndSettle();
      expect(find.text(const NetworkFailure().message), findsOneWidget);
      repository.failure = null;
      await press(tester, 'Send reset link');
      await tester.pumpAndSettle();
      expect(repository.emailUsed, 'passenger@example.com');
      expect(find.textContaining('If an account exists'), findsOneWidget);
      await press(tester, 'Back to sign in');
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
    },
  );

  for (final layout in [
    ('/register', const Size(320, 568)),
    ('/login', const Size(640, 360)),
    ('/reset-password', const Size(900, 1200)),
  ]) {
    testWidgets(
      '${layout.$1} fits ${layout.$2} with large text and dark theme',
      (tester) async {
        tester.view.physicalSize = layout.$2;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpAuth(tester, path: layout.$1, dark: true, textScale: 1.5);
        await tester.ensureVisible(find.byType(TextButton).last);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
