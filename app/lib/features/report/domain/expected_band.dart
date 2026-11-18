import '../../../core/constants/app_constants.dart';
import '../../corridors/domain/entities/corridor_stats.dart';
import 'entities/report_enums.dart';

/// Accepted price range for one corridor, time and weather
class PriceBand {
  final int low;
  final int high;

  const PriceBand({required this.low, required this.high});

  bool contains(int price) => price >= low && price <= high;
}

/// Computes the accepted range around a corridor
PriceBand expectedBand({
  required int median,
  required TimeSegment timeSegment,
  required Weather weather,
}) {
  final widened =
      weather == Weather.heavyRain || timeSegment == TimeSegment.lateNight;
  final maxRatio = widened
      ? AppConstants.bandCheckExtremeMaxRatio
      : AppConstants.bandCheckMaxRatio;
  return PriceBand(
    low: (median * AppConstants.bandCheckMinRatio).round(),
    high: (median * maxRatio).round(),
  );
}

/// Band check about a price.
enum BandVerdict {
  /// Inside the range
  within,

  /// Outside the range
  outside,

  /// Not enough history yet
  newCorridor,
}

/// Preview shown in the banner
class BandPreview {
  final BandVerdict verdict;
  final PriceBand? band;

  const BandPreview(this.verdict, [this.band]);
}

/// Previews the band check for price and stats
BandPreview previewBand({
  required CorridorStats? stats,
  required int price,
  required TimeSegment timeSegment,
  required Weather weather,
}) {
  if (stats == null || stats.sampleSize < AppConstants.newCorridorThreshold) {
    return const BandPreview(BandVerdict.newCorridor);
  }
  final band = expectedBand(
    median: stats.median,
    timeSegment: timeSegment,
    weather: weather,
  );
  return BandPreview(
    band.contains(price) ? BandVerdict.within : BandVerdict.outside,
    band,
  );
}
