import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';

/// Mirrors citizen/directory.blade.php — municipal offices with real names
/// and contact numbers copied from that file's inline $offices array.
class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Government Directory')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('Municipal Offices', style: AppTypography.subsectionLabel),
          const SizedBox(height: AppSpacing.md),
          ...MockCatalog.directoryOffices.map((o) => _OfficeTile(name: o.$1, head: o.$2, contact: o.$3)),
        ],
      ),
    );
  }
}

class _OfficeTile extends StatelessWidget {
  final String name;
  final String head;
  final String contact;
  const _OfficeTile({required this.name, required this.head, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.navy900, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.account_balance_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(head, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            InkWell(
              onTap: () => launchUrl(Uri.parse('tel:$contact')),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: AppColors.emerald50, shape: BoxShape.circle),
                child: const Icon(Icons.call_outlined, size: 16, color: AppColors.emerald700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
