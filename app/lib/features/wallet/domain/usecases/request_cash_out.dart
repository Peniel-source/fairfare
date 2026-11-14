// Request a cash-out of reward points.
import '../repositories/wallet_repository.dart';

class RequestCashOut {
  final WalletRepository repository;

  RequestCashOut(this.repository);

  Future<void> call(int amount, String method) {
    return repository.requestCashOut(amount, method);
  }
}
