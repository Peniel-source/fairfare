// Update the price of a pending report.
import '../repositories/report_repository.dart';

class UpdatePendingReport {
  final ReportRepository repository;

  UpdatePendingReport(this.repository);

  Future<void> call(String reportId, int price) {
    return repository.updatePendingPrice(reportId, price);
  }
}
