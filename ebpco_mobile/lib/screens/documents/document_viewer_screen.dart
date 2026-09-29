import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../../widgets/message_bar.dart';

/// Shows one of the citizen's own uploaded files inside the app — the same
/// approach as the admin portal's Preview: ask the API for a short-lived
/// signed link, fetch the bytes, render PDFs and images here. Handing the
/// link to an outside browser was unreliable (the API serves every file as
/// an attachment, so browsers download instead of showing, and a browser's
/// first-run screen can swallow the request entirely).
class DocumentViewerScreen extends StatefulWidget {
  final String documentId;
  final String title;
  const DocumentViewerScreen({super.key, required this.documentId, required this.title});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _loading = true;
  String? _error;
  Uint8List? _bytes;
  String _contentType = '';
  PdfControllerPinch? _pdf;

  bool get _isPdf => _contentType.contains('pdf');
  bool get _isImage => _contentType.startsWith('image/');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pdf?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = await CitizenApi.instance.getDocumentContent(widget.documentId);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final type = (response.headers['content-type'] ?? '').toLowerCase();
      final bytes = response.bodyBytes;
      _pdf?.dispose();
      _pdf = type.contains('pdf') ? PdfControllerPinch(document: PdfDocument.openData(bytes)) : null;
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _contentType = type;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load this document. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openExternally() async {
    try {
      final url = await CitizenApi.instance.getDocumentContent(widget.documentId);
      final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(messageBar('No app on this phone could open the document.'));
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(messageBar(e.citizenMessage));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftPageScaffold(
      title: widget.title,
      actions: [SoftBarAction(icon: Icons.download_rounded, tooltip: 'Download', onPressed: _openExternally)],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _message(_error!, retry: true)
              : _isPdf && _pdf != null
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(SoftRadius.md),
                        child: ColoredBox(
                          color: SoftColors.chipWash,
                          child: PdfViewPinch(
                            controller: _pdf!,
                            builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                              options: const DefaultBuilderOptions(),
                              documentLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
                              pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
                              errorBuilder: (_, _) => _message('This PDF could not be displayed. Use Download to open it in another app.'),
                            ),
                          ),
                        ),
                      ),
                    )
                  : _isImage && _bytes != null
                      ? InteractiveViewer(
                          maxScale: 5,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(SoftRadius.md),
                                child: Image.memory(_bytes!, fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        )
                      : _message('This file type cannot be previewed in the app. Use Download to open it in another app.'),
    );
  }

  Widget _message(String text, {bool retry = false}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        SoftEmptyCard(text),
        const SizedBox(height: 16),
        if (retry) SoftPillButton(label: 'Try again', kind: SoftPillKind.outline, icon: Icons.refresh_rounded, onPressed: _load),
      ],
    );
  }
}
