import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';

/// Pack C detail push. Circular back, page title, circular share.
/// No bottom nav — the caller pushes this above the shell.
class DetailPageBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onShare;

  const DetailPageBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Row(
        children: [
          SoftCircleButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Back',
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: SoftType.pageTitle,
            ),
          ),
          SoftCircleButton(
            icon: Icons.ios_share_rounded,
            tooltip: 'Share',
            onPressed: onShare,
          ),
        ],
      ),
    );
  }
}

/// Soft-blue deep-link mark. Shown when the screen was opened from an
/// Event or Balita inbox row. Other inbox rows do not set this.
class OpenedFromNotificationEyebrow extends StatelessWidget {
  const OpenedFromNotificationEyebrow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: SoftColors.blueSoft,
            borderRadius: BorderRadius.circular(SoftRadius.pill),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EyebrowDot(),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Opened from notification',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.sans,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.12,
                    color: SoftColors.blueDeep,
                    fontFeatures: SoftType.features,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EyebrowDot extends StatelessWidget {
  const _EyebrowDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: SoftColors.blue,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Detail H1. 21 / 600. [SoftType.h1] is 24 and is the hub headline.
const TextStyle detailHeadline = TextStyle(
  fontFamily: AppTypography.sans,
  fontSize: 21,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.735,
  height: 1.2,
  color: SoftColors.ink,
  fontFeatures: <FontFeature>[
    FontFeature.enable('ss01'),
    FontFeature.enable('cv11'),
  ],
);

const TextStyle detailBody = TextStyle(
  fontFamily: AppTypography.sans,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.5,
  letterSpacing: -0.13,
  color: SoftColors.muted,
  fontFeatures: <FontFeature>[
    FontFeature.enable('ss01'),
    FontFeature.enable('cv11'),
  ],
);

const TextStyle detailChip = TextStyle(
  fontFamily: AppTypography.sans,
  fontSize: 11,
  fontWeight: FontWeight.w500,
  letterSpacing: -0.11,
  fontFeatures: <FontFeature>[
    FontFeature.enable('ss01'),
    FontFeature.enable('cv11'),
  ],
);

/// Pill used on detail meta rows. Colors come from the Pack C comps.
/// Sizes to its label. A status chip may show a leading dot.
class DetailChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final bool leadingDot;

  const DetailChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.leadingDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: detailChip.copyWith(color: foreground)),
        ],
      ),
    );
  }
}

enum SoftPanelTone { white, blue, gold, muted }

class SoftPanel extends StatelessWidget {
  final SoftPanelTone tone;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const SoftPanel({
    super.key,
    required this.child,
    this.tone = SoftPanelTone.white,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
  });

  @override
  Widget build(BuildContext context) {
    final white = tone == SoftPanelTone.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: switch (tone) {
          SoftPanelTone.white => SoftColors.white,
          SoftPanelTone.blue => SoftColors.blueSoft,
          SoftPanelTone.gold => SoftColors.endedWash,
          SoftPanelTone.muted => SoftColors.pastChipWash,
        },
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: white ? Border.all(color: SoftColors.lineSoft) : null,
        boxShadow: white ? SoftShadows.cardSm : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Free chip wash. Text uses [SoftColors.verifiedInk].
const Color freeChipWash = SoftColors.freeChipWash;

/// Ended chip / banner ink from the Pack C comps.
const Color endedInk = SoftColors.endedInk;

/// Past chip and muted poster wash.
const Color pastChipWash = SoftColors.pastChipWash;

/// Dashed poster well. Gradient and copy are the comps' pending slot.
/// No poster file is painted here.
class PendingPosterSlot extends StatelessWidget {
  final bool past;

  const PendingPosterSlot({super.key, this.past = false});

  @override
  Widget build(BuildContext context) {
    final accent = past ? SoftColors.muted : SoftColors.blue;
    return AspectRatio(
      aspectRatio: 16 / 6.5,
      child: CustomPaint(
        painter: _PosterSlotPainter(past: past),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SoftColors.slotIconFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Poster · asset pending',
                style: detailBody.copyWith(
                  fontWeight: FontWeight.w500,
                  color: accent,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                past
                    ? 'Past event · muted wash'
                    : 'Soft next-up gradient · no invented art',
                style: SoftType.cellLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterSlotPainter extends CustomPainter {
  final bool past;
  const _PosterSlotPainter({required this.past});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(SoftRadius.lg),
    );
    final shader =
        (past
                ? const LinearGradient(
                    begin: Alignment(-0.8, -1),
                    end: Alignment(0.8, 1),
                    colors: [
                      SoftColors.pastPosterStart,
                      SoftColors.pastChipWash,
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment(-0.8, -1),
                    end: Alignment(0.8, 1),
                    colors: [
                      SoftColors.eventHeroStart,
                      SoftColors.eventHeroEnd,
                      SoftColors.blueWash,
                    ],
                    stops: [0, 0.55, 1],
                  ))
            .createShader(Offset.zero & size);
    canvas.drawRRect(rrect, Paint()..shader = shader);
    final border = Paint()
      ..color = past ? SoftColors.pastPosterDash : SoftColors.bannerDash
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), border);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PosterSlotPainter oldDelegate) =>
      oldDelegate.past != past;
}

/// Pill CTA used on the detail pages. Height 42, Inter 500.
class DetailPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool muted;

  const DetailPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.primary = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = !enabled || muted
        ? SoftColors.muted
        : (primary ? SoftColors.white : SoftColors.blue);
    final bg = primary
        ? SoftColors.blue
        : (muted ? SoftColors.mutedButtonFill : SoftColors.white);
    Widget button = Material(
      color: bg,
      elevation: 0,
      shadowColor: SoftColors.clear,
      surfaceTintColor: SoftColors.clear,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: onPressed,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            border: primary ? null : Border.all(color: SoftColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.sans,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.195,
                    color: fg,
                    fontFeatures: SoftType.features,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (primary && enabled) {
      button = DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(SoftRadius.pill)),
          boxShadow: SoftShadows.primary,
        ),
        child: button,
      );
    }
    return Opacity(opacity: enabled ? 1 : 0.45, child: button);
  }
}

/// Local interest switch. Not a ticketed registration control.
class InterestToggle extends StatelessWidget {
  final bool on;
  final bool enabled;

  const InterestToggle({super.key, required this.on, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: on && enabled ? SoftColors.blue : SoftColors.toggleTrack,
          borderRadius: BorderRadius.circular(SoftRadius.pill),
        ),
        child: Align(
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: SoftColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SoftColors.cardShadow.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps a pushed detail so the shell nav is not part of this route.
class DetailScaffold extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final bool openedFromNotification;
  final List<Widget> children;

  const DetailScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.onShare,
    required this.children,
    this.openedFromNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return SoftWash(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              DetailPageBar(title: title, onBack: onBack, onShare: onShare),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                  children: [
                    if (openedFromNotification)
                      const OpenedFromNotificationEyebrow(),
                    ...children,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
