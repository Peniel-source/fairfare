// Cash out rules (D4). Pure Dart, no Flutter or Firebase, so they can be unit
// tested and reused by the form and the use case.

/// Payout methods a rider can pick. Payouts are in-app points; the method only
/// tells the team where a real payout would go (see Known Limitations).
const cashOutMethods = ['MTN MoMo', 'Airtel Money'];

/// Checks the amount typed in the cash out form.
///
/// Returns an error message to show under the field, or null when the amount
/// is valid: a whole number above zero and not above [finalizedBalance].
/// Only finalized points can be cashed out; pending points are still inside
/// their review window.
String? validateCashOutAmount(String? raw, int finalizedBalance) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return 'Enter how many points to cash out';
  final amount = int.tryParse(text);
  if (amount == null) return 'Use whole points only, with no spaces or commas';
  if (amount <= 0) return 'Enter an amount above zero';
  if (finalizedBalance <= 0) {
    return 'You have no finalized points to cash out yet';
  }
  if (amount > finalizedBalance) {
    return 'You can cash out up to $finalizedBalance points';
  }
  return null;
}
