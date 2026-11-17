// A passenger's request to cash out reward points.
import '../../../report/domain/entities/report_enums.dart';

class CashOutRequest {
  final String id;
  final int amount;
  final String method;
  final CashOutStatus status;
  final DateTime createdAt;

  const CashOutRequest({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });
}
