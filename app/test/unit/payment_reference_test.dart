import 'package:fairfare/core/errors/failures.dart';

import '../fakes/fake_subscription_repository.dart';

import 'package:fairfare/features/pass/domain/payment_reference.dart';
import 'package:fairfare/features/pass/domain/usecases/submit_payment_reference.dart';
import 'package:fairfare/features/report/domain/entities/report_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validatePaymentReference', () {
    test('accepts digits within the length limits', () {
      expect(validatePaymentReference('1234567890'), isNull);
      expect(validatePaymentReference('123456'), isNull);
      expect(validatePaymentReference(' 1234 5678 '), isNull);
    });

    test('rejects empty, short, long and symbol input', () {
      expect(validatePaymentReference(null), isNotNull);
      expect(validatePaymentReference('   '), isNotNull);
      expect(validatePaymentReference('12345'), contains('too short'));
      expect(validatePaymentReference('1' * 21), contains('too long'));
      expect(validatePaymentReference('1234-5678'), contains('numbers only'));
      expect(validatePaymentReference('AB12CD34'), contains('numbers only'));
    });

    test('normalize removes spaces', () {
      expect(normalizePaymentReference(' 1234 5678 '), '12345678');
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
      await submit(' 1234 5678 ', 2000);
      final sub = await repo.watchMine().first;
      expect(sub!.reference, '12345678');
      expect(sub.status, SubscriptionStatus.pending);
      expect(sub.amount, 2000);
    });

    test('throws ValidationFailure and never calls the repository', () async {
      await expectLater(submit('12', 2000), throwsA(isA<ValidationFailure>()));
      expect(await repo.watchMine().first, isNull);
    });

    test('refuses a reference that was already used', () async {
      await submit('20260001', 2000);
      await expectLater(
        submit('2026 0001', 2000),
        throwsA(isA<DuplicateReferenceFailure>()),
      );
    });

    test('approve makes it active for 30 days', () async {
      await submit('20260002', 2000);
      repo.approve('20260002', now: DateTime(2026, 11, 14));
      final sub = await repo.watchMine().first;
      expect(sub!.status, SubscriptionStatus.active);
      expect(sub.endsAt, DateTime(2026, 12, 14));
    });
  });
}
