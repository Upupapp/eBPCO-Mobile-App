import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/soft_widget.dart';
import 'soft_flow_scaffold.dart';

/// Mirrors `resources/views/components/ui/input.blade.php`: label above,
/// optional leading icon, slate-50 fill, brand-colored focus ring, rose
/// error state with helper text.
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? error;
  final String? hintText;
  final IconData? icon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final FocusNode? focusNode;
  final EdgeInsets scrollPadding;
  final TextInputAction? textInputAction;
  final Color? labelColor;
  final Color? textColor;
  final Color? iconColor;
  final Key? fieldKey;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.hintText,
    this.icon,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.suffix,
    this.focusNode,
    this.scrollPadding = const EdgeInsets.all(20),
    this.textInputAction,
    this.labelColor,
    this.textColor,
    this.iconColor,
    this.fieldKey,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _owned;
  late FocusNode _node;

  @override
  void initState() {
    super.initState();
    _bind(widget.focusNode);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _unbind();
      _bind(widget.focusNode);
    }
  }

  void _bind(FocusNode? external) {
    if (external != null) {
      _node = external;
      _owned = null;
    } else {
      _owned = FocusNode();
      _node = _owned!;
    }
    _node.addListener(_onFocus);
  }

  void _unbind() {
    _node.removeListener(_onFocus);
    _owned?.dispose();
    _owned = null;
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _node.hasFocus;
    final hasError = widget.error != null;
    final side = hasError
        ? SoftColors.danger
        : (focused ? SoftColors.blue : SoftColors.line);
    final radius = BorderRadius.circular(SoftRadius.md);
    const none = InputBorder.none;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.labelColor ?? SoftColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // The ring is painted here, not by InputDecorator. That decorator
        // lerps every field that was focused recently, so a fast fill leaves
        // several blue rings at once. This border follows hasFocus immediately.
        Material(
          color: SoftColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: side, width: focused || hasError ? 1.5 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: TextField(
            key: widget.fieldKey,
            controller: widget.controller,
            focusNode: _node,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            scrollPadding: widget.scrollPadding,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            onChanged: widget.onChanged,
            onTap: () => SoftIme.reveal(context),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: widget.textColor ?? SoftColors.ink,
              height: 1.3,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: SoftColors.white,
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: SoftColors.muted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: widget.icon != null
                  ? Icon(
                      widget.icon,
                      size: 18,
                      color: widget.iconColor ?? SoftColors.muted,
                    )
                  : null,
              suffixIcon: widget.suffix,
              border: none,
              enabledBorder: none,
              focusedBorder: none,
              errorBorder: none,
              focusedErrorBorder: none,
              disabledBorder: none,
            ),
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.error!,
            style: const TextStyle(
              fontSize: 12,
              color: SoftColors.danger,
              height: 1.35,
            ),
          ),
        ] else if (widget.hint != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.hint!,
            style: const TextStyle(
              fontSize: 12,
              color: SoftColors.muted,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

/// A labeled dropdown/select, mirroring the same visual language as
/// AppTextField for use in multi-step forms (document/assistance requests).
class AppSelectField<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;
  final String? hintText;

  const AppSelectField({
    super.key,
    this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: SoftColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: SoftColors.muted,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: SoftColors.muted),
          ),
          items: [
            ...options,
            // A stored barangay can sit outside the official list (the
            // unverified duplicate demo uses Libertad). DropdownButton
            // throws if its value is missing from the items.
            if (value != null && !options.contains(value)) value as T,
          ]
              .map(
                (o) => DropdownMenuItem<T>(
                  value: o,
                  child: Text(
                    labelBuilder(o),
                    style: const TextStyle(fontSize: 14, color: SoftColors.ink),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
