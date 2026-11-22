import '../domain/zone_finder.dart';

//zone repository to get zones
abstract class ZoneRepository {
  Future<List<Zone>> getZones();
}

//fake zones for building the screen
class FakeZoneRepository implements ZoneRepository {
  static const _zones = [
    Zone(id: 'alu', name: 'ALU', latitude: -1.9306, longitude: 30.1529),
    Zone(
      id: 'downtown',
      name: 'Downtown',
      latitude: -1.9433,
      longitude: 30.0596,
    ),
    Zone(
      id: 'nyabugogo',
      name: 'Nyabugogo',
      latitude: -1.9409,
      longitude: 30.0447,
    ),
    Zone(id: 'kacyiru', name: 'Kacyiru', latitude: -1.9376, longitude: 30.0805),
    Zone(
      id: 'kimihurura',
      name: 'Kimihurura',
      latitude: -1.9528,
      longitude: 30.0818,
    ),
    Zone(id: 'remera', name: 'Remera', latitude: -1.9476, longitude: 30.1061),
    Zone(
      id: 'kimironko',
      name: 'Kimironko',
      latitude: -1.9384,
      longitude: 30.1242,
    ),
    Zone(
      id: 'nyarutarama',
      name: 'Nyarutarama',
      latitude: -1.9396,
      longitude: 30.1017,
    ),
    Zone(id: 'gisozi', name: 'Gisozi', latitude: -1.9178, longitude: 30.0613),
    Zone(id: 'kanombe', name: 'Kanombe', latitude: -1.9684, longitude: 30.1384),
    Zone(
      id: 'kicukiro',
      name: 'Kicukiro',
      latitude: -1.9718,
      longitude: 30.0972,
    ),
    Zone(id: 'gikondo', name: 'Gikondo', latitude: -1.9789, longitude: 30.084),
    Zone(
      id: 'nyamirambo',
      name: 'Nyamirambo',
      latitude: -1.9639,
      longitude: 30.0599,
    ),
    Zone(id: 'gahanga', name: 'Gahanga', latitude: -2.0316, longitude: 30.1097),
    Zone(id: 'masaka', name: 'Masaka', latitude: -2.0223, longitude: 30.2032),
  ];

  @override
  Future<List<Zone>> getZones() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _zones;
  }
}
