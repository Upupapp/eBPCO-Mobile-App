import 'package:flutter/material.dart';

import '../../screens/catalog/catalog_chrome.dart';
import '../../theme/soft_widget.dart';

class SoftFormField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? error;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autocorrect;
  final bool enableSuggestions;
  final int maxLines;
  final int minLines;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final Key? fieldKey;
  final String? counter;

  const SoftFormField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.error,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines = 1,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.fieldKey,
    this.counter,
  });

  @override
  State<SoftFormField> createState() => _SoftFormFieldState();
}

class _SoftFormFieldState extends State<SoftFormField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_reveal);
  }

  @override
  void didUpdateWidget(SoftFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_reveal);
      widget.focusNode?.addListener(_reveal);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_reveal);
    super.dispose();
  }

  /// The IME reveal targets the caret. Run a frame later so the whole
  /// field, including helper or error text, stays 20dp above the footer.
  void _reveal() {
    if (widget.focusNode?.hasFocus != true) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.focusNode?.hasFocus != true) return;
        Scrollable.ensureVisible(
          context,
          alignment: 1,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          duration: Duration.zero,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.label, style: CatalogType.fieldLabel)),
              if (widget.counter != null) Text(widget.counter!, style: CatalogType.meta),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            key: widget.fieldKey,
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.textCapitalization,
            textInputAction: widget.textInputAction,
            autocorrect: widget.autocorrect,
            enableSuggestions: widget.enableSuggestions,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            onSubmitted: widget.onSubmitted,
            onChanged: widget.onChanged,
            scrollPadding: kFieldScrollPadding,
            style: CatalogType.field,
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              hintStyle: CatalogType.hint,
              helperText: widget.helper,
              helperStyle: CatalogType.helper,
              helperMaxLines: 3,
              errorText: widget.error,
              errorStyle: CatalogType.error,
              errorMaxLines: 3,
              suffixIcon: widget.suffix,
              filled: true,
              fillColor: widget.error == null ? SoftColors.white : SoftColors.errorFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: _border(SoftColors.line),
              enabledBorder: _border(widget.error == null ? SoftColors.line : SoftColors.danger),
              focusedBorder: _border(widget.error == null ? SoftColors.blue : SoftColors.danger, 1.5),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, [double width = 1.5]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(SoftRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class YesNoTiles extends StatelessWidget {
  final String label;
  final bool? value;
  final ValueChanged<bool> onChanged;

  const YesNoTiles({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: CatalogType.fieldLabel),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(child: _tile('Yes', value == true, () => onChanged(true))),
            const SizedBox(width: 8),
            Expanded(child: _tile('No', value == false, () => onChanged(false))),
          ],
        ),
      ],
    );
  }

  Widget _tile(String text, bool on, VoidCallback tap) {
    return Material(
      color: on ? SoftColors.blueWash : SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.md),
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(SoftRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.md),
            border: Border.all(
              color: on ? SoftColors.blue : SoftColors.line,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (on) ...[
                const Icon(Icons.check_rounded, size: 16, color: SoftColors.blue),
                const SizedBox(width: 6),
              ],
              Text(text, style: on ? CatalogType.buttonInk : CatalogType.tileTitle),
            ],
          ),
        ),
      ),
    );
  }
}
