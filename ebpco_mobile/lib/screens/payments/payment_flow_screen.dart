import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/lgu_contact.dart';
import '../../domain/models.dart';
import '../../domain/payment_methods.dart';
import '../../domain/upload_file.dart';
import '../../services/applications_service.dart';
import '../../services/upload_limits.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import 'order_of_payment_screen.dart';
import 'payments_list_screen.dart';
import '../../widgets/message_bar.dart';

typedef LoadApplication = Future<ApplicationSummary> Function(String applicationId);
typedef LoadPaymentMethods = Future<List<PaymentMethodOption>> Function();
typedef StartGcashCheckout = Future<GcashCheckout> Function(String applicationId);
typedef OpenCheckoutPage = Future<bool> Function(Uri url);

/// The checkout is the citizen portal's own page: it opens in the browser,
/// outside the app, as a payment gateway's hosted page would.
Future<bool> _openInBrowser(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);

const _checkoutNotOpened = 'The GCash checkout could not be opened. Please try again.';

/// `POST /applications/{id}/payments` — mirrors `payment-flow.page.ts`
/// exactly: `amountCentavos` is always the real Order of Payment's own
/// total, never anything typed here, and `referenceNumber` is derived
/// (the proof's filename for Bank Transfer, an ONSITE-timestamp
/// otherwise) rather than a field a citizen fills in.
///
/// The methods are the ones the LGU accepts right now (`GET /payment-methods`,
/// ebpco-api 071; Onsite alone when that cannot be read; never Bank Transfer
/// while no deposit account is published). GCash opens a checkout
/// (`POST /applications/{id}/payments/gcash`) in the browser; when the
/// citizen comes back to the app, the application is read again and says
/// whether the payment reached the Cashier.
class PaymentFlowScreen extends StatefulWidget {
  final String applicationId;

  /// Stand-ins for the API and the browser, for tests; the real ones when null.
  final LoadApplication? loadApplication;
  final LoadPaymentMethods? loadPaymentMethods;
  final StartGcashCheckout? startGcash;
  final OpenCheckoutPage? openCheckout;

  const PaymentFlowScreen({
    super.key,
    required this.applicationId,
    this.loadApplication,
    this.loadPaymentMethods,
    this.startGcash,
    this.openCheckout,
  });

