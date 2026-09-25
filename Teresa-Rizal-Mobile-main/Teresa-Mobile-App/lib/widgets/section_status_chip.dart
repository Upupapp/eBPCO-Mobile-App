import 'package:flutter/material.dart';
import '../models/resident_profile.dart';
import '../theme/app_colors.dart';

/// Small pill used across the Resident Profile flow to show whether a
/// section (Personal/Family/Household) is Complete / In Progress / Not
/// Started — one place so the overview cards and the review screen never
/// drift into inconsistent styling.
class SectionStatusChip extends StatelessWidget {
  final SectionStatus status;
  const SectionStatusChip({super.key, required this.status});

  ({Color bg, Color fg, IconData icon}) get _style => switch (status) {
    SectionStatus.complete => (bg: AppColors.emerald50, fg: AppColors.emerald700, icon: Icons.check_circle_rounded),
    SectionStatus.inProgress => (bg: AppColors.amber50, fg: AppColors.amber700, icon: Icons.timelapse_rounded),
    SectionStatus.notStarted => (bg: AppColors.slate100, fg: AppColors.slate500, icon: Icons.circle_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 12, color: s.fg),
          const SizedBox(width: 5),
          // Flexible + longestLine: this chip is frequently placed as a
          // non-flex sibling next to an Expanded title (see
          // ResidentProfileOverviewScreen / ReviewSubmitScreen). A Row
          // with no flex child measures its content unbounded, so
          // without this the chip can report a wider-than-available
          // natural size and overflow the parent row — same root cause
          // as the Tulong/Dokyu catalog pill bug fixed earlier.
          Flexible(
            child: Text(
              status.label,
              textWidthBasis: TextWidthBasis.longestLine,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: s.fg),
            ),
          ),
        ],
      ),
    );
  }
}
