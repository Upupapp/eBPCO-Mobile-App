import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_status.dart';

/// Direct port of `resources/views/components/ui/badge.blade.php` — a pill
/// with a colored dot, using the exact same 14-status color mapping as the
/// Web Admin. Always construct from [AppStatus], never a raw string, so an
/// unrecognized status can't silently render wrong (it falls back to Draft
/// the same way the Blade component does).
class StatusChip extends StatelessWidget {
  final AppStatus status;
  final bool small;

  const StatusChip({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final style = status.style;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: style.foreground.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: style.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          // Flexible + longestLine: a Row with no flex child measures its
          // content at unconstrained natural width, so a longer label
          // ("Under Verification", "Pending Review") can overflow a
          // narrow parent (e.g. VerificationStatusPanel's icon+chip row)
          // even though every existing call site happened to have enough
          // room. Flexible makes it wrap instead, harmlessly, everywhere
          // it's used — see SectionStatusChip for the same fix.
          Flexible(
            child: Text(
              status.label,
              textWidthBasis: TextWidthBasis.longestLine,
              style: TextStyle(fontSize: small ? 11 : 12, fontWeight: FontWeight.w500, color: style.foreground),
            ),
          ),
        ],
      ),
    );
  }
}
