import 'package:geolocator/geolocator.dart';

//possible outcomes
enum LocationStatus { found, serviceOff, denied, deniedForever, failed }

class LocationResult {
  final LocationStatus status;
  final double? latitude;
  final double? longitude;

  const LocationResult(this.status, {this.latitude, this.longitude});
}

class LocationService {
  Future<LocationResult> getLocation() async {
    //location has to be turned on in the phone
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return const LocationResult(LocationStatus.serviceOff);

    //permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult(LocationStatus.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(LocationStatus.deniedForever);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult(
        LocationStatus.found,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return const LocationResult(LocationStatus.failed);
    }
  }
}
