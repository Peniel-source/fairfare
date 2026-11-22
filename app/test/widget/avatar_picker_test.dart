// A passenger with no avatar sees their initials and is invited to choose
// one; nothing is picked for them. Saving shows the choice everywhere.
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
}
