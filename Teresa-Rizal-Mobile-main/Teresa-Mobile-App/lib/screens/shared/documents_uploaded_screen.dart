import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/master_file_document.dart';
import '../../services/citizen_session_service.dart';
import '../../services/master_file_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/cross_platform_image.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/segmented_tabs.dart';

/// Resident-facing history/library of every document uploaded through a
/// Dokyu or Tulong requirement uploader (see widgets/requirement_uploader.dart)
/// — read-only, no delete. Distinct from the Master File (see
/// MasterFileDocument's own doc comment): the Master File is the reusable
/// "offer this again" canonical copy per document type, one entry per type;
/// this screen instead lists every document a resident has ever uploaded
/// through the app, exactly as it happened, and reads from the very same
/// MasterFileService store without duplicating or reinterpreting its data —
/// no second storage system, per this feature's own scope.
class DocumentsUploadedScreen extends StatefulWidget {
  const DocumentsUploadedScreen({super.key});

  @override
  State<DocumentsUploadedScreen> createState() => _DocumentsUploadedScreenState();
}

class _DocumentsUploadedScreenState extends State<DocumentsUploadedScreen> {
  int _tab = 0; // 0 = All, 1 = Dokyu, 2 = Tulong

  @override
  Widget build(BuildContext context) {
    final accountId = context.watch<CitizenSessionService>().account?.id;
    final documents = accountId == null
        ? const <MasterFileDocument>[]
        : context.watch<MasterFileService>().documentsFor(accountId);

    final filtered = switch (_tab) {
      1 => documents.where((d) => d.origin == 'Dokyu').toList(),
      2 => documents.where((d) => d.origin == 'Tulong').toList(),
      // documentsFor() returns an unmodifiable list — .toList() here makes
      // a fresh, sortable copy, same as the two branches above already do.
      _ => documents.toList(),
    }..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Documents Uploaded')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Documents you’ve uploaded through Dokyu and Tulong requests.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.lg),
              SegmentedTabs(
                labels: const ['All', 'Dokyu', 'Tulong'],
                selectedIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: filtered.isEmpty
                    ? ListView(
                        children: const [
                          EmptyState(
                            icon: Icons.folder_open_outlined,
                            title: 'No documents uploaded yet',
                            description: 'Documents you upload while submitting a Dokyu or Tulong request will '
                                'appear here.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _DocumentCard(document: filtered[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final MasterFileDocument document;
  const _DocumentCard({required this.document});

  ({Color bg, Color fg, IconData icon}) get _style => switch (document.attachment.category) {
    AttachmentCategory.image => (bg: AppColors.brand50, fg: AppColors.brand500, icon: Icons.image_outlined),
    AttachmentCategory.pdf => (bg: AppColors.rose50, fg: AppColors.rose600, icon: Icons.picture_as_pdf_outlined),
    AttachmentCategory.docx => (bg: AppColors.blue50, fg: AppColors.blue700, icon: Icons.description_outlined),
    AttachmentCategory.video => (bg: AppColors.rose50, fg: AppColors.rose600, icon: Icons.videocam_outlined),
    AttachmentCategory.other => (bg: AppColors.slate100, fg: AppColors.slate500, icon: Icons.insert_drive_file_outlined),
  };

  bool get _isDokyu => document.origin == 'Dokyu';

  void _openViewer(BuildContext context) {
    final provider = pickedFileImageProvider(bytes: document.attachment.bytes, path: document.attachment.localPath);
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _DocumentViewer(title: document.label, provider: provider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final isImage = document.attachment.category == AttachmentCategory.image;
    final canPreview =
        isImage && pickedFileImageProvider(bytes: document.attachment.bytes, path: document.attachment.localPath) != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: canPreview ? () => _openViewer(context) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(s.icon, size: 20, color: s.fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.label,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    document.attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _tag(document.origin, _isDokyu ? AppColors.brand600 : AppColors.purple700),
                      if (document.serviceName != null) _tag(document.serviceName!, AppColors.slate600),
                      Text(
                        '${document.attachment.category.shortLabel} · ${DateFormat('MMM d, y').format(document.uploadedAt)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (canPreview) const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// Same simple InteractiveViewer pattern as every other in-app document/ID
/// viewer (see RequirementUploader's own _AttachmentImageViewer,
/// GovernmentIdViewer). [provider] is null when this document's bytes
/// weren't persisted across an app restart (see Attachment's own doc
/// comment on why `bytes` is excluded from JSON) — shown as a plain
/// message instead of crashing.
class _DocumentViewer extends StatelessWidget {
  final String title;
  final ImageProvider? provider;
  const _DocumentViewer({required this.title, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        title: Text(title),
      ),
      body: SafeArea(
        child: Center(
          child: provider != null
              ? InteractiveViewer(minScale: 1, maxScale: 4, child: Image(image: provider!, fit: BoxFit.contain))
              : const Text('Preview not available.', style: TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }
}
