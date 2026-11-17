/// Passenger's wallet balances.
class Wallet {
  final int pendingBalance;
  final int finalizedBalance;

  const Wallet({this.pendingBalance = 0, this.finalizedBalance = 0});
}
