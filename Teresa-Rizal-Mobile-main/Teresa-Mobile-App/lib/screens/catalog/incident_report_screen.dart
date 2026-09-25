import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/service_catalog_mock.dart';
import '../../data/tulong_program_route.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/requests_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/form/barangay_picker.dart';
import '../../widgets/form/soft_form_fields.dart';
import 'catalog_chrome.dart';
import 'catalog_gate_sheet.dart';
import 'tulong_program_placeholder.dart';

void call911() {
  launchUrl(Uri.parse('tel:${ServiceCatalogMock.emergencyNumber}'));
}

void openIncident(BuildContext context, SakunaKind kind) {
  if (!openStartGate(context, emergency: true)) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => IncidentReportScreen(kind: kind)),
  );
}

class IncidentReportScreen extends StatefulWidget {
  final SakunaKind kind;
  final bool openPicker;
  final bool focusDescription;
  final String? barangay;

  const IncidentReportScreen({
    super.key,
    required this.kind,
    this.openPicker = false,
    this.focusDescription = false,
    this.barangay,
  });

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  late String _barangay;
  final _landmark = TextEditingController();
  final _description = TextEditingController();
  final _landmarkNode = FocusNode();
  final _descriptionNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _barangay = widget.barangay ?? ServiceCatalogMock.profileBarangay;
    if (widget.openPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickBarangay());
    }
    if (widget.focusDescription) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _descriptionNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _landmark.dispose();
    _description.dispose();
    _landmarkNode.dispose();
    _descriptionNode.dispose();
    super.dispose();
  }

  Future<void> _pickBarangay() async {
    final picked = await BarangayPicker.show(
      context,
      title: 'Where is it happening?',
      selected: _barangay,
      selectedHint: 'Your barangay',
    );
    if (picked != null && mounted) setState(() => _barangay = picked);
  }

  Future<void> _submit() async {
    try {
      final session = context.read<CitizenSessionService>();
      final requests = context.read<RequestsService>();
      final name = session.account == null
          ? 'Guest'
          : '${session.account!.firstName} ${session.account!.lastName}';
      await requests.submit(
        applicantId: session.account?.id ?? 'guest',
        applicantName: name,
        typeName: widget.kind.label,
        category: ServiceCategory.sakunaIncident,
        office: ServiceCatalogMock.mdrrmoName,
        purpose: _description.text,
        expectedDays: 'sample',
        attachments: const [],
        formFields: {
          'barangay': _barangay,
          'landmark': _landmark.text,
        },
      );
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => IncidentSentScreen(kind: widget.kind, barangay: _barangay, landmark: _landmark.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CatalogPage(
      title: 'Report ${widget.kind.label.toLowerCase()}',
      pinned: const [
        Call911Strip(subtitle: ServiceCatalogMock.formStripSub),
      ],
      footer: CatalogFooter(
        child: CatalogCta(
          label: 'Submit report',
          onPressed: _submit,
        ),
      ),
      body: ListView(
        key: const Key('sos-scroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          const Text('Sakuna · Report incident', style: CatalogType.meta),
          const SizedBox(height: 6),
          const Text('Tell us what\'s happening', style: SoftType.h1),
          const SizedBox(height: 12),
          const Text('Incident type', style: CatalogType.fieldLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in ServiceCatalogMock.sakuna)
                ChoiceChip(
                  label: Text(kind.label),
                  selected: kind.id == widget.kind.id,
                  onSelected: (_) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Barangay', style: CatalogType.fieldLabel),
          const SizedBox(height: 6),
          Material(
            color: SoftColors.white,
            borderRadius: BorderRadius.circular(SoftRadius.md),
            child: InkWell(
              key: const Key('sos-barangay'),
              onTap: _pickBarangay,
              borderRadius: BorderRadius.circular(SoftRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SoftRadius.md),
                  border: Border.all(color: SoftColors.line, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(_barangay, style: CatalogType.field)),
                    const Icon(Icons.expand_more, color: SoftColors.muted),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6, bottom: 8),
            child: Text('From your profile · change if it\'s elsewhere', style: CatalogType.helper),
          ),
          SoftFormField(
            label: 'Landmark or street',
            controller: _landmark,
            focusNode: _landmarkNode,
            hint: 'e.g. near the covered court, Purok 3',
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _descriptionNode.requestFocus(),
          ),
          SoftFormField(
            fieldKey: const Key('sos-description'),
            label: 'Description',
            counter: '${_description.text.length} / 500',
            controller: _description,
            focusNode: _descriptionNode,
            hint: 'What happened, how many people are affected, can vehicles pass?',
            helper: ServiceCatalogMock.locationTyped,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
          ),
          const Text('Photo', style: CatalogType.fieldLabel),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('Optional', style: CatalogType.meta),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SoftRadius.md),
              border: Border.all(color: SoftColors.bannerDash, width: 1.5),
            ),
            child: const Text(
              'Add a photo\nCamera · Gallery · stays on this device',
              style: CatalogType.meta,
            ),
          ),
          const SizedBox(height: 12),
          const HonestyNote(
            text: ServiceCatalogMock.reportFormHonesty,
            background: SoftColors.goldSoft,
            icon: Icons.shield_outlined,
            iconColor: SoftColors.endedInk,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Saved on this device · sample report channel', style: CatalogType.meta),
          ),
        ],
      ),
    );
  }
}

