/// Failure types used across the app.
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// No network connection.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Firebase auth failures.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class EmailInUseFailure extends AuthFailure {
  const EmailInUseFailure([super.message = 'This email is already registered']);
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([
    super.message =
        'Password must be at least 8 characters with a letter and a number',
  ]);
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure([super.message = 'Enter a valid email address']);
}

class WrongPasswordFailure extends AuthFailure {
  const WrongPasswordFailure([
    super.message = 'Wrong password. Try again or reset your password',
  ]);
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([
    super.message = 'No account found with this email',
  ]);
}

class TooManyAttemptsFailure extends AuthFailure {
  const TooManyAttemptsFailure([
    super.message = 'Too many failed attempts. Please try again later',
  ]);
}

/// Firestore operation failure.
class FirestoreFailure extends Failure {
  const FirestoreFailure([super.message = 'Database operation failed']);
}

/// A payment reference that was already submitted (the rules refuse it,
/// because the reference is the subscription document id).
class DuplicateReferenceFailure extends Failure {
  const DuplicateReferenceFailure([
    super.message =
        'This payment reference was already used. Check the code in your '
        'payment SMS and try again',
  ]);
}

/// Validation failure from form input.
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Please check your input']);
}
