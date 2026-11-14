// Riverpod providers for the wallet feature.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/fake_wallet_repository.dart';
import '../domain/entities/cash_out_request.dart';
import '../domain/entities/wallet.dart';
import '../domain/entities/wallet_entry.dart';
import '../domain/repositories/wallet_repository.dart';
import '../domain/usecases/request_cash_out.dart';

/// Provider for the WalletRepository implementation.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  if (AppConstants.useFakeData) {
    return FakeWalletRepository();
  }
  // TODO(D4): return WalletRepositoryImpl() when real Firestore wiring is ready.
  throw UnimplementedError('WalletRepositoryImpl not yet implemented');
});

/// Stream of the current rider's wallet balances.
final walletProvider = StreamProvider<Wallet>((ref) {
  return ref.watch(walletRepositoryProvider).watchWallet();
});

/// Stream of wallet transaction entries.
final walletEntriesProvider = StreamProvider<List<WalletEntry>>((ref) {
  return ref.watch(walletRepositoryProvider).watchEntries();
});

/// Stream of cash-out requests.
final cashOutRequestsProvider = StreamProvider<List<CashOutRequest>>((ref) {
  return ref.watch(walletRepositoryProvider).watchCashOutRequests();
});

/// Use case provider.
final requestCashOutProvider = Provider<RequestCashOut>((ref) {
  return RequestCashOut(ref.watch(walletRepositoryProvider));
});
