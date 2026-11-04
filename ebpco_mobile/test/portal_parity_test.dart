import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ebpco_mobile/domain/account_verification.dart';
import 'package:ebpco_mobile/domain/applying_as.dart';
import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/domain/permit_catalog.dart';
import 'package:ebpco_mobile/domain/property_address.dart';
import 'package:ebpco_mobile/domain/who_may_apply.dart';
import 'package:ebpco_mobile/screens/applications/permit_document_screen.dart';
import 'package:ebpco_mobile/screens/business/business_detail_screen.dart';
import 'package:ebpco_mobile/screens/permits/application_wizard_screen.dart';
import 'package:ebpco_mobile/screens/permits/permit_catalog_screen.dart';
import 'package:ebpco_mobile/screens/permits/requirements_sheet.dart';
import 'package:ebpco_mobile/services/applications_service.dart';
import 'package:ebpco_mobile/services/businesses_service.dart';
import 'package:ebpco_mobile/services/earlier_records_service.dart';
import 'package:ebpco_mobile/services/session_service.dart';
import 'package:ebpco_mobile/widgets/choice_card.dart';

/// App 1.0.3: the app says and does what the Citizen Portal does (parity
/// check, 4 Nov 2026) — the wizard's title and steps, the Documents step's
/// groups and count, the Requirements sheet, the verification banner where
/// the portal shows it, "Apply for a permit" from a business, the catalog's
/// chips, and the printed Property block.

class _Session extends SessionService {
  _Session(this._verification);
  final AccountVerification? _verification;

  @override
  AccountVerification? get verification => _verification;
}

class _Businesses extends BusinessesService {
  _Businesses(this._list);
  final List<Business> _list;

  @override
  List<Business> get businesses => _list;

  @override
  List<Business> get active => _list.where((b) => b.isActive).toList();

  @override
  Future<void> refresh() async {}
}

Business _business({String id = 'b1', String status = 'Active'}) => Business(
      id: id,
      name: 'Dela Cruz Sari-sari Store',
      category: 'Retail',
      street: 'Rizal St.',
      barangay: 'Poblacion',
      city: 'Castilla',
      province: 'Sorsogon',
      registrationNumber: 'DTI-1234567',
      dateRegistered: '2026-01-15',
      status: status,
    );

Widget _app(Widget home, {AccountVerification? verification, List<Business> businesses = const []}) => MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionService>(create: (_) => _Session(verification)),
        ChangeNotifierProvider(create: (_) => ApplicationsService()),
        ChangeNotifierProvider<BusinessesService>(create: (_) => _Businesses(businesses)),
        ChangeNotifierProvider(create: (_) => EarlierRecordsService()),
      ],
      child: MaterialApp(home: home),
    );

RequirementDoc _doc(String code, {bool required = true, int hardCopies = 0, String? note, String description = ''}) =>
    RequirementDoc(
      code: code,
      label: code,
      description: description,
      required: required,
      documentIds: const [],
      status: 'not-provided',
      hardCopies: hardCopies,
      hardCopyNote: note,
    );

/// Brings a row of a lazily built list on screen: drags until it is built, then scrolls it into view.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

bool _selected(WidgetTester tester, String title) =>
    tester.widget<SoftChoiceCard>(find.widgetWithText(SoftChoiceCard, title)).selected;

const _bfpNote = 'The BFP requires a hard copy. Submit it at the Castilla Fire Station.';

/// A loader that answers each action with its own list, and remembers what was asked.
class _FakeRequirements {
  final asked = <String>[];

  Future<List<RequirementDoc>> call(String permitType, String action) async {
    asked.add('$permitType/$action');
    return [
      _doc('Unified Application Form ($action)', description: 'Signed by the owner.'),
      _doc('Road Clearance', required: false, description: 'Only if the project is along a national road.'),
      _doc('FSEC', hardCopies: 1, note: _bfpNote),
    ];
  }
}

