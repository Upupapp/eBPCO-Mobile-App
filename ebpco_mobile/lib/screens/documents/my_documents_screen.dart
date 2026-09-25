import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Documents')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _documents.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxxl),
                          child: Text(
                            "You haven't uploaded any documents yet.",
                            style: AppTypography.body,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 24),
                      itemCount: _documents.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _DocRow(
                          doc: _documents[i],
                          opening: _openingId == _documents[i].id,
                          onOpen: () => _open(_documents[i]),
                          onDelete: () => _delete(_documents[i]),
                        ),
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
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: AppColors.gray500, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.label, style: AppTypography.cardTitle),
                Text(doc.fileName, style: AppTypography.cardSubtitle),
                if (doc.applicationReference != null) ...[
                  const SizedBox(height: 2),
                  Text('On ${doc.applicationReference}', style: AppTypography.caption),
                ],
              ],
            ),
          ),
          if (doc.reviewStatus != null) ...[
            StatusBadge(label: doc.reviewStatus!),
            const SizedBox(width: 4),
          ],
          if (opening)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.gray500),
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
