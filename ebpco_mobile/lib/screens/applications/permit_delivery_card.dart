import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../core/api/problem.dart';
import '../../domain/lgu_contact.dart';
import '../../domain/models.dart';
import '../../domain/permit_delivery.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/delivery_choice_form.dart';
import '../../widgets/message_bar.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';

/// Saves the citizen's choice (`PUT /applications/{id}/delivery`).
typedef SaveDeliveryChoice = Future<PermitDeliveryState> Function(Map<String, dynamic> body);

/// "I received my permit" (`POST /applications/{id}/delivery/received`).
typedef ConfirmPermitReceived = Future<PermitDeliveryState> Function();

/// "Receiving your permit" (ebpco-api 070) — the portal's
/// `app-permit-delivery`: picked up at the office, or delivered by courier —
/// the citizen's choice, changeable until the permit is handed to the
/// courier; then the courier, the tracking number and the date sent; "I
/// received my permit", which closes the application; and, if the courier
/// brought it back, why, where and when to claim it, and "Ask for delivery
/// again".
///
/// Everything it offers is what the server says may be done now
/// ([PermitDeliveryState.canChange], [PermitDeliveryState.canConfirmReceipt]),
/// never inferred here.
class PermitDeliveryCard extends StatefulWidget {
  final PermitDeliveryState state;

  /// For the confirmation's wording.
  final String? permitNumber;

  /// The office's release record (`GET /applications/{id}/permit`): where,
  /// when and with what to claim it, for a pick-up ready to collect and after
  /// the courier brought it back.
  final PermitRelease? release;

  /// The citizen's own name, mobile and address, offered for a delivery.
  final CitizenProfile? profile;

  final SaveDeliveryChoice save;
  final ConfirmPermitReceived confirmReceived;

  /// The new state after a change of choice or address.
  final ValueChanged<PermitDeliveryState> onChanged;

  /// The new state after "I received my permit": the application is Completed.
  final ValueChanged<PermitDeliveryState> onReceived;

  const PermitDeliveryCard({
    super.key,
    required this.state,
    required this.save,
    required this.confirmReceived,
    required this.onChanged,
    required this.onReceived,
    this.permitNumber,
    this.release,
    this.profile,
  });

  @override
  State<PermitDeliveryCard> createState() => _PermitDeliveryCardState();
}

class _PermitDeliveryCardState extends State<PermitDeliveryCard> {
  /// The form while Change (or Ask for delivery again) is open; null otherwise.
  DeliveryChoiceController? _editing;
  String? _problem;
  bool _saving = false;
  bool _confirming = false;
  bool _copied = false;

  @override
  void dispose() {
    _editing?.dispose();
    super.dispose();
  }

  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(messageBar(message));

  /// Opens the form: on the address already given (Change, or Ask for
  /// delivery again after a return, which opens on Delivery), or on the
  /// citizen's own profile address when they picked up until now.
  void _startEditing() {
    final d = widget.state.deliveryChosen;
    setState(() {
      _problem = null;
      _editing?.dispose();
      _editing = d != null
          ? DeliveryChoiceController(receiveBy: receiveByDelivery, address: addressFromDelivery(d))
          : DeliveryChoiceController(address: addressFromProfile(widget.profile));
    });
  }

  void _stopEditing() {
    final editing = _editing;
    setState(() {
      _editing = null;
      _problem = null;
    });
    // After the frame that stops showing its fields.
    WidgetsBinding.instance.addPostFrameCallback((_) => editing?.dispose());
  }

