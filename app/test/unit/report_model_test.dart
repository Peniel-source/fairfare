import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairfare/features/report/data/report_model.dart';
import 'package:fairfare/features/report/domain/entities/new_report.dart';
import 'package:fairfare/features/report/domain/entities/report_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportModel.fromMap', () {
    test('reads every field', () {
      final created = DateTime(2026, 11, 18, 9);
      final report = ReportModel.fromMap('abc', {
        'passengerId': 'u1',
        'corridorId': 'alu-downtown',
        'price': 2000,
        'timeSegment': 'lateNight',
        'weather': 'heavyRain',
        'status': 'rejected',
        'reason': 'Too high',
        'createdAt': Timestamp.fromDate(created),
      });

      expect(report.id, 'abc');
      expect(report.passengerId, 'u1');
      expect(report.corridorId, 'alu-downtown');
      expect(report.price, 2000);
      expect(report.timeSegment, TimeSegment.lateNight);
      expect(report.weather, Weather.heavyRain);
      expect(report.status, ReportStatus.rejected);
      expect(report.reason, 'Too high');
      expect(report.createdAt, created);
      expect(report.verifiedAt, isNull);
      expect(report.isSeeded, isFalse);
    });

    test('missing createdAt falls back to now', () {
      final before = DateTime.now();
      final report = ReportModel.fromMap('abc', {
        'passengerId': 'u1',
        'corridorId': 'c1',
        'price': 500,
        'timeSegment': 'morning',
        'weather': 'clear',
        'status': 'pending',
        'createdAt': null,
      });
      expect(report.createdAt.isBefore(before), isFalse);
    });

    test('unknown values fall back safely', () {
      final report = ReportModel.fromMap('abc', {
        'corridorId': 'c1',
        'price': 500,
        'timeSegment': 'dawn',
        'weather': 'snow',
        'status': 'archived',
      });
      expect(report.timeSegment, TimeSegment.midday);
      expect(report.weather, Weather.clear);
      expect(report.status, ReportStatus.pending);
    });
  });

  group('ReportModel.toCreateMap', () {
    test('writes only the fields the rules accept', () {
      final data = ReportModel.toCreateMap(
        const NewReport(
          corridorId: 'alu-downtown',
          price: 1800,
          timeSegment: TimeSegment.evening,
          weather: Weather.clear,
        ),
        'u1',
      );

      expect(data.keys.toSet(), {
        'passengerId',
        'corridorId',
        'price',
        'timeSegment',
        'weather',
        'status',
        'createdAt',
      });
      expect(data['passengerId'], 'u1');
      expect(data['timeSegment'], 'evening');
      expect(data['status'], 'pending');
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
