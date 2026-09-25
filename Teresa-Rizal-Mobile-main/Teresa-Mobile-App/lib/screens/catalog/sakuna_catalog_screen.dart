import 'package:flutter/material.dart';

import '../../data/service_catalog_mock.dart';
import '../../theme/soft_widget.dart';
import 'catalog_chrome.dart';
import 'catalog_gate_sheet.dart';
import 'incident_report_screen.dart';

class SakunaCatalogScreen extends StatefulWidget {
  final bool openGuestGate;
  const SakunaCatalogScreen({super.key, this.openGuestGate = false});

  @override
  State<SakunaCatalogScreen> createState() => _SakunaCatalogScreenState();
}

class _SakunaCatalogScreenState extends State<SakunaCatalogScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.openGuestGate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSakunaGuestGate(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CatalogPage(
      title: 'Report incident',
      pinned: const [Call911Strip()],
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Sakuna · 6 incident types', style: CatalogType.meta),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('What happened?', style: SoftType.h1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.35,
              children: [
                for (final kind in ServiceCatalogMock.sakuna)
                  _Tile(kind: kind),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _HotlineCard(),
          const HonestyNote(
            text: ServiceCatalogMock.sakunaHonesty,
            background: SoftColors.goldSoft,
            icon: Icons.shield_outlined,
            iconColor: SoftColors.endedInk,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final SakunaKind kind;
  const _Tile({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.lg),
      child: InkWell(
        key: Key('sakuna-${kind.id}'),
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        onTap: () => openIncident(context, kind),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: SoftColors.danger, size: 18),
              const Spacer(),
              Text(kind.label, style: CatalogType.tileTitle),
              Text(kind.blurb, style: CatalogType.meta),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotlineCard extends StatelessWidget {
  const _HotlineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.phone_outlined, color: SoftColors.danger),
            title: const Text(ServiceCatalogMock.emergencyNumber, style: CatalogType.tileTitle),
            subtitle: const Text('National emergency hotline', style: CatalogType.meta),
            trailing: TextButton(
              key: const Key('hotline-911'),
              onPressed: () => call911(),
              child: const Text('Call', style: CatalogType.link),
            ),
          ),
          const Divider(height: 1, color: SoftColors.line),
          ListTile(
            leading: const Icon(Icons.phone_outlined, color: SoftColors.disabledInk),
            title: const Text(ServiceCatalogMock.mdrrmoName, style: CatalogType.tileTitle),
            subtitle: const Text(ServiceCatalogMock.mdrrmoNumber, style: CatalogType.meta),
            trailing: const TextButton(
              key: Key('mdrrmo-call'),
              onPressed: null,
              child: Text('Call'),
            ),
          ),
        ],
      ),
    );
  }
}
