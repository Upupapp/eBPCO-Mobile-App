import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';
import 'soft_chrome.dart';

/// Every inside screen's frame, matching the design reference's page bar:
/// the radial wash behind everything, a round white back button (only when
/// there is somewhere to go back to), the 17/500 page title, and optional
/// trailing round actions. [body] fills the rest.
class SoftPageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool showBack;

  /// A root-shell tab: the body runs behind the floating nav instead of
  /// stopping above it, so lists pad with [SoftPageScaffold.navClearance].
  final bool underNav;

  const SoftPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.showBack = true,
    this.underNav = false,
  });

  /// Bottom list padding that clears the floating nav and system inset.
  static double navClearance(BuildContext context) => MediaQuery.paddingOf(context).bottom + 24;

  @override
  Widget build(BuildContext context) {
    // A tab is a root page: canPop() can read true while a pushed page is on
    // top of it, and the stale arrow then survives the pop.
    final canPop = showBack && !underNav && Navigator.of(context).canPop();
    return SoftWash(
      child: Scaffold(
        backgroundColor: SoftColors.clear,
        body: SafeArea(
          bottom: !underNav,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(canPop ? 10 : 22, 8, 12, 4),
                child: ConstrainedBox(
                  // Same bar height with or without a round button in it, so a
                  // title never jumps when an action appears or goes away.
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                  children: [
                    if (canPop) ...[
                      SoftCircleButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SoftType.pageTitle.copyWith(fontSize: 19)),
                    ),
                    ...actions,
                  ],
                ),
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round header action in the page bar (e.g. "+" or edit).
class SoftBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const SoftBarAction({super.key, required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) => SoftCircleButton(icon: icon, tooltip: tooltip, onPressed: onPressed);
}

/// Grouped list rows in ONE card with hairline dividers — the reference's
/// Profile "Account"/"Activity" sections.
class SoftGroupedList extends StatelessWidget {
  final List<SoftListRow> rows;
  const SoftGroupedList({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(SoftRadius.lg), boxShadow: SoftShadows.card),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        child: Material(
          color: SoftColors.white,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: SoftColors.line),
                rows[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SoftListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconBackground;
  final Color? iconColor;

  const SoftListRow({super.key, required this.icon, required this.title, this.subtitle, required this.onTap, this.iconBackground, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: iconBackground ?? SoftColors.primarySoft, borderRadius: BorderRadius.circular(SoftRadius.sm)),
              child: Icon(icon, color: iconColor ?? SoftColors.primary, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: SoftType.tileTitle.copyWith(fontSize: 16)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: SoftType.tileSub),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: SoftColors.chevron),
          ],
        ),
      ),
    );
  }
}
