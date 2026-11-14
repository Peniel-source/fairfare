// Repository for wallet and cash-out operations.
import '../entities/cash_out_request.dart';
import '../entities/wallet.dart';
import '../entities/wallet_entry.dart';

abstract class WalletRepository {
  Stream<Wallet> watchWallet();
  Stream<List<WalletEntry>> watchEntries();
  Future<void> requestCashOut(int amount, String method);
  Stream<List<CashOutRequest>> watchCashOutRequests();
}
