import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';
import 'soft_chrome.dart';

/// Keyboard inset and scroll-into-view for request forms and sheets.
class SoftIme {
  SoftIme._();

  /// `MediaQuery.viewInsets.bottom`. Inside a scaffold that already
  /// resizes, this is usually zero; sheets and manual padding still read it.
  static double bottom(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom;

  /// Scrolls [fieldContext] into view after the inset has been applied.
  static void reveal(BuildContext fieldContext) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!fieldContext.mounted) return;
      if (Scrollable.maybeOf(fieldContext) == null) return;
      Scrollable.ensureVisible(
        fieldContext,
        alignment: 0.22,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

/// Soft-wash page used by the request series (list, catalog, wizard, detail).
/// No navy app bar. [resizeToAvoidBottomInset] stays on so the IME lifts
/// the body; callers also pad with [SoftIme.bottom] where a sheet or a
/// scroll view sits outside that resize.
class SoftFlowScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final String backTooltip;
  final List<Widget> actions;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool resizeToAvoidBottomInset;

  /// Centers [title] in the page bar. Used by the locked request catalog,
  /// which has a back control and no trailing actions.
  final bool centerTitle;

  const SoftFlowScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.onBack,
    this.backTooltip = 'Back',
    this.actions = const [],
    this.floatingActionButton,
    this.drawer,
    this.scaffoldKey,
    this.resizeToAvoidBottomInset = true,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final back =
        onBack ?? (navigator.canPop() ? () => navigator.pop() : null);

    return SoftWash(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: SoftColors.clear,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        drawer: drawer,
        floatingActionButton: floatingActionButton,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: centerTitle
                    ? SizedBox(
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (back != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SoftCircleButton(
                                  icon: Icons.arrow_back_rounded,
                                  tooltip: backTooltip,
                                  onPressed: back,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 52),
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: SoftType.pageBar,
                              ),
                            ),
                            if (actions.isNotEmpty)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final action in actions) ...[
                                      const SizedBox(width: 8),
                                      action,
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          if (back != null) ...[
                            SoftCircleButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: backTooltip,
                              onPressed: back,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: SoftType.pageBar,
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: SoftType.cellLabel,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          for (final action in actions) ...[
                            const SizedBox(width: 8),
                            action,
                          ],
                        ],
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
