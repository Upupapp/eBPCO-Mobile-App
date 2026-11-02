import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/core/api/problem.dart';
import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/domain/permit_delivery.dart';
import 'package:ebpco_mobile/screens/applications/my_applications_screen.dart';
import 'package:ebpco_mobile/screens/applications/permit_delivery_card.dart';
import 'package:ebpco_mobile/theme/app_colors.dart';
import 'package:ebpco_mobile/theme/app_status.dart';
import 'package:ebpco_mobile/widgets/delivery_choice_form.dart';

/// Permit delivery (ebpco-api 070): pick up at the office, or delivered by
/// courier — the same rules and words as the citizen portal.

const _address = DeliveryAddressForm(
  recipientName: 'Juan Dela Cruz',
  recipientMobile: '0917 123 4567',
  addressLine: 'Purok 3, Rizal St.',
  barangay: 'Poblacion',
  city: 'Castilla',
  province: 'Sorsogon',
  postalCode: '4713',
);

Map<String, dynamic> _deliveryJson(String status, [Map<String, dynamic> more = const {}]) => {
      'status': status,
      'recipientName': 'Juan Dela Cruz',
      'recipientMobile': '09171234567',
      'addressLine': 'Purok 3, Rizal St.',
      'barangay': 'Poblacion',
      'city': 'Castilla',
      'province': 'Sorsogon',
      'postalCode': '4713',
      'landmark': 'Green gate',
      'requestedAt': '2026-11-03T01:00:00Z',
      ...more,
    };

PermitDeliveryState _state({
  String receiveBy = receiveByDelivery,
  Map<String, dynamic>? delivery,
  bool canChange = false,
  bool canConfirmReceipt = false,
  String? lifecycleStatus,
}) =>
    PermitDeliveryState.fromJson({
      'receiveBy': receiveBy,
      'delivery': delivery,
      'canChange': canChange,
      'canConfirmReceipt': canConfirmReceipt,
      'feeNote': deliveryFeeNote,
      'lifecycleStatus': ?lifecycleStatus,
    });

final _pickup = _state(receiveBy: receiveByPickup, canChange: true);

final _profile = CitizenProfile.fromJson({
  'firstName': 'Juan',
  'lastName': 'Dela Cruz',
  'mobileNumber': '09171234567',
  'street': 'Purok 3, Rizal St.',
  'barangay': 'Poblacion',
  'city': 'Castilla',
  'province': 'Sorsogon',
  'postalCode': '4713',
});

ApplicationSummary _app(String lifecycleStatus, String applicantStatus) => ApplicationSummary.fromJson({
      'id': 'a1',
      'referenceNumber': 'E-BPCO-2026-000001',
      'permitType': 'Building Permit',
      'applicationAction': 'New',
      'lifecycleStatus': lifecycleStatus,
      'applicantStatus': applicantStatus,
    });

/// The card on a page that keeps whatever state the card hands back.
class _Host extends StatefulWidget {
  final PermitDeliveryState initial;
  final SaveDeliveryChoice save;
  final ConfirmPermitReceived confirm;
  final PermitRelease? release;
  final void Function(PermitDeliveryState)? onReceived;
  const _Host({required this.initial, required this.save, required this.confirm, this.release, this.onReceived});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late PermitDeliveryState _state = widget.initial;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PermitDeliveryCard(
              state: _state,
              permitNumber: 'BP-2026-0001',
              release: widget.release,
              profile: _profile,
              save: widget.save,
              confirmReceived: widget.confirm,
              onChanged: (next) => setState(() => _state = next),
              onReceived: (next) {
                setState(() => _state = next);
                widget.onReceived?.call(next);
              },
            ),
          ),
        ),
      );
}

Future<PermitDeliveryState> _neverSave(Map<String, dynamic> body) => throw StateError('nothing should be saved');
Future<PermitDeliveryState> _neverConfirm() => throw StateError('nothing should be confirmed');

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

