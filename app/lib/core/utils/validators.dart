class Validators {
  Validators._();

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      return 'Use at least 8 characters with a letter and a number';
    }
    return null;
  }

  static String? loginPassword(String? value) =>
      value == null || value.isEmpty ? 'Enter your password' : null;

  static String? confirmPassword(String? value, String password) =>
      value == null || value.isEmpty
      ? 'Confirm your password'
      : value != password
      ? 'Passwords do not match'
      : null;

  static String? displayName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter your display name';
    if (name.length > 80) return 'Use 80 characters or fewer';
    return null;
  }
}
