import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../domain/payment_history.dart';
import '../../services/applications_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import 'payment_flow_screen.dart';
import 'payment_receipt_screen.dart';

final _pesos = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
String pesos(int centavos) => _pesos.format(centavos / 100);

String _day(String iso) {
  final when = DateTime.tryParse(iso)?.toLocal();
  return when == null ? iso : DateFormat('MMM d, yyyy').format(when);
}

/// One payment sent, with the application it was for.
class _HistoryItem {
  final PaymentEntry entry;
  final PaymentAttemptView view;
  final ApplicationSummary application;
  const _HistoryItem(this.entry, this.view, this.application);
}

/// Payments (redesigned 2026-10-01, the portal's `payments-list.page.ts`):
/// three totals, then Orders of Payment and Payment history, each filtered
/// by status with counts, and searchable. The orders are the applications
/// already held by [ApplicationsService]; the history is every payment sent
/// (`GET /applications/{id}/payments` for each order), newest first — paid
/// ones with their Official Receipt, ones still being checked, and rejected
/// ones with the cashier's reason.
class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  final _api = CitizenApi.instance;
  final _search = TextEditingController();

  bool _showHistory = false;

  /// Null is All.
  OrderState? _orderFilter;

  /// Null is All; otherwise 'Paid', 'Pending Verification', 'Rejected' or 'Other'.
  String? _historyFilter;

  /// Every payment sent, newest first; null while loading.
  List<_HistoryItem>? _history;
  bool _historyError = false;

  /// Which orders the history was last loaded for, so a refresh with the same set does not reload it.
  String _historyKey = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ApplicationsService>().refresh());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _historyKey = '';
    await context.read<ApplicationsService>().refresh();
  }

  Future<void> _loadHistory(List<ApplicationSummary> orders) async {
    try {
      final perOrder = await Future.wait(orders.map((app) async =>
          (await _api.getPayments(app.id)).map((e) => _HistoryItem(e, paymentAttemptView(e), app)).toList()));
      final all = perOrder.expand((items) => items).toList()
        ..sort((a, b) => b.entry.submittedAt.compareTo(a.entry.submittedAt));
      if (!mounted) return;
      setState(() {
        _history = all;
        _historyError = false;
      });
    } on ApiError {
      if (mounted) setState(() => _historyError = true);
    }
  }

  _HistoryItem? _lastPayment(String applicationId) {
    for (final item in _history ?? const <_HistoryItem>[]) {
      if (item.application.id == applicationId) return item;
    }
    return null;
  }

  bool _matches(List<String?> fields) {
    final words = _search.text.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final haystack = fields.whereType<String>().join(' ').toLowerCase();
    return words.every(haystack.contains);
  }

  static String _historyGroup(PaymentAttemptView view) =>
      const {'Paid', 'Pending Verification', 'Rejected'}.contains(view.label) ? view.label : 'Other';

  void _openPay(ApplicationSummary app) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => PaymentFlowScreen(applicationId: app.id)))
      .then((_) => mounted ? _refresh() : null);

  void _openReceipt(ApplicationSummary app) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => PaymentReceiptScreen(applicationId: app.id)));

  @override
  Widget build(BuildContext context) {
    final apps = context.watch<ApplicationsService>();
    final orders = apps.applications.where((a) => a.orderOfPayment != null).toList();

    final key = orders.map((a) => '${a.id}:${a.paymentStatus}').join(',');
    if (key != _historyKey && orders.isNotEmpty) {
      _historyKey = key;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory(orders));
    }

    final states = {for (final a in orders) a.id: orderStateOf(a.paymentStatus, _lastPayment(a.id)?.view)};
    int totalOf(Iterable<ApplicationSummary> list) => list.fold(0, (sum, a) => sum + a.orderOfPayment!.totalCentavos);
    List<ApplicationSummary> inState(Set<OrderState> wanted) => orders.where((a) => wanted.contains(states[a.id])).toList();

    final toPay = inState({OrderState.awaiting, OrderState.rejected});
    final verifying = inState({OrderState.verifying});
    final paid = inState({OrderState.paid});

    final history = _history ?? const <_HistoryItem>[];

    return SoftPageScaffold(
      title: 'Payments',
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: apps.loading && apps.applications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : orders.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      SoftEmptyCard(
                        apps.error != null && apps.applications.isEmpty
                            ? apps.error!
                            : 'No assessments issued yet. Once your application is evaluated, its Order of Payment will appear here.',
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      _SummaryCard(
                        toPay: totalOf(toPay),
                        toPayCount: toPay.length,
                        verifying: totalOf(verifying),
                        paid: totalOf(paid),
                      ),
                      const SizedBox(height: 18),
                      _Segmented(
                        showHistory: _showHistory,
                        ordersCount: orders.length,
                        historyCount: _history?.length,
                        onChanged: (history) => setState(() => _showHistory = history),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          children: _showHistory
                              ? [
                                  for (final (value, label) in [
                                    (null, 'All'),
                                    ('Paid', 'Paid'),
                                    ('Pending Verification', 'Pending verification'),
                                    ('Rejected', 'Rejected'),
                                    ('Other', 'Voided or refunded'),
                                  ])
                                    if (value != 'Other' || history.any((h) => _historyGroup(h.view) == 'Other'))
                                      _CountChip(
                                        label: label,
                                        count: value == null
                                            ? history.length
                                            : history.where((h) => _historyGroup(h.view) == value).length,
                                        selected: _historyFilter == value,
                                        onTap: () => setState(() => _historyFilter = value),
                                      ),
                                ]
                              : [
                                  for (final (value, label) in [
                                    (null, 'All'),
                                    (OrderState.awaiting, 'Awaiting payment'),
                                    (OrderState.rejected, 'Rejected'),
                                    (OrderState.verifying, 'Pending verification'),
                                    (OrderState.paid, 'Paid'),
                                  ])
                                    _CountChip(
                                      label: label,
                                      count: value == null ? orders.length : inState({value}).length,
                                      selected: _orderFilter == value,
                                      onTap: () => setState(() => _orderFilter = value),
                                    ),
                                ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        style: SoftType.field,
                        decoration: InputDecoration(
                          hintText: 'Search reference, receipt or permit',
                          prefixIcon: const Icon(Icons.search_rounded, color: SoftColors.muted),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close_rounded, color: SoftColors.muted),
                                  onPressed: _search.clear,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_showHistory) ..._historyList(history) else ..._orderList(orders, states),
                    ],
                  ),
      ),
    );
  }

  List<Widget> _orderList(List<ApplicationSummary> orders, Map<String, OrderState> states) {
    final shown = orders
        .where((a) => (_orderFilter == null || states[a.id] == _orderFilter) &&
            _matches([a.referenceNumber, a.permitType, a.orderOfPayment!.number, a.paymentStatus]))
        .toList();
    if (shown.isEmpty) return [_NoMatch(onShowAll: _clearFilters)];
    return [
      for (final app in shown)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OrderCard(
            application: app,
            state: states[app.id]!,
            last: _lastPayment(app.id),
            onPay: () => _openPay(app),
            onReceipt: () => _openReceipt(app),
          ),
        ),
    ];
  }

  List<Widget> _historyList(List<_HistoryItem> history) {
    if (_historyError) {
      return const [SoftEmptyCard('Your payment history could not be loaded. Pull down to try again.')];
    }
    if (_history == null) {
      return const [Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))];
    }
    if (history.isEmpty) {
      return const [SoftEmptyCard('No payments sent yet. Payments you send appear here, with their Official Receipts once confirmed.')];
    }
    final shown = history
        .where((h) => (_historyFilter == null || _historyGroup(h.view) == _historyFilter) &&
            _matches([
              h.application.referenceNumber,
              h.application.permitType,
              h.entry.referenceNumber,
              h.entry.officialReceiptNumber,
              h.view.label,
            ]))
        .toList();
    if (shown.isEmpty) return [_NoMatch(onShowAll: _clearFilters)];

    // Grouped under the day each payment was sent, newest day first.
    final days = <String, List<_HistoryItem>>{};
    for (final item in shown) {
      days.putIfAbsent(_day(item.entry.submittedAt), () => []).add(item);
    }
    return [
      for (final MapEntry(key: day, value: items) in days.entries) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text(day.toUpperCase(), style: SoftType.cellLabel.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        ),
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, item) in items.indexed) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, color: SoftColors.line),
                _HistoryRow(item: item, onTap: () => _openReceipt(item.application)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    ];
  }

  void _clearFilters() => setState(() {
        _orderFilter = null;
        _historyFilter = null;
        _search.clear();
      });
}

