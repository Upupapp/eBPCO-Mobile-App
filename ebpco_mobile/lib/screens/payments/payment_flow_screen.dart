import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/lgu_contact.dart';
import '../../domain/models.dart';
import '../../services/applications_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';
import '../applications/application_detail_screen.dart';
import 'payments_list_screen.dart';

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
    final bytes = picked.bytes ?? (picked.path != null ? await File(picked.path!).readAsBytes() : null);
    if (bytes == null) return;
    setState(() {
      _proofFileName = picked.name;
      _proofBytes = bytes;
    });
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
        proofDocumentId = await _api.uploadDocument(
          fileName: _proofFileName!,
          label: 'Proof of Payment',
          contentBase64: base64Encode(_proofBytes!),
          applicationId: widget.applicationId,
        );
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.settles
            ? 'Payment submitted to the Municipality — this settles your balance, pending verification.'
            : 'Payment submitted to the Municipality, pending verification.'),
      ));
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ApplicationDetailScreen(applicationId: widget.applicationId)));
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pay Assessment')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : app == null || order == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        _error ?? 'No assessment has been issued yet for this application.',
                        style: AppTypography.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    children: [
                      Text('${app.referenceNumber} · ${app.permitType}', style: AppTypography.caption),
                      const SizedBox(height: AppSpacing.md),
                      SoftCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Assessment', style: AppTypography.body),
                            Text(pesos(order.totalCentavos), style: AppTypography.h2),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Payment Method', style: AppTypography.fieldLabel),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _method = 'Bank Transfer'),
                              style: _method == 'Bank Transfer'
                                  ? OutlinedButton.styleFrom(backgroundColor: AppColors.primary500, foregroundColor: Colors.white)
                                  : null,
                              child: const Text('Bank Transfer'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _method = 'Onsite'),
                              style: _method == 'Onsite'
                                  ? OutlinedButton.styleFrom(backgroundColor: AppColors.primary500, foregroundColor: Colors.white)
                                  : null,
                              child: const Text('Onsite Payment'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_method == 'Bank Transfer') _bankTransferSection() else _onsiteSection(),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(_error!, style: AppTypography.error),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      if (_method == 'Onsite' || defaultBankInfo != null)
                        ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : Text(_method == 'Bank Transfer' ? 'Submit Payment' : 'Mark as Paid'),
                        ),
                    ],
                  ),
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
        color: AppColors.warning100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bank transfer is not available yet', style: AppTypography.cardTitle),
            const SizedBox(height: 6),
            Text(
              'The Municipality of Castilla has not published a deposit account for permit fees. '
              'Do not transfer permit fees to any account you have not confirmed with the Municipality directly.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 8),
            Text(
              'Use Onsite Payment instead, or confirm current arrangements with the ${municipalEngineer.name} — '
              '${municipalEngineer.mobile} or ${municipalEngineer.email}.',
              style: AppTypography.caption,
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
          color: AppColors.surfaceSecondary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bank: ${bank.bankName}', style: AppTypography.body),
              Text('Account Name: ${bank.accountName}', style: AppTypography.body),
              Text('Account Number: ${bank.accountNumber}', style: AppTypography.body),
              Text('Branch: ${bank.branch}', style: AppTypography.body),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Proof of Payment', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        _proofFileName != null
            ? Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_proofFileName!, style: AppTypography.caption)),
                  TextButton(onPressed: _pickProof, child: const Text('Replace')),
                ],
              )
            : OutlinedButton.icon(onPressed: _pickProof, icon: const Icon(Icons.upload_file, size: 18), label: const Text('Attach File')),
      ],
    );
  }

  Widget _onsiteSection() {
    return SoftCard(
      color: AppColors.surfaceSecondary,
      child: Text('Pay directly at the ${municipalEngineer.name}, $municipalHallAddress. Bring a copy of your Order of Payment.', style: AppTypography.body),
    );
  }
}
