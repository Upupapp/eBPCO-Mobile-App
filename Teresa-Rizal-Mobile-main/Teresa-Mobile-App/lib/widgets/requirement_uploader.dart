import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/attachment.dart';
import '../models/master_file_document.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/soft_widget.dart';
import 'soft_flow_scaffold.dart';
import '../utils/cross_platform_image.dart';
import '../utils/protected_action.dart';
import '../utils/requirement_document_type.dart';

/// One requirement's own upload section — the standard per-requirement
/// attachment architecture shared by every Dokyu and Tulong service (see
/// docs on the "each requirement gets its own uploader" change). Reuses the
/// app's existing camera/gallery/document permission handling
/// (`pickImageProtected`/`pickDocumentProtected` from
/// utils/protected_action.dart) rather than a new implementation, and never
/// touches the resident's Master File itself — the parent screen owns that
/// (via [onAttachNew]/[onUseExisting]) so this widget stays a pure,
/// stateless presentation of "this one requirement's current attachment".
class RequirementUploader extends StatelessWidget {
  final RequirementInfo requirement;
  final Attachment? attachment;

  /// The calling module's own identity color (Teresa, Rizal blue for Dokyu,
  /// purple for Tulong) — used for the upload prompt and the "Replace"
  /// action, so both modules share this widget's structure/behavior
  /// without becoming visually identical. Status colors (emerald for an
  /// existing-document offer, rose for Remove) stay fixed regardless of
  /// module, since those represent outcome, not brand identity.
  final Color accent;

  /// The resident's existing Master File document for this requirement's
  /// document type, if any — null when there's nothing to offer for reuse.
  /// Ignored once [attachment] is set (the attached state always takes
  /// priority over the reuse offer).
  final MasterFileDocument? existingMasterDoc;

  /// A brand-new file was picked (camera/gallery/document) — the parent is
  /// responsible for both attaching it locally and saving it to the Master
  /// File (see MasterFileService.saveOrUpdate).
  final ValueChanged<Attachment> onAttachNew;

  /// The resident chose to reuse [existingMasterDoc] — the parent copies
  /// its `attachment` onto this requirement locally; the Master File itself
  /// is never re-written for a reuse.
  final VoidCallback onUseExisting;

  final VoidCallback onRemove;

  const RequirementUploader({
    super.key,
    required this.requirement,
    required this.attachment,
    required this.accent,
    required this.existingMasterDoc,
    required this.onAttachNew,
    required this.onUseExisting,
    required this.onRemove,
  });

  Future<void> _pickNew(BuildContext context) async {
    final source = await showModalBottomSheet<_UploadSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoftColors.clear,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: SoftIme.bottom(ctx)),
        child: _UploadSourceSheet(requirementLabel: requirement.label),
      ),
    );
    if (source == null || !context.mounted) return;

    switch (source) {
      case _UploadSource.camera:
      case _UploadSource.gallery:
        final file = await pickImageProtected(
          context,
          source: source == _UploadSource.camera ? ImageSource.camera : ImageSource.gallery,
        );
        if (file == null || !context.mounted) return;
        final bytes = await file.readAsBytes();
        onAttachNew(
          Attachment(
            id: 'att-${DateTime.now().microsecondsSinceEpoch}',
            fileName: file.name,
            category: AttachmentCategoryX.fromExtension(file.name.split('.').last),
            sizeBytes: bytes.length,
            localPath: file.path,
            bytes: bytes,
            addedAt: DateTime.now(),
            documentTypeLabel: requirement.label,
          ),
        );
      case _UploadSource.document:
        final result = await pickDocumentProtected(context, allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png']);
        if (result == null || result.files.isEmpty) return;
        final f = result.files.single;
        if (f.bytes == null) return;
        onAttachNew(
          Attachment(
            id: 'att-${DateTime.now().microsecondsSinceEpoch}',
            fileName: f.name,
            category: AttachmentCategoryX.fromExtension(f.extension ?? ''),
            sizeBytes: f.size,
            localPath: f.path,
            bytes: f.bytes,
            addedAt: DateTime.now(),
            documentTypeLabel: requirement.label,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  requirement.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SoftColors.ink),
                ),
              ),
              if (!requirement.isRequired)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(999)),
                  child: const Text(
                    'Optional',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: SoftColors.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!requirement.requiresUpload)
            const _StaffProcessNote()
          else if (attachment != null)
            _AttachedTile(
              attachment: attachment!,
              accent: accent,
              onView: () => _openViewer(context),
              onReplace: () => _pickNew(context),
              onRemove: onRemove,
            )
          else if (existingMasterDoc != null)
            _ExistingDocumentPrompt(
              masterDoc: existingMasterDoc!,
              onUseExisting: onUseExisting,
              onUploadNew: () => _pickNew(context),
            )
          else
            _UploadPrompt(label: requirement.label, accent: accent, onTap: () => _pickNew(context)),
        ],
      ),
    );
  }

  void _openViewer(BuildContext context) {
    final a = attachment!;
    if (a.category != AttachmentCategory.image) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AttachmentImageViewer(title: requirement.label, attachment: a),
      ),
    );
  }
}

enum _UploadSource { camera, gallery, document }

