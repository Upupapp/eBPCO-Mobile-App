import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/service_catalog_mock.dart';
import '../../models/evacuation_center.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/app_card.dart';
import '../shared/detail_chrome.dart';

/// Signed-in profile barangay, or null for a guest and when no session
/// is provided. There is no GPS fallback.
String? evacuationProfileBarangay(BuildContext context) {
  final raw = context.watch<CitizenSessionService?>()?.account?.barangay.trim();
  if (raw == null || raw.isEmpty) return null;
  return raw;
}

/// One evacuation center. No distance, no nearest badge, and no live contact.
/// A center in the signed-in profile barangay shows a "Your barangay" chip.
class EvacuationCenterDetailScreen extends StatelessWidget {
  final EvacuationCenter center;

  const EvacuationCenterDetailScreen({super.key, required this.center});

  @override
  Widget build(BuildContext context) {
    final inProfileBarangay = EvacuationCenter.barangayMatchesProfile(
      center.barangay,
      evacuationProfileBarangay(context),
    );
    return Scaffold(
      backgroundColor: SoftColors.page,
      appBar: AppBar(
        backgroundColor: SoftColors.page,
        surfaceTintColor: SoftColors.page,
        title: const Text('Center detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SoftColors.cyanSoft,
              borderRadius: BorderRadius.circular(SoftRadius.lg),
            ),
            child: const Icon(Icons.map_outlined, size: 36, color: SoftColors.blue),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _SampleCenterChip(),
              const _OpenChip(),
              if (inProfileBarangay)
                const DetailChip(
                  label: 'Your barangay',
                  background: SoftColors.chipWash,
                  foreground: SoftColors.muted,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(center.name, style: SoftType.h1),
          const SizedBox(height: 4),
          Text('${center.barangay}, Teresa, Rizal', style: CatalogType.tileSub),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _FactCard(label: 'Barangay', value: center.barangay)),
              const SizedBox(width: 10),
              Expanded(
                child: _FactCard(
                  label: 'Capacity',
                  value: '${center.totalCapacity} / ${center.totalCapacity}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const AppCard(
            child: Row(
              children: [
                Icon(Icons.call_rounded, color: SoftColors.blue, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact', style: CatalogType.tileTitle),
                      Text(ServiceCatalogMock.mdrrmoNumber, style: CatalogType.meta),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SoftColors.blueSoft,
              borderRadius: BorderRadius.circular(SoftRadius.lg),
            ),
            child: const Text(ServiceCatalogMock.evacHonesty, style: CatalogType.note),
          ),
        ],
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  final String label;
  final String value;
  const _FactCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: CatalogType.meta),
          const SizedBox(height: 4),
          Text(value, style: CatalogType.tileTitle),
        ],
      ),
    );
  }
}

class _SampleCenterChip extends StatelessWidget {
  const _SampleCenterChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: SoftColors.sampleWash,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
      ),
      child: const Text('Sample center', style: CatalogType.sample),
    );
  }
}

class _OpenChip extends StatelessWidget {
  const _OpenChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
      ),
      child: Text(
        'Open',
        style: CatalogType.metaInk.copyWith(color: AppColors.emerald700),
      ),
    );
  }
}
