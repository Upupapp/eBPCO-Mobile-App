import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../services/businesses_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import 'edit_business_screen.dart';
import '../../widgets/message_bar.dart';

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(messageBar(business.isActive ? 'Business deactivated. Reactivate it any time from this page.' : 'Business reactivated.'));
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(messageBar(e.citizenMessage));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(Business business) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditBusinessScreen(business: business)));
    if (mounted) context.read<BusinessesService>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final matches = context.watch<BusinessesService>().businesses.where((b) => b.id == widget.businessId);
    final business = matches.isEmpty ? null : matches.first;

    if (business == null) {
      return const SoftPageScaffold(title: 'Business', body: Center(child: CircularProgressIndicator()));
    }

    return SoftPageScaffold(
      title: 'Business',
      actions: [SoftBarAction(icon: Icons.edit_outlined, tooltip: 'Edit', onPressed: () => _edit(business))],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Row(
            children: [
              const SoftIconTile(icon: Icons.storefront_outlined, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name, style: SoftType.h1.copyWith(fontSize: 24)),
                    const SizedBox(height: 2),
                    Text(business.category, style: SoftType.body.copyWith(fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SoftStatusPill(label: business.status, tone: business.isActive ? SoftStatusTone.verified : SoftStatusTone.neutral),
          ),
          const SizedBox(height: 18),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Row('Address', '${business.street}, ${business.barangay}, ${business.city}, ${business.province}'),
                const Divider(height: 1, color: SoftColors.line),
                _Row('DTI/SEC No.', business.registrationNumber),
                const Divider(height: 1, color: SoftColors.line),
                _Row('Date Registered', business.dateRegistered.substring(0, 10)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SoftPillButton(
            label: business.isActive ? 'Deactivate Business' : 'Reactivate Business',
            kind: business.isActive ? SoftPillKind.dangerSoft : SoftPillKind.outline,
            busy: _busy,
            onPressed: _busy ? null : () => _toggleActive(business),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SoftType.cellLabel.copyWith(fontSize: 13)),
          const SizedBox(height: 2),
          Text(value, style: SoftType.cellValue),
        ],
      ),
    );
  }
}
