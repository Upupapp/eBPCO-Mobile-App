import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';

/// One choice in a [showSoftActionSheet].
class SoftSheetAction<T> {
  final T value;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool destructive;

  const SoftSheetAction({required this.value, required this.icon, required this.title, this.subtitle, this.destructive = false});
}

/// The drag handle every sheet in the app opens with.
class SoftSheetHandle extends StatelessWidget {
  const SoftSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(color: SoftColors.line, borderRadius: BorderRadius.circular(SoftRadius.pill)),
        ),
      );
}

/// A short list of choices in the same shape as the Services sheet (handle,
/// title, rows with soft icon tiles). Returns the chosen value, or null.
Future<T?> showSoftActionSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<SoftSheetAction<T>> actions,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SoftSheetHandle(),
            const SizedBox(height: 18),
            Text(title, style: SoftType.section.copyWith(fontSize: 20, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: SoftType.body.copyWith(fontSize: 15)),
            ],
            const SizedBox(height: 14),
            for (final action in actions)
              InkWell(
                borderRadius: BorderRadius.circular(SoftRadius.md),
                onTap: () => Navigator.of(sheetContext).pop(action.value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: action.destructive ? SoftColors.dangerSoft : SoftColors.primarySoft,
                          borderRadius: BorderRadius.circular(SoftRadius.md),
                        ),
                        child: Icon(action.icon, color: action.destructive ? SoftColors.danger : SoftColors.primary, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action.title,
                              style: SoftType.tileTitle.copyWith(fontSize: 17, color: action.destructive ? SoftColors.danger : null),
                            ),
                            if (action.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(action.subtitle!, style: SoftType.tileSub.copyWith(fontSize: 14)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
