import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';

class ServiceEntry {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const ServiceEntry({required this.icon, required this.title, required this.subtitle, required this.onTap});
}

/// The design reference's services sheet (drag handle, title, subtitle,
/// rows with soft icon tiles), listing eBPCO's own services. Opened by the
/// nav bar's raised center control.
Future<void> showServicesSheet(BuildContext context, List<ServiceEntry> services) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: SoftColors.line, borderRadius: BorderRadius.circular(SoftRadius.pill)),
              ),
            ),
            const SizedBox(height: 18),
            Text('Services', style: SoftType.section.copyWith(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Apply for permits and manage what you have filed.', style: SoftType.body.copyWith(fontSize: 15)),
            const SizedBox(height: 14),
            for (final s in services)
              InkWell(
                borderRadius: BorderRadius.circular(SoftRadius.md),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  s.onTap();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(color: SoftColors.primarySoft, borderRadius: BorderRadius.circular(SoftRadius.md)),
                        child: Icon(s.icon, color: SoftColors.primary, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title, style: SoftType.tileTitle.copyWith(fontSize: 17)),
                            const SizedBox(height: 2),
                            Text(s.subtitle, style: SoftType.tileSub.copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
