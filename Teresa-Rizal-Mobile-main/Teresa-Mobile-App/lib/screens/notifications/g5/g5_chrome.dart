import 'package:flutter/material.dart';

import '../../../theme/app_typography.dart';
import '../../../theme/soft_widget.dart';
import '../../../widgets/soft_chrome.dart';

enum G5ButtonKind { primary, outline, danger, text, disabled }

/// Pill used on Pack E landings. [onPressed] null is the soft-disabled state.
class G5Button extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final G5ButtonKind kind;

  const G5Button({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.kind = G5ButtonKind.primary,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = kind == G5ButtonKind.disabled || onPressed == null;
    final (background, foreground, border) = switch (kind) {
      G5ButtonKind.primary => (SoftColors.blue, SoftColors.white, null),
      G5ButtonKind.outline => (SoftColors.white, SoftColors.blue, SoftColors.line),
      G5ButtonKind.danger => (SoftColors.danger, SoftColors.white, null),
      G5ButtonKind.text => (SoftColors.clear, SoftColors.blue, null),
      G5ButtonKind.disabled => (SoftColors.line, SoftColors.muted, null),
    };
    final fill = disabled && kind != G5ButtonKind.text
        ? SoftColors.line
        : background;
    final ink = disabled && kind != G5ButtonKind.text
        ? SoftColors.muted
        : foreground;
    return Semantics(
      button: true,
      enabled: !disabled && onPressed != null,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(SoftRadius.pill),
          onTap: disabled ? null : onPressed,
          child: Container(
            height: kind == G5ButtonKind.text ? 40 : 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SoftRadius.pill),
              border: border == null ? null : Border.all(color: border),
              boxShadow: kind == G5ButtonKind.primary && !disabled
                  ? SoftShadows.primary
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: ink),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SoftType.bannerTitle.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class G5Honesty extends StatelessWidget {
  final String lead;
  final String rest;
  final bool strong;
  final IconData icon;
  final bool compact;

  const G5Honesty({
    super.key,
    required this.lead,
    required this.rest,
    this.strong = false,
    this.icon = Icons.info_outline_rounded,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = SoftType.greetingHi.copyWith(
      color: SoftColors.ink,
      height: 1.4,
      fontSize: compact ? 11 : 12,
    );
    return Container(
      margin: EdgeInsets.only(top: compact ? 10 : 12),
      padding: EdgeInsets.fromLTRB(compact ? 12 : 14, compact ? 8 : 12, 12, compact ? 8 : 12),
      decoration: BoxDecoration(
        color: strong ? SoftColors.endedWash : SoftColors.blueSoft,
        borderRadius: BorderRadius.circular(SoftRadius.md),
        border: strong
            ? Border.all(color: SoftColors.gold.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 24 : 28,
            height: compact ? 24 : 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SoftColors.white,
              borderRadius: BorderRadius.circular(compact ? 8 : 10),
              boxShadow: SoftShadows.cardSm,
            ),
            child: Icon(
              icon,
              size: 14,
              color: strong ? SoftColors.endedInk : SoftColors.blue,
            ),
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

/// Push page bar. Share is optional; landings without it keep a spacer
/// so the title stays centered. No bottom nav.
class G5Page extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onShare;
  final bool openedFromNotification;
  final String? eyebrowAux;
  final Widget body;
  final Widget? footer;

  const G5Page({
    super.key,
    required this.title,
    required this.onBack,
    required this.body,
    this.onShare,
    this.openedFromNotification = true,
    this.eyebrowAux,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return SoftWash(
      child: Scaffold(
        backgroundColor: SoftColors.clear,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SoftCircleButton(
                          icon: Icons.chevron_left_rounded,
                          tooltip: 'Back',
                          onPressed: onBack,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 52),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: SoftType.pageTitle,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: onShare == null
                            ? const SizedBox(width: 36, height: 36)
                            : SoftCircleButton(
                                icon: Icons.ios_share_rounded,
                                tooltip: 'Share',
                                onPressed: onShare!,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: body),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

class G5Eyebrow extends StatelessWidget {
  final String? aux;

  const G5Eyebrow({super.key, this.aux});

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SoftColors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: AppTypography.sans,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.12,
                      color: SoftColors.blueDeep,
                      fontFeatures: SoftType.features,
                    ),
                    children: [
                      const TextSpan(text: 'Opened from notification'),
                      if (aux != null) ...[
                        TextSpan(
                          text: '  ·  ',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: SoftColors.blueDeep.withValues(alpha: 0.45),
                          ),
                        ),
                        TextSpan(
                          text: aux,
                          style: const TextStyle(fontWeight: FontWeight.w400),
                        ),
                      ],
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class G5Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;

  const G5Card({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.shadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(
          color: borderColor ?? SoftColors.lineSoft,
          width: borderWidth,
        ),
        boxShadow: shadow ?? (color == null ? SoftShadows.cardSm : null),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: SoftColors.clear,
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        onTap: onTap,
        child: box,
      ),
    );
  }
}

class G5IconDisc extends StatelessWidget {
  final IconData icon;
  final Color wash;
  final Color color;
  final double size;

  const G5IconDisc({
    super.key,
    required this.icon,
    required this.wash,
    required this.color,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(size > 40 ? 16 : 12),
      ),
      child: Icon(icon, size: size >= 44 ? 22 : 16, color: color),
    );
  }
}

/// Soft circle + stroked pin. The comp's filled map SVG renders black;
/// this uses the app icon disc instead.
class G5MapPin extends StatelessWidget {
  const G5MapPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SoftColors.slotIconFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.place_outlined,
        size: 20,
        color: SoftColors.blue,
      ),
    );
  }
}

void g5Back(BuildContext context) => Navigator.of(context).maybePop();
