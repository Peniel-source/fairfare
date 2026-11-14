// A price report from a rider on a corridor.
import 'report_enums.dart';

class Report {
  final String id;
  final String riderId;
  final String corridorId;
  final int price;
  final TimeSegment timeSegment;
  final Weather weather;
  final ReportStatus status;
  final String? reason;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  const Report({
    required this.id,
    required this.riderId,
    required this.corridorId,
    required this.price,
    required this.timeSegment,
    required this.weather,
    required this.status,
    this.reason,
    required this.createdAt,
    this.verifiedAt,
  });
}
