// Repository for price reports.
import '../entities/new_report.dart';
import '../entities/report.dart';

abstract class ReportRepository {
  Future<void> submit(NewReport report);
  Stream<List<Report>> watchMine();
  Future<void> updatePendingPrice(String reportId, int price);
  Future<void> deletePending(String reportId);
}
