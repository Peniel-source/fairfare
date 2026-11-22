import '../fakes/fake_data_overrides.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/core/theme/app_theme.dart';
import 'package:fairfare/features/auth/domain/entities/auth_user.dart';
import 'package:fairfare/features/auth/presentation/auth_providers.dart';
import 'package:fairfare/features/saved_routes/data/firestore_saved_route_repository.dart';
import 'package:fairfare/features/saved_routes/domain/entities/saved_route.dart';
import 'package:fairfare/features/saved_routes/domain/repositories/saved_route_repository.dart';
import 'package:fairfare/features/saved_routes/presentation/saved_route_providers.dart';
import 'package:fairfare/features/saved_routes/presentation/saved_route_sheet.dart';
import 'package:fairfare/features/saved_routes/presentation/saved_routes_screen.dart';

import '../fakes/fake_settings_repository.dart';

import 'package:fairfare/features/settings/presentation/settings_providers.dart';
import 'package:fairfare/router.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ControlledRepository implements SavedRouteRepository {
  _ControlledRepository(this.inner);
  final SavedRouteRepository inner;
  Object? failure;
  Completer<void>? pending;
  int additions = 0;

  @override
  Stream<List<SavedRoute>> watchAll() => inner.watchAll();
  @override
  Future<void> add(SavedRoute route) async {
    additions++;
    await pending?.future;
    if (failure != null) throw failure!;
    await inner.add(route);
  }

  @override
  Future<void> update(SavedRoute route) => inner.update(route);
  @override
  Future<void> delete(String id) => inner.delete(id);
}

