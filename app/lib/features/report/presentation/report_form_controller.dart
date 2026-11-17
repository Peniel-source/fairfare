import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../corridors/domain/entities/corridor.dart';
import '../../corridors/domain/entities/corridor_stats.dart';
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
  final String? pickup;
  final String? dropoff;
  final int? price;
  final TimeSegment timeSegment;
  final Weather weather;

  /// Show Errors after attempt
  final bool showErrors;
  final bool isSubmitting;
  final SubmittedReport? submitted;

  const ReportFormState({
    this.pickup,
    this.dropoff,
    this.price,
    required this.timeSegment,
    this.weather = Weather.clear,
    this.showErrors = false,
    this.isSubmitting = false,
    this.submitted,
  });

  ReportFormState copyWith({
    String? Function()? pickup,
    String? Function()? dropoff,
    int? Function()? price,
    TimeSegment? timeSegment,
    Weather? weather,
    bool? showErrors,
    bool? isSubmitting,
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
      submitted: submitted != null ? submitted() : this.submitted,
    );
  }
}

/// Error for the route
String? routeError({
  required String? pickup,
  required String? dropoff,
  required Corridor? corridor,
}) {
  if (pickup == null || dropoff == null) {
    return 'Choose where you got on and where you got off';
  }
  if (pickup == dropoff) return 'Pickup and drop-off must be different areas';
  if (corridor == null) {
    return 'FairFare does not track this route yet. Try the nearest area';
  }
  return null;
}

/// The corridor that goes from pickup to dropoff
Corridor? findCorridor(
  List<Corridor> corridors,
  String? pickup,
  String? dropoff,
) {
  if (pickup == null || dropoff == null) return null;
  for (final corridor in corridors) {
    if (corridor.fromArea == pickup && corridor.toArea == dropoff) {
      return corridor;
    }
  }
  return null;
}

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

  void setPickup(String? area) => state = state.copyWith(pickup: () => area);

  void setDropoff(String? area) => state = state.copyWith(dropoff: () => area);

  void swapRoute() => state = state.copyWith(
    pickup: () => state.dropoff,
    dropoff: () => state.pickup,
  );

  /// Fills both route fields from a quick load chip
  void applyRoute(Corridor corridor) => state = state.copyWith(
    pickup: () => corridor.fromArea,
    dropoff: () => corridor.toArea,
  );

  void setPrice(int? price) => state = state.copyWith(price: () => price);

  void setTimeSegment(TimeSegment segment) =>
      state = state.copyWith(timeSegment: segment);

  void setWeather(Weather weather) => state = state.copyWith(weather: weather);

  /// Clears the form for another report
  void reset() => state = build();

  /// Validates and submits
  Future<bool> submit() async {
    if (state.isSubmitting) return false;
    final corridor = ref.read(selectedCorridorProvider);
    final hasErrors =
        routeError(
              pickup: state.pickup,
              dropoff: state.dropoff,
              corridor: corridor,
            ) !=
            null ||
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

/// Area names the passenger can pick
final reportAreasProvider = Provider.autoDispose<AsyncValue<List<String>>>((
  ref,
) {
  return ref.watch(popularCorridorsProvider).whenData((corridors) {
    final areas = {
      for (final c in corridors) ...[c.fromArea, c.toArea],
    };
    return areas.toList()..sort();
  });
});

/// The tracked corridor matching the chosen pickup and drop-off
final selectedCorridorProvider = Provider.autoDispose<Corridor?>((ref) {
  final pickup = ref.watch(reportFormProvider.select((s) => s.pickup));
  final dropoff = ref.watch(reportFormProvider.select((s) => s.dropoff));
  final corridors = ref.watch(popularCorridorsProvider).value ?? const [];
  return findCorridor(corridors, pickup, dropoff);
});

/// Live stats of the chosen corridor.
final selectedCorridorStatsProvider =
    Provider.autoDispose<AsyncValue<CorridorStats?>>((ref) {
      final corridor = ref.watch(selectedCorridorProvider);
      if (corridor == null) return const AsyncData(null);
      return ref.watch(corridorStatsProvider(corridor.id));
    });

/// Routes from the passenger's latest reports (up to 3)
final recentRoutesProvider = Provider.autoDispose<List<Corridor>>((ref) {
  final corridors = ref.watch(popularCorridorsProvider).value ?? const [];
  final reports = ref.watch(myReportsProvider).value ?? const <Report>[];
  final byId = {for (final c in corridors) c.id: c};
  final newestFirst = [...reports]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final seen = <String>{};
  final recent = <Corridor>[];
  for (final report in newestFirst) {
    final corridor = byId[report.corridorId];
    if (corridor != null && seen.add(corridor.id)) recent.add(corridor);
    if (recent.length == 3) break;
  }
  return recent.isEmpty ? corridors.take(2).toList() : recent;
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
final minuteClockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});
