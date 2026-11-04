import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/dates.dart';
import 'package:ebpco_mobile/domain/lgu_contact.dart';
import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/domain/permit_fields.dart';
import 'package:ebpco_mobile/domain/reviewing_office.dart';
import 'package:ebpco_mobile/screens/applications/application_detail_screen.dart';
import 'package:ebpco_mobile/screens/applications/permit_document_screen.dart';

/// App 1.0.3, the Citizen Portal's design-review fixes (4 Nov 2026): one
/// field map for the printed permit, one name per office, the Treasurer's
/// Office as the one place to pay, the portal's dates, and documents that
/// reflow on a phone instead of being cut off or shrunk.

/// COPIED, not imported, from the Citizen Portal's permit-document.page.spec.ts
/// ("one field map"), which the Admin Portal's preview spec pins too: a label
/// changed in one place fails here until the app and both portals agree.
const _businessPermitLabels = [
  'Permit No.', 'Application No.', 'Date issued', 'Valid until',
  'Owner / Permittee name', 'Business name', 'Contact number', 'Address',
  'Location',
  'Application type', 'Date applied',
  'Fee', 'Amount', 'Total amount due', 'Balance', 'Order of Payment No.',
];

ApplicationSummary _app({
  String applyingAs = 'business',
  String? businessName = "Juan's Eatery",
  String? location = '10 Rizal Street, Bonga, Castilla, Sorsogon',
  Map<String, dynamic> form = const {},
  String paymentStatus = 'Paid',
  bool withOrder = true,
}) =>
    ApplicationSummary.fromJson({
      'id': '6f1c2b9e-4d3a-4b7e-9a51-0c2d8e7f6a10',
      'referenceNumber': 'E-BPCO-2026-000123',
      'permitType': 'Building Permit',
      'applicationAction': 'New',
      'businessId': applyingAs == 'business' ? 'b1' : null,
      'businessName': businessName,
      'location': location,
      'lifecycleStatus': 'Released',
      'applicantStatus': 'Ready for Release',
      'dateSubmitted': '2026-10-20T02:00:00Z',
      'applyingAs': applyingAs,
      'form': {'applyingAs': applyingAs, ...form},
      'payment': {
        'status': paymentStatus,
        'orderOfPayment': withOrder
            ? {
                'number': 'OP-2026-000004',
                'assessedAt': '2026-10-25T01:00:00Z',
                'totalCentavos': 682050,
                'fees': {'filing': 50000, 'processing': 0, 'others': 632050},
              }
            : null,
      },
    });

PermitInfo _permit({List<String> conditions = const [], String? scope}) => PermitInfo.fromJson({
      'permitNumber': 'BP-2026-000001',
      'issuedDate': '2026-11-04',
      'expiresOn': '2027-11-04',
      'scope': scope,
      'conditions': conditions,
      'approvingOfficial': 'Engr. Maria Santos',
      'approvingOffice': null,
    });

final _owner = CitizenProfile.fromJson(const {
  'firstName': 'Juan',
  'lastName': 'Dela Cruz',
  'mobileNumber': '09171234567',
  'street': '10 Rizal Street',
  'barangay': 'Bonga',
  'city': 'Castilla',
  'province': 'Sorsogon',
});

PermitDocumentContent _content({ApplicationSummary? app, PermitInfo? permit, bool issued = true}) => permitDocumentContent(
      app: app ?? _app(),
      permit: issued ? (permit ?? _permit()) : null,
      owner: _owner,
      verifyBaseUrl: 'https://citizen.castilla-ebpco.online',
      now: DateTime(2026, 11, 4, 16),
    );

String _value(List<(String, String)> rows, String label) => rows.firstWhere((r) => r.$1 == label).$2;

