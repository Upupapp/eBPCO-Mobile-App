import 'package:flutter/material.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';

/// The citizen's own real, issued permit (`GET /applications/{id}/permit`)
/// — every value here comes from that response; nothing is invented.
/// Deliberately not a pixel replica of a printable paper form (the web
/// portal's own ceremonial layout, complete with agency letterhead and a
/// QR watermark) — a phone screen showing real structured data honestly is
/// more useful, and safer, than an app trying to look like an official
/// document.
class PermitDocumentScreen extends StatefulWidget {
  final String applicationId;
  final String? applicationReference;
  const PermitDocumentScreen({super.key, required this.applicationId, this.applicationReference});

  @override
  State<PermitDocumentScreen> createState() => _PermitDocumentScreenState();
}

class _PermitDocumentScreenState extends State<PermitDocumentScreen> {
  PermitInfo? _permit;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final permit = await CitizenApi.instance.getPermit(widget.applicationId);
      if (!mounted) return;
      setState(() => _permit = permit);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Your Permit')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _permit == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        _error ?? 'No permit has been issued for this application yet.',
                        style: AppTypography.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _content(_permit!),
      ),
    );
  }

  Widget _content(PermitInfo permit) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Permit No.', style: AppTypography.caption),
              Text(permit.permitNumber, style: AppTypography.h1),
              const SizedBox(height: AppSpacing.md),
              if (widget.applicationReference != null) _row('Application No.', widget.applicationReference!),
              _row('Date Issued', permit.issuedDate.substring(0, 10)),
              if (permit.scope != null) _row('Scope', permit.scope!),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Conditions', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        SoftCard(
          child: permit.conditions.isEmpty
              ? Text(
                  'The Municipality has not supplied the conditions for this permit. This does not mean there are '
                  'none — ask the Office of the Municipal Engineer before relying on this document.',
                  style: AppTypography.caption,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: permit.conditions
                      .asMap()
                      .entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('${e.key + 1}. ${e.value}', style: AppTypography.body),
                          ))
                      .toList(),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Release', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        SoftCard(
          child: permit.release == null
              ? Text('Not yet recorded.', style: AppTypography.caption)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Status', permit.release!.status),
                    if (permit.release!.method != null) _row('Method', permit.release!.method!),
                    if (permit.release!.releasedAt != null) _row('Released', permit.release!.releasedAt!.substring(0, 10)),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'This permit can be verified by its permit number, ${permit.permitNumber}, on the '
          "Municipality's public verification page.",
          style: AppTypography.caption,
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
