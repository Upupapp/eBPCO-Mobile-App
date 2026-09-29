import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/lgu_contact.dart';
import '../../domain/models.dart';
import '../../domain/upload_file.dart';
import '../../services/applications_service.dart';
import '../../services/upload_limits.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import 'payments_list_screen.dart';
import '../../widgets/message_bar.dart';

/// `POST /applications/{id}/payments` — mirrors `payment-flow.page.ts`
/// exactly: `amountCentavos` is always the real Order of Payment's own
/// total, never anything typed here, and `referenceNumber` is derived
/// (the proof's filename for Bank Transfer, an ONSITE-timestamp
/// otherwise) rather than a field a citizen fills in.
class PaymentFlowScreen extends StatefulWidget {
  final String applicationId;
  const PaymentFlowScreen({super.key, required this.applicationId});

  @override
  State<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends State<PaymentFlowScreen> {
  final _api = CitizenApi.instance;
  ApplicationSummary? _application;
  bool _loading = true;
  bool _submitting = false;
  String _method = 'Bank Transfer';
  String? _proofFileName;
  List<int>? _proofBytes;
  bool _preparingProof = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final app = await _api.getApplication(widget.applicationId);
      if (!mounted) return;
      setState(() => _application = app);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickProof() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'], withData: true);
    final picked = result?.files.single;
    if (picked == null) return;
    // Made ready now, not at Submit: a file the server would refuse is
    // better known while the citizen is still choosing one.
    setState(() {
      _preparingProof = true;
      _error = null;
    });
    try {
      final bytes = picked.bytes ?? (picked.path != null ? await File(picked.path!).readAsBytes() : null);
      if (bytes == null) throw const UploadRefused(unreadableFile);
      final ready = await readyForUpload(picked.name, bytes);
      if (!mounted) return;
      setState(() {
        _proofFileName = ready.fileName;
        _proofBytes = ready.bytes;
      });
    } on UploadRefused catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _preparingProof = false);
    }
  }

  Future<void> _submit() async {
    final order = _application?.orderOfPayment;
    if (order == null) return;
    if (_method == 'Bank Transfer' && _proofFileName == null) {
      setState(() => _error = 'Please attach your proof of payment.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      String? proofDocumentId;
      if (_method == 'Bank Transfer' && _proofBytes != null) {
        // A retry after a payment that failed past its upload sends the same
        // receipt again: that copy is used rather than the payment stopped.
        proofDocumentId = (await _api.uploadOrReuse(
          fileName: _proofFileName!,
          label: 'Proof of Payment',
          contentBase64: base64Encode(_proofBytes!),
          applicationId: widget.applicationId,
        )).documentId;
      }
      final reference = _method == 'Bank Transfer' ? _proofFileName! : 'ONSITE-${DateTime.now().millisecondsSinceEpoch}';
      final result = await _api.submitPayment(
        applicationId: widget.applicationId,
        referenceNumber: reference,
        method: _method,
        paidOn: DateTime.now().toIso8601String().substring(0, 10),
        amountCentavos: order.totalCentavos,
        proofDocumentId: proofDocumentId,
      );
      if (!mounted) return;
      context.read<ApplicationsService>().refresh();
      ScaffoldMessenger.of(context).showSnackBar(messageBar(result.settles
            ? 'Payment submitted to the Municipality — this settles your balance, pending verification.'
            : 'Payment submitted to the Municipality, pending verification.'));
      // The screen that opened this (the application, or Payments) reloads on return.
      Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = _application;
    final order = app?.orderOfPayment;

    return SoftPageScaffold(
      title: 'Pay Assessment',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : app == null || order == null
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [SoftEmptyCard(_error ?? 'No assessment has been issued yet for this application.')],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(SoftRadius.lg), boxShadow: SoftShadows.feature),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(gradient: SoftColors.primaryGradient, borderRadius: BorderRadius.circular(SoftRadius.lg)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${app.referenceNumber} · ${app.permitType}', style: SoftType.tileSub.copyWith(color: const Color(0xE6FFFFFF))),
                            const SizedBox(height: 14),
                            Text('Total Assessment', style: SoftType.cellLabel.copyWith(color: const Color(0xCCFFFFFF), fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(pesos(order.totalCentavos), style: SoftType.hero.copyWith(color: SoftColors.white, fontSize: 34)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SoftSectionHeader(title: 'Payment Method'),
                    Row(
                      children: [
                        Expanded(
                          child: _MethodCard(
                            icon: Icons.account_balance_outlined,
                            label: 'Bank Transfer',
                            selected: _method == 'Bank Transfer',
                            onTap: () => setState(() => _method = 'Bank Transfer'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MethodCard(
                            icon: Icons.storefront_outlined,
                            label: 'Onsite Payment',
                            selected: _method == 'Onsite',
                            onTap: () => setState(() => _method = 'Onsite'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_method == 'Bank Transfer') _bankTransferSection() else _onsiteSection(),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!, style: AppTypography.error),
                    ],
                    const SizedBox(height: 24),
                    if (_method == 'Onsite' || defaultBankInfo != null)
                      SoftPillButton(
                        label: _method == 'Bank Transfer' ? 'Submit Payment' : 'Mark as Paid',
                        busy: _submitting,
                        onPressed: _submit,
                      ),
                  ],
                ),
    );
  }

  Widget _bankTransferSection() {
    if (defaultBankInfo == null) {
      // F-4 rule ported from the web portal: never render a placeholder
      // account number. This screen asks a citizen to move real money, so
      // "not yet available" is the only safe empty state until the
      // Municipality actually supplies a deposit account.
      return SoftCard(
        color: SoftColors.pendingCream,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bank transfer is not available yet', style: SoftType.tileTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: SoftColors.pendingInk)),
            const SizedBox(height: 6),
            Text(
              'The Municipality of Castilla has not published a deposit account for permit fees. '
              'Do not transfer permit fees to any account you have not confirmed with the Municipality directly.',
              style: SoftType.body.copyWith(color: SoftColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              'Use Onsite Payment instead, or confirm current arrangements with the ${municipalEngineer.name} — '
              '${municipalEngineer.mobile} or ${municipalEngineer.email}.',
              style: SoftType.body.copyWith(color: SoftColors.ink),
            ),
          ],
        ),
      );
    }
    final bank = defaultBankInfo!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bank: ${bank.bankName}', style: SoftType.body.copyWith(color: SoftColors.ink)),
              Text('Account Name: ${bank.accountName}', style: SoftType.body.copyWith(color: SoftColors.ink)),
              Text('Account Number: ${bank.accountNumber}', style: SoftType.body.copyWith(color: SoftColors.ink)),
              Text('Branch: ${bank.branch}', style: SoftType.body.copyWith(color: SoftColors.ink)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SoftFieldLabel('Proof of Payment'),
        _proofFileName != null
            ? Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: SoftColors.verifiedInk, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_proofFileName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: SoftType.cellValue)),
                  TextButton(onPressed: _preparingProof ? null : _pickProof, child: const Text('Replace')),
                ],
              )
            : SoftPillButton(
                label: 'Attach File',
                kind: SoftPillKind.outline,
                icon: Icons.attach_file_rounded,
                busy: _preparingProof,
                onPressed: _pickProof,
              ),
      ],
    );
  }

  Widget _onsiteSection() {
    return SoftCard(
      color: SoftColors.primaryWash,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SoftIconTile(icon: Icons.place_outlined, background: SoftColors.white, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pay directly at the ${municipalEngineer.name}, $municipalHallAddress. Bring a copy of your Order of Payment.',
              style: SoftType.body.copyWith(color: SoftColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodCard({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        boxShadow: selected ? SoftShadows.card : SoftShadows.cardSm,
      ),
      child: Material(
        color: selected ? SoftColors.primaryWash : SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(SoftRadius.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SoftRadius.lg),
              border: Border.all(color: selected ? SoftColors.primary : SoftColors.lineSoft, width: selected ? 1.5 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SoftIconTile(icon: icon, size: 40, background: selected ? SoftColors.white : SoftColors.primarySoft),
                    const Spacer(),
                    Icon(
                      selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: selected ? SoftColors.primary : SoftColors.chevron,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(label, style: SoftType.tileTitle.copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
