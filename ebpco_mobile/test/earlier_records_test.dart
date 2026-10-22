import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ebpco_mobile/core/api/problem.dart';
import 'package:ebpco_mobile/domain/earlier_records.dart';
import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/screens/applications/earlier_permits_section.dart';
import 'package:ebpco_mobile/screens/applications/find_earlier_permits_screen.dart';
import 'package:ebpco_mobile/screens/permits/application_wizard_screen.dart';
import 'package:ebpco_mobile/services/applications_service.dart';
import 'package:ebpco_mobile/services/businesses_service.dart';
import 'package:ebpco_mobile/services/earlier_records_service.dart';
import 'package:ebpco_mobile/services/session_service.dart';
import 'package:ebpco_mobile/widgets/before_ebpco_badge.dart';

/// Records before eBPCO (ebpco-api 069) on the app's side: the permits the
/// Municipality issued on paper before eBPCO, once an officer matched them
/// to the account, and "Find my earlier permits". The same rules and words
/// as the citizen portal's `earlier-records.ts`.
Map<String, dynamic> _permitJson({
  String permitType = 'Building Permit',
  String permitNumber = 'CO 2020/0033',
  String? validUntil = '2027-01-31',
  String? businessId,
  String? registerRef = 'Logbook 3, p. 41',
}) =>
    {
      'id': 'p-$permitNumber',
      'referenceNumber': 'PRE-2020-000033',
      'permitType': permitType,
      'permitNumber': permitNumber,
      'dateIssued': '2020-02-14',
      'validUntil': validUntil,
      'location': 'Purok 2, Poblacion',
      'scopeOfWork': null,
      'businessName': businessId == null ? null : 'Veggie Like',
      'businessId': businessId,
      'issuedBy': 'MPDO',
      'registerRef': registerRef,
    };

RecordClaim _claim(String status, {String? note, String? orNumber, String? dateIssued = '2019-04-12'}) =>
    RecordClaim.fromJson({
      'id': 'c-$status',
      'permitNumber': 'BP-2019-0412',
      'dateIssued': dateIssued,
      'orNumber': orNumber,
      'status': status,
      'note': note,
      'createdAt': '2026-10-20T02:00:00.000Z',
      'decidedAt': null,
    });

Widget _host(EarlierRecordsService records, Widget child) => ChangeNotifierProvider.value(
      value: records,
      child: MaterialApp(home: child),
    );

