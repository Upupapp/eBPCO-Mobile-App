import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/business_categories.dart';
import '../../domain/castilla.dart';
import '../../domain/models.dart';
import '../../services/businesses_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

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
      setState(() => _error = 'Fill in every field.');
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
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Business')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Business Name', style: AppTypography.fieldLabel),
              const SizedBox(height: 6),
              TextField(controller: _name),
              const SizedBox(height: AppSpacing.lg),
              Text('Category', style: AppTypography.fieldLabel),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: businessCategories.contains(_category) ? _category : businessCategories.first,
                items: businessCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Street Address', style: AppTypography.fieldLabel),
              const SizedBox(height: 6),
              TextField(controller: _street),
              const SizedBox(height: AppSpacing.lg),
              Text('Barangay', style: AppTypography.fieldLabel),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: castillaBarangays.contains(_barangay) ? _barangay : null,
                isExpanded: true,
                items: castillaBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _barangay = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: AppTypography.error),
              ],
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
