// Opt-in 390×844 pack for the G3 request series.
// Run: flutter test --dart-define=G3_SHOTS=true test/g3_request_series_shots_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/attachment.dart';
import 'package:teresa_rizal/models/master_file_document.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/request_detail_screen.dart';
import 'package:teresa_rizal/screens/shared/request_list_screen.dart';
import 'package:teresa_rizal/screens/shared/service_catalog_screen.dart';
import 'package:teresa_rizal/screens/shared/service_request_wizard_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_theme.dart';
import 'package:teresa_rizal/theme/soft_widget.dart';
import 'package:teresa_rizal/utils/requirement_document_type.dart';
import 'package:teresa_rizal/widgets/requirement_uploader.dart';
import 'package:teresa_rizal/widgets/soft_flow_scaffold.dart';

const _capture = bool.fromEnvironment('G3_SHOTS');
const _shotDirs = [
  '/workspace/cloud-agent-artifacts/bc-646e42a2-569b-5ce4-9aa7-f53fe96d9e7c/g3-request-series',
  '/opt/cursor/artifacts/g3-request-series',
];

/// `flutter test` ships Ahem, which paints every glyph as a block. SoftType
/// asks for Inter, and action icons ask for MaterialIcons. Register both
/// before the first frame or the shots are .notdef bars and square boxes.
Future<void> _loadShotFonts() async {
  final inter = FontLoader('Inter');
  for (final name in [
    'assets/fonts/Inter.ttf',
    'assets/fonts/Inter-Italic.ttf',
  ]) {
    final bytes = File(name).readAsBytesSync();
    inter.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  }
  await inter.load();

  final icons = FontLoader('MaterialIcons');
  final iconBytes = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
  icons.addFont(Future.value(iconBytes));
  await icons.load();
}

const _verifiedId = 'ESP-RES-2024-9002';
const _verifiedName = 'Perlita Quiambao';

Future<RequestsService> _requests(WidgetTester tester, {bool seed = false}) async {
  final requests = RequestsService(seedDemoData: seed);
  var attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return requests;
}

Future<CitizenSessionService> _session(WidgetTester tester) async {
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(MockCatalog.demoAccounts.last);
  return session;
}

void _phone(WidgetTester tester, {double keyboard = 0}) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
}

Widget _host(RequestsService requests, CitizenSessionService session, Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<RequestsService>.value(value: requests),
      ChangeNotifierProvider<CitizenSessionService>.value(value: session),
      ChangeNotifierProvider(create: (_) => MasterFileService()),
      ChangeNotifierProvider(create: (_) => ResidentProfileService()),
      ChangeNotifierProvider(create: (_) => NotificationsService()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: home,
    ),
  );
}

class _WriteComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    for (final dir in _shotDirs) {
      final file = File('$dir/${golden.pathSegments.last}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(imageBytes);
    }
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    await compare(imageBytes, golden);
  }

  @override
  Uri getTestUri(Uri key, int? version) => key;
}

/// Light Gboard phone pad (TYPE_CLASS_PHONE): four rows, return on the right.
/// Painted only for the keyboard review frame. It sits in the view inset, so
/// Continue stays in the app chrome above the keys.
class _AndroidPhoneIme extends StatelessWidget {
  const _AndroidPhoneIme();

  static const _bg = Color(0xFFE8EAED);
  static const _key = Color(0xFFFFFFFF);
  static const _special = Color(0xFFD5D8DE);
  static const _ink = Color(0xFF202124);
  static const _enter = Color(0xFF1A73E8);

