import 'package:flutter/material.dart';

import '../domain/earlier_records.dart';
import '../theme/soft_widget.dart';

/// "Issued before eBPCO" (ebpco-api 069): on a permit from the
/// Municipality's register and on a business from its registry. Gold, like
/// the portal's badge, so it never reads as an application's status.
class BeforeEbpcoBadge extends StatelessWidget {
  const BeforeEbpcoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: SoftColors.goldSoft, borderRadius: BorderRadius.circular(SoftRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_edu_rounded, size: 14, color: SoftColors.goldInk),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              beforeEbpcoLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SoftType.cellLabel.copyWith(color: SoftColors.goldInk, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
