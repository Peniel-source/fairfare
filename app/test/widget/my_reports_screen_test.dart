import 'package:fairfare/core/theme/app_theme.dart';
import 'package:fairfare/features/auth/data/fake_auth_repository.dart';
import 'package:fairfare/features/auth/presentation/auth_providers.dart';
import 'package:fairfare/features/report/data/fake_report_repository.dart';
import 'package:fairfare/features/report/domain/entities/report.dart';
import 'package:fairfare/features/report/presentation/my_reports_screen.dart';
import 'package:fairfare/features/report/presentation/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpMyReports(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final reports = FakeReportRepository();
    addTearDown(reports.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          reportRepositoryProvider.overrideWithValue(reports),
          ...overrides,
        ],
        child: MaterialApp(
          theme: AppTheme.light(useGoogleFonts: false),
          home: const MyReportsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Let the fake corridors finish their delay
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  testWidgets('shows every status and the pending countdown', (tester) async {
    await pumpMyReports(tester);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.textContaining('Time left:'), findsOneWidget);
    expect(
      find.text('Price is far above the usual range for this route'),
      findsOneWidget,
    );
  });

  testWidgets('only the pending report can be edited or deleted', (
    tester,
  ) async {
    await pumpMyReports(tester);
    expect(find.text('Edit price'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('editing the price updates the list', (tester) async {
    await pumpMyReports(tester);
    await tester.tap(find.text('Edit price'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    await tester.enterText(
      find.descendant(of: sheet, matching: find.byType(TextField)),
      '700',
    );
    await tester.tap(find.text('Save price'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Price updated'), findsOneWidget);
    expect(find.text('700 RWF'), findsOneWidget);
  });

  testWidgets('an empty price is refused in the sheet', (tester) async {
    await pumpMyReports(tester);
    await tester.tap(find.text('Edit price'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      ),
      '',
    );
    await tester.tap(find.text('Save price'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the price you paid'), findsOneWidget);
  });

  testWidgets('deleting asks first, then removes the report', (tester) async {
    await pumpMyReports(tester);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this report?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Report deleted'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);
  });

  testWidgets('no reports shows the empty state', (tester) async {
    await pumpMyReports(
      tester,
      overrides: [
        myReportsProvider.overrideWith((ref) => Stream.value(const <Report>[])),
      ],
    );
    expect(find.text('No reports yet'), findsOneWidget);
    expect(find.text('Report a ride'), findsOneWidget);
  });
}
