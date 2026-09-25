import 'attachment.dart';

/// One entry in a resident's Master File — the central, per-account store
/// of documents the citizen has already uploaded somewhere in the app
/// (Dokyu today; Personal Information/Tulong/manual uploads are additional
/// origins the same store already supports). Keyed by [documentType] (see
/// utils/requirement_document_type.dart) so a later requirement asking for
/// the same kind of document, even on a completely different service, can
/// offer this one for reuse instead of forcing another upload.
///
/// At most one entry exists per (account, documentType) — uploading a
/// newer copy of the same document type updates this entry in place
/// (see MasterFileService.saveOrUpdate) rather than accumulating history,
/// since nothing in this project tracks document versions/expiry yet and a
/// resident only ever has one "current" copy of a given document. This
/// never affects a request that has already been submitted: `ServiceRequest
/// .attachments` holds its own copied `Attachment` objects (see that
/// model's own doc comment), never a live reference back here.
class MasterFileDocument {
  final String id;
  final String documentType;
  final String label;
  final Attachment attachment;
  final DateTime uploadedAt;

  /// Where this document was first captured — 'Dokyu', 'Tulong', 'Personal
  /// Information', or 'Manual'. Display-only, never used for matching.
  final String origin;

  /// The specific catalog service/application this was uploaded through
  /// (e.g. "Barangay Clearance", "Educational Assistance") — distinct from
  /// [origin], which only ever names the broader module. Null for a
  /// document with no single originating service (e.g. uploaded directly
  /// through Personal Information). See the Documents Uploaded screen,
  /// which shows both "Source module" and "Related service/application" as
  /// separate fields.
  final String? serviceName;

  const MasterFileDocument({
    required this.id,
    required this.documentType,
    required this.label,
    required this.attachment,
    required this.uploadedAt,
    required this.origin,
    this.serviceName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'documentType': documentType,
        'label': label,
        'attachment': attachment.toJson(),
        'uploadedAt': uploadedAt.toIso8601String(),
        'origin': origin,
        'serviceName': serviceName,
      };

  factory MasterFileDocument.fromJson(Map<String, dynamic> json) => MasterFileDocument(
        id: json['id'],
        documentType: json['documentType'],
        label: json['label'],
        attachment: Attachment.fromJson(json['attachment']),
        uploadedAt: DateTime.parse(json['uploadedAt']),
        origin: json['origin'] ?? 'Manual',
        serviceName: json['serviceName'],
      );
}
