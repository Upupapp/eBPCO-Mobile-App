import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../../widgets/status_badge.dart';

/// `GET /documents/me` — every document this citizen has ever uploaded,
/// attached to an application or not. Mirrors `my-documents.page.ts`.
class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  final _api = CitizenApi.instance;
  List<DocumentEntry> _documents = [];
  bool _loading = true;
  String? _openingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final docs = await _api.getMyDocuments();
      if (!mounted) return;
      setState(() => _documents = docs);
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.citizenMessage)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(DocumentEntry doc) async {
    setState(() => _openingId = doc.id);
    try {
      final url = await _api.getDocumentContent(doc.id);
      if (!mounted) return;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.citizenMessage)));
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  Future<void> _delete(DocumentEntry doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this document?'),
        content: Text(
          doc.applicationId != null
              ? 'It will stay exactly as filed on ${doc.applicationReference ?? 'its application'} — this only stops it '
                  'being offered for reuse elsewhere.'
              : 'This removes it permanently — it is not attached to any application.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteDocument(doc.id);
      await _load();
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.citizenMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftPageScaffold(
      title: 'My Documents',
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _documents.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: const [SoftEmptyCard("You haven't uploaded any documents yet.")],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    itemCount: _documents.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DocRow(
                        doc: _documents[i],
                        opening: _openingId == _documents[i].id,
                        onOpen: () => _open(_documents[i]),
                        onDelete: () => _delete(_documents[i]),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final DocumentEntry doc;
  final bool opening;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  const _DocRow({required this.doc, required this.opening, required this.onOpen, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
      onTap: opening ? null : onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SoftIconTile(icon: Icons.insert_drive_file_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.label, style: SoftType.tileTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(doc.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: SoftType.tileSub),
                if (doc.applicationReference != null) ...[
                  const SizedBox(height: 2),
                  Text('On ${doc.applicationReference}', style: SoftType.cellLabel),
                ],
                if (doc.reviewStatus != null) ...[
                  const SizedBox(height: 10),
                  StatusBadge(label: doc.reviewStatus!),
                ],
              ],
            ),
          ),
          if (opening)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: SoftColors.muted),
              onSelected: (v) => v == 'open' ? onOpen() : onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'open', child: Text('View')),
                PopupMenuItem(value: 'delete', child: Text('Remove')),
              ],
            ),
        ],
      ),
    );
  }
}
