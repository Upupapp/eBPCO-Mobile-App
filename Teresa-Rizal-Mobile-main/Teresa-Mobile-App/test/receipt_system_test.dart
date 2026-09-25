// Functional coverage for the receipt system — a single unified
// TeresaRizalReceipt design shared by GCash/Maya/Onsite/Free (only the "Mode
// of Payment" row, badge, and amount label differ), generated synchronously
// at submission time (see RequestsService.submit) — never via a later
// tracking milestone; there is no "Waiting for Payment" or "Choose Payment
// Method (Demo)" step in the tracker anymore. FRONTEND SIMULATION ONLY: no
// real payment gateway, no real file I/O beyond what share_plus's own
// platform channel would do (which isn't available in this test
// environment — Download Receipt is exercised for graceful failure
// handling, not an actual saved file).
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/receipt.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/receipt_screen.dart';
import 'package:teresa_rizal/screens/shared/request_detail_screen.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/utils/receipt_export.dart';
import 'package:teresa_rizal/widgets/app_button.dart';
import 'package:teresa_rizal/widgets/receipts/teresa_rizal_receipt.dart';

Future<RequestsService> _readyRequests(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final requests = RequestsService(seedDemoData: false);
  var attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return requests;
}

Future<ServiceRequest> _submitPaidBarangayClearance(RequestsService requests, String method) {
  return requests.submit(
    applicantId: 'ESP-RES-2024-9002',
    applicantName: 'Perlita Quiambao',
    typeName: 'Barangay Clearance',
    category: ServiceCategory.dokyu,
    office: 'Barangay Hall',
    purpose: 'Proof of Residency',
    expectedDays: '1-2 working days',
    attachments: const [],
    requiresPayment: true,
    fee: '₱50.00',
    paymentMethod: method,
  );
}

Future<ServiceRequest> _submitFreeCertificate(RequestsService requests) {
  return requests.submit(
    applicantId: 'ESP-RES-2024-9002',
    applicantName: 'Perlita Quiambao',
    typeName: 'Certificate of Indigency',
    category: ServiceCategory.dokyu,
    office: 'Municipal Social Welfare and Development Office',
    purpose: 'Medical Assistance',
    expectedDays: '2-3 working days',
    attachments: const [],
  );
}

