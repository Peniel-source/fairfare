import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../corridors/data/location_service.dart';
import '../../corridors/domain/entities/corridor.dart';
import '../../corridors/domain/entities/corridor_stats.dart';
import '../../corridors/domain/zone_finder.dart';
import '../../corridors/presentation/corridor_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/entities/new_report.dart';
import '../domain/entities/report.dart';
import '../domain/entities/report_enums.dart';
import '../domain/price_sanity.dart';
import 'report_providers.dart';

/// Passenger submission
/// Count the 48 hour window
class SubmittedReport {
  final String corridorId;
  final int price;

  /// Device time just before the write
  final DateTime startedAt;

  const SubmittedReport({
    required this.corridorId,
    required this.price,
    required this.startedAt,
  });
}

class ReportFormState {
  final Zone? pickup;
  final Zone? dropoff;
  final int? price;
  final TimeSegment timeSegment;
  final Weather weather;

  /// Show Errors after attempt
  final bool showErrors;
  final bool isSubmitting;
  final bool isLocating;
  final SubmittedReport? submitted;

  const ReportFormState({
    this.pickup,
    this.dropoff,
    this.price,
    required this.timeSegment,
    this.weather = Weather.clear,
    this.showErrors = false,
    this.isSubmitting = false,
    this.isLocating = false,
    this.submitted,
  });

  ReportFormState copyWith({
    Zone? Function()? pickup,
    Zone? Function()? dropoff,
    int? Function()? price,
    TimeSegment? timeSegment,
    Weather? weather,
    bool? showErrors,
    bool? isSubmitting,
    bool? isLocating,
    SubmittedReport? Function()? submitted,
  }) {
    return ReportFormState(
      pickup: pickup != null ? pickup() : this.pickup,
      dropoff: dropoff != null ? dropoff() : this.dropoff,
      price: price != null ? price() : this.price,
      timeSegment: timeSegment ?? this.timeSegment,
      weather: weather ?? this.weather,
      showErrors: showErrors ?? this.showErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLocating: isLocating ?? this.isLocating,
      submitted: submitted != null ? submitted() : this.submitted,
    );
  }
}

/// Error for the route
String? routeError({required Zone? pickup, required Zone? dropoff}) {
  if (pickup == null || dropoff == null) {
    return 'Choose where you got on and where you got off';
  }
  if (pickup.id == dropoff.id) {
    return 'Pickup and drop-off must be different areas';
  }
  return null;
}

/// Corridor id is pickupId-dropoffId
String corridorIdFor(Zone pickup, Zone dropoff) => '${pickup.id}-${dropoff.id}';

/// The corridor between two different zones
Corridor? corridorFor(Zone? pickup, Zone? dropoff) {
  if (pickup == null || dropoff == null || pickup.id == dropoff.id) {
    return null;
  }
  return Corridor(
    id: corridorIdFor(pickup, dropoff),
    fromArea: pickup.name,
    toArea: dropoff.name,
  );
}

/// A pickup and dropoff pair for the quick load chips
class RouteChoice {
  final Zone pickup;
  final Zone dropoff;

  const RouteChoice(this.pickup, this.dropoff);

  String get label => '${pickup.name} → ${dropoff.name}';
}

/// Message when the location could not be used
String locationErrorMessage(LocationStatus status) => switch (status) {
  LocationStatus.serviceOff =>
    'Location is turned off. Turn it on or search an area',
  LocationStatus.denied => 'Location was not allowed. You can search an area',
  LocationStatus.deniedForever =>
    'Location is blocked for this app. Turn it on in your phone settings',
  _ => 'Could not find your location. Search an area instead',
};

/// Price chips
List<int> quickPrices(CorridorStats? stats) {
  if (stats == null) return const [500, 1000, 1500, 2000];
  int round50(num value) => (value / 50).round() * 50;
  final values = {
    round50(stats.low),
    round50(stats.median),
    round50(stats.high),
    round50(stats.high * 1.25),
  }.toList()..sort();
  return values;
}

final reportFormProvider =
    NotifierProvider.autoDispose<ReportFormController, ReportFormState>(
      ReportFormController.new,
    );

class ReportFormController extends AutoDisposeNotifier<ReportFormState> {
  @override
  ReportFormState build() {
    // Changing the setting later must not wipe the form
    final segment = ref.read(settingsProvider).defaultTimeSegment;
    return ReportFormState(timeSegment: segment);
  }

  void setPickup(Zone zone) => state = state.copyWith(pickup: () => zone);

  void setDropoff(Zone zone) => state = state.copyWith(dropoff: () => zone);

  void swapRoute() => state = state.copyWith(
    pickup: () => state.dropoff,
    dropoff: () => state.pickup,
  );

