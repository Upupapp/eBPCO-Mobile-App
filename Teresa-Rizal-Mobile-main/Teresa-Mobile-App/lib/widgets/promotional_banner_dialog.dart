import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/soft_widget.dart';

/// Shared promotional popup for Home, Balita, Events, Dokyu, and Tulong.
///
/// Layout follows the portrait poster shell: at most 94% of the screen
/// width and 90% of its height, image painted with [BoxFit.contain],
/// corners at 20, and a 44×44 close control sitting 14px outside the
/// top-right corner. The barrier is `#000000` at 60% and dismisses on
/// tap. Emergency is not a caller.
///
/// A null or non-asset [assetPath] paints [PromoPosterPlaceholder]. No
/// poster file is bundled with this shell.
class PromotionalBannerDialog extends StatelessWidget {
  final String? assetPath;
  final String label;

  const PromotionalBannerDialog({super.key, this.assetPath, required this.label});

  static const maxWidthFraction = 0.94;
  static const maxHeightFraction = 0.90;
  static const cornerRadius = 20.0;
  static const closeOutset = 14.0;
  static const closeHit = 44.0;

  /// Black at 60%. `withOpacity` is the review lock for this barrier.
  // ignore: deprecated_member_use
  static final Color barrierColor = Colors.black.withOpacity(0.60);

  /// Empty shell proportion. A later contained portrait occupies this frame.
  static const placeholderAspectRatio = 2 / 3;

  static const _insetPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xxl,
  );

  /// Shows the popup once. Callers keep their own once-per-session flag.
  static Future<void> show(
    BuildContext context, {
    String? assetPath,
    required String label,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: barrierColor,
      builder: (_) => PromotionalBannerDialog(assetPath: assetPath, label: label),
    );
  }

  bool get _paintsImage {
    final path = assetPath;
    return path != null && path.startsWith('assets/');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final maxWidth = size.width * maxWidthFraction;
    final maxHeight = size.height * maxHeightFraction;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // A rounded dialog shape rejects hits in the corner, which is where
      // the close control sits. The poster clips itself to 20.
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      insetPadding: _insetPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cornerRadius),
                boxShadow: SoftShadows.card,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cornerRadius),
                child: _paintsImage
                    ? Image.asset(
                        assetPath!,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        cacheWidth: (maxWidth * dpr).round(),
                        semanticLabel: '$label promotional poster',
                      )
                    : PromoPosterPlaceholder(label: label),
              ),
            ),
          ),
          Positioned(
            top: -closeOutset,
            right: -closeOutset,
            child: Tooltip(
              message: 'Close $label banner',
              child: SizedBox(
                width: closeHit,
                height: closeHit,
                child: Material(
                  type: MaterialType.circle,
                  color: Colors.black,
                  elevation: 0,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Center(
                      child: Icon(Icons.close, color: Colors.white, size: 24),
                    ),
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

/// Dashed portrait stand-in. Soft-widget wash and Inter copy. No image.
class PromoPosterPlaceholder extends StatelessWidget {
  final String label;

  const PromoPosterPlaceholder({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: PromotionalBannerDialog.placeholderAspectRatio,
      child: CustomPaint(
        painter: const _PromoSlotPainter(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_outlined, size: 28, color: SoftColors.bannerDash),
              const SizedBox(height: 8),
              Text(label, style: SoftType.bannerTitle),
              const SizedBox(height: 4),
              const Text('Poster slot', style: SoftType.cellLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoSlotPainter extends CustomPainter {
  const _PromoSlotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(PromotionalBannerDialog.cornerRadius),
    );
    canvas.drawRRect(outer, Paint()..color = SoftColors.blueWash);
    const stroke = 1.5;
    final inset = RRect.fromRectAndRadius(
      Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke),
      const Radius.circular(PromotionalBannerDialog.cornerRadius - stroke / 2),
    );
    final border = Paint()
      ..color = SoftColors.bannerDash
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in (Path()..addRRect(inset)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), border);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PromoSlotPainter oldDelegate) => false;
}
