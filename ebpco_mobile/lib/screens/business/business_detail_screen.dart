import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../services/businesses_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';
import 'edit_business_screen.dart';

class BusinessDetailScreen extends StatefulWidget {
  final String businessId;
  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  bool _busy = false;

  Future<void> _toggleActive(Business business) async {
    setState(() => _busy = true);
    try {
      if (business.isActive) {
        await CitizenApi.instance.deactivateBusiness(business.id);
      } else {
        await CitizenApi.instance.reactivateBusiness(business.id);
      }
      if (!mounted) return;
      await context.read<BusinessesService>().refresh();
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.citizenMessage)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = context.watch<BusinessesService>().businesses.where((b) => b.id == widget.businessId);
    final business = matches.isEmpty ? null : matches.first;

    if (business == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(business.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => EditBusinessScreen(business: business)))
                .then((_) => context.read<BusinessesService>().refresh()),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(business.name, style: AppTypography.h2)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: business.isActive ? AppColors.success100 : AppColors.gray100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          business.status,
                          style: AppTypography.caption.copyWith(color: business.isActive ? AppColors.successText : AppColors.gray600, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(business.category, style: AppTypography.body),
                  const Divider(height: AppSpacing.xxl),
                  _Row('Address', '${business.street}, ${business.barangay}, ${business.city}, ${business.province}'),
                  _Row('DTI/SEC No.', business.registrationNumber),
                  _Row('Date Registered', business.dateRegistered.substring(0, 10)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: _busy ? null : () => _toggleActive(business),
              style: OutlinedButton.styleFrom(
                foregroundColor: business.isActive ? AppColors.danger : AppColors.success,
                side: BorderSide(color: business.isActive ? AppColors.danger100 : AppColors.success100),
              ),
              child: Text(business.isActive ? 'Deactivate Business' : 'Reactivate Business'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
