// Riverpod providers for the wallet feature.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/wallet_repository_impl.dart';
import '../domain/entities/cash_out_request.dart';
import '../domain/entities/wallet.dart';
import '../domain/entities/wallet_entry.dart';
import '../domain/repositories/wallet_repository.dart';
import '../domain/usecases/request_cash_out.dart';

/// Provider for the WalletRepository implementation.
///
/// Always the real Firestore repository, like the Pass and Profile features:
/// balances are written by the server, so the app never shows made-up
/// points. It watches the signed-in uid, so it is rebuilt on sign in and sign
/// out and one passenger never sees another's wallet. Tests override it with
/// FakeWalletRepository.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final uid = ref.watch(
    authStateProvider.select((auth) => auth.valueOrNull?.id),
  );
  return WalletRepositoryImpl(FirebaseFirestore.instance, uid: uid);
});

/// Stream of the current passenger's wallet balances.
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