class IncidentSentScreen extends StatelessWidget {
  final SakunaKind kind;
  final String barangay;
  final String landmark;

  const IncidentSentScreen({
    super.key,
    required this.kind,
    required this.barangay,
    this.landmark = '',
  });

  @override
  Widget build(BuildContext context) {
    final place = landmark.isEmpty ? barangay : '$barangay · $landmark';
    return CatalogPage(
      title: 'Report incident',
      closeIcon: true,
      pinned: const [Call911Strip()],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Icon(Icons.check_rounded, color: SoftColors.blue, size: 36),
          const SizedBox(height: 8),
          const Text(ServiceCatalogMock.sentTitle, textAlign: TextAlign.center, style: SoftType.h1),
          const SizedBox(height: 6),
          const Text(ServiceCatalogMock.sentBody, textAlign: TextAlign.center, style: CatalogType.tileSub),
          const SizedBox(height: 12),
          _row('Type', kind.label),
          _row('Location', place),
          _row('Reference', ServiceCatalogMock.sentReference, sample: true),
          _row('Status', ServiceCatalogMock.sentStatus),
          const SizedBox(height: 8),
          const HonestyNote(
            text: ServiceCatalogMock.sentDanger,
            background: SoftColors.dangerSoft,
            icon: Icons.warning_amber_rounded,
            iconColor: SoftColors.danger,
          ),
          const _SentHotlines(),
          const SizedBox(height: 8),
          CatalogCta(
            label: 'View my reports',
            primary: false,
            onPressed: () {
              // TODO(Pack J): My reports list and report detail replace this placeholder.
              Navigator.of(context).push(
                MaterialPageRoute(
                  settings: const RouteSettings(name: kMyReportsRoute),
                  builder: (_) => const MyReportsPlaceholder(),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Emergency', style: CatalogType.link),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool sample = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: CatalogType.meta),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: CatalogType.tileTitle,
              maxLines: 2,
            ),
          ),
          if (sample) ...[const SizedBox(width: 6), const SamplePill()],
        ],
      ),
    );
  }
}

class _SentHotlines extends StatelessWidget {
  const _SentHotlines();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text(ServiceCatalogMock.emergencyNumber, style: CatalogType.tileTitle),
            subtitle: const Text('National emergency hotline', style: CatalogType.meta),
            trailing: TextButton(onPressed: call911, child: const Text('Call', style: CatalogType.link)),
          ),
          const ListTile(
            title: Text(ServiceCatalogMock.mdrrmoName, style: CatalogType.tileTitle),
            subtitle: Text(ServiceCatalogMock.mdrrmoNumber, style: CatalogType.meta),
            trailing: TextButton(
              key: Key('mdrrmo-call'),
              onPressed: null,
              child: Text('Call'),
            ),
          ),
        ],
      ),
    );
  }
}