String _field(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

void main() {
  group('the address, by the server\'s own rules', () {
    test('a usable address has no problem; spaces and dashes in the mobile are fine', () {
      expect(deliveryAddressProblem(_address), isNull);
      expect(deliveryAddressProblem(const DeliveryAddressForm(
        recipientName: 'Jo', recipientMobile: '+639171234567', addressLine: 'Rizal', barangay: 'B', city: 'C', province: 'P',
      )), isNull);
    });

    test('each refusal, in the server\'s words', () {
      DeliveryAddressForm but({String? name, String? mobile, String? line, String? barangay, String? zip}) => DeliveryAddressForm(
            recipientName: name ?? _address.recipientName,
            recipientMobile: mobile ?? _address.recipientMobile,
            addressLine: line ?? _address.addressLine,
            barangay: barangay ?? _address.barangay,
            city: _address.city,
            province: _address.province,
            postalCode: zip ?? _address.postalCode,
          );
      expect(deliveryAddressProblem(but(name: ' J ')), 'Give the name of whoever will receive the permit.');
      expect(deliveryAddressProblem(but(mobile: '12345')), 'Give a mobile number the courier can call (09XXXXXXXXX).');
      expect(deliveryAddressProblem(but(line: 'ab')), 'Give the house number and street, or the purok.');
      expect(deliveryAddressProblem(but(barangay: '  ')), 'Give the barangay, city or municipality, and province.');
      expect(deliveryAddressProblem(but(zip: '471')), 'A Philippine ZIP code is four digits.');
      expect(deliveryAddressProblem(but(zip: '')), isNull);
    });

    test('prefilled from the profile: name, account mobile, street, barangay, city, province, ZIP', () {
      final a = addressFromProfile(_profile);
      expect(a.recipientName, 'Juan Dela Cruz');
      expect(a.recipientMobile, '09171234567');
      expect(a.addressLine, 'Purok 3, Rizal St.');
      expect([a.barangay, a.city, a.province, a.postalCode, a.landmark], ['Poblacion', 'Castilla', 'Sorsogon', '4713', '']);
      expect(addressFromProfile(null).isBlank, isTrue);
    });
  });

  group('what is sent', () {
    test('a pick-up is only the choice', () {
      expect(deliveryChoiceBody(receiveByPickup, _address), {'receiveBy': 'pickup'});
    });

    test('a delivery sends the address trimmed, the mobile bare, blank optional fields as null', () {
      expect(deliveryChoiceBody(receiveByDelivery, _address), {
        'receiveBy': 'delivery',
        'address': {
          'recipientName': 'Juan Dela Cruz',
          'recipientMobile': '09171234567',
          'addressLine': 'Purok 3, Rizal St.',
          'barangay': 'Poblacion',
          'city': 'Castilla',
          'province': 'Sorsogon',
          'postalCode': '4713',
          'landmark': null,
        },
      });
    });

    test('the form controller holds the choice, checks it, and reads a saved one back', () {
      final controller = DeliveryChoiceController(address: _address);
      addTearDown(controller.dispose);
      expect(controller.receiveBy, receiveByPickup);
      expect(controller.problem, isNull, reason: 'a pick-up has no address to check');
      expect(controller.requestBody, {'receiveBy': 'pickup'});

      controller.receiveBy = receiveByDelivery;
      controller.recipientMobile.text = '0917';
      expect(controller.problem, 'Give a mobile number the courier can call (09XXXXXXXXX).');

      controller.load(receiveByDelivery, addressFromDelivery(DeliveryView.fromJson(_deliveryJson('requested'))));
      expect(controller.problem, isNull);
      expect(controller.landmark.text, 'Green gate');
      expect((controller.requestBody['address'] as Map)['landmark'], 'Green gate');
    });
  });

  group('what the server answers', () {
    test('a pick-up has no delivery; an unknown answer reads as a pick-up', () {
      expect(_pickup.deliveryChosen, isNull);
      expect(PermitDeliveryState.fromJson({'receiveBy': 'drone'}).receiveBy, receiveByPickup);
      expect(PermitDeliveryState.fromJson(const {}).feeNote, deliveryFeeNote);
    });

    test('days read as calendar days', () {
      expect(formatDeliveryDay('2026-11-03'), 'Nov 3, 2026');
      expect(formatDeliveryDay(null), '—');
      expect(formatDeliveryDay('soon'), 'soon');
    });

    test('the address on one line', () {
      expect(deliveryAddressLine(DeliveryView.fromJson(_deliveryJson('requested'))),
          'Purok 3, Rizal St., Brgy. Poblacion, Castilla, Sorsogon, 4713');
    });

    test('each delivery status in the contract\'s words, and an unknown one never blank', () {
      String title(String status, [Map<String, dynamic> more = const {}]) =>
          deliveryStatusText(DeliveryView.fromJson(_deliveryJson(status, more))).title;
      expect(title('requested'), 'Delivery requested');
      expect(title('out-for-delivery'), 'On its way');
      expect(title('delivered'), 'The courier delivered it');
      expect(title('received', {'receivedAt': '2026-11-05T04:00:00Z'}), 'Received on Nov 5, 2026');
      expect(title('closed'), 'Delivered');
      expect(title('returned'), 'The courier brought it back to the office');
      expect(title('lost-in-transit'), 'Delivery by courier');
    });
  });

  group('the status Out for Delivery', () {
    test('its badge, its colour and its next step', () {
      final app = _app('Out for Delivery', 'Ready for Release');
      expect(app.statusLabel, 'Out for Delivery');
      expect(statusStyleForLabel('Out for Delivery').background, AppColors.info100);
      expect(LifecycleStatus.outForDelivery.nextStep, 'Your permit is on its way by courier. Confirm here when you receive it.');
      expect(app.isClosed, isFalse);
    });

    test('listed with the permits ready for release', () {
      expect(inApplicationFilter(_app('Out for Delivery', 'Ready for Release'), 'Ready for Release'), isTrue);
      expect(inApplicationFilter(_app('Out for Delivery', 'Ready for Release'), 'Released'), isFalse);
    });

    test('a status the app does not know yet breaks nothing', () {
      expect(LifecycleStatusX.tryFromLabel('Held at Customs'), isNull);
      final app = _app('Held at Customs', 'Under Review');
      expect(app.statusLabel, 'Under Review');
      expect(app.isClosed, isFalse);
      expect(unknownStatusNextStep, isNotEmpty);
    });
  });

  group('Receiving your permit', () {
    testWidgets('a pick-up, changed to a delivery prefilled from the profile', (tester) async {
      final sent = <Map<String, dynamic>>[];
      await tester.pumpWidget(_Host(
        initial: _pickup,
        save: (body) async {
          sent.add(body);
          return _state(delivery: _deliveryJson('requested'), canChange: true);
        },
        confirm: _neverConfirm,
      ));

      expect(find.text('Receiving your permit'), findsOneWidget);
      expect(find.text('Pick up at the office'), findsOneWidget);
      expect(find.text('Claim it at the issuing office when it is ready.'), findsOneWidget);

      await _tapKey(tester, 'delivery-change');
      expect(find.text('How do you want to receive your permit?'), findsOneWidget);
      expect(find.byKey(const ValueKey('delivery-recipient-name')), findsNothing);

      await _tapKey(tester, 'receive-by-delivery');
      expect(find.text(deliveryFeeNote), findsOneWidget);
      expect(_field(tester, 'delivery-recipient-name'), 'Juan Dela Cruz');
      expect(_field(tester, 'delivery-recipient-mobile'), '09171234567');
      expect(_field(tester, 'delivery-city'), 'Castilla');

      await tester.enterText(find.byKey(const ValueKey('delivery-landmark')), 'Green gate');
      await _tapKey(tester, 'delivery-save');

      expect(sent, hasLength(1));
      expect(sent.single['receiveBy'], 'delivery');
      expect((sent.single['address'] as Map)['landmark'], 'Green gate');
      expect(find.text('Delivery requested'), findsOneWidget);
      expect(find.text('Saved. Your permit will be delivered by courier to Castilla.'), findsOneWidget);
      expect(find.byKey(const ValueKey('delivery-change')), findsOneWidget);
    });

    testWidgets('an address the courier cannot use is caught before anything is sent', (tester) async {
      await tester.pumpWidget(_Host(initial: _pickup, save: _neverSave, confirm: _neverConfirm));
      await _tapKey(tester, 'delivery-change');
      await _tapKey(tester, 'receive-by-delivery');
      await tester.enterText(find.byKey(const ValueKey('delivery-recipient-mobile')), '12345');
      await _tapKey(tester, 'delivery-save');

      expect(find.text('Give a mobile number the courier can call (09XXXXXXXXX).'), findsOneWidget);
    });

    testWidgets('the server refusing the address says why, under the form', (tester) async {
      await tester.pumpWidget(_Host(
        initial: _pickup,
        save: (_) async => throw const ApiError(422, Problem(detail: 'A Philippine ZIP code is four digits.'), false),
        confirm: _neverConfirm,
      ));
      await _tapKey(tester, 'delivery-change');
      await _tapKey(tester, 'receive-by-delivery');
      await _tapKey(tester, 'delivery-save');

      expect(find.byKey(const ValueKey('delivery-address-problem')), findsOneWidget);
      expect(find.byKey(const ValueKey('delivery-save')), findsOneWidget, reason: 'the form stays open');
    });

    testWidgets('on its way: courier, tracking number with Copy, date sent, and "I received my permit"', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      var confirmed = 0;
      PermitDeliveryState? received;
      await tester.pumpWidget(_Host(
        initial: _state(
          delivery: _deliveryJson('out-for-delivery', {'courier': 'LBC Express', 'trackingNumber': 'LBC123456789', 'sentOn': '2026-11-03'}),
          canConfirmReceipt: true,
        ),
        save: _neverSave,
        confirm: () async {
          confirmed++;
          return _state(
            delivery: _deliveryJson('received', {'receivedAt': '2026-11-05T04:00:00Z', 'courier': 'LBC Express'}),
            lifecycleStatus: 'Completed',
          );
        },
        onReceived: (state) => received = state,
      ));

      expect(find.text('On its way'), findsOneWidget);
      expect(find.text('LBC Express'), findsOneWidget);
      expect(find.text('LBC123456789'), findsOneWidget);
      expect(find.text('Nov 3, 2026'), findsOneWidget);
      expect(find.byKey(const ValueKey('delivery-change')), findsNothing, reason: 'it has left the office');

      await _tapKey(tester, 'delivery-copy-tracking');
      expect(copied, 'LBC123456789');
      expect(find.text('Copied'), findsOneWidget);

      // "Not yet" changes nothing.
      await _tapKey(tester, 'delivery-received');
      expect(find.text('Confirm that you received permit BP-2026-0001?'), findsOneWidget);
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(confirmed, 0);

      await _tapKey(tester, 'delivery-received');
      await tester.tap(find.text('Yes, I received it'));
      await tester.pumpAndSettle();
      expect(confirmed, 1);
      expect(received?.lifecycleStatus, 'Completed');
      expect(find.text('Received on Nov 5, 2026'), findsOneWidget);
      // Shown once "Tracking number copied." has had its time on screen.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Thank you. Your application is complete.'), findsOneWidget);
      expect(find.byKey(const ValueKey('delivery-received')), findsNothing);
    });

    testWidgets('returned: the reason, where and when to claim it, and Ask for delivery again', (tester) async {
      await tester.pumpWidget(_Host(
        initial: _state(
          delivery: _deliveryJson('returned', {'returnReason': 'Nobody was home after three tries.'}),
          canChange: true,
        ),
        release: PermitRelease.fromJson({
          'status': 'Ready for Release',
          'method': null,
          'releasedAt': null,
          'claimLocation': 'Office of the Municipal Engineer, Castilla Town Hall',
          'officeHours': 'Monday to Friday, 8:00 AM to 5:00 PM',
        }),
        save: _neverSave,
        confirm: _neverConfirm,
      ));

      expect(find.text('The courier brought it back to the office'), findsOneWidget);
      expect(find.text('Nobody was home after three tries.'), findsOneWidget);
      expect(find.text('Office of the Municipal Engineer, Castilla Town Hall'), findsOneWidget);
      expect(find.text('Monday to Friday, 8:00 AM to 5:00 PM'), findsOneWidget);
      expect(find.text(deliveryFeeNote), findsOneWidget);

      await _tapKey(tester, 'delivery-ask-again');
      expect(_field(tester, 'delivery-landmark'), 'Green gate', reason: 'opens on the address already given');
    });

    testWidgets('a delivery status the app does not know yet still shows the delivery', (tester) async {
      await tester.pumpWidget(_Host(
        initial: _state(delivery: _deliveryJson('lost-in-transit')),
        save: _neverSave,
        confirm: _neverConfirm,
      ));

      expect(find.text('Delivery by courier'), findsNWidgets(2));
      expect(find.text('The office will update this when it has news of your permit.'), findsOneWidget);
    });
  });
}