void main() {
  group('GET /me/earlier-permits and /me/record-claims', () {
    test('an earlier permit reads as the register writes it, with the business on the account', () {
      final permit = EarlierPermit.fromJson(_permitJson(businessId: 'b-1'));
      expect(permit.permitNumber, 'CO 2020/0033');
      expect(permit.referenceNumber, 'PRE-2020-000033');
      expect(permit.dateIssued, '2020-02-14');
      expect(permit.validUntil, '2027-01-31');
      expect(permit.businessId, 'b-1');
      expect(permit.businessName, 'Veggie Like');
      expect(permit.registerRef, 'Logbook 3, p. 41');
    });

    test('what the register leaves out stays out', () {
      final permit = EarlierPermit.fromJson(_permitJson(validUntil: null, registerRef: '  '));
      expect(permit.validUntil, isNull);
      expect(permit.registerRef, isNull);
      expect(permit.businessId, isNull);
      expect(permit.scopeOfWork, isNull);
    });

    test('a request carries what was given, its answer and the officer\'s note', () {
      final claim = _claim('rejected', note: 'The register shows another holder.', orNumber: '7712345');
      expect(claim.status, 'rejected');
      expect(claim.isWaiting, isFalse);
      expect(claim.note, 'The register shows another holder.');
      expect(claim.orNumber, '7712345');
      expect(_claim('pending').isWaiting, isTrue);
    });

    test('GET /businesses marks a business from the registry; an older server marks none', () {
      final base = {
        'id': 'b-1',
        'name': 'Veggie Like',
        'category': 'Retail',
        'street': 'Rizal St.',
        'barangay': 'Poblacion',
        'city': 'Castilla',
        'province': 'Sorsogon',
        'registrationNumber': '1234567',
        'dateRegistered': '2018-05-01',
        'status': 'Active',
      };
      expect(Business.fromJson({...base, 'importedBeforeEbpco': true}).importedBeforeEbpco, isTrue);
      expect(Business.fromJson({...base, 'importedBeforeEbpco': false}).importedBeforeEbpco, isFalse);
      expect(Business.fromJson(base).importedBeforeEbpco, isFalse);
    });
  });

  group('Valid / Expired', () {
    test('today is Castilla\'s date, whatever the phone\'s time zone', () {
      expect(manilaToday(DateTime.utc(2026, 10, 22, 15, 59)), '2026-10-22');
      expect(manilaToday(DateTime.utc(2026, 10, 22, 16, 0)), '2026-10-23');
    });

    test('the last day still counts as Valid; no date, no chip', () {
      expect(earlierPermitStanding('2026-10-23', '2026-10-23'), 'Valid');
      expect(earlierPermitStanding('2027-01-31', '2026-10-23'), 'Valid');
      expect(earlierPermitStanding('2026-10-22', '2026-10-23'), 'Expired');
      expect(earlierPermitStanding('2026-10-22T00:00:00.000Z', '2026-10-23'), 'Expired');
      expect(earlierPermitStanding(null, '2026-10-23'), isNull);
    });
  });

  group('Renew', () {
    test('only a permit type eBPCO still files can be renewed through the wizard', () {
      expect(canRenewEarlierPermit('Building Permit'), isTrue);
      expect(canRenewEarlierPermit('Certificate of Occupancy'), isTrue);
      expect(canRenewEarlierPermit('FSEC for Building Permit (BFP)'), isFalse);
      expect(canRenewEarlierPermit('Business Permit'), isFalse);
    });
  });

  group('Find my earlier permits', () {
    test('the permit number and the date issued or the OR number, at least one', () {
      expect(earlierClaimProblem(permitNumber: ' B ', dateIssued: '2019-04-12', orNumber: ''), contains('permit number'));
      expect(earlierClaimProblem(permitNumber: 'BP-2019-0412', dateIssued: null, orNumber: '  '), earlierClaimRule);
      expect(earlierClaimProblem(permitNumber: 'BP-2019-0412', dateIssued: '2019-04-12', orNumber: ''), isNull);
      expect(earlierClaimProblem(permitNumber: 'BP-2019-0412', dateIssued: null, orNumber: '7712345'), isNull);
    });

    test('the number is sent with its spacing tidied', () {
      expect(claimPermitNumber('  CO   2020/0033 '), 'CO 2020/0033');
    });

    test('Waiting, Confirmed, Not confirmed', () {
      expect(claimStatusLabel('pending'), 'Waiting');
      expect(claimStatusLabel('confirmed'), 'Confirmed');
      expect(claimStatusLabel('rejected'), 'Not confirmed');
    });

    test('a request says what was given and when it was sent', () {
      expect(claimDetails(_claim('pending', orNumber: '7712345')), 'Date issued Apr 12, 2019 · OR 7712345 · Sent Oct 20, 2026');
      expect(claimDetails(_claim('pending', dateIssued: null, orNumber: '7712345')), 'OR 7712345 · Sent Oct 20, 2026');
    });

    test('a refusal shows the server\'s own words', () {
      const waiting = ApiError(409, Problem(status: 409, detail: 'You already asked about this permit.'), false);
      const tooMany = ApiError(429, Problem(status: 429, detail: 'You have 10 requests waiting.'), false);
      const invalid = ApiError(
        400,
        Problem(status: 400, title: 'Request did not validate', fieldErrors: [
          FieldError(pointer: '/dateIssued', message: 'Give the date issued or the OR number.'),
        ]),
        false,
      );
      expect(earlierClaimMessage(waiting), 'You already asked about this permit.');
      expect(earlierClaimMessage(tooMany), 'You have 10 requests waiting.');
      expect(earlierClaimMessage(invalid), 'Give the date issued or the OR number.');
      expect(earlierClaimMessage(Exception('offline')), contains('could not reach'));
    });
  });

  group('My Applications: Issued before eBPCO', () {
    testWidgets('no earlier permit: no heading, only the way to find one', (tester) async {
      final records = EarlierRecordsService();
      await tester.pumpWidget(_host(records, const Scaffold(body: SingleChildScrollView(child: EarlierPermitsSection()))));

      expect(find.text(beforeEbpcoLabel), findsNothing);
      expect(find.text(beforeEbpcoNote), findsNothing);
      expect(find.text('Find my earlier permits'), findsOneWidget);
    });

    testWidgets('each permit: the badge, its number, Valid, the register ref, and Renew', (tester) async {
      final records = EarlierRecordsService()
        ..seed(
          permits: [
            EarlierPermit.fromJson(_permitJson(validUntil: '2099-12-31')),
            EarlierPermit.fromJson(_permitJson(
              permitType: 'FSEC for Building Permit (BFP)',
              permitNumber: 'FSEC-2018-07',
              validUntil: '2019-01-01',
              registerRef: null,
            )),
          ],
          claims: [_claim('pending')],
        );
      await tester.pumpWidget(_host(records, const Scaffold(body: SingleChildScrollView(child: EarlierPermitsSection()))));

      expect(find.text(beforeEbpcoLabel), findsNWidgets(3)); // the heading and both badges
      expect(find.byType(BeforeEbpcoBadge), findsNWidgets(2));
      expect(find.text(beforeEbpcoNote), findsOneWidget);
      expect(find.text('CO 2020/0033'), findsOneWidget);
      expect(find.text('Feb 14, 2020'), findsNWidgets(2));
      expect(find.text('Valid'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Register ref. Logbook 3, p. 41'), findsOneWidget);
      // The retired BFP type is history only.
      expect(find.text('Renew'), findsOneWidget);
      // Nothing to track, download or scan.
      expect(find.text('Download'), findsNothing);
      expect(find.textContaining('QR'), findsNothing);
      expect(find.text('1 request waiting'), findsOneWidget);
    });

    testWidgets('Renew opens the wizard as a Renewal with the number filled in', (tester) async {
      final records = EarlierRecordsService()..seed(permits: [EarlierPermit.fromJson(_permitJson(businessId: 'b-1'))]);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: records),
          ChangeNotifierProvider(create: (_) => SessionService()),
          ChangeNotifierProvider(create: (_) => ApplicationsService()),
          ChangeNotifierProvider(create: (_) => BusinessesService()),
        ],
        child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: EarlierPermitsSection()))),
      ));

      await tester.tap(find.text('Renew'));
      await tester.pumpAndSettle();

      expect(find.byType(ApplicationWizardScreen), findsOneWidget);
      final wizard = tester.widget<ApplicationWizardScreen>(find.byType(ApplicationWizardScreen));
      expect(wizard.applicationAction, 'Renewal');
      expect(wizard.permitType, 'Building Permit');
      expect(wizard.businessId, 'b-1');
      expect(find.text('Existing Permit Number'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller!.text, 'CO 2020/0033');
      // And offered as a pick under the field.
      expect(find.text('Your permits issued before eBPCO:'), findsOneWidget);
    });
  });

  group('Find my earlier permits screen', () {
    testWidgets('asks for the date issued or the OR number before sending', (tester) async {
      final records = EarlierRecordsService();
      await tester.pumpWidget(_host(records, const FindEarlierPermitsScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'BP-2019-0412');
      await tester.tap(find.text('Send'));
      await tester.pump();

      expect(find.text(earlierClaimRule), findsNWidgets(2)); // the standing rule and the error
      expect(find.text(earlierClaimSent), findsNothing);
    });

    testWidgets('Your requests: Waiting, Confirmed, Not confirmed with the officer\'s note', (tester) async {
      final records = EarlierRecordsService()
        ..seed(claims: [
          _claim('pending'),
          _claim('confirmed'),
          _claim('rejected', note: 'The register shows another holder.'),
        ]);
      await tester.pumpWidget(_host(records, const FindEarlierPermitsScreen()));
      await tester.pump();

      // The page's own list, not a text field's.
      await tester.scrollUntilVisible(find.text('Not confirmed'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Your requests'), findsOneWidget);
      expect(find.text('Waiting'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Not confirmed'), findsOneWidget);
      expect(find.text('Note from the Municipality: The register shows another holder.'), findsOneWidget);
    });
  });
}
