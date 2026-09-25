// Regression test for the Dokyu/Tulong office-name cleanup: MSWD/MSWDO and
// the other abbreviated/combined office labels (PDAO, MDRRMO, MPESO, OSCA,
// BPLO, MCRO, "MSWDO / Mayor's Office", etc.) were replaced with their full
// names in mock_catalog.dart and requests_service.dart. Full names are much
// longer than the abbreviations they replaced, so this file checks — at a
// spread of narrow device widths, same technique as
// resident_profile_overflow_test.dart — that the office/department step,
// item list, request list cards, and request detail screen all render the
// new full names with zero RenderFlex/layout overflow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/dokyu/dokyu_screen.dart';
import 'package:teresa_rizal/screens/shared/request_detail_screen.dart';
import 'package:teresa_rizal/screens/shared/service_catalog_screen.dart';
import 'package:teresa_rizal/screens/tulong/tulong_screen.dart';
import 'package:teresa_rizal/services/balita_service.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';

// The longest full office names now in the catalog — the ones most likely
// to trigger a wrap-related overflow if a card/row isn't set up to grow.
const _longOfficeNames = [
  'Municipal Social Welfare and Development Office',
  'Municipal Disaster Risk Reduction and Management Office',
  'Persons with Disability Affairs Office',
  'Municipal Public Employment Service Office',
  'Office for Senior Citizens Affairs',
  'Office of the Municipal Mayor',
  'Business Permits and Licensing Office',
  'Office of the Municipal Civil Registrar',
];

const _narrowSizes = <String, Size>{
  'extreme narrow (280x568)': Size(280, 568),
  'small (320x568)': Size(320, 568),
  'iPhone SE-ish (375x667)': Size(375, 667),
};

Future<void> _pumpWithProviders(WidgetTester tester, Widget home, {bool seedDemoData = true}) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  await session.login(MockCatalog.demoAccounts.last); // Perlita — verified, full access

  // Demo seeding (_seedDemoStatusSimulationsIfNeeded) runs asynchronously
  // off the constructor; screens like RequestDetailScreen do a synchronous
  // firstWhere lookup on first build, so it must finish seeding *before*
  // the widget under test is pumped, not just before we assert on it.
  // Real Future.delayed timers never fire under the test binding's fake
  // clock without tester.pump() driving it, so poll with pump() (which
  // both advances the clock and flushes the pending microtask) instead of
  // a raw delay — otherwise this spins forever.
  final requests = RequestsService(seedDemoData: seedDemoData);
  await tester.pumpWidget(const SizedBox.shrink());
  var attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) {
      throw StateError('RequestsService never finished loading in the test binding.');
    }
    await tester.pump(const Duration(milliseconds: 1));
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final sizeEntry in _narrowSizes.entries) {
    testWidgets('Tulong department step shows full office names with zero overflow at ${sizeEntry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = sizeEntry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const MaterialApp(
          home: ServiceCatalogScreen(
            category: ServiceCategory.tulong,
            title: 'Tulong',
            catalog: MockCatalog.assistanceTypes,
            accent: AppColors.purple700,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Which office handles this?'), findsOneWidget);

      // None of the old abbreviated/combined labels should survive.
      for (final stale in const [
        'MSWDO',
        'MSWD',
        'MSWD / PDAO',
        "MSWDO / Mayor's Office",
        'MSWDO / MDRRMO',
        'OSCA',
        'MPESO',
      ]) {
        expect(find.text(stale), findsNothing, reason: '"$stale" should have been expanded to a full office name');
      }

      // Every full department name should be reachable (scrolled into view)
      // without throwing a layout exception. Listed in the same
      // alphabetical order _DepartmentStep sorts them in, since
      // scrollUntilVisible only drags forward and can't scroll back up to
      // an item it has already passed.
      for (final name in const [
        'Municipal Disaster Risk Reduction and Management Office',
        'Municipal Public Employment Service Office',
        'Municipal Social Welfare and Development Office',
        'Office for Senior Citizens Affairs',
        'Office of the Municipal Mayor',
        'Persons with Disability Affairs Office',
      ]) {
        await tester.scrollUntilVisible(find.text(name), 200, scrollable: find.byType(Scrollable).first);
        expect(find.text(name), findsOneWidget);
      }

      expect(tester.takeException(), isNull);
    });
  }

  for (final sizeEntry in _narrowSizes.entries) {
    testWidgets('Tulong item list shows the office line under each service with zero overflow at ${sizeEntry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = sizeEntry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const MaterialApp(
          home: ServiceCatalogScreen(
            category: ServiceCategory.tulong,
            title: 'Tulong',
            catalog: MockCatalog.assistanceTypes,
            accent: AppColors.purple700,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Municipal Social Welfare and Development Office is the department
      // with the most merged-in services (former MSWDO + former MSWD) —
      // its item list is the densest test of the office line wrapping
      // cleanly under several service cards in a row.
      await tester.scrollUntilVisible(
        find.text('Municipal Social Welfare and Development Office'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // scrollUntilVisible only guarantees the target is on-screen as of
      // its last scroll step; warnIfMissed:false avoids a spurious
      // hit-test warning if settle nudged it by a pixel since then.
      await tester.tap(find.text('Municipal Social Welfare and Development Office'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Municipal Social Welfare and Development Office'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  for (final sizeEntry in _narrowSizes.entries) {
    testWidgets('Dokyu and Tulong request lists render seeded office names with zero overflow at ${sizeEntry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = sizeEntry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpWithProviders(tester, const DokyuScreen());
      expect(tester.takeException(), isNull);

      await _pumpWithProviders(tester, const TulongScreen());
      expect(tester.takeException(), isNull);
    });
  }

  for (final sizeEntry in _narrowSizes.entries) {
    testWidgets('Request detail screen renders long office + actor labels with zero overflow at ${sizeEntry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = sizeEntry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // demo-tulong-medical is seeded with office 'Municipal Social Welfare
      // and Development Office' and actor 'Municipal Social Welfare and
      // Development Office Staff' — the longest office/actor pairing among
      // the seeded demo requests.
      await _pumpWithProviders(tester, const RequestDetailScreen(requestId: 'demo-tulong-medical'));

      expect(find.text('Municipal Social Welfare and Development Office'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('sanity: every expected full office name is non-empty and none of them re-introduce a bare known abbreviation', () {
    const knownAbbreviations = ['MPESO', 'MSWDO', 'MSWD', 'PDAO', 'MDRRMO', 'OSCA', 'BPLO', 'MCRO'];
    for (final name in _longOfficeNames) {
      expect(name, isNotEmpty);
      for (final abbr in knownAbbreviations) {
        expect(name, isNot(equals(abbr)));
      }
    }
  });
}
