import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/new_report.dart';
import '../domain/entities/report.dart';
import '../domain/entities/report_enums.dart';

class ReportModel {
  ReportModel._();

  /// Firestore document to Report
  static Report fromMap(String id, Map<String, dynamic> data) {
    return Report(
      id: id,
      passengerId: data['passengerId'] as String?,
      corridorId: data['corridorId'] as String,
      price: (data['price'] as num).toInt(),
      timeSegment: _byName(
        TimeSegment.values,
        data['timeSegment'],
        TimeSegment.midday,
      ),
      weather: _byName(Weather.values, data['weather'], Weather.clear),
      status: _byName(
        ReportStatus.values,
        data['status'],
        ReportStatus.pending,
      ),
      reason: data['reason'] as String?,
      // Null until the server sets the timestamp
      createdAt: _date(data['createdAt']) ?? DateTime.now(),
      verifiedAt: _date(data['verifiedAt']),
      processedAt: _date(data['processedAt']),
      isSeeded: data['isSeeded'] as bool? ?? false,
    );
  }

  /// New report to the fields the rules accept
  static Map<String, dynamic> toCreateMap(
    NewReport report,
    String passengerId,
  ) {
    return {
      'passengerId': passengerId,
      'corridorId': report.corridorId,
      'price': report.price,
      'timeSegment': report.timeSegment.name,
      'weather': report.weather.name,
      'status': ReportStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  static T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
