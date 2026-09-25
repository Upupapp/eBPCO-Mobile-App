import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/service_catalog_mock.dart';
import '../../models/evacuation_center.dart';
import '../../services/mock_catalog.dart';
import '../../theme/soft_widget.dart';
import '../../utils/teresa_rizal_seal.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../catalog/sakuna_catalog_screen.dart';
import '../home/root_shell.dart';
import '../shared/detail_chrome.dart';
import 'evacuation_center_detail_screen.dart';

/// Citizen Emergency hub. Hotlines, incident reporting, and a sample
/// evacuation preview. No distance and no nearest ranking: centers in the
/// signed-in profile barangay come first, then the rest by name.
class SakunaScreen extends StatelessWidget {
  const SakunaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: SoftColors.page,
      appBar: AppBar(
        backgroundColor: SoftColors.page,
        surfaceTintColor: SoftColors.page,
        automaticallyImplyLeading: false,
        leading: canPop
            ? const BackButton()
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Services',
                onPressed: () => RootShell.closeService(context),
              ),
        title: const Text('Emergency'),
        actions: const [AlertsAction()],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: const [
          _OfficeRow(),
          SizedBox(height: 16),
          Text('Emergency', style: SoftType.h1),
          SizedBox(height: 4),
          Text(
            'Hotlines, incident reporting, and evacuation centers.',
            style: CatalogType.tileSub,
          ),
          SizedBox(height: 16),
          _UrgentHelpCard(),
          SizedBox(height: 16),
          _ReportButton(),
          SizedBox(height: 20),
          _EvacuationCentersSection(),
        ],
      ),
    );
  }
}

class _OfficeRow extends StatelessWidget {
  const _OfficeRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            teresaRizalSealAsset,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MDRRMO · Teresa, Rizal', style: CatalogType.metaInk),
              Text('Disaster & emergency', style: CatalogType.tileTitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _UrgentHelpCard extends StatelessWidget {
  const _UrgentHelpCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Urgent help', style: CatalogType.tileTitle)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SoftColors.dangerSoft,
                  borderRadius: BorderRadius.circular(SoftRadius.pill),
                ),
                child: const Text('911 · MDRRMO', style: CatalogType.bandTitle),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text('National & municipal lines', style: CatalogType.meta),
          const SizedBox(height: 8),
          const _HotlineRow(
            title: ServiceCatalogMock.emergencyNumber,
            subtitle: 'National emergency',
            callable: true,
          ),
          const Divider(height: 1),
          const _HotlineRow(
            title: ServiceCatalogMock.mdrrmoName,
            subtitle: ServiceCatalogMock.mdrrmoNumber,
            callable: false,
          ),
        ],
      ),
    );
  }
}

class _HotlineRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool callable;

  const _HotlineRow({
    required this.title,
    required this.subtitle,
    required this.callable,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: callable
          ? () => launchUrl(Uri.parse('tel:${ServiceCatalogMock.emergencyNumber}'))
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SoftColors.dangerSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.call_rounded, size: 16, color: SoftColors.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CatalogType.tileTitle),
                  Text(subtitle, style: CatalogType.meta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  const _ReportButton();

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Report an incident',
      variant: AppButtonVariant.danger,
      fullWidth: true,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SakunaCatalogScreen()),
      ),
    );
  }
}

class _EvacuationCentersSection extends StatefulWidget {
  const _EvacuationCentersSection();

  @override
  State<_EvacuationCentersSection> createState() => _EvacuationCentersSectionState();
}

class _EvacuationCentersSectionState extends State<_EvacuationCentersSection> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final home = evacuationProfileBarangay(context);
    final centers = [...MockCatalog.evacuationCenters]
      ..sort((a, b) => EvacuationCenter.compareByProfileBarangay(a, b, home));
    final shown = _all ? centers : centers.take(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Evacuation centers', style: SoftType.section)),
            TextButton(
              key: const Key('evac-see-all'),
              onPressed: () => setState(() => _all = !_all),
              child: Text(_all ? 'Show less' : 'See all', style: CatalogType.link),
            ),
          ],
        ),
        for (final center in shown)
          _CenterCard(
            center: center,
            inProfileBarangay: EvacuationCenter.barangayMatchesProfile(center.barangay, home),
          ),
      ],
    );
  }
}

class _CenterCard extends StatelessWidget {
  final EvacuationCenter center;
  final bool inProfileBarangay;
  const _CenterCard({required this.center, required this.inProfileBarangay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EvacuationCenterDetailScreen(center: center),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SoftColors.dangerSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.map_outlined, size: 18, color: SoftColors.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(center.name, style: CatalogType.tileTitle),
                  const SizedBox(height: 2),
                  Text(
                    'Open · ${center.barangay} · Capacity ${center.totalCapacity}',
                    style: CatalogType.meta,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      const _SampleCenterChip(),
                      if (inProfileBarangay)
                        const DetailChip(
                          label: 'Your barangay',
                          background: SoftColors.chipWash,
                          foreground: SoftColors.muted,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
