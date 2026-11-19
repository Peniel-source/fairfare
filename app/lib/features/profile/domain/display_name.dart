// Rules for the display name a passenger can set on their profile.
// Pure Dart so the edit form and the use case share them.

const int kMinDisplayNameLength = 2;
const int kMaxDisplayNameLength = 30;

/// Trims and collapses inner whitespace: "  Ama   K " -> "Ama K".
String normalizeDisplayName(String input) =>
    input.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Returns an error message, or null when the name is valid.
String? validateDisplayName(String? input) {
  final value = normalizeDisplayName(input ?? '');
  if (value.isEmpty) return 'Enter a display name';
  if (value.length < kMinDisplayNameLength) {
    return 'Use at least $kMinDisplayNameLength characters';
  }
  if (value.length > kMaxDisplayNameLength) {
    return 'Use at most $kMaxDisplayNameLength characters';
  }
  return null;
}
