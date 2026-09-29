import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/models.dart';
import '../theme/soft_widget.dart';
import 'soft_action_sheet.dart';
import 'soft_card.dart';
import 'status_badge.dart';

/// Where a requirement's file comes from.
enum AttachSource { device, library }

/// The documents a citizen can reuse: everything from `GET /documents/me`
/// except a quarantined file (its content is refused) and an earlier version
/// the office sent back that has since been replaced.
List<DocumentEntry> reusableDocuments(List<DocumentEntry> documents) =>
    documents.where((d) => !d.quarantined && d.supersededByDocumentId == null).toList();

/// Files uploaded for the same requirement first, then newest first.
List<DocumentEntry> orderForRequirement(List<DocumentEntry> documents, String requirementCode) {
  int rank(DocumentEntry d) => d.requirementCode == requirementCode ? 0 : 1;
  return [...documents]
    ..sort((a, b) {
      final byRequirement = rank(a) - rank(b);
      return byRequirement != 0 ? byRequirement : b.uploadedAt.compareTo(a.uploadedAt);
    });
}

/// The portal's "or reuse — a document you've already uploaded…" picker as a
/// sheet. Each file shows when it was uploaded, the one thing the app knows
/// about its age, so an old clearance is not reused without seeing that.
Future<DocumentEntry?> showDocumentLibrarySheet(
  BuildContext context, {
  required List<DocumentEntry> documents,
  required String forLabel,
  required String requirementCode,
}) {
  final ordered = orderForRequirement(documents, requirementCode);
  return showModalBottomSheet<DocumentEntry>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SoftSheetHandle(),
              const SizedBox(height: 18),
              Text('My Documents', style: SoftType.section.copyWith(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Reuse a file for $forLabel. Check the upload date — an older document may no longer be valid.',
                style: SoftType.body.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: ordered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: SoftColors.line),
                  itemBuilder: (_, i) => _LibraryRow(
                    doc: ordered[i],
                    onTap: () => Navigator.of(sheetContext).pop(ordered[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Replacing an attached file: a new one from the phone, or one on file.
Future<AttachSource?> showAttachSourceSheet(BuildContext context, {required String forLabel}) =>
    showSoftActionSheet<AttachSource>(
      context,
      title: 'Replace file',
      subtitle: forLabel,
      actions: const [
        SoftSheetAction(
          value: AttachSource.device,
          icon: Icons.upload_file_rounded,
          title: 'Upload a new file',
          subtitle: 'PDF, JPG, JPEG or PNG from this phone',
        ),
        SoftSheetAction(
          value: AttachSource.library,
          icon: Icons.folder_outlined,
          title: 'Choose from My Documents',
          subtitle: 'A file you have uploaded before',
        ),
      ],
    );

class _LibraryRow extends StatelessWidget {
  final DocumentEntry doc;
  final VoidCallback onTap;
  const _LibraryRow({required this.doc, required this.onTap});

  IconData get _icon {
    final type = doc.contentType.toLowerCase();
    if (type.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (type.startsWith('image/')) return Icons.image_outlined;
    return Icons.insert_drive_file_outlined;
  }

  String get _uploaded {
    final parsed = DateTime.tryParse(doc.uploadedAt);
    return parsed == null ? doc.uploadedAt : DateFormat('MMM d, y').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIconTile(icon: _icon, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: SoftType.tileTitle.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('Uploaded $_uploaded · as ${doc.label}', style: SoftType.tileSub),
                  if (doc.usedOnLabel != null) ...[
                    const SizedBox(height: 2),
                    Text('Used on ${doc.usedOnLabel}', style: SoftType.cellLabel),
                  ],
                  if (doc.reviewStatus != null) ...[
                    const SizedBox(height: 8),
                    StatusBadge(label: doc.reviewStatus!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
