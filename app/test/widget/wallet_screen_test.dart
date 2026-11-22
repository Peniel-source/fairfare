// D6: Wallet screen (D4) states and the cash out form.
import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/core/theme/app_theme.dart';
import 'package:fairfare/features/profile/presentation/profile_providers.dart';
import 'package:fairfare/features/wallet/data/fake_wallet_repository.dart';
import 'package:fairfare/features/wallet/domain/entities/cash_out_request.dart';
import 'package:fairfare/features/wallet/domain/entities/wallet.dart';
import 'package:fairfare/features/wallet/domain/entities/wallet_entry.dart';
import 'package:fairfare/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:fairfare/features/wallet/presentation/wallet_providers.dart';
import 'package:fairfare/features/wallet/presentation/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_profile_repository.dart';

/// A wallet with fixed balances and no history, or one that fails to load.
class _StubWalletRepository implements WalletRepository {
  _StubWalletRepository({this.wallet = const Wallet(), this.fail = false});

  final Wallet wallet;
  final bool fail;

  @override
  Stream<Wallet> watchWallet() =>
      fail ? Stream.error(const NetworkFailure()) : Stream.value(wallet);

  @override
  Stream<List<WalletEntry>> watchEntries() => Stream.value(const []);

  @override
  Stream<List<CashOutRequest>> watchCashOutRequests() => Stream.value(const []);

  @override
  Future<void> requestCashOut(int amount, String method) async {}
}

void main() {
  Future<void> pumpWallet(
    WidgetTester tester,
    WalletRepository repository, {
    Size size = const Size(800, 2000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final profiles = FakeProfileRepository();
    addTearDown(profiles.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          profileRepositoryProvider.overrideWithValue(profiles),
        ],
        child: MaterialApp(
          theme: AppTheme.light(useGoogleFonts: false),
          home: const WalletScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FakeWalletRepository fakeWallet() {
    final repository = FakeWalletRepository();
    addTearDown(repository.dispose);
    return repository;
  }

  Future<void> openCashOut(WidgetTester tester) async {
    await tester.tap(find.text('Cash out'));
    await tester.pumpAndSettle();
    expect(find.text('Cash out points'), findsOneWidget);
  }

  Future<void> submit(WidgetTester tester, String amount) async {
    await tester.enterText(find.byType(TextFormField), amount);
    await tester.tap(find.text('Request cash out'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows finalized and pending points, history and requests', (
    tester,
  ) async {
    await pumpWallet(tester, fakeWallet());

    expect(find.text('300 pts'), findsOneWidget);
    expect(find.text('150 pts'), findsOneWidget);
    expect(find.text('+100 pts'), findsOneWidget);
    expect(find.text('+50 pts'), findsOneWidget);
    expect(find.text('−200 pts'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
  });

  testWidgets('cash out form explains each invalid amount', (tester) async {
    await pumpWallet(tester, fakeWallet());
    await openCashOut(tester);

    await submit(tester, '');
    expect(find.text('Enter how many points to cash out'), findsOneWidget);

    await submit(tester, '0');
    expect(find.text('Enter an amount above zero'), findsOneWidget);

    await submit(tester, '500');
    expect(find.text('You can cash out up to 300 points'), findsOneWidget);
    // The sheet stays open until the amount is valid.
    expect(find.text('Cash out points'), findsOneWidget);
  });

  testWidgets('a valid cash out shows up as a pending request', (tester) async {
    await pumpWallet(tester, fakeWallet());
    await openCashOut(tester);

    await tester.enterText(find.byType(TextFormField), '120');
    await tester.tap(find.text('Airtel Money'));
    await tester.pump();
    await tester.tap(find.text('Request cash out'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Cash out points'), findsNothing);
    expect(
      find.text('Cash out requested. We will update its status here.'),
      findsOneWidget,
    );
    expect(find.text('−120 pts'), findsOneWidget);
    expect(find.textContaining('Airtel Money ·'), findsOneWidget);
  });

  testWidgets('a new passenger sees empty states and cannot cash out', (
    tester,
  ) async {
    await pumpWallet(
      tester,
      _StubWalletRepository(wallet: const Wallet(pendingBalance: 52)),
    );

    expect(find.text('52 pts'), findsOneWidget);
    expect(find.text('No rewards yet'), findsOneWidget);
    expect(find.text('No cash out requests'), findsOneWidget);
    expect(
      find.textContaining('You can cash out once you have finalized points'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cash out'));
    await tester.pumpAndSettle();
    expect(find.text('Cash out points'), findsNothing);
  });

  testWidgets('a wallet that fails to load offers a retry', (tester) async {
    await pumpWallet(tester, _StubWalletRepository(fail: true));

    expect(
      find.textContaining('We could not load your wallet'),
      findsOneWidget,
    );
    expect(find.text('300 pts'), findsNothing);
  });

  testWidgets('fits a small phone in landscape without overflow', (
    tester,
  ) async {
    await pumpWallet(tester, fakeWallet(), size: const Size(640, 360));

    expect(tester.takeException(), isNull);
    expect(find.text('300 pts'), findsOneWidget);

    await openCashOut(tester);
    expect(tester.takeException(), isNull);
  });
}