class _UploadSourceSheet extends StatelessWidget {
  final String requirementLabel;
  const _UploadSourceSheet({required this.requirementLabel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        child: Material(
          color: SoftColors.white,
          borderRadius: BorderRadius.circular(SoftRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      requirementLabel,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: SoftColors.ink),
                    ),
                  ),
                ),
                _option(context, Icons.photo_camera_outlined, 'Take Photo', _UploadSource.camera),
                _option(context, Icons.image_outlined, 'Choose Image', _UploadSource.gallery),
                _option(context, Icons.description_outlined, 'Choose File / PDF', _UploadSource.document),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.close_rounded, color: AppColors.rose600),
                  title: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.rose600)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _option(BuildContext context, IconData icon, String label, _UploadSource source) {
    return ListTile(
      leading: Icon(icon, color: AppColors.brand600),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: () => Navigator.pop(context, source),
    );
  }
}

class _UploadPrompt extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _UploadPrompt({required this.label, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          color: accent.withValues(alpha: 0.08),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file_outlined, color: accent, size: 20),
            const SizedBox(height: 4),
            // Requirement-specific, not a generic "Upload Document" — see
            // this widget's own doc comment. No maxLines/overflow set, so a
            // long requirement name wraps onto a second line instead of
            // being truncated or overflowing.
            Text(
              'Upload $label',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Existing document found" — offers the resident's Master File match for
/// this requirement's document type instead of forcing another upload (see
/// this project's own document-reuse rule). Never guesses on its own
/// whether the match is still appropriate (no expiry/validity tracking
/// exists yet to check) — always leaves the choice to the resident.
class _ExistingDocumentPrompt extends StatelessWidget {
  final MasterFileDocument masterDoc;
  final VoidCallback onUseExisting;
  final VoidCallback onUploadNew;

  const _ExistingDocumentPrompt({required this.masterDoc, required this.onUseExisting, required this.onUploadNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.folder_copy_outlined, size: 15, color: AppColors.emerald700),
              SizedBox(width: 6),
              // Flexible — this card's available width was previously only
              // ever exercised inside NewRequestScreen (Dokyu); reusing the
              // same per-requirement uploaders inside
              // ServiceRequestWizardScreen's own (slightly narrower) page
              // padding overflowed this unwrapped Text on the right.
              Flexible(
                child: Text(
                  'Existing document found',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emerald700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            masterDoc.attachment.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SoftColors.ink),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onUploadNew,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('Upload New Document', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onUseExisting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald500,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Use Existing Document', style: TextStyle(fontSize: 12, color: SoftColors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The compact attached state — thumbnail/icon, filename, category + size,
/// then View (image attachments only — this demo has no PDF/DOCX renderer)
/// / Replace / Remove.
class _AttachedTile extends StatelessWidget {
  final Attachment attachment;
  final Color accent;
  final VoidCallback onView;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  const _AttachedTile({
    required this.attachment,
    required this.accent,
    required this.onView,
    required this.onReplace,
    required this.onRemove,
  });

  ({Color bg, Color fg, IconData icon}) get _style => switch (attachment.category) {
    AttachmentCategory.image => (bg: AppColors.brand50, fg: AppColors.brand500, icon: Icons.image_outlined),
    AttachmentCategory.pdf => (bg: AppColors.rose50, fg: AppColors.rose600, icon: Icons.picture_as_pdf_outlined),
    AttachmentCategory.docx => (bg: AppColors.blue50, fg: AppColors.blue700, icon: Icons.description_outlined),
    AttachmentCategory.video => (bg: AppColors.rose50, fg: AppColors.rose600, icon: Icons.videocam_outlined),
    AttachmentCategory.other => (bg: AppColors.slate100, fg: SoftColors.muted, icon: Icons.insert_drive_file_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final isImage = attachment.category == AttachmentCategory.image;
    final provider = isImage ? pickedFileImageProvider(bytes: attachment.bytes, path: attachment.localPath) : null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: provider != null
                    ? Image(image: provider, width: 44, height: 44, fit: BoxFit.cover)
                    : Container(width: 44, height: 44, color: s.bg, child: Icon(s.icon, size: 19, color: s.fg)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SoftColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${attachment.category.shortLabel} • ${attachment.readableSize} • Uploaded',
                      style: const TextStyle(fontSize: 11, color: SoftColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (isImage) _actionButton('View', onView, color: accent),
              if (isImage) const SizedBox(width: 14),
              _actionButton('Replace', onReplace, color: accent),
              const SizedBox(width: 14),
              _actionButton('Remove', onRemove, color: AppColors.rose600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap, {required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}

/// Shown instead of an upload control for a requirement that isn't
/// something the resident attaches a file for — see RequirementInfo
/// .requiresUpload's own doc comment for the two cases this covers
/// (an internal staff/office process, or descriptive record-identifying
/// text already captured elsewhere). Still names the requirement in its
/// own card above this note (never hidden), just never offers a button
/// that would ask the resident to upload something nobody expects them to.
class _StaffProcessNote extends StatelessWidget {
  const _StaffProcessNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: SoftColors.muted),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Handled by our staff during processing — no document to upload here.',
              style: TextStyle(fontSize: 12, color: SoftColors.muted, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentImageViewer extends StatelessWidget {
  final String title;
  final Attachment attachment;
  const _AttachmentImageViewer({required this.title, required this.attachment});

  @override
  Widget build(BuildContext context) {
    final provider = pickedFileImageProvider(bytes: attachment.bytes, path: attachment.localPath);
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
              ? InteractiveViewer(minScale: 1, maxScale: 4, child: Image(image: provider, fit: BoxFit.contain))
              : const Text('Preview not available.', style: TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }
}
