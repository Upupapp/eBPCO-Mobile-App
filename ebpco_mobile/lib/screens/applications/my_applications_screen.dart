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

const _filters = ['All', 'Draft', 'Submitted', 'Under Review', 'Payment Verification', 'Approved', 'Ready for Release', 'Rejected'];

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
    final filtered = _filter == 'All' ? apps.applications : apps.applications.where((a) => a.applicantStatus == _filter).toList();

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
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                return SoftFilterChip(label: f, selected: f == _filter, onTap: () => setState(() => _filter = f));
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
                Text(application.referenceNumber, style: SoftType.tileSub),
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
