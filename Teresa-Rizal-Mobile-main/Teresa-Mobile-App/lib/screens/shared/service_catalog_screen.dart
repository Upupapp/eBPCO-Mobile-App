import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/catalog_item.dart';
import '../../models/request_filters.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/soft_widget.dart';
import '../../utils/teresa_rizal_seal.dart';
import '../../widgets/soft_flow_scaffold.dart';
import '../../utils/office_logo.dart';
import '../../utils/tulong_eligibility.dart';
import '../../widgets/app_card.dart';
import '../requests/pack_d/pack_d_flow.dart';
import 'new_request_screen.dart';
import 'request_detail_screen.dart';
import 'service_request_wizard_screen.dart';

/// Step 1 of the request wizard — pick a document/assistance type, guided
/// by progressive filtering (Barangay/LGU -> Department -> Specific
/// Program) rather than one long flat list, per the filtering spec:
/// "do not show every option at once; respond to previous selections."
/// A step is skipped automatically when it wouldn't actually narrow
/// anything — e.g. Tulong's catalog is entirely LGU/Municipal-level
/// (no barangay-administered assistance program exists), so showing a
/// Barangay/LGU choice there would be a dead end; Dokyu's catalog spans
/// both, so that step appears there. This keeps the same screen correct
/// for both Dokyu and Tulong without hand-tuning per category.
class ServiceCatalogScreen extends StatefulWidget {
  final ServiceCategory category;
  final String title;
  final List<CatalogItem> catalog;
  final Color accent;

  const ServiceCatalogScreen({
    super.key,
    required this.category,
    required this.title,
    required this.catalog,
    required this.accent,
  });

  @override
  State<ServiceCatalogScreen> createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  RequestScope? _scope;
  String? _department;

  List<RequestScope> get _availableScopes =>
      widget.catalog.map((i) => scopeOfOffice(i.office)).toSet().toList()..sort((a, b) => a.index.compareTo(b.index));

  List<CatalogItem> get _afterScope =>
      _scope == null ? widget.catalog : widget.catalog.where((i) => scopeOfOffice(i.office) == _scope).toList();

  List<String> get _availableDepartments => _afterScope.map((i) => i.office).toSet().toList()..sort();

  List<CatalogItem> get _afterDepartment =>
      _department == null ? _afterScope : _afterScope.where((i) => i.office == _department).toList();

  bool get _needsScopeStep => _availableScopes.length > 1;
  bool get _needsDepartmentStep => _availableDepartments.length > 1;

  Future<void> _openItem(BuildContext context, CatalogItem item) {
    return openCatalogItem(context, category: widget.category, item: item, accent: widget.accent);
  }

