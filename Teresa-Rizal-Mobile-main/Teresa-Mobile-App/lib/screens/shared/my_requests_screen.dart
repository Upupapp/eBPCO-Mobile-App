import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/status_chip.dart';
import 'request_detail_screen.dart';

/// The signed-in resident's full Dokyu + Tulong request history in one
/// place — derived straight from [RequestsService], never a separate
/// hardcoded list, and scoped to the current account's own `applicantId`
/// so one signed-in resident never sees another's requests (Nicanor never
/// sees Anacleto's, neither sees Perlita's, and so on). Tapping a card opens
/// the same [RequestDetailScreen] every other "Track"/"View" entry point
/// already uses — there is no second detail/tracking implementation.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  int _tab = 0; // 0 = All, 1 = Dokyu, 2 = Tulong

  @override
  Widget build(BuildContext context) {
    final account = context.watch<CitizenSessionService>().account;
    final requests = context.watch<RequestsService>();

    // "All" here means "all Dokyu + Tulong" — Sakuna incident reports are a
    // separate concern (see ServiceCategory.sakunaIncident) not covered by
    // this Dokyu/Tulong service-history screen.
    var mine = requests.all
        .where((r) => r.applicantId == account?.id && r.category != ServiceCategory.sakunaIncident)
        .toList();
    if (_tab == 1) mine = mine.where((r) => r.category == ServiceCategory.dokyu).toList();
    if (_tab == 2) mine = mine.where((r) => r.category == ServiceCategory.tulong).toList();
    mine.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedTabs(
              labels: const ['All', 'Dokyu', 'Tulong'],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: mine.isEmpty
                ? EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: _tab == 0 ? 'No requests yet' : 'No ${_tab == 1 ? 'Dokyu' : 'Tulong'} requests yet',
                    description: 'Your submitted Dokyu and Tulong requests will appear here.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: mine.length,
                    itemBuilder: (context, i) => _MyRequestCard(request: mine[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MyRequestCard extends StatelessWidget {
  final ServiceRequest request;
  const _MyRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final categoryColor = switch (request.category) {
      ServiceCategory.dokyu => AppColors.brand600,
      ServiceCategory.tulong => AppColors.purple700,
      ServiceCategory.sakunaIncident => AppColors.rose600,
      ServiceCategory.unknown => AppColors.slate600,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: request.id))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    request.category.label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: categoryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.typeName,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(status: AppStatusX.fromLabel(request.status), small: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              request.referenceNumber,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Submitted ${_fmt(request.submittedAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            if (request.requiresPayment) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    request.receipt != null ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                    size: 13,
                    color: request.receipt != null ? AppColors.emerald700 : AppColors.amber700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    request.receipt != null ? 'Paid in demo • ${request.fee}' : 'Fee ${request.fee} • Payment pending',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: request.receipt != null ? AppColors.emerald700 : AppColors.amber700,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Track', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: categoryColor)),
                Icon(Icons.chevron_right_rounded, size: 15, color: categoryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';
}
