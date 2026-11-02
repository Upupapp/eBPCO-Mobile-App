import 'package:intl/intl.dart';

import 'models.dart';

/// Permit delivery (ebpco-api 070, owner request 2026-11-03) — the citizen
/// portal's `core/domain/permit-delivery.ts`, ported.
///
/// The citizen chooses how to receive the issued permit: picked up at the
/// issuing office (the default) or delivered by courier, at their expense,
/// paid to the courier on arrival. Chosen when applying, changeable on the
/// application page until the permit is handed to the courier. The officer
/// records the courier and tracking number; the citizen confirms they
/// received it, which closes the application.
///
/// Wire shapes are the server's (`GET/PUT /applications/{id}/delivery`); the
/// address rules are the server's `addressProblem`, word for word, so a
/// citizen is told before a round trip what the server would refuse.

const receiveByPickup = 'pickup';
const receiveByDelivery = 'delivery';

/// The server's own `feeNote`, shown until the server's copy has been read.
const deliveryFeeNote =
    'Delivery is at your expense: you pay the courier when the permit arrives. The Municipality collects nothing for it.';

/// The two answers, in the portal's words.
const pickupChoiceTitle = 'Pick up at the office';
const pickupChoiceDetail = 'Claim it at the issuing office when it is ready.';
const deliveryChoiceTitle = 'Delivery by courier';
const deliveryChoiceDetail = 'Sent to the address you give. You pay the courier when it arrives.';
const receiveByQuestion = 'How do you want to receive your permit?';

/// The address as a form holds it: every field a string, blanks included.
class DeliveryAddressForm {
  final String recipientName;
  final String recipientMobile;

  /// House number and street, or the purok.
  final String addressLine;
  final String barangay;
  final String city;
  final String province;
  final String postalCode;
  final String landmark;

  const DeliveryAddressForm({
    this.recipientName = '',
    this.recipientMobile = '',
    this.addressLine = '',
    this.barangay = '',
    this.city = '',
    this.province = '',
    this.postalCode = '',
    this.landmark = '',
  });

  /// Nothing typed anywhere.
  bool get isBlank => [recipientName, recipientMobile, addressLine, barangay, city, province, postalCode, landmark]
      .every((value) => value.trim().isEmpty);
}

/// The server's `DeliveryView`. [status] stays a string on purpose: one the
/// app does not know yet must never break a screen.
class DeliveryView {
  /// requested, out-for-delivery, delivered, received, closed or returned.
  final String status;
  final String recipientName;
  final String recipientMobile;
  final String addressLine;
  final String barangay;
  final String city;
  final String province;
  final String? postalCode;
  final String? landmark;
  final String? requestedAt;
  final String? courier;
  final String? trackingNumber;

  /// YYYY-MM-DD.
  final String? sentOn;

  /// YYYY-MM-DD.
  final String? deliveredOn;
  final String? proofReference;
  final String? receivedAt;
  final String? closedAt;
  final String? closeNote;
  final String? returnedAt;
  final String? returnReason;

  /// YYYY-MM-DD: the first day an officer may close it unconfirmed.
  final String? closableFrom;

  const DeliveryView({
    required this.status,
    required this.recipientName,
    required this.recipientMobile,
    required this.addressLine,
    required this.barangay,
    required this.city,
    required this.province,
    this.postalCode,
    this.landmark,
    this.requestedAt,
    this.courier,
    this.trackingNumber,
    this.sentOn,
    this.deliveredOn,
    this.proofReference,
    this.receivedAt,
    this.closedAt,
    this.closeNote,
    this.returnedAt,
    this.returnReason,
    this.closableFrom,
  });

  factory DeliveryView.fromJson(Map<String, dynamic> json) {
    String text(String key) => json[key] is String ? json[key] as String : '';
    String? optional(String key) => json[key] is String && (json[key] as String).isNotEmpty ? json[key] as String : null;
    return DeliveryView(
      status: text('status'),
      recipientName: text('recipientName'),
      recipientMobile: text('recipientMobile'),
      addressLine: text('addressLine'),
      barangay: text('barangay'),
      city: text('city'),
      province: text('province'),
      postalCode: optional('postalCode'),
      landmark: optional('landmark'),
      requestedAt: optional('requestedAt'),
      courier: optional('courier'),
      trackingNumber: optional('trackingNumber'),
      sentOn: optional('sentOn'),
      deliveredOn: optional('deliveredOn'),
      proofReference: optional('proofReference'),
      receivedAt: optional('receivedAt'),
      closedAt: optional('closedAt'),
      closeNote: optional('closeNote'),
      returnedAt: optional('returnedAt'),
      returnReason: optional('returnReason'),
      closableFrom: optional('closableFrom'),
    );
  }
}

/// `GET /applications/{id}/delivery`, and the answer to PUT and to `.../received`.
class PermitDeliveryState {
  /// [receiveByPickup] or [receiveByDelivery].
  final String receiveBy;
  final DeliveryView? delivery;

  /// Until the permit is handed to the courier.
  final bool canChange;

  /// While it is with the courier, or delivered and not yet confirmed.
  final bool canConfirmReceipt;
  final String feeNote;

  /// Only on the confirmation's answer.
  final String? lifecycleStatus;

  const PermitDeliveryState({
    required this.receiveBy,
    required this.delivery,
    required this.canChange,
    required this.canConfirmReceipt,
    this.feeNote = deliveryFeeNote,
    this.lifecycleStatus,
  });

  /// The delivery, when the choice is delivery; null for a pick-up.
  DeliveryView? get deliveryChosen => receiveBy == receiveByDelivery ? delivery : null;

