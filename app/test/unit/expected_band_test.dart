import 'package:fairfare/features/corridors/domain/entities/corridor_stats.dart';
import 'package:fairfare/features/report/domain/entities/report_enums.dart';
import 'package:fairfare/features/report/domain/expected_band.dart';
import 'package:flutter_test/flutter_test.dart';

CorridorStats _stats({int median = 1000, int sampleSize = 20}) => CorridorStats(
  corridorId: 'c1',
  median: median,
  low: 800,
  high: 1300,
  sampleSize: sampleSize,
  confidence: 'Well covered',
  updatedAt: DateTime(2026),
);

void main() {
  group('expectedBand', () {
    test('normal conditions: 50 to 150 percent of the median', () {
      final band = expectedBand(
        median: 1000,
        timeSegment: TimeSegment.midday,
        weather: Weather.clear,
      );
      expect(band.low, 500);
      expect(band.high, 1500);
    });

    test('heavy rain raises the ceiling to 200 percent', () {
      final band = expectedBand(
        median: 1000,
        timeSegment: TimeSegment.midday,
        weather: Weather.heavyRain,
      );
      expect(band.low, 500);
      expect(band.high, 2000);
    });

    test('late night raises the ceiling to 200 percent', () {
      final band = expectedBand(
        median: 1000,
        timeSegment: TimeSegment.lateNight,
        weather: Weather.clear,
      );
      expect(band.high, 2000);
    });

    test('the edges count as inside', () {
      const band = PriceBand(low: 500, high: 1500);
      expect(band.contains(500), isTrue);
      expect(band.contains(1500), isTrue);
      expect(band.contains(1501), isFalse);
    });
  });

  group('previewBand', () {
    test('price inside the band is within', () {
      final preview = previewBand(
        stats: _stats(),
        price: 1200,
        timeSegment: TimeSegment.morning,
        weather: Weather.clear,
      );
      expect(preview.verdict, BandVerdict.within);
      expect(preview.band?.high, 1500);
    });

    test('price far above the band is outside', () {
      final preview = previewBand(
        stats: _stats(),
        price: 3000,
        timeSegment: TimeSegment.morning,
        weather: Weather.clear,
      );
      expect(preview.verdict, BandVerdict.outside);
    });

    test('the same price is within when it rains', () {
      final preview = previewBand(
        stats: _stats(),
        price: 1800,
        timeSegment: TimeSegment.morning,
        weather: Weather.heavyRain,
      );
      expect(preview.verdict, BandVerdict.within);
    });

    test('no stats means a new corridor', () {
      final preview = previewBand(
        stats: null,
        price: 1000,
        timeSegment: TimeSegment.morning,
        weather: Weather.clear,
      );
      expect(preview.verdict, BandVerdict.newCorridor);
      expect(preview.band, isNull);
    });

    test('fewer than 3 reports skips the band check', () {
      final preview = previewBand(
        stats: _stats(sampleSize: 2),
        price: 99999,
        timeSegment: TimeSegment.morning,
        weather: Weather.clear,
      );
      expect(preview.verdict, BandVerdict.newCorridor);
    });
  });
}
