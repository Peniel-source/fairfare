/// Collection names in the B1 proposed data model.
///
/// Paths with a user ID belong to the authenticated user. Repositories resolve
/// that ID from auth state; screens should not construct Firestore paths.
abstract final class FirestorePaths {
  static const riders = 'riders';
  static const savedRoutes = 'savedRoutes';
  static const corridors = 'corridors';
  static const corridorStats = 'corridorStats';
  static const reports = 'reports';
  static const wallets = 'wallets';
  static const walletEntries = 'walletEntries';
  static const cashOutRequests = 'cashOutRequests';
  static const subscriptions = 'subscriptions';
  static const leaderboard = 'leaderboard';
  static const poolLedger = 'poolLedger';
  static const notarizations = 'notarizations';

  /// The shared accounting document is `poolLedger/main`.
  static const poolLedgerDocumentId = 'main';
}
