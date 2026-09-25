// Coverage for the Transactions screen — it must be a read-only view
// derived from each ServiceRequest's own Receipt, never a separate
// hardcoded list, sorted newest-first, and it must reuse the same
// ReceiptScreen/receipt data as the request detail screen's "View Receipt".
// Free-type receipts (a Free Dokyu service's own formality/claim-stub — see
// RequestsService.submit) are excluded: this screen is specifically "paid
// transactions."
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/models/receipt.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/receipt_screen.dart';
import 'package:teresa_rizal/screens/shared/request_detail_screen.dart';
import 'package:teresa_rizal/screens/shared/transactions_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/widgets/app_button.dart';

/// AutomatedTestWidgetsFlutterBinding fakes the clock — a real
/// `Future.delayed` never fires unless something calls `tester.pump()` to
/// advance it, so the wait loop must pump rather than delay for real.
Future<RequestsService> _loaded(WidgetTester tester, {bool seedDemoData = true}) async {
  SharedPreferences.setMockInitialValues({});
  final requests = RequestsService(seedDemoData: seedDemoData);
  var attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return requests;
}

Future<CitizenSessionService> _signedInAs(WidgetTester tester, CitizenAccount account) async {
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(account);
  return session;
}

/// Pumps TransactionsScreen wired to both providers it now depends on —
/// RequestsService and (since the screen scopes its list to the signed-in
/// account's own applicantId) CitizenSessionService. Defaults to the
/// verified Perlita Quiambao demo account, since that's who the seeded
/// paid-transaction demo data (and _payThrough's manual payments) belong
/// to in every test below.
Future<void> _pumpTransactions(WidgetTester tester, RequestsService requests, {CitizenAccount? account}) async {
  final session = await _signedInAs(tester, account ?? MockCatalog.demoAccounts.last);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
      ],
      child: const MaterialApp(home: TransactionsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Submits a brand-new paid Barangay Clearance request via [method] — the
/// only way to create a receipt with a specific payment method now that
/// payment happens synchronously inside RequestsService.submit (see the
/// Mobile-only final request-flow correction pass). There is no longer a
/// way to "pay" an already-existing request after the fact, so this always
/// creates its own new request rather than advancing a seeded one.
Future<ServiceRequest> _payThrough(RequestsService requests, String method) {
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

void main() {
  testWidgets('No paid transactions yet shows the proper empty state, not a fake seeded list', (tester) async {
    // seedDemoData: false — even Perlita's own seeded paid-transaction demo
    // data must not leak into this assertion; this proves the *genuine*
    // empty state, not merely "an account with no seed happens to be empty".
    final requests = await _loaded(tester, seedDemoData: false);
    await _pumpTransactions(tester, requests);

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Your demo Dokyu or Tulong payments will appear here.'), findsOneWidget);
  });

  group('Seeded demo transactions (verified Perlita Quiambao)', () {
    testWidgets('every seeded paid Dokyu request appears, free ones excluded, with real service/fee/method data', (
      tester,
    ) async {
      final requests = await _loaded(tester);
      await _pumpTransactions(tester, requests);

      // Every Dokyu demo-status seed now gets a receipt at seed time (see
      // RequestsService._seedDemoStatusSimulationsIfNeeded) — the two paid
      // ones (Barangay Clearance, Business Permit) show up here; the free
      // one (Certificate of Indigency) does not.
      expect(find.text('Barangay Clearance'), findsOneWidget);
      expect(find.text('Business Permit (New Application)'), findsOneWidget);
      expect(find.text('Certificate of Residency'), findsOneWidget);
      expect(find.text('Real Property Tax Clearance'), findsOneWidget);
      expect(find.text('Certificate of Indigency'), findsNothing);
      expect(find.textContaining('₱50.00'), findsWidgets); // Barangay Clearance's and Residency's real fees
      expect(find.textContaining('₱100.00'), findsWidgets); // RPT Clearance's real fee
      expect(find.textContaining('GCash'), findsWidgets);
      expect(find.textContaining('Maya'), findsWidgets);
      expect(find.text('Paid in demo'), findsNWidgets(4));
    });

    testWidgets('does not duplicate on a second load (simulates a restart)', (tester) async {
      final requests = await _loaded(tester);
      final receiptCount = requests.all.where((r) => r.receipt != null).length;
      // 3 seeded Dokyu demo-status requests (2 paid + 1 free) + 2 paid-
      // transaction seeds — every Dokyu request gets a receipt at seed
      // time now, paid or free (see RequestsService.submit's own doc
      // comment on why); Tulong requests never do.
      expect(receiptCount, 5);

      // Persist, then restore into a fresh RequestsService instance from
      // the same SharedPreferences-backed storage — exactly what an app
      // restart does.
      final reloaded = RequestsService(seedDemoData: true);
      var attempts = 0;
      while (!reloaded.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('RequestsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      expect(reloaded.all.where((r) => r.receipt != null).length, 5);
    });

    testWidgets("the duplicate Perlita registration does not inherit the verified account's transactions", (
      tester,
    ) async {
      final requests = await _loaded(tester);
      await _pumpTransactions(tester, requests, account: MockCatalog.duplicateVerifiedDemoAccount);

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.text('Certificate of Residency'), findsNothing);
    });

    testWidgets('View Receipt on each seeded transaction opens the unified Teresa, Rizal receipt with correct data', (
      tester,
    ) async {
      final requests = await _loaded(tester);
      final gcash = requests.all.firstWhere((r) => r.id == 'demo-paid-dokyu-residency-gcash');
      await _pumpTransactions(tester, requests);

      await tester.tap(find.text('Certificate of Residency'));
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptScreen), findsOneWidget);
      expect(tester.widget<ReceiptScreen>(find.byType(ReceiptScreen)).receipt, same(gcash.receipt));
      expect(find.text('Perlita Quiambao'), findsWidgets);
      expect(find.text('Mode of Payment'), findsOneWidget);
      expect(find.text('GCash'), findsOneWidget);
      expect(find.text(gcash.fee), findsOneWidget);
    });
  });

  testWidgets('A paid request appears as a transaction card with its own receipt data, and View Receipt opens '
      'the same receipt shown from the request detail screen', (tester) async {
    final requests = await _loaded(tester);
    // TransactionsScreen's ListView.builder only builds cards within the
    // current viewport plus cache extent — the default 800x600 test canvas
    // is too short to fit all 5 cards (4 seeded + the one this test adds)
    // at once, same reasoning as dokyu_requirement_uploads_test.dart's own
    // taller-viewport fix. A tall portrait viewport keeps every card
    // reachable without needing to scroll before every assertion.
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final newRequest = await _payThrough(requests, 'GCash');
    final receipt = requests.all.firstWhere((r) => r.id == newRequest.id).receipt!;

    await _pumpTransactions(tester, requests);

    expect(find.text('Barangay Clearance'), findsNWidgets(2)); // the seeded one + this new one
    expect(find.text(receipt.requestReferenceNumber), findsOneWidget);
    expect(find.textContaining(receipt.amount), findsWidgets);
    expect(find.textContaining('GCash'), findsWidgets);
    expect(find.text('Paid in demo'), findsNWidgets(5)); // 4 seeded + this one

    // Newest-first sort puts the just-paid one first — its own card's
    // "View Receipt" is the first in the list.
    await tester.tap(find.text('View payment record').first);
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptScreen), findsOneWidget);
    expect(find.text(receipt.referenceNumber), findsOneWidget);
    expect(find.text(receipt.amount), findsWidgets);
  });

  testWidgets('Most recent transaction is listed first', (tester) async {
    final requests = await _loaded(tester);
    final newRequest = await _payThrough(requests, 'Onsite'); // paid "now" — must sort above every seeded one
    final firstReceipt = requests.all.firstWhere((r) => r.id == newRequest.id).receipt!;

    // The seeded transactions are all dated in the past (see
    // RequestsService's own seeding functions) — this one was just paid
    // "now", so it must sort above all of them. The ListView builds its
    // children in list order, so the first Text built in the whole tree
    // (build order, not screen position) is this transaction's own service
    // name.
    await _pumpTransactions(tester, requests);

    expect(find.text(firstReceipt.requestReferenceNumber), findsOneWidget);
    final firstCardText = tester
        .widgetList<Text>(find.descendant(of: find.byType(ListView), matching: find.byType(Text)))
        .first
        .data;
    expect(firstCardText, 'Barangay Clearance');
  });

  testWidgets('Free Dokyu/Tulong requests never produce a transaction entry', (tester) async {
    final requests = await _loaded(tester);
    // demo-tulong-medical, demo-tulong-financial (Tulong — never has a
    // receipt at all) and demo-dokyu-certificate-indigency (a Free Dokyu
    // service — gets a receipt, but never a *transaction*) must never show
    // up here even though other paid requests exist.
    await _payThrough(requests, 'Maya');

    await _pumpTransactions(tester, requests);

    expect(find.text('Medical Assistance (AICS)'), findsNothing);
    expect(find.text('Financial Assistance (AICS)'), findsNothing);
    expect(find.text('Certificate of Indigency'), findsNothing);
    expect(find.text('Barangay Clearance'), findsNWidgets(2)); // seeded one + this new paid one
  });

  testWidgets('Onsite transaction shows "Onsite / Municipal Office" as its payment method', (tester) async {
    final requests = await _loaded(tester);
    final newRequest = await _payThrough(requests, 'Onsite');
    final receipt = requests.all.firstWhere((r) => r.id == newRequest.id).receipt!;
    expect(receipt.type, ReceiptType.onsite);

    await _pumpTransactions(tester, requests);

    expect(find.textContaining('Onsite / Municipal Office'), findsOneWidget);
  });

  testWidgets(
    "Request detail screen's View Receipt reaches the exact same Receipt object Transactions would show for it",
    (tester) async {
      final requests = await _loaded(tester);
      final newRequest = await _payThrough(requests, 'GCash');
      final receipt = requests.all.firstWhere((r) => r.id == newRequest.id).receipt!;

      await tester.pumpWidget(
        ChangeNotifierProvider<RequestsService>.value(
          value: requests,
          child: MaterialApp(home: RequestDetailScreen(requestId: newRequest.id)),
        ),
      );
      await tester.pumpAndSettle();
      final scrollable = find.byType(Scrollable).first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'View payment record'));
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptScreen), findsOneWidget);
      expect(tester.widget<ReceiptScreen>(find.byType(ReceiptScreen)).receipt, same(receipt));
      expect(find.text(receipt.referenceNumber), findsOneWidget);
      expect(find.text(receipt.amount), findsOneWidget);
    },
  );
}
