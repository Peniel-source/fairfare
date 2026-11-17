// Request a cash-out of reward points.
import '../../../../core/errors/failures.dart';
import '../cash_out_rules.dart';
import '../repositories/wallet_repository.dart';

class RequestCashOut {
  final WalletRepository repository;

  RequestCashOut(this.repository);

  /// Creates a pending cash out request. Checks the amount against
  /// [finalizedBalance] again here, so the rule holds even if a screen skips
  /// its form validation. Throws a [ValidationFailure] when it does not.
  Future<void> call(
    int amount,
    String method, {
    required int finalizedBalance,
  }) async {
    final error = validateCashOutAmount('$amount', finalizedBalance);
    if (error != null) throw ValidationFailure(error);
    if (!cashOutMethods.contains(method)) {
      throw const ValidationFailure('Choose where to send the payout');
    }
    await repository.requestCashOut(amount, method);
  }
}
