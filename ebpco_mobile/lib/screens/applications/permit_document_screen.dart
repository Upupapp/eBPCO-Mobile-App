import 'package:flutter/material.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

/// The citizen's own real, issued permit (`GET /applications/{id}/permit`)
/// — every value here comes from that response; nothing is invented.
/// Deliberately not a replica of the printable paper form: a phone screen
/// showing the real structured data honestly is safer than an app trying to
/// look like an official document.
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
    return SoftPageScaffold(
      title: 'Your Permit',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _permit == null
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [SoftEmptyCard(_error ?? 'No permit has been issued for this application yet.')],
                )
              : _content(_permit!),
    );
  }

  Widget _content(PermitInfo permit) {
    final release = permit.release;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(SoftRadius.lg), boxShadow: SoftShadows.feature),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: SoftColors.primaryGradient, borderRadius: BorderRadius.circular(SoftRadius.lg)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: SoftColors.white, shape: BoxShape.circle),
                      child: Image.asset('assets/images/ebpco_seal.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Municipality of Castilla, Sorsogon',
                        style: SoftType.tileSub.copyWith(color: const Color(0xE6FFFFFF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Permit No.', style: SoftType.cellLabel.copyWith(color: const Color(0xCCFFFFFF))),
                const SizedBox(height: 2),
                Text(permit.permitNumber, style: SoftType.h1.copyWith(color: SoftColors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (widget.applicationReference != null) ...[
                _row('Application No.', widget.applicationReference!),
                const Divider(height: 1, color: SoftColors.line),
              ],
              _row('Date Issued', permit.issuedDate.substring(0, 10)),
              if (permit.scope != null) ...[
                const Divider(height: 1, color: SoftColors.line),
                _row('Scope', permit.scope!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SoftSectionHeader(title: 'Conditions'),
        if (permit.conditions.isEmpty)
          SoftCard(
            color: SoftColors.pendingCream,
            child: Text(
              'The Municipality has not supplied the conditions for this permit. This does not mean there are '
              'none — ask the Office of the Municipal Engineer before relying on this document.',
              style: SoftType.body.copyWith(color: SoftColors.pendingInk),
            ),
          )
        else
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, c) in permit.conditions.indexed)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == permit.conditions.length - 1 ? 0 : 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: SoftColors.primarySoft, shape: BoxShape.circle),
                          child: Text('${i + 1}', style: SoftType.cellLabel.copyWith(color: SoftColors.primary, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(c, style: SoftType.body.copyWith(color: SoftColors.ink))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        const SoftSectionHeader(title: 'Release'),
        if (release == null)
          const SoftEmptyCard('Not yet recorded.')
        else
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _row('Status', release.status),
                if (release.method != null) ...[
                  const Divider(height: 1, color: SoftColors.line),
                  _row('Method', release.method!),
                ],
                if (release.releasedAt != null) ...[
                  const Divider(height: 1, color: SoftColors.line),
                  _row('Released', release.releasedAt!.substring(0, 10)),
                ],
              ],
            ),
          ),
        const SizedBox(height: 20),
        Text(
          'This permit can be verified by its permit number, ${permit.permitNumber}, on the '
          "Municipality's public verification page.",
          style: SoftType.body,
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: SoftType.cellLabel.copyWith(fontSize: 13))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: SoftType.cellValue)),
        ],
      ),
    );
  }
}
