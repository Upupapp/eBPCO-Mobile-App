/// Resolves each catalog requirement line (still a plain `String` on
/// `CatalogItem.requirements` — see mock_catalog.dart) into a stable
/// document-type identity, without touching the catalog data itself. The
/// catalog's own requirement text is already the one place each service's
/// requirements are authored/sourced from real government forms (see
/// docs/DOKYU_TULONG_FORM_AUDIT.md) — deriving from it here, rather than
/// hand-tagging every one of the ~80 requirement lines across every
/// service, keeps that sourced data untouched and gives one place to fix
/// or extend the canonical-document mapping later.
library;

import '../models/attachment.dart';

/// One catalog requirement, resolved — [label] is exactly the catalog's own
/// text (shown to the citizen unchanged); [documentType] is the stable key
/// used to look up/save a matching document in the resident's Master File
/// (see services/master_file_service.dart); [isRequired] is false only when
/// the requirement's own wording already says it's conditional (e.g. "...,
/// if applicable"), since no catalog item currently carries a separate
/// required/optional flag.
class RequirementInfo {
  final String label;
  final String documentType;
  final bool isRequired;

  /// False for a requirement line that isn't actually something the
  /// resident uploads — see [_isNotResidentUploaded]'s own doc comment.
  /// Still shown in the requirements list (the catalog's own wording is
  /// never hidden), just never rendered with an upload control, and never
  /// counted as "missing" by submission validation.
  final bool requiresUpload;

  const RequirementInfo({
    required this.label,
    required this.documentType,
    required this.isRequired,
    this.requiresUpload = true,
  });
}

List<RequirementInfo> resolveRequirements(List<String> requirements) => requirements
    .map(
      (label) => RequirementInfo(
        label: label,
        documentType: documentTypeFor(label),
        isRequired: !_isOptionalPhrasing(label),
        requiresUpload: !_isNotResidentUploaded(label),
      ),
    )
    .toList();

final _optionalPhrasing = RegExp(r'if applicable|if available|if any', caseSensitive: false);

bool _isOptionalPhrasing(String label) => _optionalPhrasing.hasMatch(label);

/// Two distinct reasons a catalog requirement line is never something a
/// resident attaches a file for, found during the Dokyu/Tulong requirement-
/// upload standardization audit:
///
/// 1. An internal LGU staff/office process, not a document at all — e.g.
///    "Brief interview / social case study with the Municipal Social
///    Welfare and Development Office" (dokyu_indigency, tulong_financial).
///    Forcing an upload button here would ask citizens to submit a file for
///    something municipal staff actually conducts.
/// 2. Descriptive/identifying information about the record being
///    requested — e.g. "Details of the record being requested" (mcro_live_
///    birth, dokyu_marriage_certificate_copy) — not a physical document,
///    and where a formSpec exists, already captured there as real text
///    fields (see dokyu_marriage_certificate_copy's husbandFullName/
///    wifeFullName/dateOfMarriage). Adding an "upload" card for a sentence
///    of prose would be nonsensical; the free-text Purpose field is where
///    this belongs when no formSpec captures it.
final _notResidentUploadedPhrasing = RegExp(
  r'brief interview|case study|case assessment|details of the record being requested',
  caseSensitive: false,
);

bool _isNotResidentUploaded(String label) => _notResidentUploadedPhrasing.hasMatch(label);

/// The same physical document is asked for, worded almost identically, by
/// many different services (a valid ID above all) — matched here so a
/// document uploaded once can be offered again elsewhere (see
/// MasterFileService.findByType). Anything not recognized falls back to a
/// slug of its own label: still a stable key (the catalog's wording for a
/// given requirement doesn't change at runtime), just not shared with a
/// differently-worded requirement that happens to mean the same thing.
String documentTypeFor(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('valid government-issued id')) return 'valid_government_id';
  if (lower.contains('cedula')) return 'cedula';
  if (lower.contains('barangay business clearance')) return 'barangay_business_clearance';
  if (lower.contains('barangay clearance')) return 'barangay_clearance';
  if (lower.contains('barangay certification')) return 'barangay_certification';
  if (lower.contains('dti') && lower.contains('sec')) return 'dti_or_sec_registration';
  if (lower.contains('locational') || lower.contains('zoning')) return 'zoning_clearance';
  if (lower.contains('sanitary permit')) return 'sanitary_permit';
  if (lower.contains('proof of residency') || lower.contains('proof of barangay residency')) return 'proof_of_residency';
  if (lower.contains('solo parent id')) return 'solo_parent_id';
  if (lower.contains('psa birth certificate')) return 'psa_birth_certificate';
  if (lower.contains('2x2')) return 'id_photo_2x2';
  if (lower.contains('birth certificate')) return 'birth_certificate';
  return _slugify(label);
}

String _slugify(String label) {
  final cleaned = label
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return cleaned.isEmpty ? 'document' : cleaned;
}

/// Copies [source] (a resident's existing Master File document, offered via
/// "Use Existing Document" — see widgets/requirement_uploader.dart) onto a
/// *different* requirement slot, re-tagging [Attachment.documentTypeLabel]
/// to [requirementLabel] rather than leaving whatever label it was
/// originally uploaded under. The same document type can be worded
/// differently across services (e.g. "One (1) valid government-issued ID"
/// vs. "Valid Government-Issued ID") — without this, a reused attachment on
/// a submitted request could carry a stale label that doesn't match the
/// requirement it was actually used to satisfy here, breaking the
/// permanent requirement<->attachment mapping a later Web Admin needs (see
/// this feature's own requirement-mapping guarantee). Every other field is
/// the real, unmodified file — this never re-encodes or duplicates it.
Attachment attachmentForReuse(Attachment source, {required String requirementLabel}) => Attachment(
  id: source.id,
  fileName: source.fileName,
  category: source.category,
  sizeBytes: source.sizeBytes,
  localPath: source.localPath,
  bytes: source.bytes,
  remoteUrl: source.remoteUrl,
  addedAt: source.addedAt,
  documentTypeLabel: requirementLabel,
);
