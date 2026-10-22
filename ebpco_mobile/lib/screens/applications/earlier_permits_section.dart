import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/earlier_records.dart';
import '../../services/earlier_records_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/before_ebpco_badge.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../permits/application_wizard_screen.dart';
import 'find_earlier_permits_screen.dart';

/// "Issued before eBPCO" under My Applications (ebpco-api 069): the permits
/// the Municipality issued on paper before eBPCO, once an officer has
/// matched them to this account, and the way to "Find my earlier permits".
///
/// Register records, not filings: no tracking, timeline, download or QR, and
/// never in the filter counts above. The heading and cards are hidden until
/// there is a permit to show; the "Find my earlier permits" link is always
/// there. The portal's `earlier-permits.component.ts`.
class EarlierPermitsSection extends StatelessWidget {
  const EarlierPermitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final records = context.watch<EarlierRecordsService>();
    final today = manilaToday();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (records.permits.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(beforeEbpcoLabel, style: SoftType.section.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(beforeEbpcoNote, style: SoftType.body),
          const SizedBox(height: 12),
          for (final permit in records.permits)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EarlierPermitCard(permit: permit, today: today),
            ),
        ] else
          const SizedBox(height: 8),
        _FindLink(waiting: records.waitingCount),
      ],
    );
  }
}

/// One permit from the register: what the paper permit says, and Renew
/// when eBPCO still files its type.
class EarlierPermitCard extends StatelessWidget {
  final EarlierPermit permit;

  /// YYYY-MM-DD in Castilla, what Valid / Expired is read against.
  final String today;

  const EarlierPermitCard({super.key, required this.permit, required this.today});

  void _renew(BuildContext context) {
    // A Renewal of this type with the number filled in, for the business it
    // was issued for when that business is on the account. Continue still
    // has the server check the number, exactly like a typed one.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ApplicationWizardScreen(
        permitType: permit.permitType,
        applicationAction: 'Renewal',
        permitNumber: permit.permitNumber,
        businessId: permit.businessId,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final standing = earlierPermitStanding(permit.validUntil, today);
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              const BeforeEbpcoBadge(),
              if (standing != null)
                SoftStatusPill(
                  label: standing,
                  tone: standing == 'Valid' ? SoftStatusTone.verified : SoftStatusTone.neutral,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(permit.permitType, style: SoftType.tileSub.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          // The number as printed on the paper permit, which is what the
          // citizen will compare it against.
          Text(permit.permitNumber, style: SoftType.h1.copyWith(fontSize: 22, letterSpacing: -0.3)),
          const SizedBox(height: 10),
          _Fact('Date issued', registerDay(permit.dateIssued)),
          if (permit.validUntil != null) _Fact('Valid until', registerDay(permit.validUntil!)),
          if (permit.location != null) _Fact('Location', permit.location!),
          if (permit.businessName != null) _Fact('Business', permit.businessName!),
          if (permit.registerRef != null) ...[
            const SizedBox(height: 4),
            Text('Register ref. ${permit.registerRef}', style: SoftType.cellLabel.copyWith(fontSize: 11.5)),
          ],
          if (canRenewEarlierPermit(permit.permitType)) ...[
            const SizedBox(height: 14),
            SoftPillButton(
              label: 'Renew',
              kind: SoftPillKind.outline,
              icon: Icons.autorenew_rounded,
              onPressed: () => _renew(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  const _Fact(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: SoftType.cellLabel.copyWith(fontSize: 13))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: SoftType.cellLabel.copyWith(fontSize: 13, color: SoftColors.ink))),
        ],
      ),
    );
  }
}

/// Always shown, even with no earlier permits: the way to ask for one that
/// is not on the account yet, and how many such requests are waiting.
class _FindLink extends StatelessWidget {
  final int waiting;
  const _FindLink({required this.waiting});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FindEarlierPermitsScreen())),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SoftIconTile(icon: Icons.manage_search_rounded, background: SoftColors.goldSoft, foreground: SoftColors.goldInk),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Find my earlier permits', style: SoftType.tileTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  'A permit the Municipality issued before eBPCO that is not on your account yet.',
                  style: SoftType.tileSub,
                ),
                if (waiting > 0) ...[
                  const SizedBox(height: 8),
                  SoftStatusPill(
                    label: waiting == 1 ? '1 request waiting' : '$waiting requests waiting',
                    tone: SoftStatusTone.pending,
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: SoftColors.chevron),
        ],
      ),
    );
  }
}
