import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/business_categories.dart';
import '../../domain/castilla.dart';
import '../../services/businesses_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class RegisterBusinessScreen extends StatefulWidget {
  const RegisterBusinessScreen({super.key});

  @override
  State<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends State<RegisterBusinessScreen> {
  final _name = TextEditingController();
  final _street = TextEditingController();
  final _registrationNumber = TextEditingController();
  String _category = businessCategories.first;
  String? _barangay;
  DateTime? _dateRegistered;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _street, _registrationNumber]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _street.text.trim().isEmpty || _barangay == null || _registrationNumber.text.trim().isEmpty || _dateRegistered == null) {
      setState(() => _error = 'Fill in every field.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await CitizenApi.instance.registerBusiness(
        name: _name.text.trim(),
        category: _category,
        street: _street.text.trim(),
        barangay: _barangay!,
        city: castillaCity,
        province: castillaProvince,
        registrationNumber: _registrationNumber.text.trim(),
        dateRegistered: _dateRegistered!.toIso8601String().substring(0, 10),
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
      appBar: AppBar(title: const Text('Register a Business')),
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
                initialValue: _category,
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
                initialValue: _barangay,
                hint: const Text('Select barangay'),
                isExpanded: true,
                items: castillaBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _barangay = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('City / Municipality', style: AppTypography.fieldLabel),
                        const SizedBox(height: 6),
                        TextField(controller: TextEditingController(text: castillaCity), enabled: false),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Province', style: AppTypography.fieldLabel),
                        const SizedBox(height: 6),
                        TextField(controller: TextEditingController(text: castillaProvince), enabled: false),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('DTI/SEC Registration Number', style: AppTypography.fieldLabel),
              const SizedBox(height: 6),
              TextField(controller: _registrationNumber),
              const SizedBox(height: AppSpacing.lg),
              Text('Date Registered', style: AppTypography.fieldLabel),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1980), lastDate: DateTime.now());
                  if (picked != null) setState(() => _dateRegistered = picked);
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_dateRegistered == null
                      ? 'Select date'
                      : '${_dateRegistered!.year}-${_dateRegistered!.month.toString().padLeft(2, '0')}-${_dateRegistered!.day.toString().padLeft(2, '0')}'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: AppTypography.error),
              ],
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Register Business'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
