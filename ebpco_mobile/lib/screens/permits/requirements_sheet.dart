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
/// Building Permit), and per document Required or If applicable, its name,
/// what it is, and whether paper copies are needed too. Answers the action to
/// start an application with when "Start application" is tapped, else null.
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
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: documents.length,
                      separatorBuilder: (_, _) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: SoftColors.line),
                      ),
                      itemBuilder: (_, i) => RequirementHeading(
                        doc: documents[i],
                        required: documents[i].required,
                        attached: false,
                        showAttachState: false,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              SoftPillButton(
                label: 'Start application',
                onPressed: () => Navigator.of(context).pop(_action),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
