import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ebpco_mobile/core/api/problem.dart';
import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/domain/payment_history.dart';
import 'package:ebpco_mobile/domain/payment_methods.dart';
import 'package:ebpco_mobile/screens/payments/payment_flow_screen.dart';
import 'package:ebpco_mobile/services/applications_service.dart';

/// How a citizen pays (ebpco-api 071): the methods the LGU accepts right now
/// (`GET /payment-methods`), and GCash, which opens its checkout in the
/// browser and is checked again when the citizen comes back to the app. The
/// same rules and words as the citizen portal's `payment-flow.page.ts`.
const _gcash = PaymentMethodOption(
  method: 'GCash',
  label: 'GCash',
  instructions: 'Pay online with GCash. You are sent to the GCash checkout.',
  mode: 'test',
);
const _bank = PaymentMethodOption(method: 'Bank Transfer', label: 'Bank Transfer');
const _onsite = PaymentMethodOption(method: 'Onsite', label: 'Onsite');

/// The server's list, as `GET /payment-methods` orders it.
const _listed = [_bank, _gcash, _onsite];

ApplicationSummary _app({String lifecycleStatus = 'Assessed', String paymentStatus = 'Not Yet Available'}) =>
    ApplicationSummary.fromJson({
      'id': 'app-1',
      'referenceNumber': 'E-BPCO-2026-000123',
      'permitType': 'Building Permit',
      'applicationAction': 'New',
      'lifecycleStatus': lifecycleStatus,
      'applicantStatus': 'Payment Verification',
      'form': const {'applyingAs': 'residential'},
      'payment': {
        'status': paymentStatus,
        'orderOfPayment': {'number': 'OP-2026-0001', 'assessedAt': '2026-11-04T01:00:00Z', 'totalCentavos': 682050},
      },
    });

/// The whole payment screen at once: a list builds only what is on screen.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

GcashCheckout _checkout() => GcashCheckout.fromJson({
      'checkoutId': 'chk-1',
      'reference': 'GC-TEST-AB12CD34EF',
      'amount': 6820.5,
      'amountCentavos': 682050,
      'expiresAt': '2026-11-04T02:30:00Z',
      'mode': 'test',
      'checkoutUrl': 'https://citizen.castilla-ebpco.online/pay/gcash/chk-1?t=token',
    });

