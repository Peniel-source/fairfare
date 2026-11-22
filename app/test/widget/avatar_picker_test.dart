// A passenger with no avatar sees their initials and is invited to choose
// one; nothing is picked for them. Saving shows the choice everywhere.
import 'dart:async';

import 'package:fairfare/core/theme/app_theme.dart';
import 'package:fairfare/features/profile/domain/entities/passenger.dart';
import 'package:fairfare/features/profile/presentation/profile_providers.dart';
import 'package:fairfare/features/profile/presentation/profile_screen.dart';
import 'package:fairfare/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_profile_repository.dart';

void main() {
  testWidgets('choose an avatar from the Women or Men set and save it', (
    tester,
  ) async {
    final repo = FakeProfileRepository(
      me: const Passenger(
        id: 'fake_user_1',
        displayName: 'Aline Uwase',
        email: 'aline@example.com',
      ),
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(useGoogleFonts: false),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No avatar yet: initials, and an invitation to choose.
    expect(find.text('AU'), findsWidgets);
    await tester.tap(find.text('Choose your avatar').last);
    await tester.pumpAndSettle();

    expect(find.text('WOMEN'), findsOneWidget);
    expect(find.text('MEN'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'Save avatar');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('avatar-w03')));
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

    await tester.tap(save);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Avatar updated'), findsOneWidget);
    expect(find.text('Choose your avatar'), findsNothing);
    final header = tester.widget<UserAvatar>(find.byType(UserAvatar).first);
    expect(header.avatar, 'w03');
  });

  testWidgets('closing the sheet while saving is safe, and the save finishes', (
    tester,
  ) async {
    final repo = _HeldProfileRepository(
      me: const Passenger(
        id: 'fake_user_1',
        displayName: 'Aline Uwase',
        email: 'aline@example.com',
      ),
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(useGoogleFonts: false),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose your avatar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('avatar-m02')));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save avatar'));
    await tester.pump();

    // Close the sheet (back button) while the write is held, and let it go.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('WOMEN'), findsNothing);

    // Now the write completes: no error, Profile stays open, choice shows.
    repo.release.complete();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ProfileScreen), findsOneWidget);
    final header = tester.widget<UserAvatar>(find.byType(UserAvatar).first);
    expect(header.avatar, 'm02');
  });
}

/// Holds avatar writes until [release] completes.
class _HeldProfileRepository extends FakeProfileRepository {
  _HeldProfileRepository({super.me});

  final release = Completer<void>();

  @override
  Future<void> updateAvatar(String avatarId) async {
    await release.future;
    return super.updateAvatar(avatarId);
  }
}
