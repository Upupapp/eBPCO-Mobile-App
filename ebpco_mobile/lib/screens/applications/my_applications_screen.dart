import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../services/applications_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/status_badge.dart';
import 'application_detail_screen.dart';

const _filters = ['All', 'Draft', 'Submitted', 'Under Review', 'Payment Verification', 'Approved', 'Ready for Release', 'Rejected'];

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ApplicationsService>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final apps = context.watch<ApplicationsService>();
    final filtered = _filter == 'All' ? apps.applications : apps.applications.where((a) => a.applicantStatus == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Applications')),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final selected = f == _filter;
                  return ChoiceChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.primary100,
                    labelStyle: AppTypography.caption.copyWith(color: selected ? AppColors.primary700 : AppColors.gray600, fontWeight: FontWeight.w600),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: selected ? AppColors.primary500 : AppColors.borderMedium),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<ApplicationsService>().refresh(),
                child: apps.loading && apps.applications.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.xxxl),
                                child: Text('No applications here.', style: AppTypography.body, textAlign: TextAlign.center),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 24),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _Row(application: filtered[i]),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final ApplicationSummary application;
  const _Row({required this.application});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApplicationDetailScreen(applicationId: application.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(application.permitType, style: AppTypography.cardTitle)),
              StatusBadge(label: application.applicantStatus),
            ],
          ),
          const SizedBox(height: 4),
          Text(application.referenceNumber, style: AppTypography.cardSubtitle),
          if (application.dateSubmitted != null) ...[
            const SizedBox(height: 4),
            Text('Submitted ${application.dateSubmitted!.substring(0, 10)}', style: AppTypography.caption),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Started ${application.updatedAt.substring(0, 10)}', style: AppTypography.caption),
            ),
        ],
      ),
    );
  }
}
