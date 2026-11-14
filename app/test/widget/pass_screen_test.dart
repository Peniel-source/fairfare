import 'package:fairfare/features/pass/data/fake_subscription_repository.dart';
import 'package:fairfare/features/pass/presentation/dial_prompt_card.dart';
import 'package:fairfare/features/pass/presentation/pass_providers.dart';
import 'package:fairfare/features/pass/presentation/pass_screen.dart';
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
    await submitReference(tester, 'ab12cd34');
    expect(find.text('Payment being checked'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);

    repo.approve('AB12CD34');
    await tester.pumpAndSettle();
    expect(find.text('Pass active'), findsOneWidget);
  });

  testWidgets('a used reference shows a clear message', (tester) async {
    await pumpPass(tester);
    await submitReference(tester, 'USED123456');
    expect(find.textContaining('already used'), findsOneWidget);
    // Still no subscription, so the form stays for another try.
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Payment being checked'), findsNothing);
  });

  testWidgets('no overflow in landscape on a small phone', (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpPass(tester);
    expect(tester.takeException(), isNull);
  });

  test('dial link encodes # so the dialer keeps the whole code', () {
    expect(dialUri('*182*8*1*000000#').toString(), 'tel:*182*8*1*000000%23');
  });
}
