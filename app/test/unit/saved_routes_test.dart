import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/features/auth/domain/entities/auth_user.dart';
import 'package:fairfare/features/auth/presentation/auth_providers.dart';
import 'package:fairfare/features/corridors/data/fake_corridor_repository.dart';
import 'package:fairfare/features/corridors/domain/usecases/search_corridors.dart';
import 'package:fairfare/features/saved_routes/data/firestore_saved_route_repository.dart';
import 'package:fairfare/features/saved_routes/domain/entities/saved_route.dart';
import 'package:fairfare/features/saved_routes/domain/saved_route_validation.dart';
import 'package:fairfare/features/saved_routes/domain/usecases/add_saved_route.dart';
import 'package:fairfare/features/saved_routes/domain/usecases/update_saved_route.dart';
import 'package:fairfare/features/saved_routes/domain/usecases/delete_saved_route.dart';
import 'package:fairfare/features/saved_routes/presentation/saved_route_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _route = SavedRoute(
  id: '',
  fromArea: 'Kacyiru',
  toArea: 'Kimironko',
  label: 'Work',
);

void main() {
  late FakeFirebaseFirestore store;
  late FirestoreSavedRouteRepository repository;

  setUp(() {
    store = FakeFirebaseFirestore();
    repository = FirestoreSavedRouteRepository(store, 'alice');
  });

  test(
    'areas and labels are required, bounded and different ignoring case',
    () {
      for (final value in [null, '', '   ', 'a' * 81]) {
        expect(SavedRouteValidation.area(value), isNotNull);
        expect(SavedRouteValidation.label(value), isNotNull);
      }
      expect(SavedRouteValidation.area('a' * 80), isNull);
      expect(SavedRouteValidation.label('a' * 80), isNull);
      expect(
        SavedRouteValidation.destination(' kacyiru ', 'KACYIRU'),
        isNotNull,
      );
      expect(SavedRouteValidation.destination('Kimironko', 'Kacyiru'), isNull);
    },
  );

  test('invalid additions never reach Firestore', () async {
    final add = AddSavedRoute(repository);
    for (final route in [
      const SavedRoute(
        id: '',
        fromArea: '',
        toArea: 'Kimironko',
        label: 'Work',
      ),
      const SavedRoute(
        id: '',
        fromArea: 'Kacyiru',
        toArea: ' kacyiru ',
        label: 'Work',
      ),
      const SavedRoute(id: '', fromArea: 'Kacyiru', toArea: 'Kimironko'),
    ]) {
      expect(() => add(route), throwsA(isA<ValidationFailure>()));
    }
    expect(
      (await store.collection('passengers/alice/savedRoutes').get()).size,
      0,
    );
  });

  test('add writes a normalized owner route with only allowed fields and a server timestamp', () async {
    await AddSavedRoute(repository)(
      const SavedRoute(
        id: '',
        fromArea: ' Kacyiru ',
        toArea: ' Kimironko ',
        label: ' Work ',
      ),
    );
    final documents = await store
        .collection('passengers/alice/savedRoutes')
        .get();
    expect(documents.size, 1);
    final data = documents.docs.single.data();
    expect(
      data.keys,
      unorderedEquals(['fromArea', 'toArea', 'label', 'createdAt']),
    );
    expect(data['fromArea'], 'Kacyiru');
    expect(data['toArea'], 'Kimironko');
    expect(data['label'], 'Work');
    expect(data['createdAt'], isA<Timestamp>());
    expect(
      (await store.collection('passengers/bob/savedRoutes').get()).size,
      0,
    );
    await AddSavedRoute(repository)(_route);
    final ids = (await repository.watchAll().first)
        .map((route) => route.id)
        .toSet();
    expect(ids.length, 2);
    expect(ids.every((id) => id.isNotEmpty), isTrue);
  });

  test('update preserves creation time and other passengers; delete removes only the owner route', () async {
    final createdAt = Timestamp.fromDate(DateTime(2026));
    final data = {
      'fromArea': 'Kacyiru',
      'toArea': 'Kimironko',
      'label': 'Work',
      'createdAt': createdAt,
    };
    await store.doc('passengers/alice/savedRoutes/shared-id').set(data);
    await store.doc('passengers/bob/savedRoutes/shared-id').set(data);
    await UpdateSavedRoute(repository)(
      const SavedRoute(
        id: 'shared-id',
        fromArea: ' Gisozi ',
        toArea: ' Kacyiru ',
        label: ' Home ',
      ),
    );
    final updated =
        (await store.doc('passengers/alice/savedRoutes/shared-id').get())
            .data()!;
    expect(updated['createdAt'], createdAt);
    expect(updated['fromArea'], 'Gisozi');
    expect(updated['label'], 'Home');
    expect(
      (await store.doc('passengers/bob/savedRoutes/shared-id').get())
          .data()!['label'],
      'Work',
    );
    expect((await repository.watchAll().first).single.label, 'Home');
    await DeleteSavedRoute(repository)('shared-id');
    expect(await repository.watchAll().first, isEmpty);
    expect(
      (await store.doc('passengers/bob/savedRoutes/shared-id').get()).exists,
      isTrue,
    );
  });

  test('saved routes load newest first', () async {
    await store.doc('passengers/alice/savedRoutes/older').set({
      'fromArea': 'Kacyiru',
      'toArea': 'Kimironko',
      'label': 'Old',
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(1),
    });
    await store.doc('passengers/alice/savedRoutes/newer').set({
      'fromArea': 'Gisozi',
      'toArea': 'Kacyiru',
      'label': 'New',
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(2),
    });
    expect((await repository.watchAll().first).map((route) => route.id), [
      'newer',
      'older',
    ]);
  });

  test('update and delete require an existing route id', () {
    expect(
      () => UpdateSavedRoute(repository)(_route),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => DeleteSavedRoute(repository)(''),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test(
    'auth changes switch the saved-route stream and sign-out removes access',
    () async {
      final events = StreamController<AuthUser?>.broadcast();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => events.stream),
          savedRoutesFirestoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(events.close);
      addTearDown(container.dispose);
      final subscription = container.listen(savedRoutesProvider, (_, _) {});
      addTearDown(subscription.close);
      for (final uid in ['alice', 'bob']) {
        await store.doc('passengers/$uid/savedRoutes/route').set({
          'fromArea': 'Kacyiru',
          'toArea': 'Kimironko',
          'label': uid,
          'createdAt': Timestamp.fromMillisecondsSinceEpoch(1),
        });
      }
      events.add(
        const AuthUser(
          id: 'alice',
          email: 'alice@example.com',
          emailVerified: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        (await container.read(savedRoutesProvider.future)).single.label,
        'alice',
      );
      events.add(
        const AuthUser(
          id: 'bob',
          email: 'bob@example.com',
          emailVerified: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        (await container.read(savedRoutesProvider.future)).single.label,
        'bob',
      );
      events.add(null);
      await Future<void>.delayed(Duration.zero);
      await expectLater(
        container.read(savedRoutesProvider.future),
        throwsA(isA<AuthFailure>()),
      );
    },
  );

  test(
    'opening a saved corridor matches its direction and ignores casing',
    () async {
      final corridors = await SearchCorridors(FakeCorridorRepository())(
        ' kacyiru ',
        toArea: ' KIMIRONKO ',
      );
      expect(corridors.length, 1);
      expect(corridors.single.fromArea, 'Kacyiru');
      expect(corridors.single.toArea, 'Kimironko');
    },
  );
}
