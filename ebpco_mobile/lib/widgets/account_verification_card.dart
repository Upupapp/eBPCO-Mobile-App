import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/account_verification.dart';
import '../theme/soft_widget.dart';
import 'soft_card.dart';
import 'soft_chrome.dart';

/// The account's verification at a glance: the status chip, what it means,
/// the reason an ID was returned, and (when [onUpload] is given and the
/// account is not verified yet) the way to send an ID.
class AccountVerificationCard extends StatelessWidget {
  final AccountVerification verification;
  final VoidCallback? onUpload;

  const AccountVerificationCard({super.key, required this.verification, this.onUpload});

  static SoftStatusTone toneOf(String status) => switch (status) {
        'verified' => SoftStatusTone.verified,
        'pending' => SoftStatusTone.pending,
        'rejected' => SoftStatusTone.danger,
        _ => SoftStatusTone.neutral,
      };

  String? _day(String? iso) {
    final parsed = iso == null ? null : DateTime.tryParse(iso);
    return parsed == null ? null : DateFormat('MMM d, y').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final v = verification;
    final explanation = switch (v.status) {
      'verified' => 'Your account is verified. You can submit applications.',
      'pending' => 'The Municipality is checking your ID. You can prepare applications now and submit once your '
          'account is verified. You will be notified.',
      'rejected' => 'Upload a valid ID again so the Municipality can verify your account.',
      _ => 'The Municipality checks a valid government ID before you can submit applications. '
          'You can prepare applications while you wait.',
    };
    final sent = _day(v.submittedAt);
    final uploadLabel = switch (v.status) {
      'pending' => 'Send a different ID',
      'rejected' => 'Upload again',
      _ => 'Upload valid ID',
    };

    return SoftCard(
      color: v.isRejected ? SoftColors.dangerSoft : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Valid ID', style: SoftType.tileTitle.copyWith(fontSize: 16))),
              const SizedBox(width: 8),
              Flexible(child: SoftStatusPill(label: verificationStatusLabel(v.status), tone: toneOf(v.status))),
            ],
          ),
          const SizedBox(height: 10),
          if (v.isRejected) ...[
            Text(notAcceptedMessage(v), style: SoftType.body.copyWith(color: SoftColors.danger, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
          ],
          Text(explanation, style: SoftType.body.copyWith(color: SoftColors.ink)),
          if (v.idType != null && !v.isVerified) ...[
            const SizedBox(height: 6),
            Text(
              sent == null ? 'ID sent: ${v.idType}' : 'ID sent: ${v.idType}, on $sent',
              style: SoftType.cellLabel,
            ),
          ],
          if (onUpload != null && !v.isVerified) ...[
            const SizedBox(height: 12),
            SoftPillButton(
              label: uploadLabel,
              kind: v.isPending ? SoftPillKind.outline : SoftPillKind.primary,
              icon: Icons.badge_outlined,
              onPressed: onUpload,
            ),
          ],
        ],
      ),
    );
  }
}
