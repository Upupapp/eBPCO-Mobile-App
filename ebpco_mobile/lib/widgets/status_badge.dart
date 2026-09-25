import 'package:flutter/material.dart';

import '../theme/app_status.dart';
import '../theme/soft_widget.dart';

/// An application/document status — the design reference's dotted status
/// pill shape, with the web portals' per-status colors (the colors carry
/// meaning shared across all three surfaces, so they stay the portals').
class StatusBadge extends StatelessWidget {
  final String label;
  const StatusBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final style = statusStyleForLabel(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: style.background, borderRadius: BorderRadius.circular(SoftRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: style.foreground, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SoftType.cellLabel.copyWith(color: style.foreground, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
