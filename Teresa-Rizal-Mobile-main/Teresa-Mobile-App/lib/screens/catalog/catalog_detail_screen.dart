import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/local_reminder_store.dart';
import '../../data/service_catalog_mock.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../theme/soft_widget.dart';
import '../../data/catalog_dates.dart';
import '../../utils/age_calculator.dart';
import '../shared/service_catalog_screen.dart';
import 'catalog_chrome.dart';
import 'catalog_gate_sheet.dart';
import 'delayed_birth_wizard.dart';
import 'tulong_catalog_screen.dart';

class DokyuDetailScreen extends StatelessWidget {
  final DokyuService service;
  const DokyuDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return CatalogPage(
      title: service.appBarTitle,
      footer: CatalogFooter(
        child: CatalogCta(
          label: 'Start request',
          onPressed: () => startDokyu(context, service),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(service.blurb, style: CatalogType.note),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              '${service.fee} · ${service.time} · ${service.requirements} items',
              style: CatalogType.meta,
            ),
          ),
          const SamplePill(),
          if (service.requirementLines.isNotEmpty)
            _card('Requirements', service.requirementLines),
          if (service.claim.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(service.claim, style: CatalogType.note),
            ),
          if (service.steps.isNotEmpty)
            _card('How it works', service.steps),
          const HonestyNote(text: ServiceCatalogMock.detailHonesty),
        ],
      ),
    );
  }
}

class TulongDetailScreen extends StatefulWidget {
  final TulongProgram program;
  final DateTime? previewBirth;
  final bool previewDialog;

  const TulongDetailScreen({
    super.key,
    required this.program,
    this.previewBirth,
    this.previewDialog = false,
  });

  @override
  State<TulongDetailScreen> createState() => _TulongDetailScreenState();
}

class _TulongDetailScreenState extends State<TulongDetailScreen> {
  bool _remind = false;

  @override
  void initState() {
    super.initState();
    if (widget.previewDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeEligibility(force: true);
      });
    }
    if (widget.program.window == ProgramWindow.opensSoon) {
      LocalReminderStore.read(widget.program.id).then((value) {
        if (mounted) setState(() => _remind = value);
      });
    }
  }

  DateTime? _birth() {
    if (widget.previewBirth != null) return widget.previewBirth;
    final session = _session();
    final raw = session?.account?.birthdate;
    if (raw == null) return null;
    return parseCatalogDate(raw);
  }

  CitizenSessionService? _session() {
    try {
      return context.read<CitizenSessionService>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _maybeEligibility({bool force = false}) async {
    final program = widget.program;
    if (!force && !program.canStart) return;
    final birth = _birth();
    if (program.minAge <= 0 || birth == null) {
      if (!force && openStartGate(context)) _continueStart();
      return;
    }
    final asOf = DateTime(2026, 9, 24);
    final age = calculateAge(birth, asOf: asOf);
    if (age >= program.minAge) {
      if (!force && openStartGate(context)) _continueStart();
      return;
    }
    final see = await showDialog<bool>(
      context: context,
      builder: (ctx) => _MayNotFitDialog(
        program: program,
        age: age,
        born: formatCatalogDate(birth),
      ),
    );
    if (see == true && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const TulongCatalogScreen(openOnly: true),
        ),
      );
    }
  }

  void _continueStart() {
    final legacy = MockCatalog.assistanceTypes
        .where((item) => item.name.toLowerCase().contains(widget.program.name.toLowerCase().split(' ').first.toLowerCase()))
        .toList();
    if (legacy.isEmpty) return;
    openCatalogItem(
      context,
      category: ServiceCategory.tulong,
      item: legacy.first,
      accent: SoftColors.tulongInk,
    );
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final colors = windowColors(program.window);
    final helper = switch (program.window) {
      ProgramWindow.closed => ServiceCatalogMock.closedHelper,
      ProgramWindow.opensSoon => 'Opens ${program.soonDate} · sample date',
      ProgramWindow.open => ServiceCatalogMock.tulongDetailFooter,
    };
    return CatalogPage(
      title: program.name,
      footer: CatalogFooter(
        child: Column(
          children: [
            CatalogCta(
              label: 'Start request',
              onPressed: program.canStart
                  ? () => _maybeEligibility()
                  : null,
            ),
            const SizedBox(height: 6),
            Text(helper, textAlign: TextAlign.center, style: CatalogType.meta),
          ],
        ),
      ),
      body: ListView(
        key: const Key('tulong-detail'),
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SoftColors.tulongStrip,
                borderRadius: BorderRadius.circular(SoftRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tulong · ${program.sectionLabel}',
                          style: CatalogType.meta,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.$1,
                          borderRadius: BorderRadius.circular(SoftRadius.pill),
                        ),
                        child: Text(
                          windowLabel(program.window),
                          style: CatalogType.sample.copyWith(color: colors.$2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(program.name, style: SoftType.h1),
                  const SizedBox(height: 6),
                  Text(program.blurb, style: CatalogType.note),
                ],
              ),
            ),
          ),
          if (program.window != ProgramWindow.open)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(child: Text(program.windowLine, style: CatalogType.note)),
                  const SizedBox(width: 8),
                  const SamplePill(label: 'Sample'),
                ],
              ),
            ),
          if (program.window == ProgramWindow.opensSoon)
            SwitchListTile(
              key: const Key('remind-me'),
              title: const Text('Remind me when it opens', style: CatalogType.tileTitle),
              subtitle: const Text(ServiceCatalogMock.remindHelper, style: CatalogType.meta),
              value: _remind,
              activeThumbColor: SoftColors.blue,
              onChanged: (value) async {
                setState(() => _remind = value);
                await LocalReminderStore.write(program.id, value);
              },
            ),
          _line('Who can apply · summary', program.eligibilityDetail.isEmpty ? program.eligibility : program.eligibilityDetail, program.eligibilityDetail),
          _line('Amount', program.amountTitle, program.amountHelper),
          _line('Where to ask', program.claimTitle, program.claimSub),
          if (program.requirements.isNotEmpty)
            _card('Requirements · ${program.requirements.length} items · sample', program.requirements),
          if (program.closedTip.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(program.closedTip, style: CatalogType.note),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TulongCatalogScreen(openOnly: true),
                ),
              ),
              child: const Text('Browse open programs', style: CatalogType.link),
            ),
          ],
        ],
      ),
    );
  }
}

