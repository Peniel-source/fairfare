import 'dart:async';

import 'package:fairfare/core/theme/app_theme.dart';
import 'package:fairfare/core/utils/formatters.dart';
import 'package:fairfare/features/corridors/domain/entities/corridor.dart';
import 'package:fairfare/features/corridors/domain/entities/corridor_stats.dart';
import 'package:fairfare/features/corridors/domain/repositories/corridor_repository.dart';
import 'package:fairfare/features/corridors/presentation/corridor_providers.dart';
import 'package:fairfare/features/landing/presentation/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _corridor = Corridor(
  id: 'test-corridor',
  fromArea: 'Kacyiru',
  toArea: 'Kimironko',
);

CorridorStats _stats({int high = 1200, int sampleSize = 24}) => CorridorStats(
  corridorId: _corridor.id,
  median: 1000,
  low: 800,
  high: high,
  sampleSize: sampleSize,
  confidence: 'Well covered',
  updatedAt: DateTime(2026),
);

class _CorridorRepository implements CorridorRepository {
  final stream = StreamController<CorridorStats?>.broadcast();
  List<Corridor> corridors = [_corridor];
  int attempts = 0;
  String? watchedId;

  @override
  Future<List<Corridor>> popularCorridors() async {
    attempts++;
    return corridors;
  }

  @override
  Stream<CorridorStats?> watchStats(String corridorId) {
    watchedId = corridorId;
    return stream.stream;
  }

  @override
  Future<List<Corridor>> searchCorridors(String query) async => corridors;
}

void main() {
  late _CorridorRepository repository;

  setUp(() {
    repository = _CorridorRepository();
  });

  tearDown(() async {
    await repository.stream.close();
  });

  Future<void> pumpLanding(
    WidgetTester tester, {
    bool dark = false,
    double textScale = 1,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const LandingScreen()),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (_, _) => const Scaffold(body: Text('Register destination')),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, _) => const Scaffold(body: Text('Login destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [corridorRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          theme: dark
              ? AppTheme.dark(useGoogleFonts: false)
              : AppTheme.light(useGoogleFonts: false),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('loads the selected corridor and updates its fare preview', (
    tester,
  ) async {
    await pumpLanding(tester);
    expect(find.text('Loading fare preview…'), findsOneWidget);
    expect(repository.watchedId, _corridor.id);

    repository.stream.add(_stats());
    await tester.pumpAndSettle();
    expect(find.text('Kacyiru → Kimironko'), findsOneWidget);
    expect(find.text(Formatters.priceRange(800, 1200)), findsOneWidget);
    expect(find.text('24 reports · Well covered'), findsOneWidget);

    repository.stream.add(_stats(high: 1400));
    await tester.pumpAndSettle();
    expect(find.text(Formatters.priceRange(800, 1400)), findsOneWidget);
  });

  testWidgets('shows an empty preview when there are no corridors', (
    tester,
  ) async {
    repository.corridors = [];
    await pumpLanding(tester);
    await tester.pumpAndSettle();
    expect(find.text('No fares yet'), findsOneWidget);
    expect(repository.watchedId, isNull);
  });

  testWidgets('missing stats and zero reports show an empty preview', (
    tester,
  ) async {
    await pumpLanding(tester);
    repository.stream.add(null);
    await tester.pumpAndSettle();
    expect(find.text('No fares yet'), findsOneWidget);

    repository.stream.add(_stats(sampleSize: 0));
    await tester.pumpAndSettle();
    expect(find.text('No fares yet'), findsOneWidget);
  });

  testWidgets('retry reloads the fare preview after a failure', (tester) async {
    await pumpLanding(tester);
    repository.stream.addError(StateError('Unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load the fare preview.'), findsOneWidget);
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(repository.attempts, 2);

    repository.stream.add(_stats());
    await tester.pumpAndSettle();
    expect(find.text(Formatters.priceRange(800, 1200)), findsOneWidget);
  });

  for (final action in ['Create account', 'Sign in']) {
    testWidgets('$action opens the existing auth route', (tester) async {
      await pumpLanding(tester);
      repository.stream.add(_stats());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(action));
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      expect(
        find.text(
          action == 'Create account'
              ? 'Register destination'
              : 'Login destination',
        ),
        findsOneWidget,
      );
    });
  }

  for (final size in [
    const Size(320, 568),
    const Size(640, 360),
    const Size(900, 1200),
  ]) {
    testWidgets(
      'content and actions fit at $size with large text in dark mode',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpLanding(tester, dark: true, textScale: 1.5);
        repository.stream.add(_stats());
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Sign in'));
        expect(tester.takeException(), isNull);
        expect(find.text('Sign in').hitTestable(), findsOneWidget);
      },
    );
  }
}
