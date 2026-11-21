import '../../../core/errors/failures.dart';
import 'entities/saved_route.dart';

class SavedRouteValidation {
  SavedRouteValidation._();

  static String? area(String? value) {
    final area = value?.trim() ?? '';
    if (area.isEmpty) return 'Enter an area';
    if (area.length > 80) return 'Use 80 characters or fewer';
    return null;
  }

  static String? destination(String? value, String fromArea) {
    final error = area(value);
    if (error != null) return error;
    if (value!.trim().toLowerCase() == fromArea.trim().toLowerCase()) {
      return 'Pickup and drop-off must be different';
    }
    return null;
  }

  static String? label(String? value) {
    final label = value?.trim() ?? '';
    if (label.isEmpty) return 'Enter a route label';
    if (label.length > 80) return 'Use 80 characters or fewer';
    return null;
  }

  static SavedRoute normalized(SavedRoute route) {
    final error =
        area(route.fromArea) ??
        destination(route.toArea, route.fromArea) ??
        label(route.label);
    if (error != null) throw ValidationFailure(error);
    return SavedRoute(
      id: route.id,
      fromArea: route.fromArea.trim(),
      toArea: route.toArea.trim(),
      label: route.label!.trim(),
    );
  }
}
