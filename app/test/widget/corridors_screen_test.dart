//tests for the corridors screen: loading, empty and data
import 'dart:async';

import 'package:fairfare/core/theme/app_theme.dart';

import '../fakes/fake_corridor_repository.dart';

import 'package:fairfare/features/corridors/domain/entities/corridor.dart';
import 'package:fairfare/features/corridors/domain/entities/corridor_stats.dart';
import 'package:fairfare/features/corridors/domain/repositories/corridor_repository.dart';
import 'package:fairfare/features/corridors/presentation/corridor_providers.dart';
import 'package:fairfare/features/corridors/presentation/corridors_screen.dart';
import 'package:fairfare/features/profile/presentation/profile_providers.dart';

import '../fakes/fake_settings_repository.dart';

import 'package:fairfare/features/settings/presentation/settings_providers.dart';
import 'package:fairfare/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_profile_repository.dart';

//a repository we control. it gives the list we pass in, or never answers so we can see loading
class TestCorridorRepository implements CorridorRepository {
  TestCorridorRepository({this.corridors = const [], this.waiting = false});

  final List<Corridor> corridors;
  final bool waiting;
  final _never = Completer<List<Corridor>>();

  @override
  Stream<CorridorStats?> watchStats(String corridorId) => Stream.value(null);

  @override
  Future<List<Corridor>> searchCorridors(String query) {
    return waiting ? _never.future : Future.value(corridors);
  }

  @override
  Future<List<Corridor>> popularCorridors() {
    return waiting ? _never.future : Future.value(corridors);
  }
}

void main() {
  //puts the screen on a tall phone so every card is built
  Future<void> pumpScreen(
    WidgetTester tester,
    CorridorRepository repository,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = FakeProfileRepository();
    addTearDown(profile.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          corridorRepositoryProvider.overrideWithValue(repository),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
          profileRepositoryProvider.overrideWithValue(profile),
        ],
        child: MaterialApp(
          theme: AppTheme.light(useGoogleFonts: false),
          home: const CorridorsScreen(),
        ),
      ),
    );
  }

  testWidgets('shows loading while the routes are coming', (tester) async {
    await pumpScreen(tester, TestCorridorRepository(waiting: true));
    //only one pump, the loading spinner never stops moving
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
    expect(find.text('No routes found'), findsNothing);
  });

  testWidgets('shows the empty message when there are no routes', (
    tester,
  ) async {
    await pumpScreen(tester, TestCorridorRepository());
    await tester.pumpAndSettle();

    expect(find.text('No routes found'), findsOneWidget);
    expect(find.byType(LoadingView), findsNothing);
  });

  testWidgets('shows the routes in the list', (tester) async {
    await pumpScreen(tester, FakeCorridorRepository());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('All routes'), findsOneWidget);
    expect(find.text('ALU to Downtown'), findsWidgets);
    expect(find.text('No routes found'), findsNothing);
    expect(find.byType(LoadingView), findsNothing);
    expect(find.textContaining('24 reports'), findsWidgets);
  });

  testWidgets('typing an area that does not exist shows the empty message', (
    tester,
  ) async {
    await pumpScreen(tester, FakeCorridorRepository());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No routes found'), findsOneWidget);
  });
}
