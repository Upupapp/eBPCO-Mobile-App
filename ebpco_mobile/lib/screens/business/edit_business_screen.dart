import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/business_categories.dart';
import '../../domain/castilla.dart';
import '../../domain/models.dart';
import '../../services/applications_service.dart';
import '../../services/businesses_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

/// `PATCH /businesses/:id` — the owner-editable subset only:
/// registrationNumber/dateRegistered/status are not offered here at all,
/// matching the server's own `.strict()` refusal of them (see
/// citizen-api.models.ts's `UpdateBusinessRequest`).
class EditBusinessScreen extends StatefulWidget {
  final Business business;
  const EditBusinessScreen({super.key, required this.business});

  @override
  State<EditBusinessScreen> createState() => _EditBusinessScreenState();
}

class _EditBusinessScreenState extends State<EditBusinessScreen> {
  late final TextEditingController _name;
  late final TextEditingController _street;
  late String _category;
  late String? _barangay;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.business.name);
    _street = TextEditingController(text: widget.business.street);
    _category = widget.business.category;
    _barangay = widget.business.barangay;
  }

  @override
  void dispose() {
    _name.dispose();
    _street.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _street.text.trim().isEmpty || _barangay == null) {
      setState(() => _error = 'Please complete every required field.');
      return;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(openApplications > 0
            ? 'Business details updated. Applications already filed are unchanged.'
            : 'Business details updated.'),
      ));
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