  @override
  Widget build(BuildContext context) {
    const rows = <List<_ImeKey>>[
      [_ImeKey('1'), _ImeKey('2'), _ImeKey('3'), _ImeKey('-')],
      [_ImeKey('4'), _ImeKey('5'), _ImeKey('6'), _ImeKey('.')],
      [_ImeKey('7'), _ImeKey('8'), _ImeKey('9'), _ImeKey.icon(Icons.backspace_outlined, special: true)],
      [_ImeKey('*'), _ImeKey('0'), _ImeKey('#'), _ImeKey.icon(Icons.keyboard_return_rounded, enter: true)],
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(color: Color(0x24000000), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 8, 5, 8),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFC4C7CE),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            for (final row in rows)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      for (final key in row)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: key.enter ? _enter : (key.special ? _special : _key),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 0.5),
                                ],
                              ),
                              child: Center(child: key.glyph()),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImeKey {
  final String? label;
  final IconData? icon;
  final bool special;
  final bool enter;

  const _ImeKey(this.label) : icon = null, special = false, enter = false;

  const _ImeKey.icon(this.icon, {this.special = false, this.enter = false}) : label = null;

  Widget glyph() {
    if (icon != null) {
      return Icon(icon, size: 22, color: enter ? const Color(0xFFFFFFFF) : _AndroidPhoneIme._ink);
    }
    return Text(
      label!,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: _AndroidPhoneIme._ink,
        height: 1,
      ),
    );
  }
}

