import 'package:flutter/material.dart';

import '../data/catalog_gate_policy.dart';
import '../data/service_catalog_mock.dart';
import '../theme/app_haptics.dart';
import '../theme/soft_widget.dart';
import 'service_launcher_menu.dart';
import 'soft_flow_scaffold.dart';

/// Services entry. Dokyu, Tulong, and Emergency. The medium haptic fires
/// after the sheet is mounted.
class ServicesSheet {
  ServicesSheet._();

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<ServiceLauncherTarget> onService,
    CatalogGatePolicy? policy,
  }) {
    if (!context.mounted) return Future.value();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoftColors.clear,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: SoftIme.bottom(ctx)),
        child: ServicesSheetPanel(onService: onService, policy: policy),
      ),
    );
  }
}

class ServicesSheetPanel extends StatefulWidget {
  final ValueChanged<ServiceLauncherTarget> onService;
  final CatalogGatePolicy? policy;

  const ServicesSheetPanel({
    super.key,
    required this.onService,
    this.policy,
  });

  @override
  State<ServicesSheetPanel> createState() => _ServicesSheetPanelState();
}

class _ServicesSheetPanelState extends State<ServicesSheetPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppHaptics.medium();
    });
  }

  void _closeThen(VoidCallback action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  @override
  Widget build(BuildContext context) {
    final policy = widget.policy ?? currentCatalogGatePolicy();
    final browse = policy == CatalogGatePolicy.browseThenSheet;
    return Material(
      color: SoftColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(SoftRadius.xl)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: ListView(
          key: const ValueKey('services-sheet'),
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: SoftColors.line,
                  borderRadius: BorderRadius.circular(SoftRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Services', style: SoftType.section),
            if (browse) ...[
              const SizedBox(height: 4),
              const Text(ServiceCatalogMock.sheetSubline, style: SoftType.body),
            ],
            const SizedBox(height: 12),
            _Row(
              sheetKey: const ValueKey('services-sheet-Dokyu'),
              icon: Icons.description_outlined,
              title: 'Dokyu',
              subtitle: '${ServiceCatalogMock.dokyu.length} documents',
              background: SoftColors.blueSoft,
              foreground: SoftColors.blue,
              onTap: () => _closeThen(() => widget.onService(ServiceLauncherTarget.dokyu)),
            ),
            _Row(
              sheetKey: const ValueKey('services-sheet-Tulong'),
              icon: Icons.volunteer_activism_outlined,
              title: 'Tulong',
              subtitle: '${ServiceCatalogMock.tulong.length} programs',
              background: SoftColors.tulongSoft,
              foreground: SoftColors.tulongInk,
              onTap: () => _closeThen(() => widget.onService(ServiceLauncherTarget.tulong)),
            ),
            _Row(
              sheetKey: const ValueKey('services-sheet-Emergency'),
              icon: Icons.shield_outlined,
              title: 'Emergency',
              subtitle: '${ServiceCatalogMock.sakuna.length} incident types · 911',
              background: SoftColors.dangerSoft,
              foreground: SoftColors.danger,
              onTap: () => _closeThen(() => widget.onService(ServiceLauncherTarget.emergency)),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(ServiceCatalogMock.sheetHonesty, style: CatalogType.meta),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Key sheetKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _Row({
    required this.sheetKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.md),
        child: InkWell(
          key: sheetKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(SoftRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(SoftRadius.sm),
                    ),
                    child: Icon(icon, color: foreground, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: SoftType.name),
                        Text(subtitle, style: SoftType.cellLabel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
