import 'package:flutter/material.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../../widgets/status_badge.dart';
import 'document_viewer_screen.dart';

/// Whether [doc] answers a search: every word typed must appear in the
/// document's name, its file name, the application it is on, or its review
/// status — so "fire accepted" finds an accepted Fire Safety clearance.
bool matchesDocumentSearch(DocumentEntry doc, String query) {
  final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return true;
  final haystack = [doc.label, doc.fileName, doc.usedOnLabel ?? '', doc.reviewStatus ?? '']
      .join(' ')
      .toLowerCase();
  return words.every(haystack.contains);
}

/// `GET /documents/me` — every document this citizen has ever uploaded,
/// attached to an application or not. Mirrors `my-documents.page.ts`.
class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  final _api = CitizenApi.instance;
  final _search = TextEditingController();
  List<DocumentEntry> _documents = [];
  bool _loading = true;

  /// Showing what the citizen archived (ebpco-api 062) instead of My Documents.
  bool _archived = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<DocumentEntry> get _shown => _documents.where((d) => matchesDocumentSearch(d, _search.text)).toList();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final docs = await _api.getMyDocuments(archived: _archived);
      if (!mounted) return;
      setState(() => _documents = docs);
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.citizenMessage)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(DocumentEntry doc) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => DocumentViewerScreen(documentId: doc.id, title: doc.label)));

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showArchived(bool archived) {
    if (_archived == archived) return;
    setState(() {
      _archived = archived;
      _documents = [];
    });
    _load();
  }

  /// Archives — never deletes. Nothing leaves an application it is filed on.
  Future<void> _delete(DocumentEntry doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive this document?'),
        content: Text(
          doc.usedOnLabel != null
              ? 'It leaves My Documents and the list you reuse from, and stays exactly as filed on '
                  '${doc.usedOnLabel}. Nothing is deleted — restore it any time from Archived.'
              : 'It leaves My Documents and the list you reuse from. Nothing is deleted — restore it any time '
                  'from Archived.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Archive')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteDocument(doc.id);
      _say('"${doc.fileName}" archived. Restore it any time from Archived.');
      await _load();
    } on ApiError catch (e) {
      _say(e.citizenMessage);
    }
  }

  Future<void> _restore(DocumentEntry doc) async {
    try {
      await _api.restoreDocument(doc.id);
      _say('"${doc.fileName}" is back in My Documents.');
      await _load();
    } on ApiError catch (e) {
      _say(e.citizenMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final searching = _search.text.trim().isNotEmpty;
    return SoftPageScaffold(
      title: 'My Documents',
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _documents.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      _ArchiveToggle(archived: _archived, onChanged: _showArchived),
                      const SizedBox(height: 14),
                      SoftEmptyCard(_archived
                          ? 'You have not archived any documents.'
                          : "You haven't uploaded any documents yet."),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    // The search field and its result line ride at the top of
                    // the list, so they scroll away with it and pull-to-refresh
                    // still works from the very top.
                    itemCount: shown.isEmpty ? 2 : shown.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ArchiveToggle(archived: _archived, onChanged: _showArchived),
                              const SizedBox(height: 12),
                              _SearchField(
                            controller: _search,
                            resultLine: searching
                                ? '${shown.length} of ${_documents.length} document${_documents.length == 1 ? '' : 's'}'
                                : null,
                              ),
                            ],
                          ),
                        );
                      }
                      if (shown.isEmpty) {
                        return SoftEmptyCard('No documents match "${_search.text.trim()}".');
                      }
                      final doc = shown[i - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DocRow(
                          doc: doc,
                          archived: _archived,
                          onOpen: () => _open(doc),
                          onDelete: () => _archived ? _restore(doc) : _delete(doc),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

/// My Documents, or what the citizen archived from it.
class _ArchiveToggle extends StatelessWidget {
  final bool archived;
  final ValueChanged<bool> onChanged;
  const _ArchiveToggle({required this.archived, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          SoftFilterChip(label: 'My Documents', selected: !archived, onTap: () => onChanged(false)),
          const SizedBox(width: 8),
          SoftFilterChip(label: 'Archived', selected: archived, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String? resultLine;
  const _SearchField({required this.controller, required this.resultLine});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          style: SoftType.field,
          decoration: InputDecoration(
            hintText: 'Search by name, file or reference',
            prefixIcon: const Icon(Icons.search_rounded, color: SoftColors.muted),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded, color: SoftColors.muted),
                    onPressed: controller.clear,
                  ),
          ),
        ),
        if (resultLine != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(resultLine!, style: SoftType.cellLabel),
          ),
        ],
      ],
    );
  }
}

class _DocRow extends StatelessWidget {
  final DocumentEntry doc;
  final VoidCallback onOpen;

  /// Archive — or, in the Archived list, Restore.
  final VoidCallback onDelete;
  final bool archived;
  const _DocRow({required this.doc, required this.onOpen, required this.onDelete, this.archived = false});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
      onTap: onOpen,
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
                if (doc.usedOnLabel != null) ...[
                  const SizedBox(height: 2),
                  Text('Used on ${doc.usedOnLabel}', style: SoftType.cellLabel),
                ],
                if (doc.reviewStatus != null) ...[
                  const SizedBox(height: 10),
                  StatusBadge(label: doc.reviewStatus!),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: SoftColors.muted),
            onSelected: (v) => v == 'open' ? onOpen() : onDelete(),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'open', child: Text('View')),
              PopupMenuItem(value: 'delete', child: Text(archived ? 'Restore' : 'Archive')),
            ],
          ),
        ],
      ),
    );
  }
}
