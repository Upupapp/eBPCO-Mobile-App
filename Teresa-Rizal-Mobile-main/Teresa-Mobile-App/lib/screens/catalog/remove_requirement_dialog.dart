import 'package:flutter/material.dart';

import '../../data/service_catalog_mock.dart';
import '../../theme/soft_widget.dart';
import 'catalog_chrome.dart';

class RemoveRequirementCopy {
  final String title;
  final String body;
  final String fromHakbang;
  final String requirement;
  final String fileName;
  final String fileSize;
  final List<String> bullets;

  const RemoveRequirementCopy({
    required this.title,
    required this.body,
    required this.fromHakbang,
    required this.requirement,
    required this.fileName,
    required this.fileSize,
    required this.bullets,
  });

  static const affidavit = RemoveRequirementCopy(
    title: 'Remove the affidavit?',
    body:
        'You changed "Does the father acknowledge the child?" to No, so this requirement no longer applies.',
    fromHakbang: 'Hakbang 2',
    requirement: 'Affidavit of Acknowledgment / Admission of Paternity',
    fileName: ServiceCatalogMock.affidavitFileName,
    fileSize: ServiceCatalogMock.affidavitFileSize,
    bullets: [
      'The file is removed from this request on this device.',
      'The father\'s name is cleared too. Switch back to Yes to add both again.',
    ],
  );

  static const attendant = RemoveRequirementCopy(
    title: 'Remove the certification?',
    body:
        'You changed the place of birth away from Home, so this requirement no longer applies.',
    fromHakbang: 'Hakbang 3',
    requirement: 'Certification from the birth attendant',
    fileName: ServiceCatalogMock.attendantFileName,
    fileSize: ServiceCatalogMock.attendantFileSize,
    bullets: [
      'The file is removed from this request on this device.',
      'Switch back to Home to add the certification again.',
    ],
  );
}

/// Returns true when the file should be removed.
Future<bool> showRemoveRequirementDialog(
  BuildContext context,
  RemoveRequirementCopy copy,
) async {
  final remove = await showDialog<bool>(
    context: context,
    builder: (ctx) => _RemoveDialog(copy: copy),
  );
  return remove == true;
}

class _RemoveDialog extends StatelessWidget {
  final RemoveRequirementCopy copy;
  const _RemoveDialog({required this.copy});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('remove-requirement-dialog'),
      backgroundColor: SoftColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SoftRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: SoftColors.goldSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_outlined, color: SoftColors.endedInk),
            ),
            const SizedBox(height: 10),
            Text(copy.title, textAlign: TextAlign.center, style: CatalogType.dialogTitle),
            const SizedBox(height: 8),
            Text(copy.body, textAlign: TextAlign.center, style: CatalogType.tileSub),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SoftColors.page,
                borderRadius: BorderRadius.circular(SoftRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Requirement · from ${copy.fromHakbang}', style: CatalogType.meta),
                  const SizedBox(height: 4),
                  Text(copy.requirement, style: CatalogType.tileTitle),
                  const SizedBox(height: 8),
                  const Text('Attached file', style: CatalogType.meta),
                  Text('${copy.fileName} · ${copy.fileSize}', style: CatalogType.note),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final line in copy.bullets)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('· $line', style: CatalogType.meta),
                ),
              ),
            const SizedBox(height: 8),
            CatalogCta(
              label: 'Remove file and continue',
              danger: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep my earlier answer', style: CatalogType.link),
            ),
            const Text(
              ServiceCatalogMock.removeFinePrint,
              textAlign: TextAlign.center,
              style: CatalogType.meta,
            ),
          ],
        ),
      ),
    );
  }
}
