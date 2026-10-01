import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/permit_catalog.dart';
import '../../domain/permit_forms.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/message_bar.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

/// The blank official application forms, grouped like Permit Services, so an
/// applicant can read what will be asked before filing and print the form the
/// office expects (merged from eBPCOMobile, 2026-10-01).
///
/// [permitType] narrows the list to one permit's documents, for the link from
/// the application form.
class OfficialFormsScreen extends StatelessWidget {
  final String? permitType;
  const OfficialFormsScreen({super.key, this.permitType});

  @override
  Widget build(BuildContext context) {
    final only = permitType;
    return SoftPageScaffold(
      title: only == null ? 'Official Forms' : 'Forms for this permit',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            only == null
                ? 'The blank application forms the Office of the Building Official uses. Open one to read it, '
                    'or share it to save or print. You still file your application in this app.'
                : 'The blank form for $only. Open it to read what is asked, or share it to save or print.',
            style: SoftType.body.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 18),
          if (only != null)
            ..._formRows(context, only)
          else ...[
            SoftSectionHeader(title: 'Checklist'),
            SoftGroupedList(rows: [_row(context, oboChecklist)]),
            const SizedBox(height: 22),
            for (final group in permitTypeGroups) ...[
              SoftSectionHeader(title: group.label),
              SoftGroupedList(rows: [
                for (final type in group.types)
                  if (permitFormFor(type) case final form?) _row(context, form, permitType: type),
              ]),
              const SizedBox(height: 22),
            ],
          ],
          Text(
            'Forms marked "Reference template" are generic national forms. Castilla has not published its own '
            'for that permit yet; the office will tell you if it needs a different one.',
            style: SoftType.tileSub,
          ),
        ],
      ),
    );
  }

  List<Widget> _formRows(BuildContext context, String type) {
    final documents = permitDocumentsFor(type);
    if (documents.isEmpty) {
      return const [SoftEmptyCard('There is no blank form for this permit in the app. Ask the office for one.')];
    }
    return [
      SoftGroupedList(rows: [for (final form in documents) _row(context, form)]),
      const SizedBox(height: 22),
    ];
  }

  SoftListRow _row(BuildContext context, PermitForm form, {String? permitType}) {
    final provenance = form.isOfficialCastillaForm ? 'Castilla form' : 'Reference template';
    return SoftListRow(
      icon: form.isOfficialCastillaForm ? Icons.description_outlined : Icons.article_outlined,
      iconBackground: form.isOfficialCastillaForm ? null : SoftColors.chipWash,
      iconColor: form.isOfficialCastillaForm ? null : SoftColors.muted,
      title: permitType ?? form.title,
      subtitle: permitType == null ? '$provenance · ${form.office.label}' : '${form.title} · $provenance',
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OfficialFormViewerScreen(form: form))),
    );
  }
}

/// One bundled form, read in the app, with Share to save or print it.
class OfficialFormViewerScreen extends StatefulWidget {
  final PermitForm form;
  const OfficialFormViewerScreen({super.key, required this.form});

  @override
  State<OfficialFormViewerScreen> createState() => _OfficialFormViewerScreenState();
}

class _OfficialFormViewerScreenState extends State<OfficialFormViewerScreen> {
  late final PdfControllerPinch _pdf = PdfControllerPinch(document: PdfDocument.openAsset(widget.form.assetPath));
  bool _sharing = false;

  @override
  void dispose() {
    _pdf.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await rootBundle.load(widget.form.assetPath);
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'application/pdf', name: widget.form.fileName)],
        fileNameOverrides: [widget.form.fileName],
        subject: widget.form.title,
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(messageBar('The form could not be shared. Try again.'));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    return SoftPageScaffold(
      title: form.title,
      actions: [SoftBarAction(icon: Icons.ios_share_rounded, tooltip: 'Share, save or print', onPressed: _share)],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!form.isOfficialCastillaForm)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: SoftCard(
                color: SoftColors.pendingCream,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Reference template — not a Castilla form. It shows what will be asked; the office will tell you '
                  'if it needs its own form.',
                  style: SoftType.body.copyWith(color: SoftColors.pendingInk),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SoftRadius.md),
                child: ColoredBox(
                  color: SoftColors.chipWash,
                  child: PdfViewPinch(
                    controller: _pdf,
                    builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                      options: const DefaultBuilderOptions(),
                      documentLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
                      pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, _) => const Padding(
                        padding: EdgeInsets.all(20),
                        child: SoftEmptyCard('This form could not be displayed. Use Share to open it in another app.'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
