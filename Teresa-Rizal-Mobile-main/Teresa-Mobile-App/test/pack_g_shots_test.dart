import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/data/service_catalog_mock.dart';
import 'package:teresa_rizal/screens/catalog/catalog_detail_screen.dart';
import 'package:teresa_rizal/screens/catalog/delayed_birth_wizard.dart';
import 'package:teresa_rizal/screens/catalog/dokyu_catalog_screen.dart';
import 'support/field_specimen_gallery.dart';
import 'package:teresa_rizal/screens/catalog/incident_report_screen.dart';
import 'package:teresa_rizal/screens/catalog/sakuna_catalog_screen.dart';
import 'package:teresa_rizal/screens/catalog/tulong_catalog_screen.dart';
import 'package:teresa_rizal/theme/app_theme.dart';
import 'package:teresa_rizal/theme/soft_widget.dart';
import 'package:teresa_rizal/widgets/nav_item_data.dart';
import 'package:teresa_rizal/widgets/services_sheet.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_curved_navbar.dart';
import 'package:teresa_rizal/widgets/form/barangay_picker.dart';

import 'package:teresa_rizal/screens/catalog/catalog_chrome.dart';
import 'package:teresa_rizal/screens/catalog/catalog_gate_sheet.dart';

bool _fontsReady = false;

Future<void> _loadFonts() async {
  if (_fontsReady) return;
  final inter = FontLoader('Inter');
  for (final name in ['assets/fonts/Inter.ttf', 'assets/fonts/Inter-Italic.ttf']) {
    final bytes = File(name).readAsBytesSync();
    inter.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  }
  await inter.load();
  final icons = FontLoader('MaterialIcons');
  icons.addFont(Future.value(await rootBundle.load('fonts/MaterialIcons-Regular.otf')));
  await icons.load();
  _fontsReady = true;
}

Future<void> _prepare(WidgetTester tester, {double inset = 0}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: inset);
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  await tester.runAsync(_loadFonts);
}

Future<void> _shoot(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('g7-frame')));
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  });
  expect(bytes!.length, greaterThan(1000));
  // Frames are written for review only where the Cursor artifacts volume
  // exists; elsewhere the walk and its assertions still run.
  if (!Directory('/opt/cursor').existsSync()) return;
  final file = File('/opt/cursor/artifacts/pack-g/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

Future<void> _frame(
  WidgetTester tester,
  Widget child, {
  double inset = 0,
  String? action,
  Key? frameKey,
}) async {
  await _prepare(tester, inset: inset);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: const Key('g7-frame'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: SoftColors.page,
              child: Column(
                children: [
                  const _Status(),
                  Expanded(
                    child: MaterialApp(
                      key: frameKey,
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.light,
                      home: child,
                    ),
                  ),
                ],
              ),
            ),
            if (inset > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: inset,
                child: IgnorePointer(child: _Qwerty(action: action ?? 'Done')),
              ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _Status extends StatelessWidget {
  const _Status();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text('9:41', style: CatalogType.metaInk),
            Spacer(),
            Text('●●●', style: CatalogType.metaInk),
          ],
        ),
      ),
    );
  }
}

