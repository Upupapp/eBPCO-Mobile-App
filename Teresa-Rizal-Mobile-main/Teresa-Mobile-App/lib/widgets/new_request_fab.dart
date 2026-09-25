import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';

/// Reusable "New Request" pill, used by both Dokyu and Tulong.
///
/// Soft-widget elevation only: a blue-tinted [SoftShadows.primary] under the
/// accent fill. No Material FAB outline and no black side — Material 3's
/// extended FAB paints its elevation in black, which reads as a neo-brutal
/// stroke on the request list.
class NewRequestFab extends StatelessWidget {
  final Color accent;
  final VoidCallback onPressed;
  final String label;

  const NewRequestFab({
    super.key,
    required this.accent,
    required this.onPressed,
    this.label = 'New Request',
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(SoftRadius.pill)),
        boxShadow: SoftShadows.primary,
      ),
      child: Material(
        color: accent,
        elevation: 0,
        shadowColor: SoftColors.clear,
        surfaceTintColor: SoftColors.clear,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          splashColor: SoftColors.white.withValues(alpha: 0.24),
          highlightColor: SoftColors.white.withValues(alpha: 0.12),
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: SoftColors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: SoftType.bannerTitle.copyWith(color: SoftColors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
