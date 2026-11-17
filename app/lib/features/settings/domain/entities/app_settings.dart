// App-wide user preferences stored in shared_preferences.
import 'package:fairfare/features/report/domain/entities/report_enums.dart';

enum ThemeModeOption { system, light, dark }

class AppSettings {
  final ThemeModeOption themeMode;
  final bool onboardingSeen;
  final TimeSegment defaultTimeSegment;
  final String? lastCorridorId;

  const AppSettings({
    this.themeMode = ThemeModeOption.system,
    this.onboardingSeen = false,
    this.defaultTimeSegment = TimeSegment.morning,
    this.lastCorridorId,
  });

  AppSettings copyWith({
    ThemeModeOption? themeMode,
    bool? onboardingSeen,
    TimeSegment? defaultTimeSegment,
    String? lastCorridorId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      defaultTimeSegment: defaultTimeSegment ?? this.defaultTimeSegment,
      lastCorridorId: lastCorridorId ?? this.lastCorridorId,
    );
  }
}
