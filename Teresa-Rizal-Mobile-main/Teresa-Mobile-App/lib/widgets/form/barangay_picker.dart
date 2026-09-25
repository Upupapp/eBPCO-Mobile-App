import 'package:flutter/material.dart';

import '../../data/service_catalog_mock.dart';
import '../../theme/soft_widget.dart';

/// One barangay picker for Sakuna, Delayed Birth, and later evac / profile.
///
/// Search is not autofocused. The sheet pads by [MediaQuery.viewInsets] so
/// it rides the IME. The list keeps 20dp under the last row.
class BarangayPicker {
  BarangayPicker._();

  static const listPadding = EdgeInsets.fromLTRB(8, 0, 8, 20);
  static const scrollPadding = EdgeInsets.all(20);

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String subtitle = 'Teresa, Rizal · 9 barangays',
    String? selected,
    String? Function(String name)? subline,
    String? selectedHint,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoftColors.clear,
      builder: (ctx) {
        final inset = MediaQuery.viewInsetsOf(ctx).bottom;
        final height = MediaQuery.sizeOf(ctx).height;
        final reserve = height - 160;
        final maxHeight = reserve < height * 0.9 ? reserve : height * 0.9;
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: _BarangaySheet(
              title: title,
              subtitle: subtitle,
              selected: selected,
              subline: subline,
              selectedHint: selectedHint,
            ),
          ),
        );
      },
    );
  }
}

class _BarangaySheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? selected;
  final String? Function(String name)? subline;
  final String? selectedHint;

  const _BarangaySheet({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.subline,
    required this.selectedHint,
  });

  @override
  State<_BarangaySheet> createState() => _BarangaySheetState();
}

class _BarangaySheetState extends State<_BarangaySheet> {
  final _query = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<String> get _matches {
    final q = _query.text.trim().toLowerCase();
    final all = ServiceCatalogMock.barangays;
    if (q.isEmpty) return all;
    return all.where((name) => name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final total = ServiceCatalogMock.barangays.length;
    final querying = _query.text.trim().isNotEmpty;
    return Material(
      color: SoftColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(SoftRadius.xl)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const rowHeight = 56.0;
          final cap = constraints.maxHeight - 210;
          final listHeight = (matches.length * rowHeight + 20).clamp(rowHeight, cap < rowHeight ? rowHeight : cap);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: SoftColors.line,
                  borderRadius: BorderRadius.circular(SoftRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(widget.title, style: SoftType.pageTitle),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(widget.subtitle, style: CatalogType.meta),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  key: const Key('barangay-picker-search'),
                  controller: _query,
                  focusNode: _focus,
                  autofocus: false,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  scrollPadding: BarangayPicker.scrollPadding,
                  style: CatalogType.field,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search barangay',
                    hintStyle: CatalogType.hint,
                    prefixIcon: const Icon(Icons.search, color: SoftColors.muted, size: 20),
                    suffixIcon: _query.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            onPressed: () => setState(_query.clear),
                            icon: const Icon(Icons.close, size: 18, color: SoftColors.muted),
                          ),
                    filled: true,
                    fillColor: SoftColors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SoftRadius.pill),
                      borderSide: const BorderSide(color: SoftColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SoftRadius.pill),
                      borderSide: const BorderSide(color: SoftColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SoftRadius.pill),
                      borderSide: const BorderSide(color: SoftColors.blue, width: 1.5),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _focus.unfocus(),
                ),
              ),
              if (querying)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${matches.length} of $total barangays match',
                      key: const Key('barangay-match-count'),
                      style: CatalogType.meta,
                    ),
                  ),
                ),
              SizedBox(
                height: listHeight,
                child: ListView.builder(
                  key: const Key('barangay-picker-list'),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: BarangayPicker.listPadding,
                  itemExtent: rowHeight,
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final name = matches[index];
                    final selected = name == widget.selected;
                    final hint = (selected ? widget.selectedHint : null) ?? widget.subline?.call(name);
                    return ListTile(
                      key: Key('barangay-row-$name'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      leading: Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selected ? SoftColors.blue : SoftColors.chevron,
                        size: 22,
                      ),
                      title: _Highlighted(text: name, query: _query.text, selected: selected),
                      trailing: hint == null ? null : Text(hint, style: CatalogType.meta),
                      onTap: () => Navigator.of(context).pop(name),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Highlighted extends StatelessWidget {
  final String text;
  final String query;
  final bool selected;
  const _Highlighted({required this.text, required this.query, required this.selected});

  @override
  Widget build(BuildContext context) {
    final style = CatalogType.tileTitle.copyWith(
      color: selected ? SoftColors.blue : SoftColors.ink,
    );
    final q = query.trim();
    if (q.isEmpty) return Text(text, style: style);
    final lower = text.toLowerCase();
    final at = lower.indexOf(q.toLowerCase());
    if (at < 0) return Text(text, style: style);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, at), style: style),
          TextSpan(text: text.substring(at, at + q.length), style: CatalogType.highlight),
          TextSpan(text: text.substring(at + q.length), style: style),
        ],
      ),
    );
  }
}
