import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/catalog_item.dart';
import '../../models/request_filters.dart';
import '../../models/service_request.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/soft_widget.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../widgets/active_filter_chip.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/teresa_rizal_drawer.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/new_request_fab.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_flow_scaffold.dart';
import '../../widgets/status_chip.dart';
import '../catalog/dokyu_catalog_screen.dart';
import '../catalog/tulong_catalog_screen.dart';
import '../home/root_shell.dart';
import 'request_detail_screen.dart';

// This screen's own FAB-clearance constants — not navbar geometry. Pair
// with `MediaQuery.paddingOf(context).bottom`. RootShell does not extend
// the body under the bar, so that inset is usually zero here; the gap
// below is this screen's own breathing room above the bar.
const double _kFloatingElementGap = 16.0;
const double _kFloatingActionButtonHeight =
    56.0; // Material's standard extended-FAB footprint.

/// Shared list+tracker screen used by both Dokyu (Document Requests) and
/// Tulong (Assistance Requests) — same shape as the Web Admin's
/// document-requests.blade.php / assistance-requests.blade.php (All /
/// Active / Done tabs, reference number, type, status), plus search,
/// filtering (Barangay/LGU, Type, Status, Date, Sort — behind a "Filter"
/// button so the main screen stays clean, per the filtering spec), active
/// filter chips, and sharing the currently filtered results via the
/// device's native share sheet. One implementation parameterized by
/// [category]/[catalog] rather than two near-identical screens, per the
/// "reuse before duplicating" rule this project follows throughout its
/// own component library.
class RequestListScreen extends StatefulWidget {
  final ServiceCategory category;
  final String title;
  final String subtitle;
  final List<CatalogItem> catalog;
  final Color accent;
  final IconData icon;

  const RequestListScreen({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.catalog,
    required this.accent,
    required this.icon,
  });

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  int _tab = 0; // 0 = active, 1 = done
  RequestFilters _filters = const RequestFilters();

