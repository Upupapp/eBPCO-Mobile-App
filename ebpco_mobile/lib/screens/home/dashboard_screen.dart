import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../services/applications_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/status_badge.dart';
import '../applications/application_detail_screen.dart';
import '../applications/my_applications_screen.dart';
import '../business/business_list_screen.dart';
import '../payments/payments_list_screen.dart';
import '../permits/permit_catalog_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ApplicationsService>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final apps = context.watch<ApplicationsService>();
    final firstName = session.profile?.firstName ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<ApplicationsService>().refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl, 120),
            children: [
              Text('Welcome back,', style: AppTypography.body),
              Text(firstName.isEmpty ? 'Citizen' : firstName, style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Applications', value: '${apps.applications.length}')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      label: 'Needs Action',
                      value: '${apps.awaitingActionCount}',
                      highlight: apps.awaitingActionCount > 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SoftCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PermitCatalogScreen())),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.primary100, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.add_circle_outline, color: AppColors.primary600),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Apply for a Permit', style: AppTypography.cardTitle),
                          Text('Browse permit types and start a new application', style: AppTypography.cardSubtitle),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.gray400),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.store_outlined,
                      label: 'My Businesses',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BusinessListScreen())),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.payments_outlined,
                      label: 'Payments',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentsListScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Applications', style: AppTypography.h3),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyApplicationsScreen())),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (apps.loading && apps.applications.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (apps.applications.isEmpty)
                SoftCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Text('No applications yet. Tap "Apply for a Permit" to start your first one.', style: AppTypography.body, textAlign: TextAlign.center),
                    ),
                  ),
                )
              else
                ...apps.applications.take(4).map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ApplicationRow(application: a),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _StatCard({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: highlight ? AppColors.primary50 : AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypography.h1.copyWith(color: highlight ? AppColors.primary600 : AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary600, size: 22),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}

class _ApplicationRow extends StatelessWidget {
  final ApplicationSummary application;
  const _ApplicationRow({required this.application});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApplicationDetailScreen(applicationId: application.id))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(application.permitType, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(application.referenceNumber, style: AppTypography.cardSubtitle),
              ],
            ),
          ),
          StatusBadge(label: application.applicantStatus),
        ],
      ),
    );
  }
}
