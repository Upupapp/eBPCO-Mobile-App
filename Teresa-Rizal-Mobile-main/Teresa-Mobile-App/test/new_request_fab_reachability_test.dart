// Is the "New Request" FAB actually inert on first arrival, or was the device
// walk tapping the wrong one?
//
// The FE 03 walk reported, reproducibly across three runs, that tapping
// "New Request" on first arrival at the Dokyu or Tulong request list did
// nothing — while the same finder tapped the same control successfully later in
// the same run. That is either a real defect (a citizen taps and gets no
// response) or a defect in the harness, and the two are worth telling apart
// before anything is "fixed".
//
// The suspicion comes from `RootShell`: Dokyu and Tulong are both mounted at
// once inside an `IndexedStack`, so **two** `New Request` FABs exist in the
// tree simultaneously and only one is on screen. `finder.first` resolves in
// tree order, not visibility order — so a walk that taps `.first` can tap the
// other category's button.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/services/balita_service.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/screens/catalog/dokyu_catalog_screen.dart';
import 'package:teresa_rizal/screens/catalog/tulong_catalog_screen.dart';
import 'package:teresa_rizal/screens/shared/request_list_screen.dart';
import 'package:teresa_rizal/theme/app_colors.dart';

Widget _host(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RequestsService(seedDemoData: false)),
        ChangeNotifierProvider(create: (_) => CitizenSessionService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(home: child),
    );

RequestListScreen _dokyuList() => RequestListScreen(
      category: ServiceCategory.dokyu,
      title: 'Dokyu',
      subtitle: 'Request and track municipal documents online.',
      catalog: MockCatalog.documentTypes,
      accent: AppColors.brand600,
      icon: Icons.description_rounded,
    );

RequestListScreen _tulongList() => RequestListScreen(
      category: ServiceCategory.tulong,
      title: 'Tulong',
      subtitle: 'Submit and follow up assistance program requests.',
      catalog: MockCatalog.assistanceTypes,
      accent: AppColors.purple700,
      icon: Icons.volunteer_activism_rounded,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the FAB opens the catalogue on first arrival, with no warm-up', (tester) async {
    await tester.pumpWidget(_host(_dokyuList()));
    // Deliberately only one frame of settling: the walk's claim is that the
    // control is dead *on arrival*, so give it no more grace than a citizen
    // who taps the moment the screen appears.
    await tester.pump();

    await tester.tap(find.text('New Request'));
    await tester.pumpAndSettle();

    expect(find.byType(DokyuCatalogScreen), findsOneWidget,
        reason: 'tapping New Request on arrival must open the Dokyu catalogue');
  });

  testWidgets('it still works for Tulong', (tester) async {
    await tester.pumpWidget(_host(_tulongList()));
    await tester.pump();

    await tester.tap(find.text('New Request'));
    await tester.pumpAndSettle();

    expect(find.byType(TulongCatalogScreen), findsOneWidget);
  });

  testWidgets('an IndexedStack exposes only the visible FAB, so .first is safe', (tester) async {
    // This started as the leading explanation for the walk's report and turned
    // out to be wrong, which is worth keeping rather than deleting.
    //
    // RootShell keeps Dokyu and Tulong both mounted in an IndexedStack, so the
    // guess was that two
    // "New Request" FABs exist at once and `finder.first` taps the off-screen
    // one. Measured: finders skip offstage widgets, so exactly **one** is
    // found — matching the walk's own "Matches: 1" diagnostic. `.first` is
    // therefore safe here, and the walk's report is still unexplained.
    await tester.pumpWidget(
      _host(IndexedStack(index: 1, children: [_dokyuList(), _tulongList()])),
    );
    await tester.pump();

    expect(find.text('New Request'), findsOneWidget,
        reason: 'offstage IndexedStack children are not findable');

    // And it is the *displayed* one, so tapping it works.
    await tester.tap(find.text('New Request'));
    await tester.pumpAndSettle();
    expect(find.byType(TulongCatalogScreen), findsOneWidget);
  });
}
