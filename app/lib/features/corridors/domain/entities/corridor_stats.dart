/// Aggregated price statistics for a corridor.
class CorridorStats {
  final String corridorId;
  final int median;
  final int low;
  final int high;
  final int sampleSize;
  final String confidence;
  final DateTime updatedAt;

  const CorridorStats({
    required this.corridorId,
    required this.median,
    required this.low,
    required this.high,
    required this.sampleSize,
    required this.confidence,
    required this.updatedAt,
  });
}
