// Fake report repository with sample data.
import 'dart:async';

import '../domain/entities/new_report.dart';
import '../domain/entities/report.dart';
import '../domain/entities/report_enums.dart';
import '../domain/repositories/report_repository.dart';

class FakeReportRepository implements ReportRepository {
  final _controller = StreamController<List<Report>>.broadcast();
  final _reports = <Report>[
    Report(
      id: 'r1',
      passengerId: 'fake_user_1',
      corridorId: 'c1',
      price: 600,
      timeSegment: TimeSegment.morning,
      weather: Weather.clear,
      status: ReportStatus.verified,
      createdAt: DateTime(2026, 10, 25),
      verifiedAt: DateTime(2026, 10, 25, 12),
    ),
    Report(
      id: 'r2',
      passengerId: 'fake_user_1',
      corridorId: 'c2',
      price: 500,
      timeSegment: TimeSegment.evening,
      weather: Weather.clear,
      status: ReportStatus.pending,
      createdAt: DateTime(2026, 10, 26),
    ),
  ];

  @override
  Stream<List<Report>> watchMine() async* {
    yield List.unmodifiable(_reports);
    yield* _controller.stream;
  }

  @override
  Future<void> submit(NewReport report) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newReport = Report(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      passengerId: 'fake_user_1',
      corridorId: report.corridorId,
      price: report.price,
      timeSegment: report.timeSegment,
      weather: report.weather,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
    );
    _reports.insert(0, newReport);
    _controller.add(List.unmodifiable(_reports));
  }

  @override
  Future<void> updatePendingPrice(String reportId, int price) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1 && _reports[index].status == ReportStatus.pending) {
      _reports[index] = Report(
        id: _reports[index].id,
        passengerId: _reports[index].passengerId,
        corridorId: _reports[index].corridorId,
        price: price,
        timeSegment: _reports[index].timeSegment,
        weather: _reports[index].weather,
        status: _reports[index].status,
        createdAt: _reports[index].createdAt,
        processedAt: _reports[index].processedAt,
        isSeeded: _reports[index].isSeeded,
      );
      _controller.add(List.unmodifiable(_reports));
    }
  }

  @override
  Future<void> deletePending(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _reports.removeWhere(
      (r) => r.id == reportId && r.status == ReportStatus.pending,
    );
    _controller.add(List.unmodifiable(_reports));
  }

  void dispose() => _controller.close();
}
