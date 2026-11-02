import 'package:flutter/material.dart';

import '../domain/permit_delivery.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/soft_widget.dart';
import 'choice_card.dart';
import 'soft_chrome.dart';

/// The choice the form edits: pick up or delivery, and the address — one
/// text controller per field, so a resumed draft's saved address can be put
/// back into fields the citizen may already be looking at.
class DeliveryChoiceController extends ChangeNotifier {
  DeliveryChoiceController({String receiveBy = receiveByPickup, DeliveryAddressForm address = const DeliveryAddressForm()})
      : _receiveBy = receiveBy == receiveByDelivery ? receiveByDelivery : receiveByPickup {
    setAddress(address);
  }

  String _receiveBy;

  final recipientName = TextEditingController();
  final recipientMobile = TextEditingController();
  final addressLine = TextEditingController();
  final barangay = TextEditingController();
  final city = TextEditingController();
  final province = TextEditingController();
  final postalCode = TextEditingController();
  final landmark = TextEditingController();

  List<TextEditingController> get _fields =>
      [recipientName, recipientMobile, addressLine, barangay, city, province, postalCode, landmark];

  /// [receiveByPickup] or [receiveByDelivery].
  String get receiveBy => _receiveBy;
  bool get isDelivery => _receiveBy == receiveByDelivery;

  set receiveBy(String value) {
    final next = value == receiveByDelivery ? receiveByDelivery : receiveByPickup;
    if (next == _receiveBy) return;
    _receiveBy = next;
    notifyListeners();
  }

  DeliveryAddressForm get address => DeliveryAddressForm(
        recipientName: recipientName.text,
        recipientMobile: recipientMobile.text,
        addressLine: addressLine.text,
        barangay: barangay.text,
        city: city.text,
        province: province.text,
        postalCode: postalCode.text,
        landmark: landmark.text,
      );

  void setAddress(DeliveryAddressForm a) {
    recipientName.text = a.recipientName;
    recipientMobile.text = a.recipientMobile;
    addressLine.text = a.addressLine;
    barangay.text = a.barangay;
    city.text = a.city;
    province.text = a.province;
    postalCode.text = a.postalCode;
    landmark.text = a.landmark;
  }

  /// A saved choice, read back.
  void load(String receiveBy, DeliveryAddressForm address) {
    setAddress(address);
    _receiveBy = receiveBy == receiveByDelivery ? receiveByDelivery : receiveByPickup;
    notifyListeners();
  }

  /// Why the address cannot be used — the server's own rules — or null (a
  /// pick-up has no address to check).
  String? get problem => isDelivery ? deliveryAddressProblem(address) : null;

  /// The `PUT /applications/{id}/delivery` body.
  Map<String, dynamic> get requestBody => deliveryChoiceBody(_receiveBy, address);

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }
}

/// Pick up at the office, or delivery by courier to an address (ebpco-api
/// 070) — the portal's `app-delivery-choice`. One form for the wizard's
/// Review step and the application page's Change, so both ask the same thing
/// in the same words.
///
/// The address is anywhere a courier can reach, not only Castilla, so every
/// field is free text.
class DeliveryChoiceForm extends StatelessWidget {
  final DeliveryChoiceController controller;

  /// The server's `feeNote`; its own wording until that has been read.
  final String feeNote;

  /// Why the address cannot be used, once the parent has checked it.
  final String? problem;

  /// Any change, so the parent can clear a message it showed.
  final VoidCallback? onEdited;

  /// The citizen's own address, put into a still-blank form when they switch
  /// to delivery (the profile may not have loaded when the form opened).
  final DeliveryAddressForm Function()? prefill;

  const DeliveryChoiceForm({
    super.key,
    required this.controller,
    this.feeNote = deliveryFeeNote,
    this.problem,
    this.onEdited,
    this.prefill,
  });

  void _choose(String receiveBy) {
    if (receiveBy == receiveByDelivery && controller.address.isBlank && prefill != null) {
      controller.setAddress(prefill!());
    }
    controller.receiveBy = receiveBy;
    onEdited?.call();
  }

  Widget _field(
    String label,
    TextEditingController field, {
    required String key,
    String? hint,
    String? helper,
    TextInputType? keyboardType,
    int? maxLength,
    Iterable<String>? autofillHints,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftFieldLabel(label),
          TextField(
            key: ValueKey(key),
            controller: field,
            keyboardType: keyboardType,
            maxLength: maxLength,
            autofillHints: autofillHints,
            textCapitalization: keyboardType == null ? TextCapitalization.words : TextCapitalization.none,
            style: SoftType.field,
            onChanged: (_) => onEdited?.call(),
            decoration: InputDecoration(hintText: hint, helperText: helper, counterText: ''),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(receiveByQuestion, style: SoftType.tileTitle.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SoftChoiceCard(
            key: const ValueKey('receive-by-pickup'),
            icon: Icons.storefront_outlined,
            title: pickupChoiceTitle,
            subtitle: pickupChoiceDetail,
            selected: !controller.isDelivery,
            onTap: () => _choose(receiveByPickup),
          ),
          const SizedBox(height: 10),
          SoftChoiceCard(
            key: const ValueKey('receive-by-delivery'),
            icon: Icons.local_shipping_outlined,
            title: deliveryChoiceTitle,
            subtitle: deliveryChoiceDetail,
            selected: controller.isDelivery,
            onTap: () => _choose(receiveByDelivery),
          ),
          if (controller.isDelivery) ...[
            const SizedBox(height: 14),
            Container(
              key: const ValueKey('delivery-fee-note'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.info100, borderRadius: BorderRadius.circular(SoftRadius.sm)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.infoText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(feeNote, style: SoftType.body.copyWith(color: AppColors.infoText, fontSize: 13.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _field(
              "Recipient's name",
              controller.recipientName,
              key: 'delivery-recipient-name',
              helper: 'Whoever will receive it at the door.',
              maxLength: 160,
              autofillHints: const [AutofillHints.name],
            ),
            _field(
              'Mobile number',
              controller.recipientMobile,
              key: 'delivery-recipient-mobile',
              hint: '09XXXXXXXXX',
              helper: 'The courier calls this number.',
              keyboardType: TextInputType.phone,
              maxLength: 20,
              autofillHints: const [AutofillHints.telephoneNumber],
            ),
            _field(
              'House no. and street, or purok',
              controller.addressLine,
              key: 'delivery-address-line',
              maxLength: 300,
              autofillHints: const [AutofillHints.streetAddressLine1],
            ),
            _field('Barangay', controller.barangay, key: 'delivery-barangay', maxLength: 120),
            _field(
              'City / Municipality',
              controller.city,
              key: 'delivery-city',
              maxLength: 120,
              autofillHints: const [AutofillHints.addressCity],
            ),
            _field(
              'Province',
              controller.province,
              key: 'delivery-province',
              maxLength: 120,
              autofillHints: const [AutofillHints.addressState],
            ),
            _field(
              'ZIP code (optional)',
              controller.postalCode,
              key: 'delivery-postal-code',
              hint: 'e.g. 4713',
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofillHints: const [AutofillHints.postalCode],
            ),
            _field(
              'Landmark (optional)',
              controller.landmark,
              key: 'delivery-landmark',
              hint: 'e.g. beside the chapel, green gate',
              maxLength: 300,
            ),
            if (problem != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(problem!, key: const ValueKey('delivery-address-problem'), style: AppTypography.error),
              ),
          ],
        ],
      ),
    );
  }
}
