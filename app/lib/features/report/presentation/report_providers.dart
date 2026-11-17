// Riverpod providers for the report feature.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/fake_report_repository.dart';
import '../domain/entities/report.dart';
import '../domain/repositories/report_repository.dart';
import '../domain/usecases/submit_report.dart';
import '../domain/usecases/update_pending_report.dart';
import '../domain/usecases/delete_pending_report.dart';

/// Provider for the ReportRepository implementation.
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  if (AppConstants.useFakeData) {
    return FakeReportRepository();
  }
  // TODO(C1): return ReportRepositoryImpl() when real Firestore wiring is ready.
  throw UnimplementedError('ReportRepositoryImpl not yet implemented');
});

/// Stream of the current passenger's reports.
final myReportsProvider = StreamProvider<List<Report>>((ref) {
  return ref.watch(reportRepositoryProvider).watchMine();
});

/// Use case providers.
final submitReportProvider = Provider<SubmitReport>((ref) {
  return SubmitReport(ref.watch(reportRepositoryProvider));
});

final updatePendingReportProvider = Provider<UpdatePendingReport>((ref) {
  return UpdatePendingReport(ref.watch(reportRepositoryProvider));
});

final deletePendingReportProvider = Provider<DeletePendingReport>((ref) {
  return DeletePendingReport(ref.watch(reportRepositoryProvider));
});
