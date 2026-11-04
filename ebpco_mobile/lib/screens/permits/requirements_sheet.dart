import 'package:flutter/material.dart';

import '../../core/api/citizen_api.dart';
import '../../domain/models.dart';
import '../../domain/permit_catalog.dart';
import '../../domain/reviewing_office.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/requirement_heading.dart';
import '../../widgets/soft_action_sheet.dart';
import '../../widgets/soft_chrome.dart';

/// One action's live checklist for a permit type.
typedef RequirementsLoader = Future<List<RequirementDoc>> Function(String permitType, String applicationAction);

/// `GET /requirements/{permitType}?applicationAction=` — the same checklist
/// the portal's Requirements window and the wizard read. A business's own
/// "Apply for a permit" also asks for the rows for a business (the
/// signatory's authority).
RequirementsLoader liveRequirements({String? applyingAs}) => (permitType, action) =>
    CitizenApi.instance.requirementsForPermitType(permitType, applicationAction: action, applyingAs: applyingAs);

/// "Requirements" on a Permit Services card: the portal's
/// `requirements-modal.component.ts` as a sheet. The reviewing office, New /
/// Renewal / Amendment tabs for a type that keeps a list per action (the
/// Building Permit), one line saying everything is uploaded online, then the
/// documents in two sections, Required (n) and If applicable (n), each with
/// a business's own rows apart; per document its name, what it is, and a
/// "Hard copies: n" chip only where paper is needed (design review I13, 4 Nov
/// 2026). The header and tabs stay put while the list scrolls. Answers the
/// action to start an application with when "Start Application" is tapped,
/// else null.
Future<String?> showRequirementsSheet(
  BuildContext context, {
  required String permitType,
  RequirementsLoader? load,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => RequirementsSheet(permitType: permitType, load: load ?? liveRequirements()),
  );
}

class RequirementsSheet extends StatefulWidget {
  const RequirementsSheet({super.key, required this.permitType, required this.load});

  final String permitType;
  final RequirementsLoader load;

  @override
  State<RequirementsSheet> createState() => _RequirementsSheetState();
}

class _RequirementsSheetState extends State<RequirementsSheet> {
  String _action = 'New';

  /// Each action's list, asked for once (again after Try again).
  final Map<String, Future<List<RequirementDoc>>> _lists = {};

  bool get _hasTabs => checklistVariesByAction(widget.permitType);

  Future<List<RequirementDoc>> _list(String action) => _lists.putIfAbsent(action, () => widget.load(widget.permitType, action));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: SoftSheetHandle()),
              const SizedBox(height: 18),
              Text(widget.permitType, style: SoftType.section.copyWith(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(reviewingOfficeFor(widget.permitType), style: SoftType.body),
              if (_hasTabs) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final (i, action) in applicationActions.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: SoftFilterChip(
                            key: ValueKey('requirements-tab-$action'),
                            label: action,
                            selected: _action == action,
                            onTap: () => setState(() => _action = action),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Said once here; a document needing paper carries its own chip.
              Text(onlineOnlyNote, key: const ValueKey('requirements-online-note'), style: SoftType.cellLabel),
              const SizedBox(height: 4),
              Flexible(
                child: FutureBuilder<List<RequirementDoc>>(
                  key: ValueKey('requirements-$_action'),
                  future: _list(_action),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text("Checking for the LGU's published checklist…", style: SoftType.cellLabel),
                      );
                    }
                    if (snapshot.hasError) return _couldNotLoad();
                    final documents = snapshot.data ?? const <RequirementDoc>[];
                    if (documents.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          'The Municipality has not published the documents for this permit yet. '
                          'Ask the reviewing office what to bring.',
                          style: SoftType.body,
                        ),
                      );
                    }
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        for (final group in requirementSections(documents)) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 4),
                            child: Text(
                              '${requirementTag(required: group.required)} (${group.everyone.length + group.businessOnly.length})',
                              style: SoftType.tileTitle.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          ..._rows(group.everyone),
                          if (group.businessOnly.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                'Business applications only',
                                style: SoftType.cellLabel.copyWith(fontWeight: FontWeight.w600, color: SoftColors.ink),
                              ),
                            ),
                            ..._rows(group.businessOnly),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SoftPillButton(
                      label: 'Close',
                      kind: SoftPillKind.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SoftPillButton(
                      label: 'Start Application',
                      onPressed: () => Navigator.of(context).pop(_action),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One section's documents, each over a rule.
  List<Widget> _rows(List<RequirementDoc> documents) => [
        for (final doc in documents) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: SoftColors.line),
          ),
          RequirementHeading(doc: doc, attached: false, showAttachState: false),
        ],
      ];

  Widget _couldNotLoad() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load the requirements. Check your connection, then try again.',
              style: SoftType.body.copyWith(color: SoftColors.ink),
            ),
            const SizedBox(height: 10),
            SoftPillButton(
              label: 'Try again',
              kind: SoftPillKind.outline,
              icon: Icons.refresh_rounded,
              onPressed: () => setState(() {
                _lists.remove(_action);
              }),
            ),
          ],
        ),
      );
}

/// The sheet's sections: Required first, then If applicable, each with the
/// rows for everyone, then a business's own; an empty section is left out.
/// The portal's Requirements window, which counts each section the same way.
List<({bool required, List<RequirementDoc> everyone, List<RequirementDoc> businessOnly})> requirementSections(
  List<RequirementDoc> documents,
) =>
    [
      for (final required in [true, false])
        (
          required: required,
          everyone: documents.where((d) => d.required == required && !d.isBusinessOnly).toList(),
          businessOnly: documents.where((d) => d.required == required && d.isBusinessOnly).toList(),
        ),
    ].where((group) => group.everyone.isNotEmpty || group.businessOnly.isNotEmpty).toList();
