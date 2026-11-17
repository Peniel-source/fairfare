import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';

/// Error message for price
String? priceSanityError(int? price) {
  if (price == null) return 'Enter the price you paid';
  if (price < AppConstants.minReportPrice) {
    return 'The price must be more than 0 RWF';
  }
  if (price > AppConstants.maxReportPrice) {
    return 'That looks too high. The most you can report is '
        '${Formatters.price(AppConstants.maxReportPrice)}';
  }
  return null;
}
