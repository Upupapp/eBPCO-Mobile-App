import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Centralized confirmation dialog + toast helpers so every screen shows
/// confirmations/success/error feedback consistently (Section 2 of the
/// alignment doc — reusable states, not per-screen one-offs).
class AppDialogs {
  AppDialogs._();

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool danger = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ConfirmSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        danger: danger,
      ),
    );
    return result ?? false;
  }

  /// A single-button acknowledgment sheet — same visual shell as
  /// [confirm], for a message that only needs a dismiss action (e.g. "a
  /// permission wasn't granted, but you can keep using the app").
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InfoSheet(title: title, message: message, actionLabel: actionLabel),
    );
  }

  /// Same title/message/actions shape as [confirm], but presented as a
  /// centered dialog (`showDialog`/`Dialog`) rather than a bottom sheet —
  /// reserved for the rarer, higher-stakes confirmations (e.g. changing a
  /// profile photo bound to a 6-month cooldown) that should read as
  /// distinctly different from routine bottom-sheet confirmations.
  static Future<bool> centeredConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CenteredConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        danger: danger,
      ),
    );
    return result ?? false;
  }

  /// Centered single-button counterpart to [info] — see [centeredConfirm].
  static Future<void> centeredInfo(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _CenteredInfoDialog(title: title, message: message, actionLabel: actionLabel),
    );
  }

  static void toast(BuildContext context, String message, {bool success = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_rounded,
              size: 18,
              color: success ? AppColors.emerald500 : AppColors.brand400,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;

  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scrollable rather than sized-to-content: a long message (a
            // policy explanation, say) would otherwise overflow the sheet
            // on a short device instead of the actions staying reachable.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Text(message, style: const TextStyle(fontSize: 13.5, color: AppColors.slate500, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: danger ? AppButtonVariant.danger : AppButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;

  const _CenteredConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Text(message, style: const TextStyle(fontSize: 13.5, color: AppColors.slate500, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: danger ? AppButtonVariant.danger : AppButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredInfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;

  const _CenteredInfoDialog({required this.title, required this.message, required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Text(message, style: const TextStyle(fontSize: 13.5, color: AppColors.slate500, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: actionLabel,
              variant: AppButtonVariant.primary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;

  const _InfoSheet({required this.title, required this.message, required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scrollable rather than sized-to-content — see _ConfirmSheet's
            // matching comment.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Text(message, style: const TextStyle(fontSize: 13.5, color: AppColors.slate500, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: actionLabel,
              variant: AppButtonVariant.primary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
