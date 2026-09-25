import 'package:flutter/material.dart';
import 'package:teresa_rizal/data/service_catalog_mock.dart';
import 'package:teresa_rizal/screens/catalog/catalog_chrome.dart';
import 'package:teresa_rizal/theme/soft_widget.dart';
import 'package:teresa_rizal/widgets/form/barangay_picker.dart';
import 'package:teresa_rizal/widgets/form/soft_form_fields.dart';

/// Harness-only gallery for the fields-a / fields-b frames.
/// Lives under test/ so it is not a product route reachable from main.dart.
class FieldSpecimenGallery extends StatelessWidget {
  final bool showPicker;
  const FieldSpecimenGallery({super.key, this.showPicker = false});

  @override
  Widget build(BuildContext context) {
    if (showPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        BarangayPicker.show(
          context,
          title: 'Barangay',
          selected: 'Dalig',
          selectedHint: 'From your profile',
        );
      });
    }
    return CatalogPage(
      title: 'Fields',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SoftFormField(label: 'Full name', hint: 'Maria Santos Reyes'),
          SoftFormField(
            label: 'Mobile',
            hint: '0917 555',
            helper: '11 digits, starts with 09',
            keyboardType: TextInputType.phone,
          ),
          SoftFormField(
            label: 'Email',
            hint: 'maria.reyes@',
            error: 'Enter a complete email address',
            keyboardType: TextInputType.emailAddress,
          ),
          Text('Date of birth', style: CatalogType.fieldLabel),
          SizedBox(height: 6),
          Text('14 Mar 1992', style: CatalogType.field),
          SizedBox(height: 8),
          Text('Age 34 · Auto', style: CatalogType.meta),
          SizedBox(height: 12),
          Text(ServiceCatalogMock.fieldsHonesty, style: CatalogType.honesty),
        ],
      ),
    );
  }
}
