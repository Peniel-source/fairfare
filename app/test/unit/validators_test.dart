import 'package:fairfare/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'email rejects empty, malformed and whitespace-containing addresses',
    () {
      for (final email in [
        null,
        '',
        '  ',
        'passenger',
        'p@',
        '@example.com',
        'p@example',
        'p @example.com',
        'p@@example.com',
      ]) {
        expect(Validators.email(email), isNotNull, reason: '$email');
      }
      expect(Validators.email(' passenger+fare@example.com '), isNull);
    },
  );

  test(
    'new passwords need at least eight characters, a letter and a number',
    () {
      for (final password in [
        null,
        '',
        '12345678',
        'abcdefgh',
        'abc1234',
        '        ',
      ]) {
        expect(Validators.password(password), isNotNull, reason: '$password');
      }
      expect(Validators.password('abcd1234'), isNull);
      expect(Validators.password(' pass1234 '), isNull);
    },
  );

  test(
    'login requires a password without imposing new-account restrictions',
    () {
      expect(Validators.loginPassword(null), isNotNull);
      expect(Validators.loginPassword(''), isNotNull);
      expect(Validators.loginPassword('legacy'), isNull);
    },
  );

  test('confirmation must match exactly, including spaces', () {
    expect(Validators.confirmPassword('', 'pass1234'), isNotNull);
    expect(Validators.confirmPassword('pass1234 ', 'pass1234'), isNotNull);
    expect(Validators.confirmPassword('pass1234', 'pass1234'), isNull);
  });

  test('display name is required and respects the Firestore length limit', () {
    expect(Validators.displayName(null), isNotNull);
    expect(Validators.displayName('   '), isNotNull);
    expect(Validators.displayName('a' * 81), isNotNull);
    expect(Validators.displayName('a' * 80), isNull);
    expect(Validators.displayName(' Ménès '), isNull);
  });
}
