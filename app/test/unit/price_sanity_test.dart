import 'package:fairfare/core/constants/app_constants.dart';
import 'package:fairfare/features/report/domain/price_sanity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('priceSanityError', () {
    test('empty price asks for a price', () {
      expect(priceSanityError(null), 'Enter the price you paid');
    });

    test('zero is refused', () {
      expect(priceSanityError(0), isNotNull);
    });

    test('a normal fare passes', () {
      expect(priceSanityError(1000), isNull);
    });

    test('the limits themselves pass', () {
      expect(priceSanityError(AppConstants.minReportPrice), isNull);
      expect(priceSanityError(AppConstants.maxReportPrice), isNull);
    });

    test('above the maximum is refused with the limit in the message', () {
      final error = priceSanityError(AppConstants.maxReportPrice + 1);
      expect(error, contains('50,000 RWF'));
    });
  });
}