  factory PermitDeliveryState.fromJson(Map<String, dynamic> json) {
    final delivery = json['delivery'];
    final feeNote = json['feeNote'];
    return PermitDeliveryState(
      receiveBy: json['receiveBy'] == receiveByDelivery ? receiveByDelivery : receiveByPickup,
      delivery: delivery is Map<String, dynamic> ? DeliveryView.fromJson(delivery) : null,
      canChange: json['canChange'] == true,
      canConfirmReceipt: json['canConfirmReceipt'] == true,
      feeNote: feeNote is String && feeNote.isNotEmpty ? feeNote : deliveryFeeNote,
      lifecycleStatus: json['lifecycleStatus'] as String?,
    );
  }
}

final _mobile = RegExp(r'^(09\d{9}|\+639\d{9})$');
final _spacesAndDashes = RegExp(r'[\s-]');

/// The server's `addressProblem`: why this address cannot be used, in the
/// citizen's words, or null.
String? deliveryAddressProblem(DeliveryAddressForm address) {
  bool blank(String value) => value.trim().isEmpty;
  if (address.recipientName.trim().length < 2) return 'Give the name of whoever will receive the permit.';
  if (!_mobile.hasMatch(address.recipientMobile.replaceAll(_spacesAndDashes, ''))) {
    return 'Give a mobile number the courier can call (09XXXXXXXXX).';
  }
  if (address.addressLine.trim().length < 3) return 'Give the house number and street, or the purok.';
  if (blank(address.barangay) || blank(address.city) || blank(address.province)) {
    return 'Give the barangay, city or municipality, and province.';
  }
  if (!blank(address.postalCode) && !RegExp(r'^[0-9]{4}$').hasMatch(address.postalCode.trim())) {
    return 'A Philippine ZIP code is four digits.';
  }
  return null;
}

/// Prefilled from the citizen's profile: their name, the account mobile, and their address.
DeliveryAddressForm addressFromProfile(CitizenProfile? profile) {
  if (profile == null) return const DeliveryAddressForm();
  return DeliveryAddressForm(
    recipientName: profile.fullName,
    recipientMobile: profile.mobileNumber ?? '',
    addressLine: profile.street ?? '',
    barangay: profile.barangay ?? '',
    city: profile.city ?? '',
    province: profile.province ?? '',
    postalCode: profile.postalCode ?? '',
  );
}

/// The address a delivery was asked for, back in the form (to change it, or
/// to ask again after a return).
DeliveryAddressForm addressFromDelivery(DeliveryView delivery) => DeliveryAddressForm(
      recipientName: delivery.recipientName,
      recipientMobile: delivery.recipientMobile,
      addressLine: delivery.addressLine,
      barangay: delivery.barangay,
      city: delivery.city,
      province: delivery.province,
      postalCode: delivery.postalCode ?? '',
      landmark: delivery.landmark ?? '',
    );

/// The PUT body for this choice; blank optional fields go as null.
Map<String, dynamic> deliveryChoiceBody(String receiveBy, DeliveryAddressForm address) {
  if (receiveBy != receiveByDelivery) return {'receiveBy': receiveByPickup};
  String? optional(String value) => value.trim().isEmpty ? null : value.trim();
  return {
    'receiveBy': receiveByDelivery,
    'address': {
      'recipientName': address.recipientName.trim(),
      'recipientMobile': address.recipientMobile.replaceAll(_spacesAndDashes, ''),
      'addressLine': address.addressLine.trim(),
      'barangay': address.barangay.trim(),
      'city': address.city.trim(),
      'province': address.province.trim(),
      'postalCode': optional(address.postalCode),
      'landmark': optional(address.landmark),
    },
  };
}

final _dayFormat = DateFormat('MMM d, yyyy');

/// A YYYY-MM-DD day as the app writes dates, read as a calendar day (not
/// midnight UTC, which is the day before in some time zones).
String formatDeliveryDay(String? day) {
  if (day == null || day.isEmpty) return '—';
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(day);
  if (match == null) return day;
  return _dayFormat.format(DateTime(int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!)));
}

String _formatInstant(String iso) {
  final when = DateTime.tryParse(iso)?.toLocal();
  return when == null ? iso : _dayFormat.format(when);
}

/// The address on one line: street, barangay, city, province, ZIP.
String deliveryAddressLine(DeliveryView d) => [
      d.addressLine,
      d.barangay.trim().isEmpty ? '' : 'Brgy. ${d.barangay.trim()}',
      d.city,
      d.province,
      d.postalCode ?? '',
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(', ');

/// Where the delivery stands, for the citizen: a heading and a sentence. The
/// contract's own meanings; a status the server adds later reads as a
/// delivery by courier rather than breaking the card.
({String title, String detail}) deliveryStatusText(DeliveryView delivery) => switch (delivery.status) {
      'requested' => (title: 'Delivery requested', detail: 'We’ll send it by courier when your permit is ready.'),
      'out-for-delivery' => (
          title: 'On its way',
          detail: 'The courier has your permit. Follow it with the tracking number below.',
        ),
      'delivered' => (title: 'The courier delivered it', detail: 'Please confirm that you received it.'),
      'received' => (
          title: delivery.receivedAt != null ? 'Received on ${_formatInstant(delivery.receivedAt!)}' : 'Received',
          detail: 'You confirmed you received your permit. This application is complete.',
        ),
      'closed' => (title: 'Delivered', detail: 'Closed by the office from the courier’s proof of delivery.'),
      'returned' => (
          title: 'The courier brought it back to the office',
          detail: 'You can claim it at the office, or ask for delivery again.',
        ),
      _ => (title: 'Delivery by courier', detail: 'The office will update this when it has news of your permit.'),
    };

/// The permit has reached the citizen, one way or the other.
bool deliveryDone(DeliveryView delivery) => const {'delivered', 'received', 'closed'}.contains(delivery.status);
