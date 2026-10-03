import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../services/applications_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../../widgets/status_badge.dart';
import 'application_detail_screen.dart';

/// One chip for every status a citizen sees on a row, the same tabs as the
/// citizen portal (QA TC-35, 2026-10-03: Completed, Cancelled and Revision
/// Required had none). Each names the words on the badges it lists; null is
/// every application.
const Map<String, Set<String>?> _filterStatuses = {
  'All': null,
  'Draft': {'Draft'},
  'Submitted': {'Submitted', 'Received'},
  'Under Review': {'Document Verification', 'Under Evaluation'},
  'Revision Required': {'Revision Required'},
  'Payment': {'Assessed', 'Payment Submitted', 'Payment Under Verification', 'Payment Verified', 'For Approval'},
  'Approved': {'Approved', 'Permit Generated'},
  'Ready for Release': {'Ready for Release'},
  'Released': {'Released'},
  'Completed': {'Completed'},
  'Rejected': {'Rejected'},
  'Cancelled': {'Cancelled'},
  'Expired': {'Expired'},
};

final _filters = _filterStatuses.keys.toList();

/// Whether [application] is listed under the chip named [filter].
bool inApplicationFilter(ApplicationSummary application, String filter) {
  final statuses = _filterStatuses[filter];
  return statuses == null || statuses.contains(application.lifecycleStatus);
}

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  /// Asks the (kept-alive) Applications tab to show [filter] — the tab keeps
  /// whatever chip was last picked across tab switches, so a link that means
  /// "every application", like the dashboard's "See all", must say so rather
  /// than land wherever the citizen last left it.
  static void showFilter(String filter) {
    _requestedFilter.value = null;
    _requestedFilter.value = filter;
  }

  static final _requestedFilter = ValueNotifier<String?>(null);

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  String _filter = 'All';
  final _chips = ScrollController();

  @override
  void initState() {
    super.initState();
    MyApplicationsScreen._requestedFilter.addListener(_onFilterRequested);
    _onFilterRequested();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ApplicationsService>().refresh());
  }

  @override
  void dispose() {
    MyApplicationsScreen._requestedFilter.removeListener(_onFilterRequested);
    _chips.dispose();
    super.dispose();
  }

  void _onFilterRequested() {
    final requested = MyApplicationsScreen._requestedFilter.value;
    if (requested == null || !_filters.contains(requested)) return;
    if (mounted) setState(() => _filter = requested);
    // Bring the requested chip into view — "All" sits at the very start, and
    // the row may have been scrolled to a filter near the end.
    if (requested == _filters.first && _chips.hasClients) _chips.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final apps = context.watch<ApplicationsService>();
    final filtered = apps.applications.where((a) => inApplicationFilter(a, _filter)).toList();
    // Expired is a chip only once something has expired; the rest always show.
    final chips = _filters
        .where((f) => f != 'Expired' || f == _filter || apps.applications.any((a) => inApplicationFilter(a, f)))
        .toList();

    return SoftPageScaffold(
      title: 'My Applications',
      underNav: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              controller: _chips,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = chips[i];
                final count = apps.applications.where((a) => inApplicationFilter(a, f)).length;
                return SoftFilterChip(label: '$f ($count)', selected: f == _filter, onTap: () => setState(() => _filter = f));
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<ApplicationsService>().refresh(),
              child: apps.loading && apps.applications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? ListView(
                          padding: EdgeInsets.fromLTRB(20, 8, 20, SoftPageScaffold.navClearance(context)),
                          children: [
                            SoftEmptyCard(
                              apps.error != null && apps.applications.isEmpty
                                  ? apps.error!
                                  : _filter == 'All'
                                      ? 'No applications yet. Start one from Services.'
                                      : 'No $_filter applications.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(20, 4, 20, SoftPageScaffold.navClearance(context)),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _Row(application: filtered[i]),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final ApplicationSummary application;
  const _Row({required this.application});

  @override
  Widget build(BuildContext context) {
    final date = application.dateSubmitted != null
        ? 'Submitted ${application.dateSubmitted!.substring(0, 10)}'
        : 'Started ${application.updatedAt.substring(0, 10)}';
    return SoftCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApplicationDetailScreen(applicationId: application.id))),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SoftIconTile(icon: Icons.description_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(application.permitType, style: SoftType.tileTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(application.displayReference, style: SoftType.tileSub),
                const SizedBox(height: 2),
                Text(date, style: SoftType.cellLabel),
                const SizedBox(height: 10),
                StatusBadge(label: application.statusLabel),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Icon(Icons.chevron_right_rounded, color: SoftColors.chevron),
          ),
        ],
      ),
    );
  }
}
