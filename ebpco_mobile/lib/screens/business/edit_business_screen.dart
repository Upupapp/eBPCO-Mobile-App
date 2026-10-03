import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/business_categories.dart';
import '../../domain/castilla.dart';
import '../../domain/models.dart';
import '../../domain/registration_number.dart';
import '../../services/applications_service.dart';
import '../../services/businesses_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../../widgets/message_bar.dart';

/// `PATCH /businesses/:id` — the owner-editable subset only. `status` is the
/// Municipality's and is not offered. The DTI/SEC/CDA registration number and
/// date are what the citizen typed, so they are theirs to correct until an
/// application under the business reaches the office (QA TC-24, 2026-10-03:
/// a mistyped "x" could never be fixed); after that they show read-only, with
/// who to ask — the portal's Edit Business, the same rule.
class EditBusinessScreen extends StatefulWidget {
  final Business business;
  const EditBusinessScreen({super.key, required this.business});

  @override
  State<EditBusinessScreen> createState() => _EditBusinessScreenState();
}

class _EditBusinessScreenState extends State<EditBusinessScreen> {
  late final TextEditingController _name;
  late final TextEditingController _street;
  late final TextEditingController _registrationNumber;
  late String _dateRegistered;
  late String _category;
  late String? _barangay;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.business.name);
    _street = TextEditingController(text: widget.business.street);
    _registrationNumber = TextEditingController(text: widget.business.registrationNumber);
    _dateRegistered = widget.business.dateRegistered.length >= 10
        ? widget.business.dateRegistered.substring(0, 10)
        : widget.business.dateRegistered;
    _category = widget.business.category;
    _barangay = widget.business.barangay;
  }

  @override
  void dispose() {
    _name.dispose();
    _street.dispose();
    _registrationNumber.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _street.text.trim().isEmpty || _barangay == null) {
      setState(() => _error = 'Please complete every required field.');
      return;
    }
    final locked = registrationLockedBy(context.read<ApplicationsService>().applications, widget.business.id);
    final registrationChanged = !locked &&
        (_registrationNumber.text.trim() != widget.business.registrationNumber ||
            _dateRegistered != widget.business.dateRegistered.substring(0, widget.business.dateRegistered.length.clamp(0, 10)));
    if (registrationChanged) {
      if (registrationNumberProblem(_registrationNumber.text) case final problem?) {
        setState(() => _error = problem);
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await CitizenApi.instance.updateBusiness(
        businessId: widget.business.id,
        name: _name.text.trim(),
        category: _category,
        street: _street.text.trim(),
        barangay: _barangay!,
        city: castillaCity,
        province: castillaProvince,
        registrationNumber: registrationChanged ? _registrationNumber.text.trim() : null,
        dateRegistered: registrationChanged ? _dateRegistered : null,
      );
      if (!mounted) return;
      await context.read<BusinessesService>().refresh();
      if (!mounted) return;
      // Says what did NOT move, like the portal: filed applications keep the
      // details they were filed with.
      const closed = {'Draft', 'Released', 'Completed', 'Rejected', 'Cancelled', 'Expired'};
      final openApplications = context
          .read<ApplicationsService>()
          .applications
          .where((a) => a.businessId == widget.business.id && !closed.contains(a.lifecycleStatus))
          .length;
      ScaffoldMessenger.of(context).showSnackBar(messageBar(openApplications > 0
            ? 'Business details updated. Applications already filed are unchanged.'
            : 'Business details updated.'));
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = registrationLockedBy(context.watch<ApplicationsService>().applications, widget.business.id);
    return SoftPageScaffold(
      title: 'Edit Business',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SoftFieldLabel('Business Name'),
            TextField(controller: _name, style: SoftType.field),
            const SizedBox(height: 16),
            const SoftFieldLabel('Category'),
            DropdownButtonFormField<String>(
              initialValue: businessCategories.contains(_category) ? _category : businessCategories.first,
              isExpanded: true,
              borderRadius: BorderRadius.circular(SoftRadius.md),
              items: businessCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            const SoftFieldLabel('Street Address'),
            TextField(controller: _street, style: SoftType.field),
            const SizedBox(height: 16),
            const SoftFieldLabel('Barangay'),
            DropdownButtonFormField<String>(
              initialValue: castillaBarangays.contains(_barangay) ? _barangay : null,
              isExpanded: true,
              borderRadius: BorderRadius.circular(SoftRadius.md),
              items: castillaBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _barangay = v),
            ),
            const SizedBox(height: 16),
            if (locked) ...[
              const SoftFieldLabel('DTI / SEC / CDA Registration'),
              Text(
                '${widget.business.registrationNumber} · registered ${_dateRegistered.isEmpty ? 'date not on file' : _dateRegistered}',
                style: SoftType.cellValue,
              ),
              const SizedBox(height: 6),
              Text(
                'An application filed under this business has reached the office, which now relies on these details. '
                'To correct them, ask the Office of the Building Official.',
                style: SoftType.body.copyWith(color: SoftColors.muted),
              ),
            ] else ...[
              const SoftFieldLabel('DTI / SEC / CDA Registration Number'),
              TextField(controller: _registrationNumber, style: SoftType.field),
              const SizedBox(height: 16),
              const SoftFieldLabel('Date Registered'),
              SoftPickerField(
                value: _dateRegistered.isEmpty ? null : _dateRegistered,
                placeholder: 'Select date',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(_dateRegistered) ?? DateTime.now(),
                    firstDate: DateTime(1980),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _dateRegistered = picked.toIso8601String().substring(0, 10));
                },
              ),
              const SizedBox(height: 6),
              Text('You can correct these until you file an application for this business.',
                  style: SoftType.body.copyWith(color: SoftColors.muted)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: AppTypography.error),
            ],
            const SizedBox(height: 26),
            SoftPillButton(label: 'Save Changes', busy: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
