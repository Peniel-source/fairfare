import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/features/pass/data/fake_subscription_repository.dart';
import 'package:fairfare/features/pass/domain/payment_reference.dart';
import 'package:fairfare/features/pass/domain/usecases/submit_payment_reference.dart';
import 'package:fairfare/features/report/domain/entities/report_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validatePaymentReference', () {
    test('accepts letters and numbers within the length limits', () {
      expect(validatePaymentReference('1234567890'), isNull);
      expect(validatePaymentReference('ab12cd'), isNull);
      expect(validatePaymentReference(' AB 12 CD 34 '), isNull);
    });

    test('rejects empty, short, long and symbol input', () {
      expect(validatePaymentReference(null), isNotNull);
      expect(validatePaymentReference('   '), isNotNull);
      expect(validatePaymentReference('12345'), contains('too short'));
      expect(validatePaymentReference('1' * 21), contains('too long'));
      expect(validatePaymentReference('1234-5678'), contains('letters'));
    });

    test('normalize removes spaces and upper-cases', () {
      expect(normalizePaymentReference(' ab 12 cd '), 'AB12CD');
    });
  });

  group('SubmitPaymentReference', () {
    late FakeSubscriptionRepository repo;
    late SubmitPaymentReference submit;

    setUp(() {
      repo = FakeSubscriptionRepository();
      submit = SubmitPaymentReference(repo);
    });
    tearDown(() => repo.dispose());

    test('stores a normalized pending subscription', () async {
      await submit(' ab 12 cd 34 ', 2000);
      final sub = await repo.watchMine().first;
      expect(sub!.reference, 'AB12CD34');
      expect(sub.status, SubscriptionStatus.pending);
      expect(sub.amount, 2000);
    });

    test('throws ValidationFailure and never calls the repository', () async {
      await expectLater(submit('12', 2000), throwsA(isA<ValidationFailure>()));
      expect(await repo.watchMine().first, isNull);
    });

    test('refuses a reference that was already used', () async {
      await submit('REF0001', 2000);
      await expectLater(
        submit('ref 0001', 2000),
        throwsA(isA<DuplicateReferenceFailure>()),
      );
    });

    test('approve makes it active for 30 days', () async {
      await submit('REF0002', 2000);
      repo.approve('REF0002', now: DateTime(2026, 11, 14));
      final sub = await repo.watchMine().first;
      expect(sub!.status, SubscriptionStatus.active);
      expect(sub.endsAt, DateTime(2026, 12, 14));
    });
  });
}
