import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

/// RA 10173 §18 data portability — `POST /me/export` then poll
/// `GET /me/export/{id}` until `status: 'ready'`, same shape the web
/// portal's `checkExportStatus` uses. The finished archive is opened via
/// its signed URL in the device's own browser/download manager rather than
/// this app trying to render an unknown archive format itself.
class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final _api = CitizenApi.instance;
  bool _busy = false;
  String? _requestId;
  String? _status;
  String? _downloadUrl;
  String? _error;

  Future<void> _request() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _api.requestExport();
      if (!mounted) return;
      setState(() {
        _requestId = result['requestId'] as String;
        _status = 'queued';
      });
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkStatus() async {
    if (_requestId == null) return;
    setState(() => _busy = true);
    try {
      final result = await _api.exportStatus(_requestId!);
      if (!mounted) return;
      setState(() => _status = result['status'] as String?);
      if (_status == 'ready') {
        final url = await _api.exportContent(_requestId!);
        if (!mounted) return;
        setState(() => _downloadUrl = url);
      }
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftPageScaffold(
      title: 'Export Your Data',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          const SoftIconTile(icon: Icons.download_outlined, size: 56),
          const SizedBox(height: 16),
          Text('Your data, in one file', style: SoftType.h1.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            'Request a copy of everything the Municipality holds about you — your profile, applications, '
            'documents, payments, and notifications. This is your right under the Data Privacy Act (RA 10173, §18).',
            style: SoftType.body.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 24),
          if (_requestId == null)
            SoftPillButton(label: 'Request My Data', busy: _busy, onPressed: _request)
          else if (_downloadUrl != null) ...[
            SoftCard(
              color: SoftColors.verifiedSoft,
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: SoftColors.verifiedInk),
                const SizedBox(width: 10),
                Expanded(child: Text('Your export is ready.', style: SoftType.tileTitle.copyWith(color: SoftColors.verifiedInk))),
              ]),
            ),
            const SizedBox(height: 16),
            SoftPillButton(
              label: 'Download',
              icon: Icons.download_rounded,
              onPressed: () => launchUrl(Uri.parse(_downloadUrl!), mode: LaunchMode.externalApplication),
            ),
          ] else ...[
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Status', style: SoftType.cellLabel.copyWith(fontSize: 13)),
                      const Spacer(),
                      SoftStatusPill(label: _status ?? 'queued', tone: SoftStatusTone.pending),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('This can take a while to produce. Check back and tap below again later.', style: SoftType.body),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SoftPillButton(label: 'Check Status', kind: SoftPillKind.outline, busy: _busy, onPressed: _checkStatus),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: AppTypography.error),
          ],
        ],
      ),
    );
  }
}
