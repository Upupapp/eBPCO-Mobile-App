import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/account_verification.dart';
import '../screens/profile/account_verification_screen.dart';
import '../services/session_service.dart';
import '../theme/soft_widget.dart';
import 'soft_card.dart';
import 'soft_chrome.dart';

/// Account verification (ebpco-api 067), where it decides what a citizen can
/// do next: Home, Permit Services and the application wizard, as on the
/// portal. Says nothing for a verified account, or when the server sent no
/// verification state at all; the server's own refusal at Submit stays the
/// backstop either way. Amber while the citizen has something to do or waits,
/// red when the ID was not accepted.
class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key, this.bottomGap = 14});

  /// Space under the banner when it shows; none when it does not.
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    final verification = context.watch<SessionService>().verification;
    final banner = verificationBanner(verification);
    if (banner == null) return const SizedBox.shrink();
    final rejected = verification?.isRejected ?? false;
    final ink = rejected ? SoftColors.danger : SoftColors.pendingInk;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: SoftCard(
        key: const ValueKey('verification-banner'),
        color: rejected ? SoftColors.dangerSoft : SoftColors.pendingCream,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: SoftColors.white, borderRadius: BorderRadius.circular(SoftRadius.sm)),
                  child: Icon(rejected ? Icons.error_outline_rounded : Icons.badge_outlined, color: ink, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(banner.title, style: SoftType.tileTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w600)),
                      if (banner.body case final body?) ...[
                        const SizedBox(height: 4),
                        Text(body, style: SoftType.body.copyWith(color: SoftColors.muted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (banner.action case final action?) ...[
              const SizedBox(height: 14),
              SoftPillButton(
                label: action,
                icon: Icons.badge_outlined,
                kind: SoftPillKind.outline,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountVerificationScreen()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
