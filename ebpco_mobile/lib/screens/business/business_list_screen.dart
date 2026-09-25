import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../services/businesses_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';
import 'business_detail_screen.dart';
import 'register_business_screen.dart';

class BusinessListScreen extends StatefulWidget {
  const BusinessListScreen({super.key});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BusinessesService>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final businesses = context.watch<BusinessesService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Businesses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const RegisterBusinessScreen()))
                .then((_) => context.read<BusinessesService>().refresh()),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<BusinessesService>().refresh(),
          child: businesses.loading && businesses.businesses.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : businesses.businesses.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxxl),
                          child: Column(
                            children: [
                              Text('No businesses yet.', style: AppTypography.body, textAlign: TextAlign.center),
                              const SizedBox(height: AppSpacing.lg),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (_) => const RegisterBusinessScreen()))
                                    .then((_) => context.read<BusinessesService>().refresh()),
                                child: const Text('Register a Business'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 24),
                      itemCount: businesses.businesses.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _BusinessRow(business: businesses.businesses[i]),
                      ),
                    ),
        ),
      ),
    );
  }
}

class _BusinessRow extends StatelessWidget {
  final Business business;
  const _BusinessRow({required this.business});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BusinessDetailScreen(businessId: business.id))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(business.name, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text('${business.category} · ${business.barangay}', style: AppTypography.cardSubtitle),
              ],
            ),
          ),
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
    );
  }
}
