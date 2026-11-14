// Rules for the mobile money payment reference a passenger types in.
//
// Pure Dart (no Flutter, no Firebase) so it is shared by the form and the use
// case, and easy to unit test.

/// Shortest and longest reference we accept. Mobile money transaction ids
/// are usually 8 to 12 characters.
const int kMinReferenceLength = 6;
const int kMaxReferenceLength = 20;

final _allowed = RegExp(r'^[A-Z0-9]+$');

/// Trims, removes inner spaces and upper-cases, so " ab 12 cd " and
/// "AB12CD" are treated as the same reference (and caught as duplicates).
String normalizePaymentReference(String input) =>
    input.replaceAll(RegExp(r'\s+'), '').toUpperCase();

/// Returns an error message, or null when the reference is valid.
String? validatePaymentReference(String? input) {
  final value = normalizePaymentReference(input ?? '');
  if (value.isEmpty) return 'Enter the reference from your payment SMS';
  if (!_allowed.hasMatch(value)) {
    return 'Use only letters and numbers';
  }
  if (value.length < kMinReferenceLength) {
    return 'The reference is too short (at least $kMinReferenceLength characters)';
  }
  if (value.length > kMaxReferenceLength) {
    return 'The reference is too long (at most $kMaxReferenceLength characters)';
  }
  return null;
}