void main() {
  group('the wizard', () {
    test('is titled "New <permit type> application", with the portal\'s four step names', () {
      expect(wizardTitle('Building Permit'), 'New Building Permit application');
      expect(wizardTitle('Certificate of Occupancy'), 'New Certificate of Occupancy application');
      expect(wizardTitle(''), 'New permit application');
      expect(wizardStepLabels, ['Applicant & type', 'Details', 'Documents', 'Review & submit']);
    });

    testWidgets('shows the title, the step\'s name and the Business choice in the portal\'s words', (tester) async {
      await tester.pumpWidget(_app(const ApplicationWizardScreen(permitType: 'Electrical Permit')));
      await tester.pumpAndSettle();

      expect(find.text('New Electrical Permit application'), findsOneWidget);
      expect(find.text('Electrical Permit'), findsOneWidget); // the Permit Type card, not the title
      expect(find.text('Step 1 of 4 · Applicant & type'), findsOneWidget);
      expect(find.text('For a business or commercial establishment you registered.'), findsOneWidget);
    });

    testWidgets('shows the verification banner while the account waits', (tester) async {
      await tester.pumpWidget(_app(
        const ApplicationWizardScreen(permitType: 'Electrical Permit'),
        verification: const AccountVerification(status: 'pending'),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('verification-banner')), findsOneWidget);
      expect(find.text('Your account is being verified.'), findsOneWidget);
      expect(find.text('You can prepare applications now and submit once it is verified.'), findsOneWidget);
    });

    testWidgets('shows no banner once the account is verified', (tester) async {
      await tester.pumpWidget(_app(
        const ApplicationWizardScreen(permitType: 'Fencing Permit'),
        verification: const AccountVerification(status: 'verified'),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('verification-banner')), findsNothing);
    });

    testWidgets('started from a business: Applying as is Business, with that business chosen', (tester) async {
      await tester.pumpWidget(_app(
        const ApplicationWizardScreen(permitType: 'Electrical Permit', businessId: 'b1'),
        businesses: [_business()],
      ));
      await tester.pumpAndSettle();

      expect(_selected(tester, 'Business'), isTrue);
      expect(_selected(tester, 'Residential / Private Individual'), isFalse);
      expect(find.text('Dela Cruz Sari-sari Store'), findsWidgets);
    });

    test('an unanswered Applying as is asked politely, as the portal does', () {
      expect(
        applyingAsProblem(applyingAs: null, businessId: null),
        'Please choose whether you are applying as Residential / Private Individual or as a Business.',
      );
    });
  });

  group('the Documents step', () {
    test('groups Required first, then If applicable, in the checklist\'s order; an empty group is left out', () {
      final docs = [_doc('A'), _doc('B', required: false), _doc('C')];
      final groups = documentGroups(docs, isRequired: (d) => d.required);
      expect(groups.map((g) => g.required), [true, false]);
      expect(groups.first.documents.map((d) => d.code), ['A', 'C']);
      expect(groups.last.documents.map((d) => d.code), ['B']);

      final requiredOnly = documentGroups([_doc('A')], isRequired: (d) => d.required);
      expect(requiredOnly.map((g) => g.required), [true]);
      // The wizard's own rule (the paper permit's copy) decides, not only the flag.
      final proof = documentGroups([_doc('prior-permit-proof', required: false)], isRequired: (_) => true);
      expect(proof.single.required, isTrue);
    });

    test('counts required documents only: "n of m required attached"', () {
      expect(requiredProgressText(required: 3, attached: 1), '1 of 3 required attached');
      expect(requiredProgressText(required: 12, attached: 12), '12 of 12 required attached');
    });

    testWidgets('each group is headed in the portal\'s words', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Column(children: [DocumentGroupHeading(required: true), DocumentGroupHeading(required: false)])),
      ));
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Needed before you can submit.'), findsOneWidget);
      expect(find.text('If applicable'), findsOneWidget);
      expect(find.text('Attach only if your project includes this work.'), findsOneWidget);
    });
  });

  group('the Requirements sheet', () {
    Future<void> open(
      WidgetTester tester,
      String permitType,
      _FakeRequirements load, {
      void Function(String?)? answered,
    }) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final action = await showRequirementsSheet(context, permitType: permitType, load: load.call);
                answered?.call(action);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('Building Permit: the office, New / Renewal / Amendment, tags and hard copies; Start answers the tab',
        (tester) async {
      final load = _FakeRequirements();
      String? started;
      await open(tester, 'Building Permit', load, answered: (action) => started = action);

      expect(find.text('Building Permit'), findsOneWidget);
      expect(find.text('Office of the Building Official (OBO)'), findsOneWidget);
      for (final action in ['New', 'Renewal', 'Amendment']) {
        expect(find.byKey(ValueKey('requirements-tab-$action')), findsOneWidget);
      }
      expect(load.asked, ['Building Permit/New']);
      expect(find.text('Unified Application Form (New)'), findsOneWidget);
      expect(find.text('Signed by the owner.'), findsOneWidget);
      expect(find.text('Required'), findsNWidgets(2));
      expect(find.text('If applicable'), findsOneWidget);
      expect(find.text('Online only, no hard copy'), findsNWidgets(2));
      expect(find.text('Hard copies: 1'), findsOneWidget);
      expect(find.text(_bfpNote), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('requirements-tab-Renewal')));
      await tester.pumpAndSettle();
      expect(load.asked, ['Building Permit/New', 'Building Permit/Renewal']);
      expect(find.text('Unified Application Form (Renewal)'), findsOneWidget);

      // Back to New: asked once only.
      await tester.tap(find.byKey(const ValueKey('requirements-tab-New')));
      await tester.pumpAndSettle();
      expect(load.asked, hasLength(2));

      await tester.tap(find.byKey(const ValueKey('requirements-tab-Amendment')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start application'));
      await tester.pumpAndSettle();
      expect(find.text('Start application'), findsNothing);
      expect(started, 'Amendment');
    });

    testWidgets('a type with one list has no tabs, and is read as New', (tester) async {
      final load = _FakeRequirements();
      await open(tester, 'Zoning / Locational Clearance', load);

      expect(find.text('Municipal Planning and Development Office (MPDO / Zoning)'), findsOneWidget);
      expect(find.byKey(const ValueKey('requirements-tab-New')), findsNothing);
      expect(load.asked, ['Zoning / Locational Clearance/New']);
      expect(checklistVariesByAction('Building Permit'), isTrue);
      expect(checklistVariesByAction('Zoning / Locational Clearance'), isFalse);
    });

    testWidgets('a list that cannot be read says so, and Try again asks again', (tester) async {
      var calls = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RequirementsSheet(
            permitType: 'Sign Permit',
            load: (_, _) async {
              calls++;
              if (calls == 1) throw Exception('offline');
              return [_doc('Sign design')];
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Could not load the requirements. Check your connection, then try again.'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Sign design'), findsOneWidget);
    });
  });

  group('Permit Services', () {
    testWidgets('a chip only on a restricted type; Requirements on each card; the banner; the FSCCR', (tester) async {
      final load = _FakeRequirements();
      await tester.pumpWidget(_app(
        PermitCatalogScreen(
          applicantKinds: Future.value({'Building Permit': [applyingAsBusiness]}),
          requirements: load.call,
        ),
        verification: const AccountVerification(status: 'unsubmitted'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Verify your account to submit applications.'), findsOneWidget);
      expect(find.text('Verify my account'), findsOneWidget);

      // The Certificate of Occupancy asks for the FSCCR, as the server's checklist does.
      expect(find.textContaining('FSCCR'), findsNothing);
      await tester.tap(find.text('What to upload here'));
      await tester.pumpAndSettle();
      expect(find.text(bfpUploadNote), findsOneWidget);
      expect(bfpUploadNote, contains('a Certificate of Occupancy application asks for the Fire Safety Compliance and '
          'Commissioning Report (FSCCR) instead'));

      // The cards sit below the notices: brought on screen first.
      await _reveal(tester, find.text('Business only'));
      expect(find.text('Business only'), findsOneWidget);
      expect(find.text('Homes & businesses'), findsNothing);

      final requirements = find.byKey(const ValueKey('requirements-Electrical Permit'));
      await _reveal(tester, requirements);
      await tester.tap(requirements);
      await tester.pumpAndSettle();
      expect(load.asked, ['Electrical Permit/New']);
      expect(find.text('Start application'), findsOneWidget);
    });

    test('the chip is left out for a type open to homes and businesses', () {
      expect(restrictedKindsChip(bothApplicantKinds), isNull);
      expect(restrictedKindsChip([applyingAsBusiness]), 'Business only');
      expect(restrictedKindsChip([applyingAsResidential]), 'Residential only');
    });
  });

  group('"Apply for a permit" on a business', () {
    testWidgets('opens Permit Services, then the wizard as Business with that business', (tester) async {
      await tester.pumpWidget(_app(const BusinessDetailScreen(businessId: 'b1'), businesses: [_business()]));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('business-apply')));
      await tester.tap(find.byKey(const ValueKey('business-apply')));
      await tester.pumpAndSettle();
      expect(tester.widget<PermitCatalogScreen>(find.byType(PermitCatalogScreen)).businessId, 'b1');

      final row = find.text('Electrical Permit');
      await _reveal(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(tester.widget<ApplicationWizardScreen>(find.byType(ApplicationWizardScreen)).businessId, 'b1');
      expect(_selected(tester, 'Business'), isTrue);
    });

    testWidgets('an inactive business is told to reactivate it first', (tester) async {
      await tester.pumpWidget(_app(const BusinessDetailScreen(businessId: 'b1'), businesses: [_business(status: 'Inactive')]));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('business-apply')));
      await tester.tap(find.byKey(const ValueKey('business-apply')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('This business is inactive. Reactivate it before applying for a permit.'), findsOneWidget);
      expect(find.byType(PermitCatalogScreen), findsNothing);
    });
  });

  group('the printed permit\'s Valid Until and Approval', () {
    test('a Certificate of Occupancy with no expiry has no fixed term; another type reads a neutral "Not recorded"', () {
      expect(
        permitValidUntil(issued: true, permitType: 'Certificate of Occupancy'),
        "No fixed expiry (valid while the building's use and occupancy stay the same)",
      );
      expect(permitValidUntil(issued: true, permitType: 'Certificate of Occupancy', expiresOn: ' '), occupancyNoExpiry);
      for (final type in ['Building Permit', 'Fencing Permit']) {
        expect(permitValidUntil(issued: true, permitType: type), 'Not recorded', reason: type);
      }
      expect(permitValidUntil(issued: true, permitType: 'Building Permit', expiresOn: '2027-11-04'), 'November 4, 2027');
      expect(permitValidUntil(issued: false, permitType: 'Certificate of Occupancy'), 'Not yet assigned');
    });

    test('an old permit with no approving official or office reads "Not recorded", never "Not on file"', () {
      expect(permitApproval(issued: true, office: 'Office of the Building Official (OBO)'),
          (name: 'Not recorded', position: 'Not recorded'));
      expect(
        permitApproval(
          issued: true,
          approvingOfficial: 'Engr. Maria Santos',
          approvingOffice: 'Office of the Building Official',
          office: 'Office of the Building Official (OBO)',
        ),
        (name: 'Engr. Maria Santos', position: 'Office of the Building Official'),
      );
      expect(permitApproval(issued: true, approvingOfficial: 'Engr. Maria Santos', office: 'OBO').position, 'Not recorded');
      expect(permitApproval(issued: false, office: 'Office of the Building Official (OBO)'),
          (name: 'Not yet assigned', position: 'Office of the Building Official (OBO)'));
    });
  });

  group('the printed Property block', () {
    const home = 'Purok 3, San Rafael, Castilla, Sorsogon';

    test('reads the application\'s own address, with the barangay it names, never the business\'s', () {
      expect(propertyRows(location: home, business: _business()), [
        ('Barangay', 'San Rafael'),
        ('Street / Location', home),
      ]);
      expect(propertyLine(location: home, business: _business()), home);
    });

    test('a Residential application with an address is not "Not on file"', () {
      final rows = propertyRows(location: home);
      expect(rows.map((r) => r.$2), isNot(contains('Not on file')));
    });

    test('falls back to the business only when the application gave none', () {
      expect(propertyRows(location: '  ', business: _business()), [
        ('Barangay', 'Poblacion'),
        ('City / Municipality', 'Castilla'),
        ('Street / Location', 'Rizal St.'),
        ('Province', 'Sorsogon'),
      ]);
      expect(propertyLine(location: null, business: _business()), 'Rizal St., Poblacion, Castilla');
      expect(propertyRows().map((r) => r.$2).toSet(), {'Not on file'});
      expect(propertyLine(), 'Not on file');
    });

    test('a barangay is named only when exactly one is in the address', () {
      expect(barangayIn('brgy. bonga, castilla'), 'Bonga');
      expect(barangayIn('Lot 4, Bongabong Road'), isNull);
      expect(barangayIn('Mayon St., Poblacion, Castilla'), isNull);
      expect(barangayIn('Somewhere far away'), isNull);
      expect(propertyRows(location: 'Lot 4, Bongabong Road'), [('Street / Location', 'Lot 4, Bongabong Road')]);
    });
  });
}
