/// A rider's saved favorite route.
class SavedRoute {
  final String id;
  final String fromArea;
  final String toArea;
  final String? label;

  const SavedRoute({
    required this.id,
    required this.fromArea,
    required this.toArea,
    this.label,
  });
}
