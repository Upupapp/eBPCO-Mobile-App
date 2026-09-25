import 'package:flutter/material.dart';

import '../../../theme/soft_widget.dart';
import 'pack_d_chrome.dart';
import 'pack_d_frame.dart';

/// Local preview of the Pack D request-deep and permission sheets.
///
/// Guest-safe: the sample applicant and reference labels are frontend
/// simulation. Nothing here signs a citizen in, calls a camera pipeline,
/// or creates a live LGU ticket.
class PackDRequestFlow extends StatefulWidget {
  const PackDRequestFlow({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PackDRequestFlow()),
    );
  }

  @override
  State<PackDRequestFlow> createState() => _PackDRequestFlowState();
}

class _PackDRequestFlowState extends State<PackDRequestFlow> {
  PackDFrame? _frame;
  String _sex = 'Female';
  String _pay = 'GCash';
  bool _settingsHandoff = false;
  bool _removed = false;
  bool _receipt = false;

  void _go(PackDFrame frame) {
    setState(() {
      _settingsHandoff = false;
      _receipt = false;
      _frame = frame;
    });
  }

  void _backToIndex() {
    setState(() {
      _receipt = false;
      _frame = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _frame == null && !_receipt,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          if (_receipt) {
            _receipt = false;
            return;
          }
          _frame = null;
        });
      },
      child: _receipt
          ? PackDReceiptPreview(onBack: () => setState(() => _receipt = false))
          : _frame == null
          ? _index()
          : PackDFrameScreen(
              frame: _frame!,
              onBack: _backToIndex,
              onGo: _go,
              sex: _sex,
              onSex: (value) => setState(() => _sex = value),
              payMethod: _pay,
              onPayMethod: (value) => setState(() => _pay = value),
              settingsHandoff: _settingsHandoff,
              onOpenSettings: () => setState(() => _settingsHandoff = true),
              // TODO(PR-L): route to payment detail
              onViewReceipt: () => setState(() => _receipt = true),
              onCancelRequest: () => setState(() {
                _removed = true;
                _frame = null;
              }),
            ),
    );
  }

  Widget _index() {
    return PackDShell(
      title: 'Request preview',
      onBack: () => Navigator.of(context).maybePop(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const Text('Barangay clearance', style: SoftType.h1),
          const SizedBox(height: 6),
          const Text(
            'Local preview for Teresa, Rizal. These screens do not sign you in and do not create a live request.',
            style: SoftType.body,
          ),
          const PackDHonesty(
            lead: 'Frontend simulation.',
            rest:
                'Permissions, payment, and status changes stay on this device. No live LGU camera, ticket, or treasury path.',
          ),
          if (_removed) ...[
            const SizedBox(height: 12),
            Text(
              'TR-DKY-0924 was removed from this local preview only.',
              style: SoftType.greetingHi.copyWith(color: SoftColors.ink),
            ),
          ],
          const SizedBox(height: 8),
          for (final frame in PackDFrame.values)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Material(
                color: SoftColors.white,
                borderRadius: BorderRadius.circular(SoftRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(SoftRadius.md),
                  onTap: () => _go(frame),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(SoftRadius.md),
                      border: Border.all(color: SoftColors.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(frame.indexLabel, style: SoftType.cellValue),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: SoftColors.muted,
                        ),
                      ],
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
