import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/service_catalog_mock.dart';
import '../../theme/soft_widget.dart';
import '../support/help_support_screen.dart';
import 'catalog_chrome.dart';
import 'catalog_detail_screen.dart';

enum DokyuAnchor { top, continued }

class DokyuCatalogScreen extends StatefulWidget {
  final String initialQuery;
  final DokyuAnchor anchor;

  const DokyuCatalogScreen({
    super.key,
    this.initialQuery = '',
    this.anchor = DokyuAnchor.top,
  });

  @override
  State<DokyuCatalogScreen> createState() => _DokyuCatalogScreenState();
}

class _DokyuCatalogScreenState extends State<DokyuCatalogScreen> {
  late final TextEditingController _query;
  Timer? _debounce;
  String _applied = '';

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
    _applied = widget.initialQuery;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _applied = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final searching = _applied.trim().isNotEmpty;
    final results = searching ? ServiceCatalogMock.search(_applied) : ServiceCatalogMock.dokyu;
    return CatalogPage(
      title: 'Dokyu',
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                key: const Key('dokyu-search-field'),
                controller: _query,
                autofocus: false,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                scrollPadding: kFieldScrollPadding,
                style: CatalogType.field,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search documents',
                  hintStyle: CatalogType.hint,
                  prefixIcon: const Icon(Icons.search, color: SoftColors.muted, size: 20),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            _query.clear();
                            _debounce?.cancel();
                            setState(() => _applied = '');
                          },
                          icon: const Icon(Icons.close, size: 18, color: SoftColors.muted),
                        ),
                  filled: true,
                  fillColor: SoftColors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                onChanged: (value) {
                  setState(() {});
                  _onChanged(value);
                },
                onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
            if (!searching) const _Chips(),
            Expanded(
              child: ListView(
                key: const Key('dokyu-results'),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (searching) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Text(
                        keyboard
                            ? '${results.length} results in Dokyu · filters as you type'
                            : '${results.length} results in Dokyu',
                        style: CatalogType.meta,
                      ),
                    ),
                    if (results.isEmpty) const _NoResults() else ..._resultTiles(results),
                    if (keyboard) ...[
                      const HonestyNote(text: ServiceCatalogMock.dokyuHonesty),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Text(ServiceCatalogMock.dokyuSearchTipShort, style: CatalogType.note),
                      ),
                    ] else ...[
                      if (results.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: Text(ServiceCatalogMock.dokyuSearchTip, style: CatalogType.note),
                        ),
                      const HonestyNote(text: ServiceCatalogMock.dokyuHonesty),
                    ],
                  ] else if (widget.anchor == DokyuAnchor.continued)
                    ..._continued()
                  else
                    ..._top(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _resultTiles(List<DokyuService> results) {
    return [
      for (final item in results)
        _DokyuTile(item: item, query: _applied),
    ];
  }

  List<Widget> _top() {
    return [
      const HonestyNote(text: ServiceCatalogMock.dokyuHonesty),
      _section(DokyuSection.barangay, ServiceCatalogMock.dokyu.where((e) => e.section == DokyuSection.barangay)),
      _section(
        DokyuSection.civil,
        ServiceCatalogMock.dokyu.where((e) => e.section == DokyuSection.civil).take(3),
      ),
    ];
  }

  List<Widget> _continued() {
    final civil = ServiceCatalogMock.dokyu.where((e) => e.section == DokyuSection.civil).skip(3);
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(
          children: [
            const Expanded(
              child: Text('Civil registry · continued', style: CatalogType.sectionLabel),
            ),
            Text('5 of ${ServiceCatalogMock.sectionCount(DokyuSection.civil)}', style: CatalogType.meta),
          ],
        ),
      ),
      for (final item in civil) _DokyuTile(item: item),
      _section(DokyuSection.business, ServiceCatalogMock.dokyu.where((e) => e.section == DokyuSection.business)),
      _section(DokyuSection.ids, ServiceCatalogMock.dokyu.where((e) => e.section == DokyuSection.ids)),
    ];
  }

  Widget _section(DokyuSection section, Iterable<DokyuService> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Text(ServiceCatalogMock.sectionTitle(section), style: CatalogType.sectionLabel),
        ),
        for (final item in items) _DokyuTile(item: item),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips();

  @override
  Widget build(BuildContext context) {
    final chips = [
      ('All ${ServiceCatalogMock.dokyu.length}', true),
      ('Barangay ${ServiceCatalogMock.sectionCount(DokyuSection.barangay)}', false),
      ('Civil registry ${ServiceCatalogMock.sectionCount(DokyuSection.civil)}', false),
      ('Business & tax ${ServiceCatalogMock.sectionCount(DokyuSection.business)}', false),
      ('IDs ${ServiceCatalogMock.sectionCount(DokyuSection.ids)}', false),
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final chip in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: chip.$2 ? SoftColors.blue : SoftColors.white,
                  borderRadius: BorderRadius.circular(SoftRadius.pill),
                  border: Border.all(color: chip.$2 ? SoftColors.blue : SoftColors.line),
                ),
                child: Text(
                  chip.$1,
                  style: CatalogType.chip.copyWith(color: chip.$2 ? SoftColors.white : SoftColors.ink),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DokyuTile extends StatelessWidget {
  final DokyuService item;
  final String query;
  const _DokyuTile({required this.item, this.query = ''});

  @override
  Widget build(BuildContext context) {
    final tint = dokyuTint(item.section);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(SoftRadius.lg),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DokyuDetailScreen(service: item)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconDisc(icon: Icons.description_outlined, background: tint.$1, foreground: tint.$2),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(TextSpan(children: highlightQuery(item.display, query, CatalogType.tileTitle))),
                      const SizedBox(height: 2),
                      Text(
                        '${item.fee} · ${item.time} · ${item.requirements} req.',
                        style: CatalogType.fee,
                      ),
                    ],
                  ),
                ),
                const SamplePill(),
                const Icon(Icons.chevron_right_rounded, color: SoftColors.chevron),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    final related = ServiceCatalogMock.relatedWhenEmpty
        .map(ServiceCatalogMock.dokyuById)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text('No Dokyu service matches', style: SoftType.h1),
        ),
        const HonestyNote(text: ServiceCatalogMock.noResultsHonesty),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text('Related in Business, tax & property', style: CatalogType.sectionLabel),
        ),
        for (final item in related) _DokyuTile(item: item),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: CatalogCta(
            label: 'Browse all ${ServiceCatalogMock.dokyu.length}',
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DokyuCatalogScreen()),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
          ),
          child: const Text('Help & Support', style: CatalogType.link),
        ),
      ],
    );
  }
}
