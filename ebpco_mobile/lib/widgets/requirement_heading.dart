import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../theme/soft_widget.dart';
import 'soft_card.dart';
import 'soft_chrome.dart';

/// The top of one document's card in the wizard's Documents step: whether it
/// is attached, its name, what it is, and — only on a document that needs
/// paper too — a "Hard copies: n" chip with the LGU's note under it word for
/// word (ebpco-api 071). Required or If applicable is said once by the group
/// it sits in, and "online only" once above the list ([onlineOnlyNote]), as
/// the portal's wizard and Requirements window do (design review I13, 4 Nov
/// 2026). Also each row of the Requirements sheet, where nothing is attached
/// yet ([showAttachState] false: a plain document mark, not an upload one).
class RequirementHeading extends StatelessWidget {
  const RequirementHeading({
    super.key,
    required this.doc,
    required this.attached,
    this.showAttachState = true,
  });

  final RequirementDoc doc;
  final bool attached;
  final bool showAttachState;

  @override
  Widget build(BuildContext context) {
    final copies = hardCopiesText(doc.hardCopies);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIconTile(
              icon: !showAttachState
                  ? Icons.description_outlined
                  : attached
                      ? Icons.check_rounded
                      : Icons.upload_file_rounded,
              background: attached ? SoftColors.verifiedSoft : SoftColors.primarySoft,
              foreground: attached ? SoftColors.verifiedInk : SoftColors.primary,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Text(doc.label, style: SoftType.tileTitle),
              ),
            ),
          ],
        ),
        if (doc.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(doc.description, style: SoftType.body),
        ],
        if (copies != null) ...[
          const SizedBox(height: 8),
          SoftStatusPill(label: copies, tone: SoftStatusTone.pending),
          if (doc.hardCopyNote case final note?) ...[
            const SizedBox(height: 4),
            Text(note, style: SoftType.cellLabel),
          ],
        ],
      ],
    );
  }
}