/// The three totals: what is owed, large, on the red; what is being checked
/// and what is paid under it.
class _SummaryCard extends StatelessWidget {
  final int toPay;
  final int toPayCount;
  final int verifying;
  final int paid;
  const _SummaryCard({required this.toPay, required this.toPayCount, required this.verifying, required this.paid});

  static const _soft = Color(0xE0FFFFFF);
  static const _faint = Color(0x33FFFFFF);

  Widget _minor(String label, int amount) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: SoftType.cellLabel.copyWith(color: _soft)),
            const SizedBox(height: 2),
            Text(
              pesos(amount),
              style: SoftType.cellValue.copyWith(color: SoftColors.white, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: SoftColors.primaryGradient,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        boxShadow: SoftShadows.feature,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TO PAY', style: SoftType.cellLabel.copyWith(color: _soft, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(pesos(toPay), style: SoftType.hero.copyWith(color: SoftColors.white, fontSize: 32)),
          const SizedBox(height: 2),
          Text(
            toPayCount == 0
                ? 'Nothing to pay right now.'
                : '$toPayCount Order${toPayCount == 1 ? '' : 's'} of Payment waiting for payment',
            style: SoftType.tileSub.copyWith(color: _soft),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: _faint),
          const SizedBox(height: 12),
          Row(children: [_minor('Pending verification', verifying), _minor('Paid', paid)]),
        ],
      ),
    );
  }
}