  Future<void> _save() async {
    final editing = _editing;
    if (editing == null) return;
    final problem = editing.problem;
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }
    setState(() => _saving = true);
    try {
      final next = await widget.save(editing.requestBody);
      if (!mounted) return;
      _stopEditing();
      widget.onChanged(next);
      final d = next.deliveryChosen;
      _toast(d != null
          ? 'Saved. Your permit will be delivered by courier to ${d.city}.'
          : 'Saved. You will pick up your permit at the office.');
    } on ApiError catch (e) {
      if (!mounted) return;
      if (editing.isDelivery) setState(() => _problem = e.citizenMessage);
      _toast(e.citizenMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmReceived() async {
    final number = widget.permitNumber;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm that you received ${number != null ? 'permit $number' : 'your permit'}?'),
        content: const Text('This closes the delivery and completes your application.'),
        actions: [
          TextButton(
            key: const ValueKey('delivery-received-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not yet'),
          ),
          TextButton(
            key: const ValueKey('delivery-received-yes'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, I received it'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _confirming = true);
    try {
      final next = await widget.confirmReceived();
      if (!mounted) return;
      widget.onReceived(next);
      _toast('Thank you. Your application is complete.');
    } on ApiError catch (e) {
      if (mounted) _toast(e.citizenMessage);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _copyTracking(String trackingNumber) async {
    try {
      await Clipboard.setData(ClipboardData(text: trackingNumber));
      if (!mounted) return;
      setState(() => _copied = true);
      _toast('Tracking number copied.');
    } catch (_) {
      if (mounted) _toast('Could not copy it. Press and hold the tracking number to copy it instead.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = _editing;
    final d = widget.state.deliveryChosen;
    return SoftCard(
      key: const ValueKey('permit-delivery-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Receiving your permit', style: SoftType.tileTitle.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (editing != null)
            ..._editingView(editing)
          else if (d != null)
            ..._deliveryView(d)
          else
            ..._pickupView(),
        ],
      ),
    );
  }

  List<Widget> _editingView(DeliveryChoiceController editing) => [
        DeliveryChoiceForm(
          controller: editing,
          feeNote: widget.state.feeNote,
          problem: _problem,
          onEdited: () {
            if (_problem != null) setState(() => _problem = null);
          },
          prefill: () => addressFromProfile(widget.profile),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SoftPillButton(
                key: const ValueKey('delivery-cancel-edit'),
                label: 'Cancel',
                kind: SoftPillKind.outline,
                onPressed: _saving ? null : _stopEditing,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SoftPillButton(
                key: const ValueKey('delivery-save'),
                label: _saving ? 'Saving…' : 'Save',
                busy: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ];

  List<Widget> _pickupView() {
    final release = widget.release;
    return [
      _choiceLine(Icons.storefront_outlined, pickupChoiceTitle, pickupChoiceDetail),
      if (release != null && release.status == 'Ready for Release') ...[
        const SizedBox(height: 12),
        ..._claimRows(release),
      ],
      if (widget.state.canChange) ...[
        const SizedBox(height: 14),
        SoftPillButton(
          key: const ValueKey('delivery-change'),
          label: 'Change',
          kind: SoftPillKind.outline,
          icon: Icons.edit_outlined,
          onPressed: _startEditing,
        ),
        const SizedBox(height: 6),
        _note('Until the permit is ready, you can have it delivered by courier instead.'),
      ],
    ];
  }

  List<Widget> _deliveryView(DeliveryView d) {
    final text = deliveryStatusText(d);
    final returned = d.status == 'returned';
    final (background, ink) = deliveryDone(d)
        ? (SoftColors.verifiedSoft, SoftColors.verifiedInk)
        : returned
            ? (SoftColors.pendingCream, SoftColors.pendingInk)
            : (SoftColors.chipWash, SoftColors.ink);
    final release = widget.release;
    final tracking = d.trackingNumber;
    return [
      _choiceLine(Icons.local_shipping_outlined, deliveryChoiceTitle, null),
      const SizedBox(height: 12),
      Container(
        key: const ValueKey('delivery-status'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(SoftRadius.sm)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text.title, style: SoftType.tileTitle.copyWith(fontWeight: FontWeight.w600, color: ink)),
            const SizedBox(height: 4),
            Text(text.detail, style: SoftType.body.copyWith(color: SoftColors.ink, fontSize: 14)),
          ],
        ),
      ),
      if (returned && d.returnReason != null) ...[
        const SizedBox(height: 10),
        _row('Reason', d.returnReason!),
      ],
      if (returned && release != null && release.status == 'Ready for Release') ...[
        const SizedBox(height: 10),
        ..._claimRows(release),
      ],
      const SizedBox(height: 6),
      if (d.courier case final courier?) _row('Courier', courier),
      if (tracking != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text('Tracking no.', style: SoftType.cellLabel.copyWith(fontSize: 13.5)),
              const SizedBox(width: 10),
              Expanded(
                child: SelectableText(
                  tracking,
                  key: const ValueKey('delivery-tracking-number'),
                  style: SoftType.cellValue.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('delivery-copy-tracking'),
                onPressed: () => _copyTracking(tracking),
                icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 16),
                label: Text(_copied ? 'Copied' : 'Copy'),
              ),
            ],
          ),
        ),
      if (d.sentOn != null) _row('Date sent', formatDeliveryDay(d.sentOn)),
      if (d.deliveredOn != null && !returned) _row('Delivered', formatDeliveryDay(d.deliveredOn)),
      const SizedBox(height: 4),
      _row(
        'Deliver to',
        [
          '${d.recipientName} · ${d.recipientMobile}',
          deliveryAddressLine(d),
          if (d.landmark != null) 'Landmark: ${d.landmark}',
        ].join('\n'),
        key: 'delivery-address',
      ),
      if (d.status == 'requested' || returned) ...[
        const SizedBox(height: 10),
        _note(widget.state.feeNote),
      ],
      if (d.status == 'delivered' && d.closableFrom != null) ...[
        const SizedBox(height: 10),
        _note(
          'If you do not confirm, the office may close it from the courier’s proof of delivery '
          'from ${formatDeliveryDay(d.closableFrom)}.',
        ),
      ],
      if (widget.state.canConfirmReceipt) ...[
        const SizedBox(height: 14),
        SoftPillButton(
          key: const ValueKey('delivery-received'),
          label: _confirming ? 'Confirming…' : 'I received my permit',
          icon: Icons.task_alt_rounded,
          busy: _confirming,
          onPressed: _confirming ? null : _confirmReceived,
        ),
        const SizedBox(height: 6),
        _note('Confirm once the permit is in your hands.'),
      ],
      if (widget.state.canChange) ...[
        const SizedBox(height: 14),
        if (returned)
          SoftPillButton(
            key: const ValueKey('delivery-ask-again'),
            label: 'Ask for delivery again',
            icon: Icons.local_shipping_outlined,
            onPressed: _startEditing,
          )
        else ...[
          SoftPillButton(
            key: const ValueKey('delivery-change'),
            label: 'Change',
            kind: SoftPillKind.outline,
            icon: Icons.edit_outlined,
            onPressed: _startEditing,
          ),
          const SizedBox(height: 6),
          _note('Until the permit is sent, you can change the address or pick it up instead.'),
        ],
      ],
    ];
  }

  /// Where, when and with what to claim it — as the Releasing Officer typed
  /// them, and the portal's own defaults where they did not.
  List<Widget> _claimRows(PermitRelease release) => [
        _row('Where', release.claimLocation ?? 'the ${municipalEngineer.name}, $municipalHallAddress', key: 'delivery-claim-where'),
        if (release.officeHours case final hours?) _row('When', hours),
        _row(
          'Bring',
          release.bringWithYou.isNotEmpty
              ? release.bringWithYou.map((item) => '• $item').join('\n')
              : 'a valid ID${release.method == 'Authorized Representative' ? ' and a letter of authorisation' : ''}.',
        ),
      ];

  Widget _choiceLine(IconData icon, String title, String? detail) => Row(
        key: const ValueKey('delivery-choice'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIconTile(icon: icon, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(title, style: SoftType.tileTitle),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail, style: SoftType.tileSub),
                ],
              ],
            ),
          ),
        ],
      );

  Widget _row(String label, String value, {String? key}) => Padding(
        key: key == null ? null : ValueKey(key),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 92, child: Text(label, style: SoftType.cellLabel.copyWith(fontSize: 13.5))),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: SoftType.cellValue.copyWith(fontSize: 14.5))),
          ],
        ),
      );

  Widget _note(String text) => Text(text, style: SoftType.cellLabel.copyWith(fontSize: 13));
}