void main() {
  group('the methods offered', () {
    test('what the server lists, without Bank Transfer while no deposit account is published', () {
      final offered = offeredPaymentMethods(_listed, bankPublished: false);
      expect(offered.map((m) => m.method), ['GCash', 'Onsite']);
      expect(defaultPaymentMethod(offered), 'Onsite');
    });

    test('Bank Transfer first once an account is published, as before', () {
      final offered = offeredPaymentMethods(_listed, bankPublished: true);
      expect(offered.map((m) => m.method), ['Bank Transfer', 'GCash', 'Onsite']);
      expect(defaultPaymentMethod(offered), 'Bank Transfer');
    });

    test('a list that cannot be read, is empty, or names only unknown methods is Onsite', () {
      for (final listed in [const <PaymentMethodOption>[], const [PaymentMethodOption(method: 'Maya', label: 'Maya')]]) {
        final offered = offeredPaymentMethods(listed, bankPublished: false);
        expect(offered.map((m) => m.method), ['Onsite']);
      }
      expect(localPaymentMethods(bankPublished: false).map((m) => m.method), ['Onsite']);
    });

    test('GCash alone when the LGU closed Onsite', () {
      final offered = offeredPaymentMethods(const [_gcash], bankPublished: false);
      expect(defaultPaymentMethod(offered), 'GCash');
    });

    test('the cards\' words', () {
      expect(paymentMethodTitle(_gcash), 'GCash');
      expect(paymentMethodBlurb(_gcash), 'Pay online. Test mode: no real money is charged.');
      expect(paymentMethodBlurb(const PaymentMethodOption(method: 'GCash', label: 'GCash')), 'Pay online with GCash.');
      expect(paymentMethodTitle(_onsite), 'Onsite Payment');
      expect(paymentMethodBlurb(_onsite), 'Pay at the Municipal Hall, then mark it paid here.');
    });

    test('read from the server\'s bare array', () {
      final m = PaymentMethodOption.fromJson(const {'method': 'GCash', 'label': 'GCash', 'instructions': 'x', 'mode': 'test'});
      expect(m.method, 'GCash');
      expect(m.isTestMode, isTrue);
      expect(PaymentMethodOption.fromJson(const {'method': 'Onsite', 'label': 'Onsite', 'instructions': ''}).mode, isNull);
    });

    test('a checkout: the exact amount in centavos, its GC-TEST reference and the page to pay on', () {
      final checkout = _checkout();
      expect(checkout.amountCentavos, 682050);
      expect(checkout.reference, startsWith('GC-TEST-'));
      expect(checkout.checkoutUrl, contains('/pay/gcash/chk-1?t='));
    });

    test('back from the checkout: Payment Submitted means it reached the Cashier', () {
      expect(gcashPaymentSent(_app()), isFalse);
      expect(gcashPaymentSent(_app(lifecycleStatus: 'Payment Submitted', paymentStatus: 'Pending Verification')), isTrue);
    });

    test('the payment history names GCash like any other method', () {
      expect(paymentMethodText('GCash'), 'GCash');
      expect(paymentMethodText('Bank Transfer'), 'Bank Transfer');
      expect(paymentMethodText('Onsite'), 'Paid at the Treasurer’s Office');
    });
  });

  group('the payment screen', () {
    late ApplicationSummary current;
    late List<String> calls;
    late List<Uri> opened;

    setUp(() {
      current = _app();
      calls = [];
      opened = [];
    });

    Widget host({Future<List<PaymentMethodOption>> Function()? methods, Future<GcashCheckout> Function(String id)? start}) =>
        ChangeNotifierProvider(
          create: (_) => ApplicationsService(),
          child: MaterialApp(
            home: PaymentFlowScreen(
              applicationId: 'app-1',
              loadApplication: (id) async {
                calls.add('GET /applications/$id');
                return current;
              },
              loadPaymentMethods: methods ?? () async => _listed,
              startGcash: start ??
                  (id) async {
                    calls.add('POST /applications/$id/payments/gcash');
                    return _checkout();
                  },
              openCheckout: (url) async {
                opened.add(url);
                return true;
              },
            ),
          ),
        );

    testWidgets('lists GCash and Onsite, with no Bank Transfer while no account is published', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.text('GCash'), findsOneWidget);
      expect(find.text('Pay online. Test mode: no real money is charged.'), findsOneWidget);
      expect(find.text('Onsite Payment'), findsOneWidget);
      expect(find.text('Bank Transfer'), findsNothing);
      // Onsite stays the first choice, as before.
      expect(find.text('Mark as Paid'), findsOneWidget);
      expect(find.text('Pay with GCash'), findsNothing);
    });

    testWidgets('methods that cannot be read leave Onsite, as before', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(host(methods: () async => throw const ApiError(500, null, true)));
      await tester.pumpAndSettle();

      expect(find.text('GCash'), findsNothing);
      expect(find.textContaining('Pay onsite at the Municipal Hall'), findsOneWidget);
      expect(find.text('Mark as Paid'), findsOneWidget);
    });

    testWidgets('Pay with GCash opens the checkout in the browser; back in the app it shows Payment Submitted', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.tap(find.text('GCash'));
      await tester.pumpAndSettle();
      expect(find.textContaining('You go to the checkout page to pay'), findsOneWidget);
      await tester.ensureVisible(find.text('Pay with GCash'));
      await tester.tap(find.text('Pay with GCash'));
      await tester.pumpAndSettle();

      expect(calls, contains('POST /applications/app-1/payments/gcash'));
      expect(opened.single.toString(), 'https://citizen.castilla-ebpco.online/pay/gcash/chk-1?t=token');
      expect(find.text('Finish paying on the checkout page'), findsOneWidget);

      // Paid on the checkout page, then back to the app.
      current = _app(lifecycleStatus: 'Payment Submitted', paymentStatus: 'Pending Verification');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Payment sent'), findsOneWidget);
      expect(find.text('Status: Payment Submitted'), findsOneWidget);
      expect(find.text('Paid through GCash · ref. GC-TEST-AB12CD34EF'), findsOneWidget);
      expect(find.text('The Cashier verifies it and issues your official receipt.'), findsOneWidget);
      expect(find.text('Back to My Application'), findsOneWidget);
    });

    testWidgets('back without paying: a hint to finish the checkout', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await tester.tap(find.text('GCash'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pay with GCash'));
      await tester.tap(find.text('Pay with GCash'));
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Payment sent'), findsNothing);
      expect(find.textContaining('No payment yet. Finish paying on the checkout page'), findsOneWidget);
      expect(find.text('Check Payment'), findsOneWidget);
    });

    testWidgets('the server\'s refusal is shown in its own words', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(host(
        start: (_) async => throw const ApiError(
          422,
          Problem(status: 422, detail: 'A payment for this application is already waiting for the Cashier to verify it.'),
          false,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GCash'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pay with GCash'));
      await tester.tap(find.text('Pay with GCash'));
      await tester.pumpAndSettle();

      expect(find.text('A payment for this application is already waiting for the Cashier to verify it.'), findsOneWidget);
      expect(opened, isEmpty);
    });
  });
}