/// Orders | History, as one rounded control.
class _Segmented extends StatelessWidget {
  final bool showHistory;
  final int ordersCount;
  final int? historyCount;
  final ValueChanged<bool> onChanged;
  const _Segmented({required this.showHistory, required this.ordersCount, required this.historyCount, required this.onChanged});

  Widget _segment(String label, int? count, bool selected, VoidCallback onTap) => Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? SoftColors.white : SoftColors.clear,
                borderRadius: BorderRadius.circular(SoftRadius.sm),
                boxShadow: selected ? SoftShadows.cardSm : null,
              ),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: label),
                  if (count != null)
                    TextSpan(text: '  $count', style: const TextStyle(color: SoftColors.muted, fontWeight: FontWeight.w500)),
                ]),
                style: SoftType.chip.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? SoftColors.ink : SoftColors.muted,
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: SoftColors.chipWash, borderRadius: BorderRadius.circular(SoftRadius.md)),
      child: Row(
        children: [
          _segment('Orders of Payment', ordersCount, !showHistory, () => onChanged(false)),
          _segment('Payment history', historyCount, showHistory, () => onChanged(true)),
        ],
      ),
    );
  }
}

/// A status filter with how many it holds.
class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _CountChip({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? SoftColors.primary : SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(SoftRadius.pill),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SoftRadius.pill),
              border: Border.all(color: selected ? SoftColors.primary : SoftColors.line),
            ),
            child: Row(
              children: [
                Text(label, style: SoftType.chip.copyWith(color: selected ? SoftColors.white : SoftColors.ink)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0x38FFFFFF) : SoftColors.chipWash,
                    borderRadius: BorderRadius.circular(SoftRadius.pill),
                  ),
                  child: Text(
                    '$count',
                    style: SoftType.cellLabel.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? SoftColors.white : SoftColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

SoftStatusTone _toneOf(PaymentTone tone) => switch (tone) {
      PaymentTone.verified => SoftStatusTone.verified,
      PaymentTone.pending => SoftStatusTone.pending,
      PaymentTone.danger => SoftStatusTone.danger,
      PaymentTone.neutral => SoftStatusTone.neutral,
    };

/// One Order of Payment: what it is for, how much, where it stands, its last
/// payment, and the one thing to do.
class _OrderCard extends StatelessWidget {
  final ApplicationSummary application;
  final OrderState state;
  final _HistoryItem? last;
  final VoidCallback onPay;
  final VoidCallback onReceipt;
  const _OrderCard({required this.application, required this.state, required this.last, required this.onPay, required this.onReceipt});

  @override
  Widget build(BuildContext context) {
    final order = application.orderOfPayment!;
    final overdue = application.paymentStatus == 'Overdue';
    final (label, tone) = switch (state) {
      OrderState.rejected => ('Payment Rejected', SoftStatusTone.danger),
      OrderState.awaiting => (overdue ? 'Overdue' : 'Awaiting Payment', overdue ? SoftStatusTone.danger : SoftStatusTone.pending),
      OrderState.verifying => ('Pending Verification', SoftStatusTone.pending),
      OrderState.paid => ('Paid', SoftStatusTone.verified),
    };
    final canPay = state == OrderState.awaiting || state == OrderState.rejected;
    final meta = [
      'Order No. ${order.number}',
      'Issued ${_day(order.assessedAt)}',
      if (canPay && order.dueDate != null) 'Due ${_day(order.dueDate!)}',
    ].join(' · ');

    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SoftIconTile(icon: Icons.receipt_long_outlined, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(application.permitType, style: SoftType.tileTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(application.referenceNumber, style: SoftType.tileSub),
                    const SizedBox(height: 8),
                    SoftStatusPill(label: label, tone: tone),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(meta, style: SoftType.cellLabel.copyWith(fontSize: 12.5)),
          if (last case final item?) ...[
            const SizedBox(height: 10),
            _LastPayment(item: item),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(pesos(order.totalCentavos), style: SoftType.h1.copyWith(fontSize: 22)),
              ),
              SizedBox(
                width: 150,
                child: canPay
                    ? SoftPillButton(
                        label: state == OrderState.rejected ? 'Pay Again' : 'Pay Now',
                        icon: Icons.payments_outlined,
                        onPressed: onPay,
                      )
                    : SoftPillButton(
                        label: 'Receipt',
                        kind: SoftPillKind.outline,
                        icon: Icons.receipt_long_outlined,
                        onPressed: onReceipt,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The order's most recent payment, in a tinted box: why it was rejected,
/// its receipt, or that it is being checked.
class _LastPayment extends StatelessWidget {
  final _HistoryItem item;
  const _LastPayment({required this.item});

  @override
  Widget build(BuildContext context) {
    final view = item.view;
    final (background, ink) = switch (view.tone) {
      PaymentTone.danger => (SoftColors.dangerSoft, SoftColors.danger),
      PaymentTone.verified => (SoftColors.verifiedSoft, SoftColors.verifiedInk),
      _ => (SoftColors.chipWash, SoftColors.ink),
    };
    final lead = switch (view.label) {
      'Rejected' => 'Your last payment was rejected. ',
      'Paid' => 'Paid. ',
      _ => 'Payment sent ${_day(item.entry.submittedAt)}. ',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(SoftRadius.sm)),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: lead, style: const TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(text: view.detail),
        ]),
        style: SoftType.body.copyWith(color: ink, fontSize: 13.5, height: 1.4),
      ),
    );
  }
}

/// One payment in the history.
class _HistoryRow extends StatelessWidget {
  final _HistoryItem item;
  final VoidCallback onTap;
  const _HistoryRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final view = item.view;
    final (background, ink, icon) = switch (view.tone) {
      PaymentTone.verified => (SoftColors.verifiedSoft, SoftColors.verifiedInk, Icons.check_rounded),
      PaymentTone.danger => (SoftColors.dangerSoft, SoftColors.danger, Icons.close_rounded),
      PaymentTone.pending => (SoftColors.pendingCream, SoftColors.pendingInk, Icons.schedule_rounded),
      PaymentTone.neutral => (SoftColors.chipWash, SoftColors.muted, Icons.remove_rounded),
    };
    final method = item.entry.method == 'Onsite' ? 'Paid at the Treasurer’s Office' : item.entry.method;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: background, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(item.application.permitType, style: SoftType.tileTitle.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pesos(item.entry.amountCentavos),
                        style: SoftType.cellValue.copyWith(fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SoftStatusPill(label: view.label, tone: _toneOf(view.tone)),
                  const SizedBox(height: 6),
                  Text(
                    '${item.application.referenceNumber} · $method · Ref. ${item.entry.referenceNumber}',
                    style: SoftType.cellLabel.copyWith(fontSize: 12.5),
                  ),
                  if (view.detail.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(children: [
                        if (view.label == 'Rejected') const TextSpan(text: 'Why: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: view.detail),
                      ]),
                      style: SoftType.body.copyWith(
                        fontSize: 13,
                        height: 1.4,
                        color: view.tone == PaymentTone.danger ? SoftColors.danger : SoftColors.ink,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatch extends StatelessWidget {
  final VoidCallback onShowAll;
  const _NoMatch({required this.onShowAll});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Nothing matches this filter.', style: SoftType.body),
          const SizedBox(height: 8),
          TextButton(onPressed: onShowAll, child: const Text('Show all')),
        ],
      ),
    );
  }
}
