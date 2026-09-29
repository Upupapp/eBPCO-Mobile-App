import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/permit_catalog.dart';
import '../../widgets/soft_card.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import 'application_wizard_screen.dart';

/// Ported grouping from `permit.model.ts`'s `PERMIT_TYPE_GROUPS` — see that
/// file's own comment on why this is the mirror, not a re-derivation.
class PermitCatalogScreen extends StatelessWidget {
  const PermitCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftPageScaffold(
      title: 'Permit Services',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text('Apply for a Permit', style: SoftType.h1),
          const SizedBox(height: 6),
          Text('Browse permit types and start a new application.', style: SoftType.body.copyWith(fontSize: 15)),
          const SizedBox(height: 18),
          const BfpClearanceNotice(),
          const SizedBox(height: 22),
          for (final group in permitTypeGroups) ...[
            SoftSectionHeader(title: group.label),
            SoftGroupedList(rows: [
              for (final type in group.types)
                SoftListRow(
                  icon: Icons.description_outlined,
                  title: type,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApplicationWizardScreen(permitType: type))),
                ),
            ]),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}

/// The FSEC and the FSIC used to be permit types in this catalog. The BFP
/// issues both through its own system, BFP-FSIS; filing them with the
/// Municipality sent citizens to the wrong office. They are uploaded as
/// documents instead, and the Fire Safety stage verifies them.
class BfpClearanceNotice extends StatelessWidget {
  const BfpClearanceNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: SoftColors.primaryWash,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fire Safety clearances come from the BFP', style: SoftType.tileTitle.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'The Fire Safety Evaluation Clearance (FSEC) for a building permit and the Fire Safety Inspection '
            'Certificate (FSIC) for occupancy are issued by the Bureau of Fire Protection, not by the Municipality. '
            'Apply for them on BFP-FSIS or at the Castilla Fire Station, then upload the one you receive with your '
            'Building Permit or Certificate of Occupancy application.',
            style: SoftType.body.copyWith(color: SoftColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            'Permits with nothing for the BFP to check, like a Fencing or Sign Permit, skip the Fire Safety stage.',
            style: SoftType.body,
          ),
          const SizedBox(height: 12),
          SoftPillButton(
            label: 'Open BFP-FSIS',
            kind: SoftPillKind.outline,
            icon: Icons.open_in_new_rounded,
            onPressed: () => launchUrl(Uri.parse(bfpFsisUrl), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}
