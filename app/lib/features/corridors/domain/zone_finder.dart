import 'dart:math';


//zone class
class Zone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const Zone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}


//max distance away from zone
const maxZoneDistanceKm = 3.0;

//distance in km between two points, using haversine formula
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;

  final dLat = toRadians(lat2 - lat1);
  final dLng = toRadians(lng2 - lng1);

  final a =
      sin(dLat / 2) * sin(dLat / 2) +
          cos(toRadians(lat1)) * cos(toRadians(lat2)) * sin(dLng / 2) * sin(dLng / 2);

  return 2 * earthRadiusKm * asin(sqrt(a));
}

double toRadians(double degrees) => degrees * pi / 180;

//find nearest zone or return null if no nearest zones
Zone? findNearestZone(double latitude, double longitude, List<Zone> zones) {
  Zone? nearest;
  var shortest = double.infinity;

  for (final zone in zones) {
    final km = distanceKm(latitude, longitude, zone.latitude, zone.longitude);
    if (km < shortest) {
      shortest = km;
      nearest = zone;
    }
  }

  if (nearest == null || shortest > maxZoneDistanceKm) return null;
  return nearest;
}