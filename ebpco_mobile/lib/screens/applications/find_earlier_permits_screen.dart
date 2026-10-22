import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/earlier_records.dart';
import '../../services/earlier_records_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

/// "Find my earlier permits" (ebpco-api 069): the citizen names a permit the
/// Municipality issued on paper before eBPCO that is not on their account
/// yet (`POST /me/record-claims`), and sees what became of what they asked
/// for under "Your requests". An officer checks the register and decides;
/// the answer is the same whether or not the number is on file.
class FindEarlierPermitsScreen extends StatefulWidget {
  const FindEarlierPermitsScreen({super.key});

  @override
  State<FindEarlierPermitsScreen> createState() => _FindEarlierPermitsScreenState();
}

class _FindEarlierPermitsScreenState extends State<FindEarlierPermitsScreen> {
  final _permitNumber = TextEditingController();
  final _orNumber = TextEditingController();
  DateTime? _dateIssued;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // An officer may have answered since the list was last fetched.
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EarlierRecordsService>().refresh());
  }

  @override
  void dispose() {
    _permitNumber.dispose();
    _orNumber.dispose();
    super.dispose();
  }

  /// Any change to what was typed takes back the last error or "Sent".
  void _edited() {
    if (_error != null || _sent) {
      setState(() {
        _error = null;
        _sent = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.parse(manilaToday());
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateIssued ?? today,
      firstDate: DateTime(1950),
      lastDate: today,
      helpText: 'Date issued',
    );
    if (picked == null || !mounted) return;
    setState(() => _dateIssued = picked);
    _edited();
  }

  Future<void> _send() async {
    if (_sending) return;
    final permitNumber = claimPermitNumber(_permitNumber.text);
    final dateIssued = _dateIssued == null ? null : DateFormat('yyyy-MM-dd').format(_dateIssued!);
    final orNumber = _orNumber.text.trim();
    final problem = earlierClaimProblem(permitNumber: permitNumber, dateIssued: dateIssued, orNumber: orNumber);
    setState(() {
      _sent = false;
      _error = problem;
    });
    if (problem != null) return;
    FocusScope.of(context).unfocus();
    final records = context.read<EarlierRecordsService>();
    setState(() => _sending = true);
    final error = await records.claim(
      permitNumber: permitNumber,
      dateIssued: dateIssued,
      orNumber: orNumber.isEmpty ? null : orNumber,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = error;
      if (error == null) {
        _permitNumber.clear();
        _orNumber.clear();
        _dateIssued = null;
        _sent = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final claims = context.watch<EarlierRecordsService>().claims;
    return SoftPageScaffold(
      title: 'Find my earlier permits',
      body: RefreshIndicator(
        onRefresh: () => context.read<EarlierRecordsService>().refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(
              'Give the number on your paper permit. The Municipality checks its register and adds the permit to '
              'your account if it is yours.',
              style: SoftType.body.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 18),
            const SoftFieldLabel('Permit Number'),
            TextField(
              controller: _permitNumber,
              style: SoftType.field,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              autocorrect: false,
              onChanged: (_) => _edited(),
              decoration: const InputDecoration(hintText: 'As printed on the paper permit, e.g. BP-2019-0412'),
            ),
            const SizedBox(height: 16),
            const SoftFieldLabel('Date Issued'),
            SoftPickerField(
              value: _dateIssued == null ? null : DateFormat('MMM d, y').format(_dateIssued!),
              placeholder: 'Select date',
              onTap: _pickDate,
            ),
            if (_dateIssued != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() => _dateIssued = null);
                    _edited();
                  },
                  child: const Text('Clear date'),
                ),
              ),
            const SizedBox(height: 16),
            const SoftFieldLabel('Official Receipt (OR) Number'),
            TextField(
              controller: _orNumber,
              style: SoftType.field,
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              autocorrect: false,
              onChanged: (_) => _edited(),
            ),
            const SizedBox(height: 8),
            Text(earlierClaimRule, style: SoftType.cellLabel),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Semantics(liveRegion: true, child: Text(_error!, style: AppTypography.error)),
            ],
            if (_sent) ...[
              const SizedBox(height: 14),
              Semantics(
                liveRegion: true,
                child: SoftCard(
                  color: SoftColors.verifiedSoft,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 18, color: SoftColors.verifiedInk),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          earlierClaimSent,
                          style: SoftType.body.copyWith(color: SoftColors.verifiedInk, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            SoftPillButton(label: 'Send', busy: _sending, onPressed: _send),
            if (claims.isNotEmpty) ...[
              const SizedBox(height: 30),
              const SoftSectionHeader(title: 'Your requests'),
              SoftCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, claim) in claims.indexed) ...[
                      if (i > 0) const Divider(height: 1, color: SoftColors.line),
                      _RequestRow(claim: claim),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One request: the number asked about, what was given, and the answer.
class _RequestRow extends StatelessWidget {
  final RecordClaim claim;
  const _RequestRow({required this.claim});

  @override
  Widget build(BuildContext context) {
    final tone = switch (claim.status) {
      'pending' => SoftStatusTone.pending,
      'confirmed' => SoftStatusTone.verified,
      _ => SoftStatusTone.neutral,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(claim.permitNumber, style: SoftType.tileTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(claimDetails(claim), style: SoftType.tileSub),
                if (claim.note != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Note from the Municipality: ${claim.note}',
                    style: SoftType.cellLabel.copyWith(fontSize: 13, color: SoftColors.ink),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          SoftStatusPill(label: claimStatusLabel(claim.status), tone: tone),
        ],
      ),
    );
  }
}
