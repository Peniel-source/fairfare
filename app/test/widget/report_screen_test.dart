import 'package:fairfare/core/theme/app_theme.dart';
import 'package:fairfare/features/report/data/fake_report_repository.dart';
import 'package:fairfare/features/report/presentation/report_providers.dart';
import 'package:fairfare/features/report/presentation/report_screen.dart';
import 'package:fairfare/features/settings/data/fake_settings_repository.dart';
import 'package:fairfare/features/settings/presentation/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeReportRepository reports;

  Future<void> pumpReport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    reports = FakeReportRepository();
    addTearDown(reports.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(reports),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(useGoogleFonts: false),
          home: const ReportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the form and the recent routes', (tester) async {
    await pumpReport(tester);
    expect(find.text('Report your ride fare'), findsOneWidget);
    expect(find.text('Kacyiru → Kimironko'), findsOneWidget);
    expect(find.text('Submit report'), findsOneWidget);
  });

  testWidgets('empty submit shows the route and price errors', (tester) async {
    await pumpReport(tester);
    await tapSubmit(tester);
    expect(
      find.text('Choose where you got on and where you got off'),
      findsOneWidget,
    );
    expect(find.text('Enter the price you paid'), findsOneWidget);
    expect(find.text('Report submitted'), findsNothing);
  });

  testWidgets('a recent route fills the usual price and previews the band', (
    tester,
  ) async {
    await pumpReport(tester);
    await tester.tap(find.text('Kacyiru → Kimironko'));
    await tester.pumpAndSettle();

    // Fake corridor c1 has a median of 600
    expect(find.text('Usual price: 600 RWF'), findsOneWidget);
    expect(find.textContaining('Within expected band'), findsOneWidget);
  });

  testWidgets('submitting shows the pending banner with a countdown', (
    tester,
  ) async {
    await pumpReport(tester);
    await tester.tap(find.text('Kacyiru → Kimironko'));
    await tester.pumpAndSettle();
    await tapSubmit(tester);

    expect(find.text('Report submitted'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.textContaining('Time left: 47h'), findsOneWidget);
    expect(find.text('Submit report'), findsNothing);

    await tester.tap(find.text('Report another ride'));
    await tester.pumpAndSettle();
    expect(find.text('Submit report'), findsOneWidget);
  });
}