  Future<void> _openFilters(List<ServiceRequest> categoryRequests) async {
    final typeOptions = categoryRequests.map((r) => r.typeName).toSet().toList()
      ..sort();
    final statusOptions = categoryRequests.map((r) => r.status).toSet().toList()
      ..sort();
    final result = await showModalBottomSheet<RequestFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initial: _filters,
        typeOptions: typeOptions,
        statusOptions: statusOptions,
        accent: widget.accent,
      ),
    );
    if (result != null && mounted) setState(() => _filters = result);
  }

  Future<void> _shareFilteredResults(List<ServiceRequest> visible) async {
    if (visible.isEmpty) return;
    final lines = <String>[
      '${widget.title} — ${_filters.isActive ? "Filtered Results" : "My Requests"} (${visible.length})',
      '',
      for (final r in visible.take(20))
        '• ${r.typeName} — ${r.status} (${r.referenceNumber})',
      if (visible.length > 20) '…and ${visible.length - 20} more',
    ];
    await SharePlus.instance.share(
      ShareParams(
        text: lines.join('\n'),
        subject: '${widget.title} — Teresa, Rizal',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<RequestsService>();
    final categoryRequests = requests.byCategory(widget.category);
    final activeAll = categoryRequests
        .where((r) => !AppStatusX.fromLabel(r.status).isDone)
        .toList();
    final doneAll = categoryRequests
        .where((r) => AppStatusX.fromLabel(r.status).isDone)
        .toList();
    final tabSource = _tab == 0 ? activeAll : doneAll;
    final visible = _filters.apply(tabSource);

    final canPop = Navigator.of(context).canPop();
    return SoftFlowScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      backTooltip: canPop ? 'Back' : 'Services',
      resizeToAvoidBottomInset: true,
      onBack: canPop
          ? () => Navigator.of(context).pop()
          : () => RootShell.closeService(context),
      actions: [
        SoftCircleButton(
          icon: Icons.menu_rounded,
          tooltip: 'Menu',
          onPressed: () => showTeresaRizalMenu(context),
        ),
        const AlertsAction(),
      ],
      // Nested in RootShell, which owns the bar and does not extend the
      // body under it. The extra bottom gap keeps the FAB off the bar
      // when a parent does publish a bottom inset.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + _kFloatingElementGap,
        ),
        child: NewRequestFab(
          accent: widget.accent,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => widget.category == ServiceCategory.dokyu
                  ? const DokyuCatalogScreen()
                  : const TulongCatalogScreen(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedTabs(
              labels: [
                'Active (${activeAll.length})',
                'Done (${doneAll.length})',
              ],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
              accent: widget.accent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openFilters(categoryRequests),
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: _filters.isActive
                          ? widget.accent
                          : SoftColors.muted,
                    ),
                    label: Text(
                      _filters.isActive
                          ? 'Filter (${_filters.activeCount})'
                          : 'Filter',
                      style: TextStyle(
                        color: _filters.isActive
                            ? widget.accent
                            : SoftColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _filters.isActive
                            ? widget.accent
                            : SoftColors.line,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: visible.isEmpty
                      ? null
                      : () => _shareFilteredResults(visible),
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: 'Share results',
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: SoftColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_filters.isActive) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_filters.search.trim().isNotEmpty)
                            ActiveFilterChip(
                              label: '"${_filters.search.trim()}"',
                              accent: widget.accent,
                              onRemove: () => setState(
                                () => _filters = _filters.copyWith(search: ''),
                              ),
                            ),
                          if (_filters.scope != null)
                            ActiveFilterChip(
                              label: _filters.scope!.label,
                              accent: widget.accent,
                              onRemove: () => setState(
                                () => _filters = _filters.copyWith(
                                  clearScope: true,
                                ),
                              ),
                            ),
                          if (_filters.typeName != null)
                            ActiveFilterChip(
                              label: _filters.typeName!,
                              accent: widget.accent,
                              onRemove: () => setState(
                                () => _filters = _filters.copyWith(
                                  clearTypeName: true,
                                ),
                              ),
                            ),
                          if (_filters.status != null)
                            ActiveFilterChip(
                              label: _filters.status!,
                              accent: widget.accent,
                              onRemove: () => setState(
                                () => _filters = _filters.copyWith(
                                  clearStatus: true,
                                ),
                              ),
                            ),
                          if (_filters.dateRange != null)
                            ActiveFilterChip(
                              label: 'Date range',
                              accent: widget.accent,
                              onRemove: () => setState(
                                () => _filters = _filters.copyWith(
                                  clearDateRange: true,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _filters = const RequestFilters()),
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${visible.length} result${visible.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: SoftColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? _EmptyStateArea(
                    icon: widget.icon,
                    title: _filters.isActive
                        ? 'No requests match your current filters.'
                        : (_tab == 0
                              ? 'No active requests'
                              : 'No completed requests yet'),
                    description: _filters.isActive
                        ? null
                        : (_tab == 0
                              ? 'Tap "New Request" to get started.'
                              : null),
                    action: _filters.isActive
                        ? OutlinedButton(
                            onPressed: () => setState(
                              () => _filters = const RequestFilters(),
                            ),
                            child: const Text('Clear Filters'),
                          )
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: visible.length,
                    itemBuilder: (context, i) => _RequestTile(
                      request: visible[i],
                      accent: widget.accent,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The "no requests yet" / "no results match your filters" state, biased
/// upward so it clears the floating New Request button and the navbar
/// beneath it — shared by Dokyu and Tulong through RequestListScreen, so
/// fixing the positioning here keeps both consistent automatically.
///
/// Reserves `MediaQuery.paddingOf(context).bottom` plus the FAB's own
/// footprint and a couple of visual gaps below
/// the centered content — the same clearance math the FAB's own position
/// already uses (see RequestListScreen's `floatingActionButton`), so both
/// stay in sync if that ever changes.
///
/// Uses `ConstrainedBox(minHeight: ...)` + `SingleChildScrollView` (not a
/// plain `Padding` + `Center`) specifically so short screens degrade by
/// becoming scrollable instead of the reserved bottom padding silently
/// eating all the available room and pushing the content past the FAB
/// anyway — every part of the empty state stays reachable regardless of
/// screen height.
class _EmptyStateArea extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const _EmptyStateArea({
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final bottomReserve =
        MediaQuery.paddingOf(context).bottom +
        _kFloatingElementGap +
        _kFloatingActionButtonHeight +
        _kFloatingElementGap;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState(
                  icon: icon,
                  title: title,
                  description: description,
                  action: action,
                ),
                SizedBox(height: bottomReserve),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  final ServiceRequest request;
  final Color accent;
  const _RequestTile({required this.request, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RequestDetailScreen(requestId: request.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.typeName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: SoftColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Flexible, not a bare fixed-size child: a longer status
                // label ("Under Verification") plus a longer typeName
                // together can exceed a narrow phone's card width, and a
                // non-flex StatusChip here reports its own unconstrained
                // natural width to this Row regardless of the internal
                // wrapping StatusChip already does for itself — see
                // StatusChip's own doc comment on the same class of bug.
                Flexible(
                  child: StatusChip(
                    status: AppStatusX.fromLabel(request.status),
                    small: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              request.referenceNumber,
              style: const TextStyle(
                fontSize: 12,
                color: SoftColors.muted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.office,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SoftColors.muted,
                    ),
                  ),
                ),
                _ScopeTag(office: request.office),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flexible: a spaceBetween Row sizes each child to its own
                // natural width — on a narrow phone "Submitted M/D/YYYY"
                // plus "Track >" can together exceed the card width (a
                // pre-existing overflow this task's new demo-seeded
                // requests newly exposed, since Dokyu/Tulong are no longer
                // always empty at narrow widths). Same fix pattern as
                // PostActionButton's own label elsewhere in this app.
                Flexible(
                  child: Text(
                    'Submitted ${_fmt(request.submittedAt)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: SoftColors.muted,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Track',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 15, color: accent),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';
}

/// Small "Barangay" / "LGU" badge next to the office line — makes the
/// Barangay-vs-Municipality distinction visually understandable on every
/// tile, not just inside the filter sheet.
class _ScopeTag extends StatelessWidget {
  final String office;
  const _ScopeTag({required this.office});

  @override
  Widget build(BuildContext context) {
    final scope = scopeOfOffice(office);
    final isBarangay = scope == RequestScope.barangay;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isBarangay ? AppColors.emerald50 : AppColors.indigo50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isBarangay ? 'Barangay' : 'LGU',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isBarangay ? AppColors.emerald700 : AppColors.indigo700,
        ),
      ),
    );
  }
}
