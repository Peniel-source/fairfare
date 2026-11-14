// Submit a new price report.
import '../entities/new_report.dart';
import '../repositories/report_repository.dart';

class SubmitReport {
  final ReportRepository repository;

  SubmitReport(this.repository);

  Future<void> call(NewReport report) {
    return repository.submit(report);
  }
}
