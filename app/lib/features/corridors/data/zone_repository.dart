import '../domain/zone_finder.dart';

//zone repository to get zones
abstract class ZoneRepository {
  Future<List<Zone>> getZones();
}
