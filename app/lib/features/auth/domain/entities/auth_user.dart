/// Minimal user info returned by Auth.
class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final bool emailVerified;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.emailVerified = false,
  });
}
