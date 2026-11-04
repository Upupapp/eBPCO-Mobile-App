import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/citizen_api.dart';
import '../../domain/applying_as.dart';
import '../../domain/permit_catalog.dart';
import '../../domain/who_may_apply.dart';
import '../../widgets/soft_card.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../../widgets/verification_banner.dart';
import 'application_wizard_screen.dart';
import 'requirements_sheet.dart';

/// Ported grouping from `permit.model.ts`'s `PERMIT_TYPE_GROUPS` — see that
/// file's own comment on why this is the mirror, not a re-derivation. Each
/// type says who may apply when the Municipality restricted it (ebpco-api 068)
/// and, for a few, who usually does; each opens its Requirements, and a tap
/// starts an application. From a business's own "Apply for a permit"
/// ([businessId]), the wizard opens as Business with that business chosen.
class PermitCatalogScreen extends StatefulWidget {
  const PermitCatalogScreen({super.key, this.businessId, this.applicantKinds, this.requirements});

  /// The business the citizen came from, carried into the wizard.
  final String? businessId;

  /// Who may apply for each type; read from the server when not given (tests give it).
  final Future<Map<String, List<String>>>? applicantKinds;

  /// Where the Requirements sheet reads its lists; the live API when not given.
  final RequirementsLoader? requirements;

  @override
  State<PermitCatalogScreen> createState() => _PermitCatalogScreenState();
}

class _PermitCatalogScreenState extends State<PermitCatalogScreen> {
  /// Who may apply for each type; null until loaded. Never fails: an older
  /// server or no connection reads as every type open to both.
  Map<String, List<String>>? _applicantKinds;

  @override
  void initState() {
    super.initState();
    (widget.applicantKinds ?? CitizenApi.instance.permitTypeApplicantKinds()).then((kinds) {
      if (mounted) setState(() => _applicantKinds = kinds);
    });
  }

  void _start(String type, {String? applicationAction}) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ApplicationWizardScreen(
            permitType: type,
            businessId: widget.businessId,
            applicationAction: applicationAction,
          ),
        ),
      );

  Future<void> _requirements(String type) async {
    final action = await showRequirementsSheet(
      context,
      permitType: type,
      load: widget.requirements ?? liveRequirements(applyingAs: widget.businessId == null ? null : applyingAsBusiness),
    );
    if (action != null && mounted) _start(type, applicationAction: action);
  }

  @override
  Widget build(BuildContext context) {
    final applicantKinds = _applicantKinds;
    return SoftPageScaffold(
      title: 'Permit Services',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text('Apply for a Permit', style: SoftType.h1),
          const SizedBox(height: 6),
          Text('Browse requirements before you start, or begin a new application.', style: SoftType.body.copyWith(fontSize: 15)),
          const SizedBox(height: 18),
          // Not verified yet (ebpco-api 067): what can hold a citizen back now.
          const VerificationBanner(),
          const BfpClearanceNotice(),
          const SizedBox(height: 22),
          for (final group in permitTypeGroups) ...[
            SoftSectionHeader(title: group.label),
            SoftGroupedList(rows: [
              for (final type in group.types)
                SoftListRow(
                  icon: Icons.description_outlined,
                  title: type,
                  tag: switch (applicantKinds == null ? null : restrictedKindsChip(applicantKindsFor(applicantKinds, type))) {
                    final chip? => SoftStatusPill(label: chip, tone: SoftStatusTone.neutral),
                    null => null,
                  },
                  subtitle: usualUseNote(type, applicantKinds == null ? null : applicantKindsFor(applicantKinds, type)),
                  action: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: ValueKey('requirements-$type'),
                      onPressed: () => _requirements(type),
                      icon: const Icon(Icons.checklist_rounded, size: 18),
                      label: Text('Requirements', style: SoftType.sectionLink.copyWith(fontSize: 14)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  onTap: () => _start(type),
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
/// documents instead, and the Fire Safety stage verifies them. The portal's
/// words: one line, with what to upload a tap away. A Certificate of
/// Occupancy asks for the FSCCR, not the FSIC (the server's checklist).
class BfpClearanceNotice extends StatefulWidget {
  const BfpClearanceNotice({super.key});

  @override
  State<BfpClearanceNotice> createState() => _BfpClearanceNoticeState();
}

class _BfpClearanceNoticeState extends State<BfpClearanceNotice> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: SoftColors.primaryWash,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fire Safety clearances (FSEC, FSIC) come from the BFP, not the Municipality.',
            style: SoftType.tileTitle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Apply on BFP-FSIS (fsis.e-bfp.com) or at the Castilla Fire Station.',
            style: SoftType.body.copyWith(color: SoftColors.ink),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => setState(() => _open = !_open),
            icon: Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20),
            label: Text('What to upload here', style: SoftType.sectionLink.copyWith(fontSize: 14)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          ),
          if (_open) ...[
            Text(
              bfpUploadNote,
              style: SoftType.body.copyWith(color: SoftColors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              'Permits with nothing for the BFP to check, like a Fencing or Sign Permit, skip the Fire Safety stage.',
              style: SoftType.body,
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 6),
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

/// What to upload, in the portal's words (`permit-catalog.page.ts`): the FSEC
/// with a Building Permit; the FSCCR, not the FSIC, with a Certificate of
/// Occupancy, as the server's checklist asks.
const String bfpUploadNote =
    'The Fire Safety Evaluation Clearance (FSEC) for a building permit and the Fire Safety Inspection '
    'Certificate (FSIC) for occupancy are issued by the Bureau of Fire Protection. Upload the FSEC with your '
    'Building Permit application here; a Certificate of Occupancy application asks for the Fire Safety '
    'Compliance and Commissioning Report (FSCCR) instead. Our Fire Safety officer checks both.';
