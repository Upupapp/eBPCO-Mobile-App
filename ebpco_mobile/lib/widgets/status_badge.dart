import 'package:flutter/material.dart';

import '../theme/app_status.dart';
import '../theme/app_typography.dart';

/// The pill shown for an application's status — same color mapping as the
/// web portals' `<app-status-pill>` (see `theme/app_status.dart`'s own doc
/// comment for the exact source).
class StatusBadge extends StatelessWidget {
  final String label;
  const StatusBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final style = statusStyleForLabel(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: style.background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: style.foreground, fontWeight: FontWeight.w700, fontSize: 11.5),
      ),
    );
  }
}
