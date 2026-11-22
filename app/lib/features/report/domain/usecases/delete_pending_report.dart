// Delete a pending report.
import '../repositories/report_repository.dart';

class DeletePendingReport {
  final ReportRepository repository;

  DeletePendingReport(this.repository);

  Future<void> call(String reportId) {
    return repository.deletePending(reportId);
  }
}