  @override
  Widget build(BuildContext context) {
    // Locked req-catalog: Dokyu opens on a 2×3 grid of six representative
    // types. Tulong still narrows by office, because that catalog has no
    // locked grid comp.
    if (widget.category == ServiceCategory.dokyu) {
      return SoftFlowScaffold(
        title: 'New request',
        centerTitle: true,
        resizeToAvoidBottomInset: true,
        onBack: () => Navigator.of(context).maybePop(),
        body: _DokyuTypeGrid(
          items: widget.catalog,
          accent: widget.accent,
          onOpen: (item) => _openItem(context, item),
        ),
      );
    }

    // Steps are resolved in order: Scope -> Department -> Item list. Once
    // a step isn't needed (or has already been answered), fall through to
    // the next one — this is what makes "not enough distinct values to
    // matter" transparently skip instead of showing a single-option menu.
    Widget body;
    final appBarTitle = 'Select ${widget.title} Type';
    if (_needsScopeStep && _scope == null) {
      body = _ScopeStep(scopes: _availableScopes, accent: widget.accent, onSelected: (s) => setState(() => _scope = s));
    } else if (_needsDepartmentStep && _department == null) {
      body = _DepartmentStep(
        departments: _availableDepartments,
        accent: widget.accent,
        onSelected: (d) => setState(() => _department = d),
      );
    } else {
      body = _ItemList(category: widget.category, items: _afterDepartment, accent: widget.accent);
    }

    final crumbs = <String>[?_scope?.label, ?_department];

    return SoftFlowScaffold(
      title: appBarTitle,
      resizeToAvoidBottomInset: true,
      onBack: () {
        if (crumbs.isNotEmpty) {
          setState(() {
            if (_department != null) {
              _department = null;
            } else {
              _scope = null;
            }
          });
          return;
        }
        Navigator.of(context).maybePop();
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (crumbs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (int i = 0; i < crumbs.length; i++) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                        child: Icon(Icons.chevron_right_rounded, size: 14, color: SoftColors.muted),
                      ),
                    Text(
                      crumbs[i],
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: widget.accent),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _ScopeStep extends StatelessWidget {
  final List<RequestScope> scopes;
  final Color accent;
  final ValueChanged<RequestScope> onSelected;
  const _ScopeStep({required this.scopes, required this.accent, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          'Where is this service administered?',
          style: SoftType.name,
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Choose Barangay or Municipality-level services to narrow the list.',
          style: TextStyle(fontSize: 12.5, color: SoftColors.muted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final scope in scopes)
          _StepTile(
            icon: scope == RequestScope.barangay ? Icons.holiday_village_outlined : Icons.account_balance_outlined,
            label: scope.label,
            accent: accent,
            onTap: () => onSelected(scope),
          ),
      ],
    );
  }
}

class _DepartmentStep extends StatelessWidget {
  final List<String> departments;
  final Color accent;
  final ValueChanged<String> onSelected;
  const _DepartmentStep({required this.departments, required this.accent, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          'Which office handles this?',
          style: SoftType.name,
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Choose a department to see its specific services.',
          style: TextStyle(fontSize: 12.5, color: SoftColors.muted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final dept in departments)
          _StepTile(
            icon: Icons.apartment_outlined,
            logoAsset: officeLogoAsset(dept),
            label: dept,
            accent: accent,
            onTap: () => onSelected(dept),
          ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  /// When set, an office logo replaces [icon] inside the same tinted
  /// container (used for the department/office step only — the
  /// Barangay/Municipality scope step still uses a plain icon).
  final String? logoAsset;

  const _StepTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: logoAsset != null
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(logoAsset!, fit: BoxFit.contain),
                    )
                  : Icon(icon, color: accent, size: 19),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SoftColors.ink),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: SoftColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Locked `req-catalog` copy kept for direct test pumps. Pack G removed
/// "Business endorsement" and "Certificate of employment". The Services
/// sheet opens the full catalogs instead of this grid.
const _dokyuGrid = <_DokyuType>[
  _DokyuType('dokyu_barangay_clearance', 'Barangay clearance', 'Common · Fee may apply'),
  _DokyuType('dokyu_cedula', 'Cedula (CTC)', 'Community tax certificate'),
  _DokyuType('dokyu_indigency', 'Indigency certificate', 'Assistance prerequisite'),
  _DokyuType('dokyu_residency', 'Residency certificate', 'Proof of residence'),
];

class _DokyuType {
  final String key;
  final String title;
  final String subtitle;
  const _DokyuType(this.key, this.title, this.subtitle);
}

class _DokyuTypeGrid extends StatelessWidget {
  final List<CatalogItem> items;
  final Color accent;
  final ValueChanged<CatalogItem> onOpen;

  const _DokyuTypeGrid({required this.items, required this.accent, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final byKey = {for (final item in items) item.key: item};
    final tiles = [for (final type in _dokyuGrid) if (byKey[type.key] != null) (type, byKey[type.key]!)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text('Dokyu catalog', style: SoftType.greetingHi),
        const SizedBox(height: 6),
        const Text('Choose a document', style: SoftType.h1),
        const SizedBox(height: 6),
        const Text(
          'Representative types — not the full MockCatalog.',
          style: SoftType.body,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: SoftColors.blue,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => PackDRequestFlow.open(context),
            child: const Text('Preview request states', style: SoftType.sectionLink),
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 176,
          children: [
            for (final tile in tiles)
              _DokyuTypeCard(
                title: tile.$1.title,
                subtitle: tile.$1.subtitle,
                onTap: () => onOpen(tile.$2),
              ),
          ],
        ),
      ],
    );
  }
}

class _DokyuTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DokyuTypeCard({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(SoftRadius.lg)),
        boxShadow: SoftShadows.card,
      ),
      child: Material(
        color: SoftColors.white,
        elevation: 0,
        shadowColor: SoftColors.clear,
        surfaceTintColor: SoftColors.clear,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: SoftColors.blueSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_rounded, color: SoftColors.blue, size: 18),
                ),
                const SizedBox(height: 12),
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: SoftType.name),
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: SoftType.eyebrow),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> openCatalogItem(
  BuildContext context, {
  required ServiceCategory category,
  required CatalogItem item,
  required Color accent,
}) async {
  if (category == ServiceCategory.tulong) {
    final account = context.read<CitizenSessionService>().account;
    if (account != null) {
      final result = tulongEligibilityFor(
        context.read<RequestsService>(),
        applicantId: account.id,
        typeName: item.name,
      );
      if (!result.isEligible) {
        final viewRequest = await showTulongBlockedDialog(context, result);
        if (viewRequest && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: result.blockingRequest!.id)),
          );
        }
        return;
      }
    }
  }
  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => item.formSpec != null
          ? ServiceRequestWizardScreen(category: category, item: item, accent: accent)
          : NewRequestScreen(category: category, item: item, accent: accent),
    ),
  );
}

