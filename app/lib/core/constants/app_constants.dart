/// App-wide constants.
class AppConstants {
  AppConstants._();

  /// Maximum sane report price in RWF.
  static const int maxReportPrice = 50000;

  /// Minimum sane report price in RWF.
  static const int minReportPrice = 1;

  /// Trust score bounds.
  static const int minTrustScore = 0;
  static const int maxTrustScore = 100;

  /// Trust score change for verified report.
  static const int trustVerifiedBonus = 5;

  /// Trust score change for rejected report.
  static const int trustRejectedPenalty = 3;

  /// Corroboration price tolerance (10%).
  static const double corroborationTolerance = 0.10;

  /// Corroboration time window (48 hours).
  static const Duration corroborationWindow = Duration(hours: 48);

  /// Band check range: 50-150% of median.
  static const double bandCheckMinRatio = 0.50;
  static const double bandCheckMaxRatio = 1.50;

  /// Band check range in heavy rain or late night: 200%.
  static const double bandCheckExtremeMaxRatio = 2.00;

  /// New corridor threshold: first 3 reports skip band check.
  static const int newCorridorThreshold = 3;

  /// Rolling window for corridor prices (14 days).
  static const Duration corridorRollingWindow = Duration(days: 14);

  /// Pending to finalized hold (24 hours).
  static const Duration rewardHoldDuration = Duration(hours: 24);

  /// Subscription duration (30 days).
  static const Duration subscriptionDuration = Duration(days: 30);

  /// Price of one Pass in RWF.
  /// PLACEHOLDER: confirm the real price with the team before the demo.
  static const int passPriceRwf = 2000;

  /// FairFare's MTN MoMo Pay merchant code. Shown on the Pass screen so the
  /// passenger can check the payee on the MoMo confirmation before the PIN.
  static const String passMerchantCode = '2358998';

  /// MoMo Pay USSD code with the merchant and amount filled in, so the
  /// passenger cannot type the wrong payee or amount.
  static const String passDialCode =
      '*182*8*1*$passMerchantCode*$passPriceRwf#';

  /// Toggle between fake repositories (true) and real Firestore repositories (false).
  /// Flip this to false in Phase 2 when real data wiring is ready.
  static const bool useFakeData = true;
}
