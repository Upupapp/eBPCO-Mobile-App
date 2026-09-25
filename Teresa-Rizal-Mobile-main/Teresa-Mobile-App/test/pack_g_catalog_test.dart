import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/data/catalog_gate_policy.dart';
import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/data/service_catalog_mock.dart';
import 'package:teresa_rizal/data/tulong_program_route.dart';
import 'package:teresa_rizal/models/access_level.dart';
import 'package:teresa_rizal/screens/catalog/delayed_birth_wizard.dart';
import 'package:teresa_rizal/screens/catalog/dokyu_catalog_screen.dart';
import 'package:teresa_rizal/screens/catalog/incident_report_screen.dart';
import 'package:teresa_rizal/screens/catalog/sakuna_catalog_screen.dart';
import 'package:teresa_rizal/screens/catalog/tulong_catalog_screen.dart';
import 'package:teresa_rizal/screens/catalog/catalog_detail_screen.dart';
import 'package:teresa_rizal/screens/home/root_shell.dart';
import 'package:teresa_rizal/services/balita_service.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/widgets/service_launcher_menu.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CitizenSessionService()..continueAsGuest()),
        ChangeNotifierProvider(create: (_) => RequestsService(seedDemoData: false)),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pump();
}

void main() {
  test('gate switch is one const and resolves both modes', () {
    expect(kCatalogGatePolicy, CatalogGatePolicy.browseThenSheet);
    expect(currentCatalogGatePolicy(), CatalogGatePolicy.browseThenSheet);
    expect(catalogEntryFor('dokyu', CatalogGatePolicy.browseThenSheet), CatalogEntry.dokyuCatalog);
    expect(catalogEntryFor('tulong', CatalogGatePolicy.hubRestricted), CatalogEntry.guardedRequestList);
    expect(catalogEntryFor('emergency', CatalogGatePolicy.hubRestricted), CatalogEntry.sakunaCatalog);
    expect(
      startRequestGate(CatalogAccountKind.duplicate, CatalogGatePolicy.browseThenSheet),
      StartRequestGate.duplicateDialog,
    );
    expect(
      startRequestGate(CatalogAccountKind.duplicate, CatalogGatePolicy.hubRestricted),
      StartRequestGate.unverifiedSheet,
    );
    expect(
      startRequestGate(CatalogAccountKind.rejected, CatalogGatePolicy.browseThenSheet),
      StartRequestGate.rejectedSheet,
    );
    expect(
      startRequestGate(
        CatalogAccountKind.rejected,
        CatalogGatePolicy.browseThenSheet,
        emergency: true,
      ),
      StartRequestGate.proceed,
    );
    expect(catalogAccountKind(MockCatalog.duplicateVerifiedDemoAccount), CatalogAccountKind.duplicate);
  });

  testWidgets('removed catalog names are absent from the new Dokyu list', (tester) async {
    await _pump(tester, const DokyuCatalogScreen());
    expect(find.text('Business endorsement'), findsNothing);
    expect(find.text('Certificate of employment'), findsNothing);
    expect(find.text('Barangay Clearance'), findsOneWidget);
  });

  testWidgets('birth search keeps three results and uses the search action', (tester) async {
    await _pump(tester, const DokyuCatalogScreen(initialQuery: 'birth'));
    final field = tester.widget<TextField>(find.byKey(const Key('dokyu-search-field')));
    expect(field.keyboardType, TextInputType.text);
    expect(field.autocorrect, isFalse);
    expect(field.textInputAction, TextInputAction.search);
    expect(find.textContaining('Live Birth copy'), findsOneWidget);
    expect(find.textContaining('Delayed Birth'), findsWidgets);
    expect(find.textContaining('Late Birth brgy cert'), findsWidgets);
    expect(find.text('Cedula'), findsNothing);
    final list = tester.widget<ListView>(find.byKey(const Key('dokyu-results')));
    expect(list.keyboardDismissBehavior, ScrollViewKeyboardDismissBehavior.onDrag);
    await tester.showKeyboard(find.byKey(const Key('dokyu-search-field')));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.textContaining('Live Birth copy'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('dokyu-search-field'))).scrollPadding.bottom, greaterThanOrEqualTo(16));
  });

  testWidgets('building permit search offers related services', (tester) async {
    await _pump(tester, const DokyuCatalogScreen(initialQuery: 'building permit'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('No Dokyu service matches'), findsOneWidget);
    expect(find.textContaining('Business Permit (New)'), findsOneWidget);
    expect(find.textContaining('Locational Clearance'), findsOneWidget);
    expect(find.textContaining('Help & Support'), findsOneWidget);
  });

  testWidgets('closed program start is disabled and has no remind toggle', (tester) async {
    await _pump(tester, TulongDetailScreen(program: ServiceCatalogMock.byId('tupad')));
    expect(find.text('Remind me when it opens'), findsNothing);
    expect(find.text('Start request'), findsOneWidget);
    final button = tester.widget<InkWell>(
      find.ancestor(of: find.text('Start request'), matching: find.byType(InkWell)).first,
    );
    expect(button.onTap, isNull);
  });

  testWidgets('opens soon is the only remind-me program', (tester) async {
    await _pump(tester, TulongDetailScreen(program: ServiceCatalogMock.byId('tesda')));
    expect(find.byKey(const Key('remind-me')), findsOneWidget);
    expect(find.text(ServiceCatalogMock.remindHelper), findsOneWidget);
  });

  testWidgets('may-not-fit dialog fires only on start request', (tester) async {
    await _pump(
      tester,
      TulongDetailScreen(
        program: ServiceCatalogMock.byId('social-pension'),
        previewBirth: DateTime(1992, 4, 12),
      ),
    );
    expect(find.byKey(const Key('may-not-fit-dialog')), findsNothing);
    expect(find.textContaining('not eligible'), findsNothing);
    await tester.tap(find.text('Start request'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('may-not-fit-dialog')), findsOneWidget);
    expect(find.textContaining('may not fit'), findsOneWidget);
    expect(find.text('See programs that may fit'), findsOneWidget);
    await tester.tap(find.text('See programs that may fit'));
    await tester.pumpAndSettle();
    expect(find.text('Open programs'), findsOneWidget);
  });

  testWidgets('MDRRMO call stays disabled', (tester) async {
    await _pump(tester, const SakunaCatalogScreen());
    expect(find.text('Medical emergency'), findsOneWidget);
    expect(find.text('Road accident'), findsOneWidget);
    final call = tester.widget<TextButton>(find.byKey(const Key('mdrrmo-call')));
    expect(call.onPressed, isNull);
    expect(find.byKey(const Key('sos-911-strip')), findsOneWidget);
  });

  testWidgets('911 strip stays behind the barangay picker', (tester) async {
    await _pump(
      tester,
      IncidentReportScreen(kind: ServiceCatalogMock.sakunaById('flood'), openPicker: true),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sos-911-strip')), findsOneWidget);
    expect(find.byKey(const Key('barangay-picker-search')), findsOneWidget);
    final search = tester.widget<TextField>(find.byKey(const Key('barangay-picker-search')));
    expect(search.autofocus, isFalse);
    expect(find.descendant(of: find.byType(ListTile).first, matching: find.text('Call 911')), findsNothing);
  });

  testWidgets('sent screen uses the sample copy', (tester) async {
    await _pump(
      tester,
      IncidentSentScreen(kind: ServiceCatalogMock.sakunaById('flood'), barangay: 'Dalig', landmark: 'near the covered court'),
    );
    expect(find.text(ServiceCatalogMock.sentTitle), findsOneWidget);
    expect(find.text(ServiceCatalogMock.sentBody), findsOneWidget);
    expect(find.text(ServiceCatalogMock.sentDanger), findsOneWidget);
    expect(find.text(ServiceCatalogMock.sentReference), findsOneWidget);
    expect(find.byKey(const Key('sos-911-strip')), findsOneWidget);
    expect(find.text('View my reports'), findsOneWidget);
  });

  testWidgets('home birth adds and drops the attendant requirement', (tester) async {
    await _pump(tester, const DelayedBirthWizard(key: Key('step-4'), initialStep: 4));
    expect(find.byKey(const Key('req-attendant')), findsOneWidget);
    await _pump(tester, const DelayedBirthWizard(key: Key('step-3'), initialStep: 3));
    await tester.tap(find.text('Hospital'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('remove-requirement-dialog')), findsNothing);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('req-attendant')), findsNothing);
  });

  testWidgets('attached home-birth file asks before it is dropped', (tester) async {
    await _pump(
      tester,
      const DelayedBirthWizard(
        initialStep: 3,
        attendantFile: ServiceCatalogMock.attendantFileName,
      ),
    );
    await tester.tap(find.text('Hospital'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('remove-requirement-dialog')), findsOneWidget);
    await tester.tap(find.text('Keep my earlier answer'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
    expect(find.byKey(const Key('remove-requirement-dialog')), findsNothing);
  });

  testWidgets('affidavit with no file disappears, and Keep reverts a filed one', (tester) async {
    await _pump(tester, const DelayedBirthWizard(key: Key('ack-none'), initialStep: 2));
    await tester.tap(find.text('No').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('remove-requirement-dialog')), findsNothing);
    expect(find.byKey(const Key('father-name-field')), findsNothing);

    await _pump(
      tester,
      const DelayedBirthWizard(
        key: Key('ack-file'),
        initialStep: 2,
        affidavitFile: ServiceCatalogMock.affidavitFileName,
      ),
    );
    await tester.ensureVisible(find.text('No').last);
    await tester.tap(find.text('No').last);
    await tester.pumpAndSettle();
    expect(find.text('Remove the affidavit?'), findsOneWidget);
    expect(find.textContaining(ServiceCatalogMock.affidavitFileName), findsOneWidget);
    await tester.tap(find.text('Keep my earlier answer'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('father-name-field')), findsOneWidget);
    expect(find.text('Mateo Cruz Villanueva'), findsOneWidget);
  });

  testWidgets('remove clears the father name', (tester) async {
    await _pump(
      tester,
      const DelayedBirthWizard(
        initialStep: 2,
        affidavitFile: ServiceCatalogMock.affidavitFileName,
      ),
    );
    await tester.ensureVisible(find.text('No').last);
    await tester.tap(find.text('No').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove file and continue'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('father-name-field')), findsNothing);
    expect(find.text('Mateo Cruz Villanueva'), findsNothing);
  });

  testWidgets('wizard footer rides and the pinned head stays out of the scroll', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    await _pump(tester, const DelayedBirthWizard(initialStep: 2, focusFather: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final head = find.byKey(const Key('wizard-pinned-head'));
    final scroll = find.byKey(const Key('wizard-scroll'));
    expect(find.descendant(of: scroll, matching: find.text('Hakbang 2 · Parents')), findsNothing);
    expect(tester.getTopLeft(head).dy, lessThan(tester.getTopLeft(scroll).dy));
    final footer = tester.getRect(find.byKey(const Key('wizard-footer')));
    final field = tester.getRect(find.byKey(const Key('father-name-field')));
    final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect((screen - 336) - footer.bottom, lessThan(8));
    expect(footer.top - field.bottom, greaterThanOrEqualTo(16));
    final text = tester.widget<TextField>(find.byKey(const Key('father-name-field')));
    expect(text.scrollPadding.bottom, greaterThanOrEqualTo(16));
    expect(text.keyboardType, TextInputType.name);
    expect(text.textCapitalization, TextCapitalization.words);
    expect(text.textInputAction, TextInputAction.done);
  });

  testWidgets('next on the last name opens the date picker', (tester) async {
    await _pump(tester, const DelayedBirthWizard(initialStep: 1));
    await tester.enterText(find.byKey(const Key('child-last-name')), 'Mercado');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('educational AICS uses the program route constant', (tester) async {
    await _pump(tester, const TulongCatalogScreen());
    await tester.scrollUntilVisible(find.text('Educational AICS'), 200);
    await tester.tap(find.text('Educational AICS'));
    await tester.pumpAndSettle();
    expect(find.text('Educational Assistance'), findsOneWidget);
    final route = ModalRoute.of(tester.element(find.text('Educational Assistance')));
    expect(route?.settings.name, kTulongProgramRoute);
  });

  testWidgets('hub-restricted entry still reaches the guarded request list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final session = CitizenSessionService();
    await session.continueAsGuest();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider(create: (_) => RequestsService(seedDemoData: false)),
          ChangeNotifierProvider(create: (_) => BalitaService()),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider(create: (_) => MasterFileService()),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: MaterialApp(home: RootShell.withKey()),
      ),
    );
    await tester.pumpAndSettle();
    final close = find.byIcon(Icons.close);
    if (close.evaluate().isNotEmpty) {
      await tester.tap(close, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    RootShell.openCatalog(
      tester.element(find.byType(RootShell)),
      ServiceLauncherTarget.dokyu,
      policy: CatalogGatePolicy.hubRestricted,
    );
    await tester.pumpAndSettle();
    expect(find.text('Create Account'), findsOneWidget);
    expect(session.accessLevel, AccessLevel.guest);
  });

  testWidgets('duplicate intercept fires on Start request, and Not now stays put', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final session = CitizenSessionService();
    await session.login(MockCatalog.duplicateVerifiedDemoAccount);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider(create: (_) => RequestsService(seedDemoData: false)),
          ChangeNotifierProvider(create: (_) => BalitaService()),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider(create: (_) => MasterFileService()),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: MaterialApp(home: RootShell.withKey()),
      ),
    );
    await tester.pumpAndSettle();
    final close = find.byIcon(Icons.close);
    if (close.evaluate().isNotEmpty) {
      await tester.tap(close, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    RootShell.openCatalog(
      tester.element(find.byType(RootShell)),
      ServiceLauncherTarget.dokyu,
    );
    await tester.pumpAndSettle();
    expect(find.text('Use your verified account'), findsNothing);
    expect(find.text('Barangay Clearance'), findsWidgets);

    await tester.tap(find.text('Barangay Clearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start request'));
    await tester.pumpAndSettle();
    expect(find.text('Use your verified account'), findsOneWidget);
    expect(find.text('Sample switch. No password is shared between accounts.'), findsOneWidget);
    expect(find.textContaining('Policy text to confirm'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Use your verified account'), findsNothing);
    expect(find.text('Barangay Clearance'), findsOneWidget);
    expect(session.account?.id, MockCatalog.duplicateVerifiedDemoAccount.id);

    await tester.tap(find.text('Start request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to my verified account'));
    await tester.pumpAndSettle();
    expect(find.text('Use your verified account'), findsNothing);
    expect(session.account?.id, MockCatalog.duplicateVerifiedDemoAccount.id);
  });

  testWidgets('rejected account browses Dokyu and is gated on Start request', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final base = MockCatalog.demoAccounts.first;
    final rejected = CitizenAccount(
      id: base.id,
      firstName: base.firstName,
      lastName: base.lastName,
      email: base.email,
      mobile: base.mobile,
      barangay: base.barangay,
      purok: base.purok,
      address: base.address,
      birthdate: base.birthdate,
      sex: base.sex,
      civilStatus: base.civilStatus,
      occupation: base.occupation,
      profileCompleteness: base.profileCompleteness,
      status: 'Rejected',
    );
    final session = CitizenSessionService();
    await session.login(rejected);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider(create: (_) => RequestsService(seedDemoData: false)),
        ],
        child: const MaterialApp(home: DokyuCatalogScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Barangay Clearance'), findsOneWidget);
    expect(find.text('Resubmit verification'), findsNothing);
    expect(find.text('Reapply'), findsNothing);

    await tester.tap(find.text('Barangay Clearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start request'));
    await tester.pumpAndSettle();
    expect(find.text('Resubmit verification'), findsOneWidget);
    expect(find.text('Reapply'), findsNothing);
    expect(find.text('Continue verification'), findsNothing);
  });
}