class _MayNotFitDialog extends StatelessWidget {
  final TulongProgram program;
  final int age;
  final String born;
  const _MayNotFitDialog({required this.program, required this.age, required this.born});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('may-not-fit-dialog'),
      backgroundColor: SoftColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SoftRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${program.name} may not fit your profile',
              textAlign: TextAlign.center,
              style: CatalogType.dialogTitle,
            ),
            const SizedBox(height: 8),
            const Text(
              ServiceCatalogMock.mayNotFitIntro,
              textAlign: TextAlign.center,
              style: CatalogType.tileSub,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SoftColors.page,
                borderRadius: BorderRadius.circular(SoftRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(child: Text('Sample eligibility line', style: CatalogType.meta)),
                      SamplePill(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(program.eligibilityDetail, style: CatalogType.tileTitle),
                  const SizedBox(height: 8),
                  const Text('Your profile', style: CatalogType.meta),
                  Text('Age $age · born $born', style: CatalogType.tileTitle),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '· Applying for a senior in your household? They can apply from their own account.',
                style: CatalogType.meta,
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '· Not sure? Ask the MSWDO desk at the Municipal Hall, Poblacion.',
                style: CatalogType.meta,
              ),
            ),
            const SizedBox(height: 12),
            CatalogCta(
              label: 'See programs that may fit',
              onPressed: () => Navigator.of(context).pop(true),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep browsing', style: CatalogType.link),
            ),
            const Text(
              ServiceCatalogMock.mayNotFitFooter,
              textAlign: TextAlign.center,
              style: CatalogType.meta,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _line(String kicker, String title, String sub) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker, style: CatalogType.meta),
        Text(title, style: CatalogType.tileTitle),
        Text(sub, style: CatalogType.meta),
      ],
    ),
  );
}

Widget _card(String title, List<String> lines) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: CatalogType.eyebrow),
          const SizedBox(height: 8),
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${i + 1}  ${lines[i]}', style: CatalogType.note),
            ),
        ],
      ),
    ),
  );
}

void startDokyu(BuildContext context, DokyuService service) {
  if (!openStartGate(context)) return;
  if (service.delayedBirth) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DelayedBirthWizard()),
    );
    return;
  }
  final legacy = MockCatalog.documentTypes.where((item) => item.key == service.legacyKey);
  if (legacy.isEmpty) return;
  openCatalogItem(
    context,
    category: ServiceCategory.dokyu,
    item: legacy.first,
    accent: SoftColors.blue,
  );
}
