import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../theme/soft_widget.dart';
import 'soft_card.dart';
import 'soft_chrome.dart';

/// The top of one document's card in the wizard's Documents step: whether it
/// is attached, its name, Required or If applicable, what it is, and whether
/// paper copies are needed too ("Online only, no hard copy", or "Hard copies:
/// n" with the LGU's note; ebpco-api 071). The same order as the portal's.
class RequirementHeading extends StatelessWidget {
  const RequirementHeading({super.key, required this.doc, required this.required, required this.attached});

  final RequirementDoc doc;

  /// Needed before submitting: the server's own flag, or the wizard's (the
  /// copy of a paper permit on that path).
  final bool required;
  final bool attached;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIconTile(
              icon: attached ? Icons.check_rounded : Icons.upload_file_rounded,
              background: attached ? SoftColors.verifiedSoft : SoftColors.primarySoft,
              foreground: attached ? SoftColors.verifiedInk : SoftColors.primary,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.label, style: SoftType.tileTitle),
                  const SizedBox(height: 6),
                  SoftStatusPill(
                    label: requirementTag(required: required),
                    tone: required ? SoftStatusTone.danger : SoftStatusTone.neutral,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (doc.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(doc.description, style: SoftType.body),
        ],
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              doc.hardCopies > 0 ? Icons.description_outlined : Icons.cloud_done_outlined,
              size: 16,
              color: SoftColors.muted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hardCopiesText(doc.hardCopies),
                    style: SoftType.cellLabel.copyWith(fontWeight: FontWeight.w600, color: SoftColors.ink),
                  ),
                  if (doc.hardCopyNote case final note?) Text(note, style: SoftType.cellLabel),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
