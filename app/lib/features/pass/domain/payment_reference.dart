// Rules for the mobile money payment reference a passenger types in.
//
// Pure Dart (no Flutter, no Firebase) so it is shared by the form and the use
// case, and easy to unit test.

/// Shortest and longest reference we accept. MoMo transaction ids are
/// numbers only, usually 8 to 12 digits.
const int kMinReferenceLength = 6;
const int kMaxReferenceLength = 20;

final _allowed = RegExp(r'^[0-9]+$');

/// Removes all spaces, so " 1234 5678 " and "12345678" are treated as the
/// same reference (and caught as duplicates).
String normalizePaymentReference(String input) =>
    input.replaceAll(RegExp(r'\s+'), '');

/// Returns an error message, or null when the reference is valid.
String? validatePaymentReference(String? input) {
  final value = normalizePaymentReference(input ?? '');
  if (value.isEmpty) return 'Enter the reference from your payment SMS';
  if (!_allowed.hasMatch(value)) {
    return 'Use numbers only, as in the transaction ID in your MoMo SMS';
  }
  if (value.length < kMinReferenceLength) {
    return 'The reference is too short (at least $kMinReferenceLength digits)';
  }
  if (value.length > kMaxReferenceLength) {
    return 'The reference is too long (at most $kMaxReferenceLength digits)';
  }
  return null;
}