Future<void> _save(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('$name.png'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('390x844 request series pack', (tester) async {
    goldenFileComparator = _WriteComparator();
    await tester.runAsync(_loadShotFonts);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final requests = await _requests(tester, seed: true);
    final session = await _session(tester);

    _phone(tester);
    await tester.pumpWidget(
      _host(
        requests,
        session,
        const RequestListScreen(
          category: ServiceCategory.dokyu,
          title: 'Dokyu',
          subtitle: 'Request and track municipal documents online.',
          catalog: MockCatalog.documentTypes,
          accent: SoftColors.blue,
          icon: Icons.description_outlined,
        ),
      ),
    );
    await _save(tester, '01-request-list');

    await tester.pumpWidget(
      _host(
        requests,
        session,
        const ServiceCatalogScreen(
          category: ServiceCategory.dokyu,
          title: 'Dokyu',
          catalog: MockCatalog.documentTypes,
          accent: SoftColors.blue,
        ),
      ),
    );
    await _save(tester, '02-catalog');

    final clearance = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_barangay_clearance');
    await tester.pumpWidget(
      _host(
        requests,
        session,
        ServiceRequestWizardScreen(
          key: const ValueKey('wizard-applicant'),
          category: ServiceCategory.dokyu,
          item: clearance,
          accent: SoftColors.blue,
        ),
      ),
    );
    await _save(tester, '03-wizard-applicant');

    await tester.pumpWidget(
      _host(
        requests,
        session,
        ServiceRequestWizardScreen(
          key: const ValueKey('wizard-review'),
          category: ServiceCategory.dokyu,
          item: clearance,
          accent: SoftColors.blue,
          initialStep: 3,
        ),
      ),
    );
    await _save(tester, '04-wizard-review');

    await tester.pumpWidget(
      _host(
        requests,
        session,
        ServiceRequestWizardScreen(
          key: const ValueKey('wizard-payment'),
          category: ServiceCategory.dokyu,
          item: clearance,
          accent: SoftColors.blue,
          initialStep: 4,
        ),
      ),
    );
    await _save(tester, '05-wizard-payment');

    _phone(tester, keyboard: 336);
    await tester.pumpWidget(
      _host(
        requests,
        session,
        Stack(
          fit: StackFit.expand,
          children: [
            ServiceRequestWizardScreen(
              key: const ValueKey('wizard-keyboard'),
              category: ServiceCategory.dokyu,
              item: clearance,
              accent: SoftColors.blue,
            ),
            // Widget tests do not open the system IME. The Mobile field is
            // TextInputType.phone, so the review frame paints Gboard's phone
            // keypad in the same 336px inset the scaffold already reserves.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 336,
              child: IgnorePointer(child: _AndroidPhoneIme()),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final mobile = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == '09XX XXX XXXX',
    );
    await tester.ensureVisible(mobile);
    await tester.tap(mobile);
    await tester.pumpAndSettle();
    await _save(tester, '06-wizard-keyboard-open');
    _phone(tester);

    await tester.pumpWidget(
      _host(
        requests,
        session,
        const RequestDetailScreen(requestId: 'demo-tulong-educational'),
      ),
    );
    await _save(tester, '07-detail-rejected');

    final correction = await requests.submit(
      applicantId: _verifiedId,
      applicantName: _verifiedName,
      typeName: 'Barangay Clearance',
      category: ServiceCategory.dokyu,
      office: 'Barangay Hall',
      purpose: 'Proof of residency for a municipal transaction.',
      expectedDays: '1-2 working days',
      attachments: const [],
    );
    await requests.flagAdditionalDocuments(
      correction.id,
      requirementLabel: 'Proof of residency',
      reason: 'The residency proof is unreadable. Please upload a clearer copy.',
    );
    await tester.pumpWidget(_host(requests, session, RequestDetailScreen(requestId: correction.id)));
    await _save(tester, '08-detail-needs-correction');

    final manual = await requests.submit(
      applicantId: _verifiedId,
      applicantName: _verifiedName,
      typeName: 'Certificate of Indigency',
      category: ServiceCategory.dokyu,
      office: 'Municipal Social Welfare and Development Office',
      purpose: 'Medical assistance',
      expectedDays: '2-3 working days',
      attachments: const [],
    );
    await requests.flagManualVerification(
      manual.id,
      reason: 'Staff in Teresa, Rizal still need to confirm this request in person.',
    );
    await tester.pumpWidget(_host(requests, session, RequestDetailScreen(requestId: manual.id)));
    await _save(tester, '09-detail-manual-verify');

    final cancelled = await requests.submit(
      applicantId: _verifiedId,
      applicantName: _verifiedName,
      typeName: 'Barangay Clearance',
      category: ServiceCategory.dokyu,
      office: 'Barangay Hall',
      purpose: 'Local identification',
      expectedDays: '1-2 working days',
      attachments: const [],
    );
    await requests.cancel(cancelled.id);
    await tester.pumpWidget(_host(requests, session, RequestDetailScreen(requestId: cancelled.id)));
    await _save(tester, '10-detail-cancelled');

    final released = await requests.submit(
      applicantId: _verifiedId,
      applicantName: _verifiedName,
      typeName: 'Barangay Clearance',
      category: ServiceCategory.dokyu,
      office: 'Barangay Hall',
      purpose: 'Proof of residency',
      expectedDays: '1-2 working days',
      attachments: const [],
      requiresPayment: true,
      fee: '₱50.00',
      paymentMethod: 'Onsite',
    );
    for (var i = 0; i < 4; i++) {
      await requests.advanceMilestone(released.id);
    }
    await tester.pumpWidget(_host(requests, session, RequestDetailScreen(requestId: released.id)));
    await _save(tester, '11-detail-approved-released');

    await tester.pumpWidget(
      _host(
        requests,
        session,
        ServiceRequestWizardScreen(
          key: const ValueKey('wizard-requirements'),
          category: ServiceCategory.dokyu,
          item: clearance,
          accent: SoftColors.blue,
          initialStep: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Upload').first);
    await tester.pumpAndSettle();
    await _save(tester, '12-attachment-sources');

    final existing = MasterFileDocument(
      id: 'mf-1',
      documentType: 'Valid ID',
      label: 'Valid ID',
      origin: 'Dokyu',
      serviceName: 'Barangay Clearance',
      uploadedAt: DateTime(2026, 9, 1),
      attachment: Attachment(
        id: 'att-1',
        fileName: 'perlita-valid-id.pdf',
        category: AttachmentCategory.pdf,
        sizeBytes: 180000,
        addedAt: DateTime(2026, 9, 1),
        documentTypeLabel: 'Valid ID',
      ),
    );
    await tester.pumpWidget(
      _host(
        requests,
        session,
        SoftFlowScaffold(
          title: 'Requirements',
          subtitle: 'Barangay Clearance',
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RequirementUploader(
                requirement: const RequirementInfo(
                  label: 'Valid ID',
                  documentType: 'Valid ID',
                  isRequired: true,
                ),
                attachment: null,
                accent: SoftColors.blue,
                existingMasterDoc: existing,
                onAttachNew: (_) {},
                onUseExisting: () {},
                onRemove: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await _save(tester, '13-attachment-use-existing');
  }, skip: !_capture);
}
