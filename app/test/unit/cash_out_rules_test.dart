// D6: the cash out rules (D4), shared by the form and the use case.
import 'package:fairfare/core/errors/failures.dart';
import 'package:fairfare/features/wallet/data/fake_wallet_repository.dart';
import 'package:fairfare/features/wallet/domain/cash_out_rules.dart';
import 'package:fairfare/features/wallet/domain/usecases/request_cash_out.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateCashOutAmount', () {
    test('asks for an amount when the field is empty', () {
      expect(
        validateCashOutAmount('', 300),
        'Enter how many points to cash out',
      );
      expect(
        validateCashOutAmount(null, 300),
        'Enter how many points to cash out',
      );
      expect(
        validateCashOutAmount('   ', 300),
        'Enter how many points to cash out',
      );
    });

    test('refuses anything that is not a whole number', () {
      const message = 'Use whole points only, with no spaces or commas';
      expect(validateCashOutAmount('12.5', 300), message);
      expect(validateCashOutAmount('1,000', 300), message);
      expect(validateCashOutAmount('ten', 300), message);
    });

    test('refuses zero and negative amounts', () {
      expect(validateCashOutAmount('0', 300), 'Enter an amount above zero');
      expect(validateCashOutAmount('-5', 300), 'Enter an amount above zero');
    });

    test('explains when there are no finalized points yet', () {
      expect(
        validateCashOutAmount('10', 0),
        'You have no finalized points to cash out yet',
      );
    });

    test('refuses more than the finalized balance', () {
      expect(
        validateCashOutAmount('301', 300),
        'You can cash out up to 300 points',
      );
    });

    test('accepts a whole amount up to the finalized balance', () {
      expect(validateCashOutAmount('1', 300), isNull);
      expect(validateCashOutAmount(' 300 ', 300), isNull);
    });
  });

  group('RequestCashOut', () {
    late FakeWalletRepository repository;
    late RequestCashOut requestCashOut;

    setUp(() {
      repository = FakeWalletRepository();
      requestCashOut = RequestCashOut(repository);
    });

    tearDown(() => repository.dispose());

    test('checks the amount again even if a screen skips the form', () {
      expect(
        requestCashOut(500, 'MTN MoMo', finalizedBalance: 300),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            'You can cash out up to 300 points',
          ),
        ),
      );
    });

    test('refuses an unknown payout method', () {
      expect(
        requestCashOut(100, 'Bank card', finalizedBalance: 300),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('sends a valid request to the repository', () async {
      await requestCashOut(120, 'Airtel Money', finalizedBalance: 300);

      final requests = await repository.watchCashOutRequests().first;
      expect(requests.first.amount, 120);
      expect(requests.first.method, 'Airtel Money');
    });
  });
}
