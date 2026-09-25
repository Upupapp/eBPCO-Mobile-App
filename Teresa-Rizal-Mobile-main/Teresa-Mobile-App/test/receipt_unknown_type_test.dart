// A receipt must never claim a payment method it could not read.
//
// `Receipt.fromJson` used to fall back to `ReceiptType.onsite` for a payment
// type this build no longer recognises. A receipt is the citizen's own proof of
// how they paid, so that fallback made three false statements: a completed
// GCash or Maya payment rendered as cash owed at the municipal office, the
// badge read "DUE ONSITE" for money already taken, and a free service appeared
// to carry a fee. Both CLAUDE.md files and the master command's own guardrail
// forbid exactly this class of fabrication.
//
// The fallback is now `ReceiptType.unknown`, which every display renders as
// "—". The receipt is still shown, because its amount, date, reference and
// service are all still true — only the method is unknown, and it says so.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/models/receipt.dart';
import 'package:teresa_rizal/utils/receipt_export.dart';
import 'package:teresa_rizal/widgets/receipts/teresa_rizal_receipt.dart';

Map<String, dynamic> _persistedReceipt(String type) => Receipt(
      type: ReceiptType.gcash,
      amount: '₱50.00',
      referenceNumber: 'GC1234567890',
      dateTime: DateTime(2026, 3, 1, 9, 30),
      residentName: 'Test Fixture',
      serviceName: 'Barangay Clearance',
      requestReferenceNumber: 'DR-2026-000001',
    ).toJson()
      ..['type'] = type;

void main() {
  group('an unreadable payment type decodes to unknown, not to cash', () {
    test('a renamed ReceiptType falls back to unknown', () {
      final receipt = Receipt.fromJson(_persistedReceipt('aPaymentTypeThisBuildDoesNotHave'));

      expect(receipt.type, ReceiptType.unknown);
      // The rest of the receipt is untouched: only the method was unreadable.
      expect(receipt.amount, '₱50.00');
      expect(receipt.referenceNumber, 'GC1234567890');
      expect(receipt.requestReferenceNumber, 'DR-2026-000001');
    });

    test('it does not fall back to onsite', () {
      final receipt = Receipt.fromJson(_persistedReceipt('gcashV2'));

      // The specific regression: `onsite` means "cash, due at the municipal
      // office", which is a statement about money this build cannot support.
      expect(receipt.type, isNot(ReceiptType.onsite));
    });

    test('a readable type is unaffected', () {
      expect(Receipt.fromJson(_persistedReceipt('maya')).type, ReceiptType.maya);
      expect(Receipt.fromJson(_persistedReceipt('free')).type, ReceiptType.free);
      expect(Receipt.fromJson(_persistedReceipt('onsite')).type, ReceiptType.onsite);
    });

    test('an exported copy names no method in its filename', () {
      final receipt = Receipt.fromJson(_persistedReceipt('aTypeThisBuildDoesNotHave'));
      final name = receiptFilename(receipt);

      // The exported PNG is the copy a citizen keeps or forwards. Its name
      // must not assert a method either.
      expect(name.toLowerCase(), isNot(contains('onsite')));
      expect(name.toLowerCase(), isNot(contains('gcash')));
      expect(name, contains('Unknown'));
    });
  });

  group('the rendered receipt claims neither payment nor debt', () {
    testWidgets('the badge says neither PAID nor DUE ONSITE', (tester) async {
      final receipt = Receipt.fromJson(_persistedReceipt('aTypeThisBuildDoesNotHave'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: TeresaRizalReceipt(receipt: receipt)),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('PAID'), findsNothing, reason: 'no payment can be claimed for an unknown method');
      expect(find.text('DUE ONSITE'), findsNothing, reason: 'no debt can be claimed either');
      expect(find.text('RECEIVED'), findsNothing);

      // The amount itself is still true and still shown.
      expect(find.textContaining('₱50.00'), findsWidgets);
    });

    testWidgets('no payment method is named anywhere on the receipt', (tester) async {
      final receipt = Receipt.fromJson(_persistedReceipt('aTypeThisBuildDoesNotHave'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: TeresaRizalReceipt(receipt: receipt)),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Onsite'), findsNothing);
      expect(find.textContaining('GCash'), findsNothing);
      expect(find.textContaining('Maya'), findsNothing);
      expect(find.textContaining('No Payment Required'), findsNothing);
    });
  });
}