class _Qwerty extends StatelessWidget {
  final String action;
  const _Qwerty({required this.action});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFDFE3E9);
    const key = Color(0xFFF7F8FA);
    const ink = Color(0xFF3A4150);
    const rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        child: Column(
          children: [
            for (final row in rows)
              Expanded(
                child: Row(
                  children: [
                    for (final glyph in row.split(''))
                      Expanded(child: _key(glyph, key, ink)),
                  ],
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 2, child: _key('?123', key, ink)),
                  Expanded(child: _key(',', key, ink)),
                  Expanded(flex: 4, child: _key('space', key, ink)),
                  Expanded(child: _key('.', key, ink)),
                  Expanded(flex: 2, child: _key(action, const Color(0xFF3A4150), Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _key(String label, Color fill, Color color) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(6)),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: label.length > 3 ? 11 : 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _services() {
  return Scaffold(
    backgroundColor: SoftColors.page,
    body: Stack(
      children: [
        const ColoredBox(
          color: SoftColors.page,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Magandang araw, Maria', style: SoftType.h1),
          ),
        ),
        const ModalBarrier(color: SoftColors.sheetScrim, dismissible: false),
        Column(
          children: [
            const Spacer(),
            ServicesSheetPanel(onService: (_) {}),
            TeresaRizalCurvedNavBar(
              items: const [
                NavItemData(outlineIcon: Icons.home_outlined, filledIcon: Icons.home_rounded, label: 'Home'),
                NavItemData(outlineIcon: Icons.campaign_outlined, filledIcon: Icons.campaign_rounded, label: 'Balita'),
                NavItemData(outlineIcon: Icons.event_outlined, filledIcon: Icons.event_rounded, label: 'Events'),
                NavItemData(outlineIcon: Icons.person_outline_rounded, filledIcon: Icons.person_rounded, label: 'Profile'),
              ],
              activeIndex: 0,
              onTabSelected: (_) {},
              onCenterPressed: () {},
            ),
          ],
        ),
      ],
    ),
  );
}

class _PickerStage extends StatefulWidget {
  const _PickerStage();

  @override
  State<_PickerStage> createState() => _PickerStageState();
}

class _PickerStageState extends State<_PickerStage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      BarangayPicker.show(
        context,
        title: 'Filter by barangay',
        subline: (name) {
          if (name == 'San Gabriel') return '1 center · sample';
          if (name == 'San Roque') return 'No centers listed';
          return null;
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoftColors.page,
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: const [
          Text('Evacuation centers', textAlign: TextAlign.center, style: SoftType.pageTitle),
          SizedBox(height: 8),
          Call911Strip(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _FilterRow(),
          ),
          SizedBox(height: 8),
          HonestyNote(
            text:
                'Sample list. Names, status and capacity are placeholders until MDRRMO shares the official list. Status is not live.',
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip('All barangays'),
        _Chip('All  5', filled: true),
        _Chip('Open  2'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool filled;
  const _Chip(this.label, {this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: filled ? SoftColors.blue : SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        border: Border.all(color: filled ? SoftColors.blue : SoftColors.line),
      ),
      child: Text(label, style: filled ? CatalogType.onDanger : CatalogType.meta),
    );
  }
}

class _DupShot extends StatefulWidget {
  const _DupShot();

  @override
  State<_DupShot> createState() => _DupShotState();
}

class _DupShotState extends State<_DupShot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDuplicateAccountDialog(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DokyuDetailScreen(service: ServiceCatalogMock.dokyuById('brgy-clearance'));
  }
}

class _GateShot extends StatefulWidget {
  final bool guest;
  const _GateShot({required this.guest});

  @override
  State<_GateShot> createState() => _GateShotState();
}

class _GateShotState extends State<_GateShot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.guest) {
        showGuestRequestGate(context);
      } else {
        showUnverifiedRequestGate(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.guest
        ? ServiceCatalogMock.dokyuById('brgy-clearance')
        : null;
    if (service != null) return DokyuDetailScreen(service: service);
    return TulongDetailScreen(program: ServiceCatalogMock.byId('medical-aics'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name, Widget child, {double inset = 0, String? action}) async {
    await _frame(tester, child, inset: inset, action: action, frameKey: ValueKey(name));
    await _shoot(tester, name);
  }

  testWidgets('pack g frames', (tester) async {
    final frames = <String, Widget>{
      'g7cat-services-sheet': _services(),
      'g7cat-dokyu': const DokyuCatalogScreen(),
      'g7cat-dokyu-more': const DokyuCatalogScreen(anchor: DokyuAnchor.continued),
      'g7cat-dokyu-search': const DokyuCatalogScreen(initialQuery: 'birth'),
      'g7cat-dokyu-noresults': const DokyuCatalogScreen(initialQuery: 'building permit'),
      'g7cat-tulong': const TulongCatalogScreen(),
      'g7cat-tulong-more': const TulongCatalogScreen(anchor: TulongAnchor.programs),
      'g7cat-sakuna': const SakunaCatalogScreen(),
      'g7cat-dokyu-detail': DokyuDetailScreen(service: ServiceCatalogMock.dokyuById('brgy-clearance')),
      'g7cat-tulong-detail': TulongDetailScreen(program: ServiceCatalogMock.byId('medical-aics')),
      'g7cat-gate-guest': const _GateShot(guest: true),
      'g7cat-gate-unverified': const _GateShot(guest: false),
      'g7cat-fields-a': const FieldSpecimenGallery(),
      'g7cat-fields-b': const FieldSpecimenGallery(),
      'g7cat-wizard-intro': const DelayedBirthWizard(),
      'g7cat-wizard-parents': const DelayedBirthWizard(initialStep: 2),
      'g7i-tulong-closed': TulongDetailScreen(program: ServiceCatalogMock.byId('tupad')),
      'g7i-tulong-soon': TulongDetailScreen(program: ServiceCatalogMock.byId('tesda')),
      'g7i-tulong-ineligible': TulongDetailScreen(
        program: ServiceCatalogMock.byId('social-pension'),
        previewBirth: DateTime(1992, 4, 12),
        previewDialog: true,
      ),
      'g7i-sos-form': IncidentReportScreen(kind: ServiceCatalogMock.sakunaById('flood')),
      'g7i-sos-barangay': IncidentReportScreen(kind: ServiceCatalogMock.sakunaById('flood'), openPicker: true),
      'g7i-sos-guest': const SakunaCatalogScreen(openGuestGate: true),
      'g7i-sos-sent': IncidentSentScreen(
        kind: ServiceCatalogMock.sakunaById('flood'),
        barangay: 'Dalig',
        landmark: 'near the covered court',
      ),
      'g7i-db-h1': const DelayedBirthWizard(initialStep: 1),
      'g7i-db-h3': const DelayedBirthWizard(initialStep: 3),
      'g7i-db-h4': const DelayedBirthWizard(initialStep: 4),
      'g7k-dup-intercept': const _DupShot(),
      'g7j-req-remove-confirm': const DelayedBirthWizard(
        initialStep: 2,
        affidavitFile: ServiceCatalogMock.affidavitFileName,
        showRemoveDialog: true,
      ),
    };
    for (final entry in frames.entries) {
      await shot(tester, entry.key, entry.value);
    }
    await shot(tester, 'kbd-dokyu-search', const DokyuCatalogScreen(initialQuery: 'birth'), inset: 336, action: 'Search');
    await shot(tester, 'kbd-wizard-parents', const DelayedBirthWizard(initialStep: 2, focusFather: true), inset: 336, action: 'Done');
    await shot(
      tester,
      'g7i-sos-kbd',
      IncidentReportScreen(kind: ServiceCatalogMock.sakunaById('flood'), focusDescription: true),
      inset: 336,
      action: 'return',
    );
    await shot(
      tester,
      'g7i-db-h1-error-kbd',
      const DelayedBirthWizard(initialStep: 1, showLastNameError: true),
      inset: 336,
      action: 'Next',
    );
    await _frame(tester, const _PickerStage(), inset: 336, action: 'Search', frameKey: const ValueKey('g7j-picker-search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('barangay-picker-search')), 'San');
    await tester.pump();
    await _shoot(tester, 'g7j-picker-search');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