void main() {
  late FakeFirebaseFirestore store;
  late _ControlledRepository repository;

  setUp(() {
    store = FakeFirebaseFirestore();
    repository = _ControlledRepository(
      FirestoreSavedRouteRepository(store, 'alice'),
    );
  });

  Future<void> seedRoute() =>
      store.doc('passengers/alice/savedRoutes/route-1').set({
        'fromArea': 'Kacyiru',
        'toArea': 'Kimironko',
        'label': 'Work',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(1),
      });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Stream<List<SavedRoute>>? updates,
    bool settle = true,
    bool dark = false,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeDataOverrides(),
          savedRouteRepositoryProvider.overrideWithValue(repository),
          if (updates != null)
            savedRoutesProvider.overrideWith((ref) => updates),
        ],
        child: MaterialApp(
          theme: dark
              ? AppTheme.dark(useGoogleFonts: false)
              : AppTheme.light(useGoogleFonts: false),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const SavedRoutesScreen(),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
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

  Future<void> fillRoute(WidgetTester tester) async {
    await tester.enterText(field('Label'), ' Work ');
    await tester.enterText(field('Pickup area'), ' Kacyiru ');
    await tester.enterText(field('Drop-off area'), ' Kimironko ');
  }

  testWidgets('new passenger sees an empty list and can add a route', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('No saved routes yet'), findsOneWidget);
    await press(tester, 'Add route');
    await tester.pumpAndSettle();
    await fillRoute(tester);
    await press(tester, 'Save route');
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Kacyiru → Kimironko'), findsOneWidget);
    expect(find.byType(SavedRouteSheet), findsNothing);
    expect(
      (await store.collection('passengers/alice/savedRoutes').get()).size,
      1,
    );
  });

  testWidgets('empty fields and equal areas are rejected before saving', (
    tester,
  ) async {
    await pumpScreen(tester);
    await press(tester, 'Add route');
    await tester.pumpAndSettle();
    await press(tester, 'Save route');
    expect(find.text('Enter a route label'), findsOneWidget);
    expect(find.text('Enter an area'), findsNWidgets(2));
    await fillRoute(tester);
    await tester.enterText(field('Drop-off area'), 'KACYIRU');
    await press(tester, 'Save route');
    expect(find.text('Pickup and drop-off must be different'), findsOneWidget);
    expect(repository.additions, 0);
  });

  testWidgets('edit is prefilled and updates the existing route', (
    tester,
  ) async {
    await seedRoute();
    await pumpScreen(tester);
    await tester.tap(find.byTooltip('Edit Work'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(field('Pickup area')).controller!.text,
      'Kacyiru',
    );
    await tester.enterText(field('Label'), 'Campus');
    await press(tester, 'Save route');
    await tester.pumpAndSettle();
    expect(find.text('Campus'), findsOneWidget);
    final documents = await store
        .collection('passengers/alice/savedRoutes')
        .get();
    expect(documents.size, 1);
    expect(documents.docs.single.id, 'route-1');
  });

  testWidgets('delete asks for confirmation and cancel keeps the route', (
    tester,
  ) async {
    await seedRoute();
    await pumpScreen(tester);
    await tester.tap(find.byTooltip('Delete Work'));
    await tester.pumpAndSettle();
    await press(tester, 'Cancel');
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete Work'));
    await tester.pumpAndSettle();
    await press(tester, 'Delete');
    await tester.pumpAndSettle();
    expect(find.text('No saved routes yet'), findsOneWidget);
    expect(
      (await store.doc('passengers/alice/savedRoutes/route-1').get()).exists,
      isFalse,
    );
  });

  testWidgets('failed save keeps the form editable and can be retried', (
    tester,
  ) async {
    await pumpScreen(tester);
    await press(tester, 'Add route');
    await tester.pumpAndSettle();
    await fillRoute(tester);
    repository.failure = const NetworkFailure();
    await press(tester, 'Save route');
    await tester.pumpAndSettle();
    expect(find.text(const NetworkFailure().message), findsOneWidget);
    expect(tester.widget<TextFormField>(field('Label')).enabled, isTrue);
    repository.failure = null;
    await press(tester, 'Save route');
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('pending save prevents duplicate submissions', (tester) async {
    await pumpScreen(tester);
    await press(tester, 'Add route');
    await tester.pumpAndSettle();
    await fillRoute(tester);
    repository.pending = Completer<void>();
    await press(tester, 'Save route');
    expect(repository.additions, 1);
    expect(tester.widget<TextFormField>(field('Label')).enabled, isFalse);
    final saveButton = find.descendant(
      of: find.byType(SavedRouteSheet),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsOneWidget);
    expect(repository.additions, 1);
  });

  testWidgets('loading and failed reads show a retry that recovers', (
    tester,
  ) async {
    final updates = StreamController<List<SavedRoute>>.broadcast();
    addTearDown(updates.close);
    await pumpScreen(tester, updates: updates.stream, settle: false);
    expect(find.text('Loading saved routes…'), findsOneWidget);
    updates.addError(const NetworkFailure());
    await tester.pumpAndSettle();
    expect(find.text(const NetworkFailure().message), findsOneWidget);
    await press(tester, 'Try again');
    updates.add([]);
    await tester.pumpAndSettle();
    expect(find.text('No saved routes yet'), findsOneWidget);
  });

  testWidgets(
    'entry opens saved routes and a route opens only its corridor direction',
    (tester) async {
      await seedRoute();
      final container = ProviderContainer(
        overrides: [
          ...fakeDataOverrides(),
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(
                id: 'alice',
                email: 'alice@example.com',
                emailVerified: true,
              ),
            ),
          ),
          savedRouteRepositoryProvider.overrideWithValue(repository),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      router.go('/home/corridors');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light(useGoogleFonts: false),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Saved routes'));
      await tester.pumpAndSettle();
      expect(find.byType(SavedRoutesScreen), findsOneWidget);
      await press(tester, 'Work');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.queryParameters, {
        'from': 'Kacyiru',
        'to': 'Kimironko',
      });
      expect(find.text('Kacyiru to Kimironko'), findsOneWidget);
      expect(find.text('Kimironko to Kacyiru'), findsNothing);
      await press(tester, 'All routes');
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.queryParameters,
        isEmpty,
      );
      expect(find.text('Kimironko to Kacyiru'), findsWidgets);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(640, 360),
    const Size(900, 1200),
  ]) {
    testWidgets(
      'saved routes and form fit $size with larger text and keyboard',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await seedRoute();
        await pumpScreen(tester, dark: true, textScale: 1.5);
        await tester.tap(find.byTooltip('Edit Work'));
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 160);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save route'));
        await tester.pumpAndSettle();
        expect(find.text('Save route').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
