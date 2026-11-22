/// A single wallet transaction entry.
class WalletEntry {
  final String id;
  final String? reportId;
  final int amount;
  final String state; // 'pending' or 'finalized'
  final DateTime createdAt;

  const WalletEntry({
    required this.id,
    this.reportId,
    required this.amount,
    required this.state,
    required this.createdAt,
  });
}