Future<void> _pumpDetail(WidgetTester tester, RequestsService requests, String requestId) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<RequestsService>.value(
      value: requests,
      child: MaterialApp(home: RequestDetailScreen(requestId: requestId)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Receipt generated at submission', () {
    testWidgets('a paid Dokyu request gets a receipt the moment it is submitted, before any tracking milestone', (
      tester,
    ) async {
      final requests = await _readyRequests(tester);
      final request = await _submitPaidBarangayClearance(requests, 'GCash');
      expect(request.receipt, isNotNull);
      expect(request.receipt!.type, ReceiptType.gcash);
      expect(request.status, 'Submitted'); // receipt exists well before Approved
    });

    testWidgets('a free Dokyu request gets a formality receipt with no invented amount', (tester) async {
      final requests = await _readyRequests(tester);
      final request = await _submitFreeCertificate(requests);
      expect(request.receipt, isNotNull);
      expect(request.receipt!.type, ReceiptType.free);
      expect(request.receipt!.amount, 'Free');
      expect(request.paymentMethod, isNull);
    });
  });

  group('View Receipt', () {
    testWidgets('Onsite payment shows the unified Teresa, Rizal receipt, relabeled Due Onsite (not a paid amount)', (
      tester,
    ) async {
      final requests = await _readyRequests(tester);
      final request = await _submitPaidBarangayClearance(requests, 'Onsite');
      final receipt = request.receipt!;
      expect(receipt.type, ReceiptType.onsite);

      await _pumpDetail(tester, requests, request.id);
      await tester.tap(find.widgetWithText(AppButton, 'View payment record'));
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptScreen), findsOneWidget);
      expect(find.byType(TeresaRizalReceipt), findsOneWidget);
      expect(find.text('Municipality of Teresa, Rizal'), findsOneWidget);
      expect(find.text('Payment record (demo)'), findsWidgets);
      expect(find.text('Official Payment Receipt'), findsNothing);
      // Onsite hasn't actually paid anything yet — the real fee is shown,
      // but relabeled "due", never presented as an already-collected amount.
      expect(find.text('DUE ONSITE'), findsOneWidget);
      expect(find.text('Amount Due'), findsOneWidget);
      expect(find.text(receipt.residentName), findsWidgets);
      expect(find.text(receipt.serviceName), findsOneWidget);
      expect(find.text(receipt.requestReferenceNumber), findsOneWidget);
      expect(find.text(receipt.amount), findsOneWidget);
      expect(find.text('Mode of Payment'), findsOneWidget);
      expect(find.text('Onsite — Municipal Office'), findsOneWidget);
      expect(receipt.referenceNumber.startsWith('DEMO-PAY-'), isTrue);
      expect(find.text('Local reference'), findsOneWidget);
      expect(find.text(receipt.referenceNumber), findsOneWidget);
      expect(find.textContaining('OR-'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GCash payment shows the exact same unified Teresa, Rizal receipt, PAID, with GCash as its Mode of Payment', (
      tester,
    ) async {
      final requests = await _readyRequests(tester);
      final request = await _submitPaidBarangayClearance(requests, 'GCash');
      final receipt = request.receipt!;
      expect(receipt.type, ReceiptType.gcash);

      await _pumpDetail(tester, requests, request.id);
      await tester.tap(find.widgetWithText(AppButton, 'View payment record'));
      await tester.pumpAndSettle();

      expect(find.byType(TeresaRizalReceipt), findsOneWidget);
      // No separate GCash-branded design — same municipal receipt shell.
      expect(find.text('Municipality of Teresa, Rizal'), findsOneWidget);
      expect(find.text('Payment record (demo)'), findsWidgets);
      expect(find.text('Official Payment Receipt'), findsNothing);
      expect(find.text('PAID IN DEMO'), findsOneWidget);
      expect(find.text('Amount (sample)'), findsOneWidget);
      expect(find.text('Mode of Payment'), findsOneWidget);
      expect(find.text('GCash'), findsOneWidget);
      expect(find.text(receipt.amount), findsOneWidget);
      expect(find.text(receipt.referenceNumber), findsOneWidget);
      // The real bundled GCash logo, not a color-chip placeholder — and no
      // overflow from its own source size (see teresa_rizal_receipt.dart).
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Maya payment shows the exact same unified Teresa, Rizal receipt, PAID, with Maya as its Mode of Payment', (
      tester,
    ) async {
      final requests = await _readyRequests(tester);
      final request = await _submitPaidBarangayClearance(requests, 'Maya');
      final receipt = request.receipt!;
      expect(receipt.type, ReceiptType.maya);

      await _pumpDetail(tester, requests, request.id);
      await tester.tap(find.widgetWithText(AppButton, 'View payment record'));
      await tester.pumpAndSettle();

      expect(find.byType(TeresaRizalReceipt), findsOneWidget);
      expect(find.text('Municipality of Teresa, Rizal'), findsOneWidget);
      expect(find.text('Payment record (demo)'), findsWidgets);
      expect(find.text('Official Payment Receipt'), findsNothing);
      expect(find.text('PAID IN DEMO'), findsOneWidget);
      expect(find.text('Mode of Payment'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text(receipt.amount), findsOneWidget);
      expect(find.text(receipt.referenceNumber), findsOneWidget);
      // The real bundled Maya logo (a wide wordmark raster), size-capped so
      // it can't overflow or dominate the row — see teresa_rizal_receipt.dart.
      final mayaLogo = tester
          .widgetList<Image>(find.byType(Image))
          .where((w) => w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/Maya_logo.svg.webp');
      expect(mayaLogo.length, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a free service shows RECEIVED, never a fabricated peso amount', (tester) async {
      final requests = await _readyRequests(tester);
      final request = await _submitFreeCertificate(requests);
      final receipt = request.receipt!;

      await _pumpDetail(tester, requests, request.id);
      await tester.tap(find.widgetWithText(AppButton, 'View payment record'));
      await tester.pumpAndSettle();

      expect(find.byType(TeresaRizalReceipt), findsOneWidget);
      expect(find.text('RECEIVED'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Free'), findsWidgets); // the amount value itself
      expect(find.text('No Payment Required'), findsOneWidget);
      expect(find.text(receipt.requestReferenceNumber), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('View Receipt stays reachable after the request advances all the way to Released', (tester) async {
      final requests = await _readyRequests(tester);
      final request = await _submitPaidBarangayClearance(requests, 'Onsite');
      await requests.advanceMilestone(request.id); // Submitted -> Under Verification
      await requests.advanceMilestone(request.id); // -> Approved
      await requests.advanceMilestone(request.id); // -> Mark to Release
      await requests.advanceMilestone(request.id); // -> Released

      final finalReceipt = requests.all.firstWhere((r) => r.id == request.id).receipt;
      expect(finalReceipt, isNotNull);

      // Still reachable and tappable even after Completed — not tied to any
      // milestone, since it was generated back at submission.
      await _pumpDetail(tester, requests, request.id);
      await tester.tap(find.widgetWithText(AppButton, 'View payment record'));
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Download Receipt', () {
    testWidgets('the button is present, enabled, and captures the receipt without a synchronous crash', (
      tester,
    ) async {
      final requests = await _readyRequests(tester);
      final request = await _submitPaidBarangayClearance(requests, 'Onsite');
      await _pumpDetail(tester, requests, request.id);
      await tester.tap(find.widgetWithText(AppButton, 'View payment record'));
      await tester.pumpAndSettle();

      final downloadButton = find.widgetWithText(AppButton, 'Save payment record');
      expect(downloadButton, findsOneWidget);
      expect(tester.widget<AppButton>(downloadButton).onPressed, isNotNull);

      // Actually completing an export depends on share_plus's own platform
      // channel (and, for a memory-only XFile, path_provider's) — neither
      // has a registered response in this widget-test environment, so
      // waiting for it to fully resolve isn't meaningful here (and
      // `pumpAndSettle` times out doing so). A handful of bounded pumps is
      // enough to prove the tap starts the export (the loading state
      // engages) without throwing synchronously; the actual
      // save/share/download behavior is verified live (Flutter Web run),
      // not by this widget test.
      await tester.tap(downloadButton);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('captureRepaintBoundary produces non-empty, well-formed PNG bytes from a rendered receipt', (
      tester,
    ) async {
      final key = GlobalKey();
      final receipt = Receipt(
        type: ReceiptType.onsite,
        amount: '₱50.00',
        referenceNumber: 'DEMO-PAY-0012',
        dateTime: DateTime(2026, 1, 1, 9, 30),
        residentName: 'Perlita Quiambao',
        serviceName: 'Barangay Clearance',
        requestReferenceNumber: 'DOC-2026-001',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(key: key, child: TeresaRizalReceipt(receipt: receipt)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // RenderRepaintBoundary.toImage() rasterizes on the engine's raster
      // thread, which the fake-clock AutomatedTestWidgetsFlutterBinding
      // never actually drives forward — awaiting it directly here hangs
      // until the test framework's own timeout. `runAsync` escapes to a
      // real event loop for just this call, which is all toImage() needs.
      final bytes = await tester.runAsync(() => captureRepaintBoundary(key));
      expect(bytes, isNotNull);
      expect(bytes, isNotEmpty);
      // PNG magic bytes — confirms this is a real, well-formed PNG, not
      // just "some bytes came back".
      expect(bytes!.take(8).toList(), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    });

    for (final type in [ReceiptType.gcash, ReceiptType.maya]) {
      testWidgets(
        'captureRepaintBoundary also captures the $type payment-mode logo (SvgPicture/webp render into the raster, not just the widget tree)',
        (tester) async {
          final key = GlobalKey();
          final receipt = Receipt(
            type: type,
            amount: '₱50.00',
            referenceNumber: 'DEMO-PAY-0012',
            dateTime: DateTime(2026, 1, 1, 9, 30),
            residentName: 'Perlita Quiambao',
            serviceName: 'Barangay Clearance',
            requestReferenceNumber: 'DOC-2026-001',
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RepaintBoundary(key: key, child: TeresaRizalReceipt(receipt: receipt)),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final bytes = await tester.runAsync(() => captureRepaintBoundary(key));
          expect(bytes, isNotNull);
          expect(bytes, isNotEmpty);
          expect(bytes!.take(8).toList(), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Independent per-request receipts', () {
    testWidgets("one request's receipt never appears on another request's screen", (tester) async {
      final requests = await _readyRequests(tester);
      final gcashRequest = await _submitPaidBarangayClearance(requests, 'GCash');
      final onsiteRequest = await _submitPaidBarangayClearance(requests, 'Onsite');

      final gcashReceipt = requests.all.firstWhere((r) => r.id == gcashRequest.id).receipt!;
      final onsiteReceipt = requests.all.firstWhere((r) => r.id == onsiteRequest.id).receipt!;

      expect(onsiteReceipt.type, ReceiptType.onsite);
      expect(gcashReceipt.type, ReceiptType.gcash);
      expect(onsiteReceipt.referenceNumber, isNot(gcashReceipt.referenceNumber));
    });
  });
}
