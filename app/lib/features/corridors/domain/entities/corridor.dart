/// A route between two areas.
class Corridor {
  final String id;
  final String fromArea;
  final String toArea;

  const Corridor({
    required this.id,
    required this.fromArea,
    required this.toArea,
  });
}