  @override
  State<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends State<PaymentFlowScreen> with WidgetsBindingObserver {
  final _api = CitizenApi.instance;
  ApplicationSummary? _application;
  bool _loading = true;
  bool _submitting = false;

  static const _bankPublished = defaultBankInfo != null;

  /// Until the server answers, what this screen always had.
  List<PaymentMethodOption> _methods = localPaymentMethods(bankPublished: _bankPublished);

  // Onsite unless the Municipality has published a deposit account (QA TC-25,
  // 2026-10-03: Bank Transfer opened first, on a "not available yet" notice).
  late String _method = defaultPaymentMethod(_methods);
  String? _proofFileName;
  List<int>? _proofBytes;
  bool _preparingProof = false;
  String? _error;

  /// The GCash checkout opened last, while the citizen pays on it.
  GcashCheckout? _checkout;

  /// Read again once the citizen came back: the payment reached the Cashier.
  bool _gcashSent = false;
  bool _checkingGcash = false;

  /// Said after a check that found no payment yet.
  String? _gcashHint;

  LoadApplication get _loadApplication => widget.loadApplication ?? _api.getApplication;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the browser: whether the checkout was paid.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _checkout != null && !_gcashSent) _checkGcash();
  }

  /// Never fails: a list that cannot be read offers Onsite.
  Future<List<PaymentMethodOption>> _listedMethods() async {
    try {
      return await (widget.loadPaymentMethods ?? _api.paymentMethods)();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _load() async {
    final methods = _listedMethods();
    try {
      final app = await _loadApplication(widget.applicationId);
      final listed = await methods;
      if (!mounted) return;
      setState(() {
        _application = app;
        _useMethods(listed);
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _useMethods(List<PaymentMethodOption> listed) {
    _methods = offeredPaymentMethods(listed, bankPublished: _bankPublished);
    if (!_methods.any((m) => m.method == _method)) _method = defaultPaymentMethod(_methods);
  }

  void _chooseMethod(String method) => setState(() {
        _method = method;
        _error = null;
      });

  /// The GCash provider is the test one: no real money moves (the server says so with `mode: 'test'`).
  bool get _gcashTestMode => _methods.any((m) => m.method == paymentMethodGcash && m.isTestMode);

  /// Opens a GCash checkout for the Order of Payment in force and goes to it in
  /// the browser. The server names the amount; nothing is sent but the
  /// application. Its refusal (not waiting for payment, a payment already with
  /// the Cashier, GCash closed) is shown in its own words.
  Future<void> _payWithGcash() async {
    setState(() {
      _submitting = true;
      _error = null;
      _gcashHint = null;
    });
    try {
      final checkout = await (widget.startGcash ?? _api.startGcashPayment)(widget.applicationId);
      final url = Uri.tryParse(checkout.checkoutUrl);
      if (!mounted) return;
      if (url == null || !url.hasScheme) {
        setState(() => _error = _checkoutNotOpened);
        return;
      }
      setState(() => _checkout = checkout);
      final opened = await (widget.openCheckout ?? _openInBrowser)(url);
      if (!opened && mounted) setState(() => _error = _checkoutNotOpened);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.citizenMessage);
    } catch (_) {
      if (mounted) setState(() => _error = _checkoutNotOpened);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Reads the application again: paid on the checkout, it reads Payment
  /// Submitted and waits for the Cashier; otherwise the checkout is still to
  /// be finished.
  Future<void> _checkGcash() async {
    if (_checkingGcash) return;
    setState(() => _checkingGcash = true);
    try {
      final app = await _loadApplication(widget.applicationId);
      if (!mounted) return;
      final sent = gcashPaymentSent(app);
      setState(() {
        _application = app;
        _gcashSent = sent;
        _error = null;
        _gcashHint = sent
            ? null
            : 'No payment yet. Finish paying on the checkout page in your browser, then come back to the app.';
      });
      if (sent) context.read<ApplicationsService>().refresh();
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _checkingGcash = false);
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

  /// Marking an onsite payment declares that money changed hands, so it is
  /// asked once, plainly (QA TC-27, 2026-10-03: one tap did it).
  Future<bool> _confirmOnsite(OrderOfPayment order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Have you paid ${pesos(order.totalCentavos)} at the ${municipalEngineer.name}?'),
        content: Text(
          'Only mark it paid once you have paid and have your Official Receipt. Your balance stays '
          '${pesos(order.totalCentavos)} until the Cashier verifies the payment.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Not yet')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes, I have paid')),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _submit() async {
    final order = _application?.orderOfPayment;
    if (order == null) return;
    if (_method == paymentMethodBankTransfer && _proofFileName == null) {
      setState(() => _error = 'Please attach your proof of payment.');
      return;
    }
    if (_method == paymentMethodOnsite && !await _confirmOnsite(order)) return;
    if (!mounted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      String? proofDocumentId;
      if (_method == paymentMethodBankTransfer && _proofBytes != null) {
        // A retry after a payment that failed past its upload sends the same
        // receipt again: that copy is used rather than the payment stopped.
        proofDocumentId = (await _api.uploadOrReuse(
          fileName: _proofFileName!,
          label: 'Proof of Payment',
          contentBase64: base64Encode(_proofBytes!),
          applicationId: widget.applicationId,
        )).documentId;
      }
      final reference = _method == paymentMethodBankTransfer ? _proofFileName! : 'ONSITE-${DateTime.now().millisecondsSinceEpoch}';
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
      // Says what is true now: the balance stands until the Cashier verifies
      // the payment (QA TC-27: "this settles your balance" sat above an
      // unchanged balance).
      ScaffoldMessenger.of(context).showSnackBar(messageBar(result.settles
            ? 'Payment sent for verification. Once the Cashier verifies it, your balance will be settled.'
            : 'Payment sent for verification.'));
      // The screen that opened this (the application, or Payments) reloads on return.
      Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static IconData _iconOf(String method) => switch (method) {
        paymentMethodBankTransfer => Icons.account_balance_outlined,
        paymentMethodGcash => Icons.smartphone_outlined,
        _ => Icons.storefront_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final app = _application;
    final order = app?.orderOfPayment;

    return SoftPageScaffold(
      title: 'Pay Assessment',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : app != null && _gcashSent
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  children: [_gcashSentCard(app)],
                )
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
                            Text('${app.displayReference} · ${app.permitType}', style: SoftType.tileSub.copyWith(color: const Color(0xE6FFFFFF))),
                            const SizedBox(height: 14),
                            Text('Total Assessment', style: SoftType.cellLabel.copyWith(color: const Color(0xCCFFFFFF), fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(pesos(order.totalCentavos), style: SoftType.hero.copyWith(color: SoftColors.white, fontSize: 34)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SoftPillButton(
                      label: 'View Order of Payment',
                      kind: SoftPillKind.outline,
                      icon: Icons.receipt_long_outlined,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => OrderOfPaymentScreen(applicationId: widget.applicationId)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SoftSectionHeader(title: 'Payment Method'),
                    // The methods the LGU accepts right now (ebpco-api 071).
                    // Bank Transfer is offered only once the Municipality
                    // publishes a deposit account (QA TC-25).
                    if (_methods.length > 1)
                      for (final m in _methods)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MethodCard(
                            icon: _iconOf(m.method),
                            label: paymentMethodTitle(m),
                            blurb: paymentMethodBlurb(m),
                            selected: _method == m.method,
                            onTap: () => _chooseMethod(m.method),
                          ),
                        )
                    else if (_method == paymentMethodOnsite)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Pay onsite at the Municipal Hall. Bank transfer will be offered here once the Municipality '
                          'publishes its deposit account.',
                          style: SoftType.body.copyWith(color: SoftColors.muted),
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (_method == paymentMethodBankTransfer)
                      _bankTransferSection()
                    else if (_method == paymentMethodGcash)
                      _gcashSection(order)
                    else
                      _onsiteSection(),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!, style: AppTypography.error),
                    ],
                    const SizedBox(height: 24),
                    if (_method == paymentMethodGcash)
                      SoftPillButton(
                        label: 'Pay with GCash',
                        busy: _submitting,
                        onPressed: _submitting ? null : _payWithGcash,
                      )
                    else if (_method == paymentMethodOnsite || _bankPublished)
                      SoftPillButton(
                        label: _method == paymentMethodBankTransfer ? 'Submit Payment' : 'Mark as Paid',
                        busy: _submitting,
                        onPressed: _submit,
                      ),
                  ],
                ),
    );
  }

  /// GCash (ebpco-api 071): the checkout opens in the browser. Test mode until
  /// the LGU has a GCash merchant account: no money moves, and the page says
  /// so. Verified by the Cashier like any payment.
  Widget _gcashSection(OrderOfPayment order) {
    final checkout = _checkout;
    final until = checkout == null ? null : DateTime.tryParse(checkout.expiresAt)?.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          color: SoftColors.primaryWash,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SoftIconTile(icon: Icons.smartphone_outlined, background: SoftColors.white, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You go to the checkout page to pay ${pesos(order.totalCentavos)}. Once paid, the Cashier '
                      'verifies the payment and issues your official receipt.',
                      style: SoftType.body.copyWith(color: SoftColors.ink),
                    ),
                    if (_gcashTestMode) ...[
                      const SizedBox(height: 6),
                      Text.rich(
                        const TextSpan(children: [
                          TextSpan(text: 'Test mode: ', style: TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: 'no real money is charged.'),
                        ]),
                        style: SoftType.body.copyWith(color: SoftColors.ink),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Away paying, or back without having finished.
        if (checkout != null) ...[
          const SizedBox(height: 12),
          SoftCard(
            color: SoftColors.pendingCream,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finish paying on the checkout page',
                  style: SoftType.tileTitle.copyWith(fontWeight: FontWeight.w600, color: SoftColors.pendingInk),
                ),
                const SizedBox(height: 6),
                Text(
                  'The checkout opened in your browser (ref. ${checkout.reference}). Pay there, then come back to '
                  'the app: this page checks the payment when you return.'
                  '${until == null ? '' : ' The checkout is open until ${DateFormat('h:mm a').format(until)}.'}'
                  ' Closed it? Tap Pay with GCash again.',
                  style: SoftType.body.copyWith(color: SoftColors.ink),
                ),
                if (_gcashHint case final hint?) ...[
                  const SizedBox(height: 8),
                  Text(hint, style: SoftType.body.copyWith(color: SoftColors.pendingInk, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _checkingGcash ? null : _checkGcash,
                    child: Text(_checkingGcash ? 'Checking…' : 'Check Payment'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Paid on the checkout: the application waits for the Cashier.
  Widget _gcashSentCard(ApplicationSummary app) {
    final status = LifecycleStatusX.tryFromLabel(app.lifecycleStatus)?.label ?? app.statusLabel;
    return SoftCard(
      color: SoftColors.verifiedSoft,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: SoftColors.verifiedInk, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Payment sent', style: SoftType.tileTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w600, color: SoftColors.verifiedInk)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${app.displayReference} · ${app.permitType}', style: SoftType.cellLabel),
          const SizedBox(height: 10),
          Text('Status: $status', style: SoftType.cellValue),
          if (_checkout case final checkout?) ...[
            const SizedBox(height: 4),
            Text('Paid through GCash · ref. ${checkout.reference}', style: SoftType.body.copyWith(color: SoftColors.ink)),
          ],
          const SizedBox(height: 10),
          Text(
            'The Cashier verifies it and issues your official receipt.',
            style: SoftType.body.copyWith(color: SoftColors.ink),
          ),
          const SizedBox(height: 16),
          SoftPillButton(
            label: 'Back to My Application',
            onPressed: () => Navigator.of(context).pop(true),
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

/// One way to pay: its name, a line on how, and whether it is chosen.
class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String blurb;
  final bool selected;
  final VoidCallback onTap;
  const _MethodCard({required this.icon, required this.label, required this.blurb, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SoftRadius.lg),
                border: Border.all(color: selected ? SoftColors.primary : SoftColors.lineSoft, width: selected ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  SoftIconTile(icon: icon, size: 40, background: selected ? SoftColors.white : SoftColors.primarySoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: SoftType.tileTitle.copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(blurb, style: SoftType.cellLabel),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: selected ? SoftColors.primary : SoftColors.chevron,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
