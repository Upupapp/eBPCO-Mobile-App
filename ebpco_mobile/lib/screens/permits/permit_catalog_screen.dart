import 'package:flutter/material.dart';

import '../../domain/permit_catalog.dart';
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
