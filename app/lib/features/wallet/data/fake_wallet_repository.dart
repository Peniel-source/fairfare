// Fake wallet repository with sample data.
import 'dart:async';

import '../domain/entities/cash_out_request.dart';
import '../domain/entities/wallet.dart';
import '../domain/entities/wallet_entry.dart';
import '../domain/repositories/wallet_repository.dart';
import '../../report/domain/entities/report_enums.dart';

class FakeWalletRepository implements WalletRepository {
  final _walletController = StreamController<Wallet>.broadcast();
  final _entriesController = StreamController<List<WalletEntry>>.broadcast();
  final _cashOutController = StreamController<List<CashOutRequest>>.broadcast();

  final Wallet _wallet = const Wallet(
    pendingBalance: 150,
    finalizedBalance: 300,
  );

  final _entries = <WalletEntry>[
    WalletEntry(
      id: 'we1',
      reportId: 'r1',
      amount: 100,
      state: 'finalized',
      createdAt: DateTime(2026, 10, 25),
    ),
    WalletEntry(
      id: 'we2',
      reportId: 'r2',
      amount: 50,
      state: 'pending',
      createdAt: DateTime(2026, 10, 26),
    ),
  ];

  final _cashOutRequests = <CashOutRequest>[
    CashOutRequest(
      id: 'co1',
      amount: 200,
      method: 'Mobile Money',
      status: CashOutStatus.paid,
      createdAt: DateTime(2026, 10, 24),
    ),
  ];

  FakeWalletRepository() {
    _walletController.add(_wallet);
    _entriesController.add(_entries);
    _cashOutController.add(_cashOutRequests);
  }

  @override
  Stream<Wallet> watchWallet() => _walletController.stream;

  @override
  Stream<List<WalletEntry>> watchEntries() => _entriesController.stream;

  @override
  Stream<List<CashOutRequest>> watchCashOutRequests() =>
      _cashOutController.stream;

  @override
  Future<void> requestCashOut(int amount, String method) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final request = CashOutRequest(
      id: 'co_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      method: method,
      status: CashOutStatus.pending,
      createdAt: DateTime.now(),
    );
    _cashOutRequests.insert(0, request);
    _cashOutController.add(_cashOutRequests);
  }

  void dispose() {
    _walletController.close();
    _entriesController.close();
    _cashOutController.close();
  }
}
