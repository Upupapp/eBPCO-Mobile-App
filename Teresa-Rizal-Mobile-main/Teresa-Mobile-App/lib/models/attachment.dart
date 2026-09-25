import 'dart:typed_data';

enum AttachmentCategory { image, pdf, docx, video, other }

extension AttachmentCategoryX on AttachmentCategory {
  /// Matches the Web Admin's file-picker category tags (IMG/PDF/DOCX/VID) —
  /// see resources/views/components/ui/file-picker.blade.php.
  String get shortLabel => switch (this) {
        AttachmentCategory.image => 'IMG',
        AttachmentCategory.pdf => 'PDF',
        AttachmentCategory.docx => 'DOCX',
        AttachmentCategory.video => 'VID',
        AttachmentCategory.other => 'FILE',
      };

  static AttachmentCategory fromExtension(String ext) {
    final e = ext.toLowerCase().replaceAll('.', '');
    if (['jpg', 'jpeg', 'png', 'heic', 'webp'].contains(e)) return AttachmentCategory.image;
    if (e == 'pdf') return AttachmentCategory.pdf;
    if (['doc', 'docx'].contains(e)) return AttachmentCategory.docx;
    if (['mp4', 'mov'].contains(e)) return AttachmentCategory.video;
    return AttachmentCategory.other;
  }
}

/// A file/photo attached to a request. `localPath` is the file the user
/// picked on-device (real image_picker/file_picker output — not a
/// placeholder) — but on Flutter Web that "path" is a blob: URL, or absent
/// entirely, so it must never be fed into `dart:io`'s `File()`. Preview
/// (and any future upload) goes through [bytes] instead — see
/// `lib/utils/cross_platform_image.dart`, the one place platform-specific
/// handling lives.
///
/// [bytes] is intentionally excluded from [toJson] — this is a
/// frontend-only demo with no backend to re-fetch a real file from, so a
/// picked attachment's preview is only guaranteed to survive the current
/// session, not an app restart. After restoring from SharedPreferences,
/// `bytes` is null and the UI falls back to a category icon instead of a
/// thumbnail (see `AttachmentPicker`), rather than attempting to read a
/// path that may no longer resolve to anything. This shape is otherwise
/// backend-ready: once a real API exists, [bytes] is uploaded and
/// [remoteUrl] takes over as the source of truth for re-display.
class Attachment {
  final String id;
  final String fileName;
  final AttachmentCategory category;
  final int sizeBytes;
  final String? localPath;
  final Uint8List? bytes;
  final String? remoteUrl;
  final DateTime addedAt;
  final String documentTypeLabel;

  Attachment({
    required this.id,
    required this.fileName,
    required this.category,
    required this.sizeBytes,
    this.localPath,
    this.bytes,
    this.remoteUrl,
    required this.addedAt,
    required this.documentTypeLabel,
  });

  String get readableSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'category': category.name,
        'sizeBytes': sizeBytes,
        'localPath': localPath,
        'remoteUrl': remoteUrl,
        'addedAt': addedAt.toIso8601String(),
        'documentTypeLabel': documentTypeLabel,
      };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'],
        fileName: json['fileName'],
        category: AttachmentCategory.values
            .firstWhere((c) => c.name == json['category'], orElse: () => AttachmentCategory.other),
        sizeBytes: json['sizeBytes'],
        localPath: json['localPath'],
        remoteUrl: json['remoteUrl'],
        addedAt: DateTime.parse(json['addedAt']),
        documentTypeLabel: json['documentTypeLabel'],
      );
}
