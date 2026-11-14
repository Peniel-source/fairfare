// A new report being submitted by a rider.
import 'report_enums.dart';

class NewReport {
  final String corridorId;
  final int price;
  final TimeSegment timeSegment;
  final Weather weather;

  const NewReport({
    required this.corridorId,
    required this.price,
    required this.timeSegment,
    required this.weather,
  });
}
