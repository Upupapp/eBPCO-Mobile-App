import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../services/businesses_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
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

  Future<void> _register() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterBusinessScreen()));
    if (mounted) context.read<BusinessesService>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final businesses = context.watch<BusinessesService>();

    return SoftPageScaffold(
      title: 'My Businesses',
      actions: [SoftBarAction(icon: Icons.add_rounded, tooltip: 'Register a Business', onPressed: _register)],
      body: RefreshIndicator(
        onRefresh: () => context.read<BusinessesService>().refresh(),
        child: businesses.loading && businesses.businesses.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : businesses.businesses.isEmpty && businesses.error != null
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      SoftEmptyCard(businesses.error!),
                      const SizedBox(height: 16),
                      SoftPillButton(
                        label: 'Try again',
                        kind: SoftPillKind.outline,
                        icon: Icons.refresh_rounded,
                        onPressed: () => context.read<BusinessesService>().refresh(),
                      ),
                    ],
                  )
                : businesses.businesses.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      const SoftEmptyCard('No businesses yet.'),
                      const SizedBox(height: 16),
                      SoftPillButton(label: 'Register a Business', icon: Icons.add_rounded, onPressed: _register),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    itemCount: businesses.businesses.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BusinessRow(business: businesses.businesses[i]),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SoftIconTile(icon: Icons.storefront_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(business.name, style: SoftType.tileTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text('${business.category} · ${business.barangay}', style: SoftType.tileSub),
                const SizedBox(height: 8),
                SoftStatusPill(label: business.status, tone: business.isActive ? SoftStatusTone.verified : SoftStatusTone.neutral),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: SoftColors.chevron),
        ],
      ),
    );
  }
}
