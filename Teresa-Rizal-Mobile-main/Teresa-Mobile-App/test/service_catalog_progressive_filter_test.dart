// Verifies the new progressive filtering on ServiceCatalogScreen: a step
// is only shown when it would actually narrow something. Dokyu's catalog
// spans both Barangay and LGU offices, so it shows a scope step first;
// Tulong's catalog is entirely LGU/Municipal-level, so that step is
// skipped and it starts directly at Department.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/service_catalog_screen.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/theme/app_colors.dart';

void main() {
  testWidgets('Dokyu catalog is the locked 2×3 representative grid', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ServiceCatalogScreen(
        category: ServiceCategory.dokyu,
        title: 'Dokyu',
        catalog: MockCatalog.documentTypes,
        accent: AppColors.brand600,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Choose a document'), findsOneWidget);
    expect(find.text('Where is this service administered?'), findsNothing);
    for (final label in const [
      'Barangay clearance',
      'Cedula (CTC)',
      'Indigency certificate',
      'Residency certificate',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Business endorsement'), findsNothing);
    expect(find.text('Certificate of employment'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tulong catalog is entirely LGU-scoped, so the Barangay/LGU step is skipped', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ServiceCatalogScreen(
        category: ServiceCategory.tulong,
        title: 'Tulong',
        catalog: MockCatalog.assistanceTypes,
        accent: AppColors.purple700,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Where is this service administered?'), findsNothing);
    expect(find.text('Which office handles this?'), findsOneWidget);
    // The department list has grown since this test was written (more
    // sourced Tulong services now exist — see docs/DOKYU_TULONG_FORM_AUDIT.md),
    // so 'Office for Senior Citizens Affairs' (sorted last alphabetically)
    // may now be below the fold; scroll it into view rather than assuming
    // it's on-screen already.
    await tester.scrollUntilVisible(
      find.text('Office for Senior Citizens Affairs'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Office for Senior Citizens Affairs'), findsOneWidget);

    await tester.tap(find.text('Office for Senior Citizens Affairs'));
    await tester.pumpAndSettle();

    expect(find.text('Social Pension (Indigent Senior Citizen)'), findsOneWidget);
    // Municipal Social Welfare and Development Office department
    expect(find.text('Medical Assistance (AICS)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
