import 'package:flutter/material.dart';

import '../domain/password_policy.dart';
import '../theme/soft_widget.dart';

/// Live, rule-by-rule password feedback — the portal's sign-up checklist.
class PasswordChecklist extends StatelessWidget {
  final String password;
  final PasswordContext context_;
  const PasswordChecklist({super.key, required this.password, this.context_ = const PasswordContext()});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final check in passwordChecks(password, context_))
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  check.passed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: check.passed ? SoftColors.verifiedInk : SoftColors.chevron,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    check.label,
                    style: SoftType.cellLabel.copyWith(color: check.passed ? SoftColors.verifiedInk : SoftColors.muted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