void main() {
  group('one name per office (design review I5)', () {
    test('the backend\'s issuing-office names, word for word; the short forms for chips only', () {
      expect(Offices.buildingOfficial.name, 'Office of the Building Official (Municipal Engineering Office)');
      expect(Offices.buildingOfficial.short, 'OBO');
      expect(Offices.zoning.name, 'Municipal Planning and Development Office (Zoning Administrator)');
      expect(Offices.zoning.short, 'MPDO');
      expect(Offices.fireStation.name, 'Bureau of Fire Protection — Castilla Fire Station');
      expect(Offices.treasurer.name, "Municipal Treasurer's Office");
      expect(municipalTreasurer.name, Offices.treasurer.name);
      expect(municipalTreasurer.short, Offices.treasurer.short);
      expect(municipalEngineer.name, Offices.buildingOfficial.name);
      expect(planningAndDevelopment.name, Offices.zoning.name);
    });

    test('each permit type\'s documents name its issuer from the registry', () {
      expect(reviewingOfficeFor('Building Permit'), Offices.buildingOfficial.name);
      expect(reviewingOfficeFor('Certificate of Occupancy'), Offices.buildingOfficial.name);
      expect(reviewingOfficeFor('Zoning / Locational Clearance'), Offices.zoning.name);
      expect(reviewingOfficeFor('FSEC for Building Permit (BFP)'), Offices.fireStation.name);
      expect(reviewingOfficeFor('Something new'), Offices.buildingOfficial.name);
    });
  });

  group('the printed permit\'s one field map (design review I3)', () {
    test('prints the shared labels, in order, on a business application\'s permit', () {
      expect(_content().labels, _businessPermitLabels);
    });

    test('a private individual\'s permit has no Business name row; occupancy and scope add their own', () {
      final private = _content(
        app: _app(applyingAs: 'residential', businessName: null, form: const {'occupancyGroup': 'A'}),
        permit: _permit(scope: 'Two-storey residence'),
      );
      expect(private.labels, isNot(contains('Business name')));
      expect(private.labels.sublist(private.labels.indexOf('Date applied') + 1, private.labels.indexOf('Fee')),
          ['Use or character of occupancy', 'Scope']);
      expect(_value(private.project, 'Use or character of occupancy'), 'Group A — Residential, Dwellings');
    });

    test('the values: the whole address, Location once, the portal\'s dates, the reference never an internal id', () {
      final c = _content();
      expect(_value(c.owner, 'Owner / Permittee name'), 'Juan Dela Cruz');
      expect(_value(c.owner, 'Business name'), "Juan's Eatery");
      expect(_value(c.owner, 'Address'), '10 Rizal Street, Bonga, Castilla, Sorsogon');
      expect(c.property, [('Location', '10 Rizal Street, Bonga, Castilla, Sorsogon')]);
      expect(_value(c.facts, 'Date issued'), 'Nov 4, 2026');
      expect(_value(c.facts, 'Valid until'), 'Nov 4, 2027');
      expect(_value(c.project, 'Application type'), 'New');
      expect(c.office, Offices.buildingOfficial.name);
      expect(c.footer.last, 'Document Ref. E-BPCO-2026-000123 · Generated Nov 4, 2026 · 4:00 PM · Page 1 of 1');
      expect(c.footer.join(' '), isNot(contains('6f1c2b9e')));
    });

    test('one assessment: the fees that apply, Total amount due, Balance, the Order of Payment number', () {
      final paid = _content().assessment!;
      expect(paid.fees, [('Filing Fee', '₱500.00'), ('Other Fees', '₱6,320.50')]);
      expect(paid.total, '₱6,820.50');
      expect(paid.balance, '₱0.00');
      expect(paid.orderNumber, 'OP-2026-000004');
      expect(_content(app: _app(paymentStatus: 'Pending Verification')).assessment!.balance, '₱6,820.50');
      expect(_content(app: _app(withOrder: false)).assessment, isNull);
    });

    test('an issued permit says where the signed copy is; the approving office falls back to the issuer', () {
      final issued = _content();
      expect(issued.approvalNote, 'Signed copy available at the release desk');
      expect(issued.approvalName, 'Engr. Maria Santos');
      expect(issued.approvalPosition, Offices.buildingOfficial.name);
      expect(issued.verificationUrl, 'https://citizen.castilla-ebpco.online/verify/BP-2026-000001');

      final preview = _content(issued: false);
      expect(preview.approvalNote, 'Pending authorized signature');
      expect(preview.number, 'Not yet assigned');
      expect(preview.verificationUrl, isNull);
      expect(preview.footer.first, startsWith('This is a system-generated preview'));
    });

    test('the owner as the permit was issued (server 073) wins over the account; the account only without it', () {
      final kept = PermitInfo.fromJson({
        'permitNumber': 'BP-2026-000001',
        'issuedDate': '2026-11-04',
        'conditions': const [],
        'ownerName': 'Juan P. Dela Cruz',
        'ownerAddress': '5 Mabini Street, Poblacion, Castilla, Sorsogon',
        'ownerContact': null,
      });
      expect(kept.keptOwner, (name: 'Juan P. Dela Cruz', address: '5 Mabini Street, Poblacion, Castilla, Sorsogon', contact: null));
      final printed = _content(permit: kept).owner;
      expect(_value(printed, 'Owner / Permittee name'), 'Juan P. Dela Cruz');
      expect(_value(printed, 'Address'), '5 Mabini Street, Poblacion, Castilla, Sorsogon');
      // Nothing on file when issued reads so, never the profile's current number.
      expect(_value(printed, 'Contact number'), 'Not on file');

      // An older server sends no ownerName: the account, as before.
      expect(_permit().keptOwner, isNull);
      final fallback = _content().owner;
      expect(_value(fallback, 'Owner / Permittee name'), 'Juan Dela Cruz');
      expect(_value(fallback, 'Contact number'), '09171234567');
      expect(_value(fallback, 'Address'), '10 Rizal Street, Bonga, Castilla, Sorsogon');
    });

    testWidgets('on a phone the permit reflows and scrolls: nothing cut off, every label readable', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PermitDocumentView(content: _content()))));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('paper-scroll')), findsOneWidget);
      for (final label in ['Owner / Permittee name', 'Business name', 'Contact number', 'Address', 'Location']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // Nothing laid out wider than the screen.
      final right = tester.getTopRight(find.text('10 Rizal Street, Bonga, Castilla, Sorsogon').first).dx;
      expect(right, lessThanOrEqualTo(390));
      expect(find.text(noConditionsNote), findsOneWidget);
      expect(find.text('Signed copy available at the release desk'), findsOneWidget);
      expect(find.text('Scan to verify at citizen.castilla-ebpco.online/verify/\nBP-2026-000001', findRichText: true),
          findsOneWidget);
      expect(find.text('Order of Payment No.: OP-2026-000004'), findsOneWidget);
    });

    testWidgets('on a tablet the A4 page is kept, two fields to a row', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PermitDocumentView(content: _content(issued: false)))));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('paper-scroll')), findsNothing);
      expect(find.text('Pending authorized signature'), findsOneWidget);
      // Owner name and Business name share a row; the address has one of its own.
      final name = tester.getTopLeft(find.text('Owner / Permittee name'));
      final business = tester.getTopLeft(find.text('Business name'));
      final address = tester.getTopLeft(find.text('Address'));
      expect(business.dy, name.dy);
      expect(address.dy, greaterThan(name.dy));
    });
  });

  group('the receipt and the Order of Payment (design review I2)', () {
    test('the footer: GCash says so; one paid in person names the Treasurer\'s stamped original', () {
      expect(
        PaymentDocumentText.receiptFooter(verified: true, method: 'GCash', reference: 'GC-TEST-AB12', orNumber: 'OR-1'),
        'This is an electronic copy of an Official Receipt recorded by the Municipality of Castilla, Sorsogon. '
        'Paid online through GCash, ref GC-TEST-AB12; Official Receipt No. OR-1 recorded by the Cashier.',
      );
      expect(
        PaymentDocumentText.receiptFooter(verified: true, method: 'Onsite', reference: 'OR 1', orNumber: 'OR-1'),
        endsWith("The stamped paper receipt from the Municipal Treasurer's Office is the original."),
      );
      expect(
        PaymentDocumentText.receiptFooter(verified: false, method: 'Onsite', reference: 'ONSITE-1'),
        startsWith('This is a system-generated preview'),
      );
    });

    test('the receipt\'s reference: the OR number, else the Order of Payment\'s, else the application\'s', () {
      expect(PaymentDocumentText.receiptReference(orNumber: 'OR-1', orderNumber: 'OP-1', applicationNumber: 'E-1'), 'OR-1');
      expect(PaymentDocumentText.receiptReference(orderNumber: 'OP-1', applicationNumber: 'E-1'), 'OP-1');
      expect(PaymentDocumentText.receiptReference(applicationNumber: 'E-1'), 'E-1');
    });

    test('the Order of Payment says where to pay as the pay screen does', () {
      expect(
        PaymentDocumentText.orderPayNote('2026.1'),
        "Fee schedule 2026.1. Pay the full amount at the Municipal Treasurer's Office (Cashier), Castilla Town Hall, "
        'and keep the Official Receipt it gives you.',
      );
      expect(PaymentDocumentText.orderPayNote(null), startsWith("Pay the full amount at the Municipal Treasurer's Office"));
      expect(PaymentDocumentText.orderFooter, endsWith("Present it at the Municipal Treasurer's Office when you pay."));
      final order = OrderOfPayment.fromJson(const {
        'number': 'OP-1',
        'assessedAt': '2026-11-04',
        'totalCentavos': 100,
        'feeScheduleVersion': ' 2026.1 ',
      });
      expect(order.feeScheduleVersion, '2026.1');
    });
  });

  group('dates and the timeline, in the portal\'s words (design review I11, I22)', () {
    test('"Nov 4, 2026" and "Nov 4, 2026 · 4:00 PM"', () {
      expect(formatDate('2026-11-04'), 'Nov 4, 2026');
      expect(formatMoment(DateTime(2026, 11, 4, 16)), 'Nov 4, 2026 · 4:00 PM');
      expect(formatDate('not a date'), 'not a date');
    });

    test('an entry reads as its pill; a second line only where it names the step', () {
      expect(timelineStatusLabel('Under Evaluation'), 'Under Review');
      expect(timelineStatusLabel('Received'), 'Submitted');
      expect(timelineStatusLabel('Assessed'), 'Awaiting Payment');
      expect(timelineStatusLabel('For Approval'), 'Payment Verified');
      expect(timelineStatusLabel('Released'), 'Released');
      expect(timelineStatusLabel('Something New'), 'Something New');
      expect(timelineStepName('Document Verification'), 'Document check');
      expect(timelineStepName('For Approval'), 'For approval');
      expect(timelineStepName('Under Evaluation'), isNull);
      expect(timelineStepName('Assessed'), isNull);
    });

    test('back-to-back steps under one word show once, the newest; remarks always stay', () {
      TimelineEntry entry(String status, {String? remarks}) =>
          TimelineEntry(status: status, occurredAt: '2026-11-04T01:00:00Z', remarks: remarks);
      final shown = timelineForDisplay([
        entry('Submitted'),
        entry('Received'),
        entry('Document Verification'),
        entry('Under Evaluation', remarks: 'Site photo is blurred.'),
        entry('Under Evaluation'),
        entry('Assessed'),
      ]);
      expect(shown.map((e) => e.status), ['Assessed', 'Under Evaluation', 'Under Evaluation', 'Received']);
    });
  });
}