  /// Fills both route fields from a quick load chip
  void applyRoute(RouteChoice route) => state = state.copyWith(
    pickup: () => route.pickup,
    dropoff: () => route.dropoff,
  );

  /// Sets the pickup to the nearest zone, returns a message if it fails
  Future<String?> useMyLocation() async {
    if (state.isLocating) return null;
    state = state.copyWith(isLocating: true);
    try {
      final result = await ref.read(locationServiceProvider).getLocation();
      if (result.status != LocationStatus.found) {
        return locationErrorMessage(result.status);
      }
      final zones = await ref.read(zonesProvider.future);
      final zone = findNearestZone(result.latitude!, result.longitude!, zones);
      if (zone == null) {
        return 'You are not near a FairFare area. Search an area instead';
      }
      state = state.copyWith(pickup: () => zone);
      return null;
    } catch (_) {
      return locationErrorMessage(LocationStatus.failed);
    } finally {
      state = state.copyWith(isLocating: false);
    }
  }

  void setPrice(int? price) => state = state.copyWith(price: () => price);

  void setTimeSegment(TimeSegment segment) =>
      state = state.copyWith(timeSegment: segment);

  void setWeather(Weather weather) => state = state.copyWith(weather: weather);

  /// Clears the form for another report
  void reset() => state = build();

  /// Validates and submits
  Future<bool> submit() async {
    if (state.isSubmitting) return false;
    final corridor = corridorFor(state.pickup, state.dropoff);
    final hasErrors =
        routeError(pickup: state.pickup, dropoff: state.dropoff) != null ||
        priceSanityError(state.price) != null;
    if (hasErrors) {
      state = state.copyWith(showErrors: true);
      return false;
    }

    final startedAt = DateTime.now();
    state = state.copyWith(showErrors: true, isSubmitting: true);
    try {
      await ref
          .read(submitReportProvider)
          .call(
            NewReport(
              corridorId: corridor!.id,
              price: state.price!,
              timeSegment: state.timeSegment,
              weather: state.weather,
            ),
          );
      state = state.copyWith(
        isSubmitting: false,
        submitted: () => SubmittedReport(
          corridorId: corridor.id,
          price: state.price!,
          startedAt: startedAt,
        ),
      );
      return true;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

/// The corridor for the chosen pickup and drop-off
final selectedCorridorProvider = Provider.autoDispose<Corridor?>((ref) {
  final pickup = ref.watch(reportFormProvider.select((s) => s.pickup));
  final dropoff = ref.watch(reportFormProvider.select((s) => s.dropoff));
  return corridorFor(pickup, dropoff);
});

/// Live stats of the chosen corridor.
final selectedCorridorStatsProvider =
    Provider.autoDispose<AsyncValue<CorridorStats?>>((ref) {
      final corridor = ref.watch(selectedCorridorProvider);
      if (corridor == null) return const AsyncData(null);
      return ref.watch(corridorStatsProvider(corridor.id));
    });

/// Routes from the passenger's latest reports (up to 3)
final recentRoutesProvider = Provider.autoDispose<List<RouteChoice>>((ref) {
  final zones = ref.watch(zonesProvider).value ?? const <Zone>[];
  final reports = ref.watch(myReportsProvider).value ?? const <Report>[];
  final popular = ref.watch(popularCorridorsProvider).value ?? const [];
  final byId = {
    for (final a in zones)
      for (final b in zones)
        if (a.id != b.id) corridorIdFor(a, b): RouteChoice(a, b),
  };
  final newestFirst = [...reports]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final recent = <String>[];
  for (final report in newestFirst) {
    if (byId.containsKey(report.corridorId) &&
        !recent.contains(report.corridorId)) {
      recent.add(report.corridorId);
    }
    if (recent.length == 3) break;
  }
  if (recent.isEmpty) {
    recent.addAll(popular.map((c) => c.id).where(byId.containsKey).take(2));
  }
  return [for (final id in recent) byId[id]!];
});

/// The report submitted from this screen
/// Status changes live (pending, then verified, rejected or expired)
final submittedReportProvider = Provider.autoDispose<Report?>((ref) {
  final submitted = ref.watch(reportFormProvider.select((s) => s.submitted));
  if (submitted == null) return null;
  final reports = ref.watch(myReportsProvider).value ?? const <Report>[];

  final earliest = submitted.startedAt.subtract(const Duration(minutes: 2));
  for (final report in reports) {
    if (report.corridorId == submitted.corridorId &&
        report.price == submitted.price &&
        !report.createdAt.isBefore(earliest)) {
      return report;
    }
  }
  return null;
});

/// Ticks once a minute so the countdown stays current
final minuteClockProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final controller = StreamController<DateTime>()..add(DateTime.now());
  final timer = Timer.periodic(
    const Duration(minutes: 1),
    (_) => controller.add(DateTime.now()),
  );
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});
