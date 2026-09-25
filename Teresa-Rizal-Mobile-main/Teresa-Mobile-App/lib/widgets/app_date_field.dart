import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// A labeled, tappable date field matching AppTextField/AppSelectField's
/// visual language (it reuses the app-wide InputDecorationTheme via a
/// read-only TextFormField rather than hand-rolling a lookalike box), that
/// opens the platform date picker — the mobile-native way to satisfy
/// "dropdowns/date pickers that work on mobile" without a custom calendar
/// widget.
class AppDateField extends StatefulWidget {
  final String? label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String hintText;
  final DateTime? firstDate;
  final DateTime? lastDate;

  AppDateField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.hintText = 'Select date',
    DateTime? firstDate,
    DateTime? lastDate,
  }) : firstDate = firstDate ?? DateTime(1900),
       lastDate = lastDate ?? DateTime.now();

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  // Owned once here instead of a fresh TextEditingController being
  // allocated on every build (the previous StatelessWidget did that
  // inline in its `controller:` argument, never disposing any of them) —
  // this instance is created once and just has its `.text` kept in sync
  // whenever `widget.value` changes.
  late final _controller = TextEditingController(text: _format(widget.value));

  String _format(DateTime? d) => d != null ? DateFormat('MMM d, y').format(d) : '';

  @override
  void didUpdateWidget(covariant AppDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? DateTime(widget.lastDate!.year - 25),
      firstDate: widget.firstDate!,
      lastDate: widget.lastDate!,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate700),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          readOnly: true,
          controller: _controller,
          onTap: () => _pick(context),
          style: const TextStyle(fontSize: 14, color: AppColors.textBody),
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 17, color: AppColors.slate400),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.slate400),
          ),
        ),
      ],
    );
  }
}
