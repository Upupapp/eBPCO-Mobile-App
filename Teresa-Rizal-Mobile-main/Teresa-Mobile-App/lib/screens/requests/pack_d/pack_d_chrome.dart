import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/soft_widget.dart';
import '../../../widgets/soft_chrome.dart';
import '../../../widgets/soft_flow_scaffold.dart';

/// Shared Pack D chrome. Copy and layout follow the request-deep comps.
/// Colours and type stay on [SoftColors] / [SoftType].
class PackDShell extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback onBack;

  const PackDShell({
    super.key,
    required this.title,
    required this.body,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SoftFlowScaffold(
      title: title,
      centerTitle: true,
      onBack: onBack,
      body: body,
    );
  }
}

enum PackDHonestyTone { info, strong, danger }

class PackDHonesty extends StatelessWidget {
  final String lead;
  final String rest;
  final PackDHonestyTone tone;

  const PackDHonesty({
    super.key,
    required this.lead,
    required this.rest,
    this.tone = PackDHonestyTone.info,
  });

  @override
  Widget build(BuildContext context) {
    final (background, border, iconColor, icon) = switch (tone) {
      PackDHonestyTone.info => (
        SoftColors.blueSoft,
        null,
        SoftColors.blue,
        Icons.info_outline_rounded,
      ),
      PackDHonestyTone.strong => (
        SoftColors.pendingCream,
        SoftColors.gold.withValues(alpha: 0.35),
        SoftColors.pendingInk,
        Icons.shield_outlined,
      ),
      PackDHonestyTone.danger => (
        SoftColors.dangerSoft,
        null,
        SoftColors.danger,
        Icons.shield_outlined,
      ),
    };
    final style = SoftType.greetingHi.copyWith(
      color: SoftColors.ink,
      height: 1.4,
    );
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SoftRadius.md),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: SoftColors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              boxShadow: SoftShadows.cardSm,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: style,
                children: [
                  TextSpan(
                    text: lead,
                    style: style.copyWith(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: ' $rest'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PackDGlyph extends StatelessWidget {
  final IconData icon;
  final bool danger;

  const PackDGlyph({super.key, required this.icon, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      margin: const EdgeInsets.only(bottom: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: danger ? SoftColors.dangerSoft : SoftColors.blueSoft,
        shape: BoxShape.circle,
        boxShadow: SoftShadows.cardSm,
      ),
      child: Icon(
        icon,
        size: 28,
        color: danger ? SoftColors.danger : SoftColors.blue,
      ),
    );
  }
}

class PackDSheet extends StatelessWidget {
  final Widget child;

  const PackDSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(SoftRadius.xl)),
            boxShadow: SoftShadows.nav,
          ),
          child: Material(
            color: SoftColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(SoftRadius.xl)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 28 + bottom),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class PackDHandle extends StatelessWidget {
  const PackDHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 4, bottom: 14),
        decoration: BoxDecoration(
          color: SoftColors.bannerDash,
          borderRadius: BorderRadius.circular(SoftRadius.pill),
        ),
      ),
    );
  }
}

class PackDProgress extends StatelessWidget {
  final double fraction;
  final String label;

  const PackDProgress({super.key, required this.fraction, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SoftRadius.pill),
              child: SizedBox(
                height: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: SoftColors.line),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction,
                      child: const ColoredBox(color: SoftColors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: SoftType.sectionLink),
        ],
      ),
    );
  }
}

class PackDField extends StatelessWidget {
  final String label;
  final String value;

  const PackDField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: SoftType.greetingHi.copyWith(
              color: SoftColors.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 44,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: SoftColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SoftColors.line),
            ),
            child: Text(
              value,
              style: SoftType.body.copyWith(color: SoftColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class PackDActions extends StatelessWidget {
  final String primary;
  final VoidCallback onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;
  final bool danger;
  final bool pinned;
  final SoftPillKind primaryKind;

  const PackDActions({
    super.key,
    required this.primary,
    required this.onPrimary,
    this.secondary,
    this.onSecondary,
    this.danger = false,
    this.pinned = false,
    this.primaryKind = SoftPillKind.primary,
  });

  @override
  Widget build(BuildContext context) {
    final primaryButton = SoftPillButton(
      label: primary,
      kind: danger ? SoftPillKind.danger : primaryKind,
      onPressed: onPrimary,
    );
    final secondaryButton = SoftPillButton(
      label: secondary ?? '',
      kind: SoftPillKind.outline,
      onPressed: onSecondary,
    );
    final row = secondary == null
        ? primaryButton
        : Row(
            children: [
              if (pinned)
                SizedBox(width: 110, child: secondaryButton)
              else
                Expanded(child: secondaryButton),
              const SizedBox(width: 8),
              Expanded(child: primaryButton),
            ],
          );
    if (!pinned) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: row,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: row,
    );
  }
}

class PackDStatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const PackDStatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: SoftType.cellLabel.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class PackDMilestone extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color dot;
  final Color? ring;
  final bool line;

  const PackDMilestone({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dot,
    this.ring,
    this.line = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: line ? 14 : 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 14,
              child: Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                      boxShadow: ring == null
                          ? null
                          : [BoxShadow(color: ring!, spreadRadius: 4)],
                    ),
                  ),
                  if (line)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.only(top: 4),
                        color: SoftColors.line,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SoftType.bannerTitle.copyWith(color: SoftColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: SoftType.greetingHi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PackDCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadow;
  final EdgeInsets padding;

  const PackDCard({
    super.key,
    required this.child,
    this.color = SoftColors.white,
    this.borderColor = SoftColors.lineSoft,
    this.borderWidth = 1,
    this.shadow = SoftShadows.cardSm,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}

class PackDScrim extends StatelessWidget {
  final Widget backdrop;
  final Widget sheet;

  const PackDScrim({super.key, required this.backdrop, required this.sheet});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
            child: Opacity(opacity: 0.55, child: backdrop),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(color: SoftColors.ink.withValues(alpha: 0.42)),
        ),
        sheet,
      ],
    );
  }
}

class PackDUploadTile extends StatelessWidget {
  final String title;
  final String hint;
  final bool active;

  const PackDUploadTile({
    super.key,
    required this.title,
    required this.hint,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedTilePainter(
        color: active ? SoftColors.blue : SoftColors.bannerDash,
        fill: active ? SoftColors.blueSoft : SoftColors.blueWash,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(title, style: SoftType.bannerTitle),
            const SizedBox(height: 4),
            Text(hint, style: SoftType.greetingHi),
          ],
        ),
      ),
    );
  }
}

class _DashedTilePainter extends CustomPainter {
  final Color color;
  final Color fill;

  const _DashedTilePainter({required this.color, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(SoftRadius.md),
    );
    canvas.drawRRect(rrect, Paint()..color = fill);
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 5.0;
    const gap = 4.0;
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
  bool shouldRepaint(covariant _DashedTilePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fill != fill;
}
