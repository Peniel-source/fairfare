import 'package:fairfare/core/constants/app_constants.dart';

import '../fakes/fake_subscription_repository.dart';

import 'package:fairfare/features/pass/presentation/dial_prompt_card.dart';
import 'package:fairfare/features/pass/presentation/pass_providers.dart';
import 'package:fairfare/features/pass/domain/entities/subscription.dart';
import 'package:fairfare/features/pass/presentation/pass_screen.dart';
import 'package:fairfare/features/report/domain/entities/report_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeSubscriptionRepository repo;

  Future<void> pumpPass(WidgetTester tester) async {
    repo = FakeSubscriptionRepository();
    addTearDown(repo.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [subscriptionRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: PassScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submitReference(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextFormField), value);
    final submit = find.widgetWithText(FilledButton, 'Submit');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('new passenger sees No Pass, the steps and the form', (
    tester,
  ) async {
    await pumpPass(tester);
    expect(find.text('No Pass yet'), findsOneWidget);
    expect(find.text('How to pay'), findsOneWidget);
    expect(find.text('MoMo Pay merchant 2358998'), findsOneWidget);
    expect(find.text('*182*8*1*2358998*2000#'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('empty submit shows a validation message', (tester) async {
    await pumpPass(tester);
    await submitReference(tester, '');
    expect(
      find.text('Enter the reference from your payment SMS'),
      findsOneWidget,
    );
  });

  testWidgets('valid reference goes pending, then active after approval', (
    tester,
  ) async {
    await pumpPass(tester);
    await submitReference(tester, '12345678');
    expect(find.text('Payment pending'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);

    repo.approve('12345678');
    // Let the live update arrive and the message slide in; it stays a few
    // seconds, so it is still on screen here.
    await tester.pumpAndSettle();
    expect(find.text('Payment successful'), findsOneWidget);
    expect(
      find.text('Payment successful. Your Pass is now active'),
      findsOneWidget,
    );
  });

  testWidgets('a rejected payment shows not approved and the form again', (
    tester,
  ) async {
    await pumpPass(tester);
    await submitReference(tester, '12345678');
    repo.reject('12345678');
    await tester.pumpAndSettle();
    expect(find.text('Payment not approved'), findsOneWidget);
    expect(find.text('Payment successful'), findsNothing);
    // The pay steps and the form come back for another try.
    expect(find.text('How to pay'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TextFormField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(TextFormField), findsOneWidget);
  });

  test('success message only for this payment going pending to active', () {
    Subscription sub(String ref, SubscriptionStatus status) =>
        Subscription(reference: ref, amount: 2000, status: status);
    const p = SubscriptionStatus.pending, a = SubscriptionStatus.active;
    expect(justApproved(sub('R1', p), sub('R1', a)), isTrue);
    // Opening the screen on an already active Pass is not a new success.
    expect(justApproved(null, sub('R1', a)), isFalse);
    expect(justApproved(sub('R1', a), sub('R1', a)), isFalse);
    expect(justApproved(sub('R1', p), sub('R2', a)), isFalse);
    expect(
      justApproved(sub('R1', p), sub('R1', SubscriptionStatus.rejected)),
      isFalse,
    );
  });

  testWidgets('a used reference shows a clear message', (tester) async {
    await pumpPass(tester);
    await submitReference(tester, '1000000001');
    expect(find.textContaining('already used'), findsOneWidget);
    // Still no subscription, so the form stays for another try.
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Payment pending'), findsNothing);
  });

  testWidgets('no overflow in landscape on a small phone', (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpPass(tester);
    expect(tester.takeException(), isNull);
  });

  test('dial link encodes # so the dialer keeps the whole code', () {
    expect(
      dialUri(AppConstants.passDialCode).toString(),
      'tel:*182*8*1*2358998*2000%23',
    );
  });
}
