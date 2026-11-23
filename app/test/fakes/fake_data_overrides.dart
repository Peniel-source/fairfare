// the fake corridors, zones and receipt for tests that open a screen which
// reads them. put ...fakeDataOverrides() first in the overrides list.
import 'package:fairfare/features/corridors/presentation/corridor_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_corridor_repository.dart';
import 'fake_notarization_repository.dart';
import 'fake_zone_repository.dart';

List<Override> fakeDataOverrides() {
  return [
    corridorRepositoryProvider.overrideWithValue(FakeCorridorRepository()),
    zoneRepositoryProvider.overrideWithValue(FakeZoneRepository()),
    notarizationRepositoryProvider.overrideWithValue(
      FakeNotarizationRepository(),
    ),
  ];
}
