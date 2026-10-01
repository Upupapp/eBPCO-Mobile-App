import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/permit_forms.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/message_bar.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

/// A blank form the citizen must fill in, sign and upload, read in the app.
/// Opened from the document card that asks for it (see `permit_forms.dart`).
///
/// Download saves it to the phone through the system's own save dialog
/// (Downloads by default); Share hands it to another app, which is also how a
/// phone prints. Both use the form's own name, not the bundle's.
class BlankFormScreen extends StatefulWidget {
  final PermitForm form;
  const BlankFormScreen({super.key, required this.form});

  @override
  State<BlankFormScreen> createState() => _BlankFormScreenState();
}

class _BlankFormScreenState extends State<BlankFormScreen> {
  late final PdfControllerPinch _pdf = PdfControllerPinch(document: PdfDocument.openAsset(widget.form.assetPath));
  bool _saving = false;
  bool _sharing = false;

  @override
  void dispose() {
    _pdf.dispose();
    super.dispose();
  }

  Future<Uint8List> _bytes() async => (await rootBundle.load(widget.form.assetPath)).buffer.asUint8List();

  void _say(String text) => ScaffoldMessenger.of(context).showSnackBar(messageBar(text));

  Future<void> _download() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save ${widget.form.title}',
        fileName: widget.form.downloadName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: await _bytes(),
      );
      // Null: the citizen closed the save dialog, which needs no message.
      if (saved != null && mounted) _say('Saved "${widget.form.downloadName}". Print it, sign it, and upload it here.');
    } catch (_) {
      if (mounted) _say('The form could not be saved. Try again, or use Share.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(await _bytes(), mimeType: 'application/pdf', name: widget.form.downloadName)],
        fileNameOverrides: [widget.form.downloadName],
        subject: widget.form.title,
      ));
    } catch (_) {
      if (mounted) _say('The form could not be shared. Try again.');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SoftPageScaffold(
      title: form.title,
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
                  'Reference template, not a Castilla form. It shows what will be asked; the office will tell you '
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
                        child: SoftEmptyCard('This form could not be displayed. Use Download or Share to open it in another app.'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
            decoration: const BoxDecoration(
              color: SoftColors.white,
              border: Border(top: BorderSide(color: SoftColors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SoftPillButton(
                    label: 'Download',
                    icon: Icons.download_rounded,
                    busy: _saving,
                    onPressed: _saving ? null : _download,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SoftPillButton(
                    label: 'Share or print',
                    kind: SoftPillKind.outline,
                    icon: Icons.ios_share_rounded,
                    busy: _sharing,
                    onPressed: _sharing ? null : _share,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
