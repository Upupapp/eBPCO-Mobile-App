import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/business_categories.dart';
import '../../domain/castilla.dart';
import '../../services/businesses_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../../widgets/message_bar.dart';

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
      setState(() => _error = 'Please complete all required fields.');
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
      ScaffoldMessenger.of(context).showSnackBar(messageBar('${_name.text.trim()} registered with the Municipality.'));
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
      title: 'Register a Business',
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
              initialValue: _category,
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
              initialValue: _barangay,
              hint: const Text('Select barangay'),
              isExpanded: true,
              borderRadius: BorderRadius.circular(SoftRadius.md),
              items: castillaBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _barangay = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SoftFieldLabel('City / Municipality'),
                      TextField(controller: TextEditingController(text: castillaCity), enabled: false, style: SoftType.field),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SoftFieldLabel('Province'),
                      TextField(controller: TextEditingController(text: castillaProvince), enabled: false, style: SoftType.field),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SoftFieldLabel('DTI/SEC Registration Number'),
            TextField(controller: _registrationNumber, style: SoftType.field),
            const SizedBox(height: 16),
            const SoftFieldLabel('Date Registered'),
            SoftPickerField(
              value: _dateRegistered == null
                  ? null
                  : '${_dateRegistered!.year}-${_dateRegistered!.month.toString().padLeft(2, '0')}-${_dateRegistered!.day.toString().padLeft(2, '0')}',
              placeholder: 'Select date',
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1980), lastDate: DateTime.now());
                if (picked != null) setState(() => _dateRegistered = picked);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: AppTypography.error),
            ],
            const SizedBox(height: 26),
            SoftPillButton(label: 'Register Business', busy: _saving, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
