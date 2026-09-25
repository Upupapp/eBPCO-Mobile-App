import 'package:flutter/material.dart';
import '../models/request_filters.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// The shared filtering UI for Dokyu and Tulong (and reusable for any
/// future request-style list) — keeps the main list screen clean per the
/// nav spec's "don't display every possible filter directly on the main
/// screen" by moving Search/Barangay-LGU/Type/Status/Date/Sort into one
/// bottom sheet behind a single "Filter" button. Edits a working copy of
/// [RequestFilters] and returns the new value on "Apply Filters"; the
/// caller applies it, this sheet never touches the request list itself.
class FilterBottomSheet extends StatefulWidget {
  final RequestFilters initial;
  final List<String> typeOptions;
  final List<String> statusOptions;
  final Color accent;

  const FilterBottomSheet({
    super.key,
    required this.initial,
    required this.typeOptions,
    required this.statusOptions,
    required this.accent,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RequestFilters _draft = widget.initial;
  late final _searchController = TextEditingController(text: widget.initial.search);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(999)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filter Requests',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _draft = const RequestFilters();
                        _searchController.clear();
                      }),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: 'Search',
                        hintText: 'Reference number, type, office...',
                        icon: Icons.search_rounded,
                        controller: _searchController,
                        onChanged: (v) => setState(() => _draft = _draft.copyWith(search: v)),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _sectionLabel('Barangay / LGU'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final scope in RequestScope.values)
                            _Pill(
                              label: scope.label,
                              selected: _draft.scope == scope,
                              accent: widget.accent,
                              onTap: () => setState(
                                () => _draft = _draft.scope == scope
                                    ? _draft.copyWith(clearScope: true)
                                    : _draft.copyWith(scope: scope),
                              ),
                            ),
                        ],
                      ),
                      if (widget.typeOptions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _sectionLabel('Request Type'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final type in widget.typeOptions)
                              _Pill(
                                label: type,
                                selected: _draft.typeName == type,
                                accent: widget.accent,
                                onTap: () => setState(
                                  () => _draft = _draft.typeName == type
                                      ? _draft.copyWith(clearTypeName: true)
                                      : _draft.copyWith(typeName: type),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (widget.statusOptions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _sectionLabel('Status'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final status in widget.statusOptions)
                              _Pill(
                                label: status,
                                selected: _draft.status == status,
                                accent: widget.accent,
                                onTap: () => setState(
                                  () => _draft = _draft.status == status
                                      ? _draft.copyWith(clearStatus: true)
                                      : _draft.copyWith(status: status),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _sectionLabel('Date Submitted'),
                      const SizedBox(height: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.slate50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.slate500),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _draft.dateRange == null ? 'Any date' : _formatRange(_draft.dateRange!),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.slate700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_draft.dateRange != null)
                                InkWell(
                                  onTap: () => setState(() => _draft = _draft.copyWith(clearDateRange: true)),
                                  child: const Icon(Icons.close_rounded, size: 17, color: AppColors.slate400),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _sectionLabel('Sort By'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final sort in RequestSort.values)
                            _Pill(
                              label: sort.label,
                              selected: _draft.sort == sort,
                              accent: widget.accent,
                              onTap: () => setState(() => _draft = _draft.copyWith(sort: sort)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: AppButton(
                  label: 'Apply Filters',
                  fullWidth: true,
                  size: AppButtonSize.lg,
                  onPressed: () => Navigator.of(context).pop(_draft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.slate600),
  );

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _draft.dateRange,
    );
    if (picked != null) setState(() => _draft = _draft.copyWith(dateRange: picked));
  }

  String _formatRange(DateTimeRange r) => '${_fmt(r.start)} – ${_fmt(r.end)}';
  String _fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.1) : AppColors.slate50,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? accent : AppColors.slate200),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? accent : AppColors.slate600),
        ),
      ),
    );
  }
}
