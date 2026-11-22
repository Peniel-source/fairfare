// Fake report repository with sample data.
import 'dart:async';

import 'package:fairfare/features/report/domain/entities/new_report.dart';
import 'package:fairfare/features/report/domain/entities/report.dart';
import 'package:fairfare/features/report/domain/entities/report_enums.dart';
import 'package:fairfare/features/report/domain/repositories/report_repository.dart';

class FakeReportRepository implements ReportRepository {
  final _controller = StreamController<List<Report>>.broadcast();
  final _reports = <Report>[
    Report(
      id: 'r2',
      passengerId: 'fake_user_1',
      corridorId: 'alu-downtown',
      price: 500,
      timeSegment: TimeSegment.evening,
      weather: Weather.clear,
      status: ReportStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Report(
      id: 'r1',
      passengerId: 'fake_user_1',
      corridorId: 'kacyiru-kimironko',
      price: 600,
      timeSegment: TimeSegment.morning,
      weather: Weather.clear,
      status: ReportStatus.verified,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      verifiedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Report(
      id: 'r3',
      passengerId: 'fake_user_1',
      corridorId: 'gisozi-kacyiru',
      price: 3000,
      timeSegment: TimeSegment.midday,
      weather: Weather.clear,
      status: ReportStatus.rejected,
      reason: 'Price is far above the usual range for this route',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Report(
      id: 'r4',
      passengerId: 'fake_user_1',
      corridorId: 'remera-downtown',
      price: 800,
      timeSegment: TimeSegment.lateNight,
      weather: Weather.heavyRain,
      status: ReportStatus.expired,
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
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