class _ItemList extends StatelessWidget {
  final ServiceCategory category;
  final List<CatalogItem> items;
  final Color accent;
  const _ItemList({required this.category, required this.items, required this.accent});

  /// Tulong's reapplication rule is checked here, before the request screen
  /// ever opens — the citizen must never fill out an entire application
  /// only to discover at Submit that it's blocked (see
  /// utils/tulong_eligibility.dart). Dokyu items open immediately; there is
  /// no such restriction for Dokyu (the same document may legitimately be
  /// requested again).
  Future<void> _open(BuildContext context, CatalogItem item) {
    return openCatalogItem(context, category: category, item: item, accent: accent);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            onTap: () => _open(context, item),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // The Teresa, Rizal municipal seal — every individual Dokyu/
                  // Tulong service card uses it (no per-document logo
                  // exists, unlike the office-selection step above, which
                  // does have some office-specific logos).
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(teresaRizalSealAsset, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: SoftColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(item.office, style: const TextStyle(fontSize: 12, color: SoftColors.muted)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _pill(Icons.schedule_rounded, item.days),
                          _pill(
                            item.amount != null ? Icons.payments_outlined : Icons.receipt_long_outlined,
                            item.amount ?? item.fee,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_right_rounded, color: SoftColors.muted),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Renders as a compact single-line pill for short text, but grows
  /// vertically and wraps for long amounts/descriptions (e.g. "₱1,000/month
  /// (₱3,000 per quarter)") instead of overflowing the card. The `Flexible`
  /// is what makes this safe: without it, a `Row` with no flex children
  /// sizes to its content's *unbounded* intrinsic width, which is exactly
  /// what produced the overflow warnings — `Flexible` forces the Row to
  /// respect the width `Wrap` actually offers it, and `longestLine` keeps
  /// short pills from stretching to fill that width unnecessarily.
  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Icon(icon, size: 11, color: SoftColors.muted),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              textWidthBasis: TextWidthBasis.longestLine,
              style: const TextStyle(
                fontSize: 10.5,
                color: SoftColors.muted,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
