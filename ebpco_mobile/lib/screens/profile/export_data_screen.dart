import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Export Your Data')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Request a copy of everything the Municipality holds about you — your profile, applications, '
                'documents, payments, and notifications. This is your right under the Data Privacy Act (RA 10173, §18).',
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (_requestId == null)
                ElevatedButton(onPressed: _busy ? null : _request, child: const Text('Request My Data'))
              else if (_downloadUrl != null) ...[
                Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Your export is ready.')),
                ]),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => launchUrl(Uri.parse(_downloadUrl!), mode: LaunchMode.externalApplication),
                  child: const Text('Download'),
                ),
              ] else ...[
                Text('Status: ${_status ?? 'queued'}', style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Text('This can take a while to produce. Check back and tap below again later.', style: AppTypography.caption),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(onPressed: _busy ? null : _checkStatus, child: const Text('Check Status')),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: AppTypography.error),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
