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

/// A blank form the citizen must fill in and upload, read in the app, with
/// Share to save or print it. Opened from the document card that asks for it
/// (see `permit_forms.dart`).
class BlankFormScreen extends StatefulWidget {
  final PermitForm form;
  const BlankFormScreen({super.key, required this.form});

  @override
  State<BlankFormScreen> createState() => _BlankFormScreenState();
}

class _BlankFormScreenState extends State<BlankFormScreen> {
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
