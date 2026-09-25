import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/screens/auth/login_screen.dart';
import 'package:teresa_rizal/screens/auth/register_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/theme/app_theme.dart';
import 'package:teresa_rizal/utils/teresa_rizal_seal.dart';
import 'package:teresa_rizal/widgets/app_button.dart';
import 'package:teresa_rizal/widgets/app_text_field.dart';

/// 390×844 logical frames, written at 2× with Inter loaded.
/// Run: G4_SHOTS=1 flutter test test/g4_pack_a_shots_test.dart
bool _fontsReady = false;

Future<void> _loadShotFonts() async {
  if (_fontsReady) return;
  final inter = FontLoader('Inter');
  for (final name in [
    'assets/fonts/Inter.ttf',
    'assets/fonts/Inter-Italic.ttf',
  ]) {
    final bytes = File(name).readAsBytesSync();
    inter.addFont(
      Future.value(ByteData.sublistView(Uint8List.fromList(bytes))),
    );
  }
  await inter.load();
  final icons = FontLoader('MaterialIcons');
  final iconBytes = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
  icons.addFont(Future.value(iconBytes));
  await icons.load();
  _fontsReady = true;
}

void _mark(String step) {
  File('/tmp/g4-step.txt').writeAsStringSync(step);
}

Future<void> _prepare(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.runAsync(_loadShotFonts);
}

Future<void> _pumpHome(
  WidgetTester tester,
  Widget home, {
  CitizenSessionService? session,
  ValueNotifier<bool>? ime,
}) async {
  final showIme = ime ?? ValueNotifier<bool>(false);
  final app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: home,
  );
  await tester.pumpWidget(
    session == null
        ? ChangeNotifierProvider(
            create: (_) => CitizenSessionService(),
            child: _ShotFrame(ime: showIme, child: app),
          )
        : ChangeNotifierProvider.value(
            value: session,
            child: _ShotFrame(ime: showIme, child: app),
          ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

/// Same idea as the inbox harness: `Image.asset` stays blank until the
/// codec finishes, and the test clock never finishes that decode.
Future<void> _resolveImages(WidgetTester tester) async {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  final context = tester.element(find.byType(MaterialApp));
  Object? failure;
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage(teresaRizalSealAsset),
      context,
      onError: (exception, _) {
        failure ??= exception;
      },
    );
    for (final image in images) {
      await precacheImage(
        image.image,
        context,
        onError: (exception, _) {
          failure ??= exception;
        },
      );
    }
  });
  await tester.pump();
  if (failure != null) {
    fail('Image failed to decode: $failure');
  }
}

Future<void> _shoot(WidgetTester tester, String name) async {
  await _resolveImages(tester);
  _mark('shoot $name');
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('g4-frame')),
  );
  // toImage finishes on the engine thread. The test binding's fake clock
  // never delivers that callback, so the capture has to leave the zone.
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  });
  final file = File('/opt/cursor/artifacts/g4/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
  _mark('wrote $name');
}

Future<void> _fillPersonal(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(AppTextField, 'Full name'),
    'Maria Santos Reyes',
  );
  await tester.enterText(
    find.widgetWithText(AppTextField, 'Birth date'),
    '12 Apr 1992',
  );
  await tester.ensureVisible(find.text('Female'));
  await tester.tap(find.text('Female'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.enterText(
    find.widgetWithText(AppTextField, 'Mobile'),
    '0917 555 0142',
  );
  await tester.enterText(
    find.widgetWithText(AppTextField, 'Email'),
    'maria.reyes@example.com',
  );
  await tester.enterText(
    find.widgetWithText(AppTextField, 'Address / Barangay'),
    'Purok 3, Dalig, Teresa, Rizal',
  );
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _tapLabeled(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder.last);
  await tester.tap(finder.last);
  await tester.pump();
  // Let the button splash finish so the next frame shows the solid fill.
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final enabled = Platform.environment['G4_SHOTS'] == '1';

  const shotTimeout = Timeout(Duration(minutes: 3));

  testWidgets('login', (tester) async {
    if (!enabled) return;
    await _prepare(tester);
    await _pumpHome(tester, const LoginScreen());
    await _shoot(tester, 'login');
  }, timeout: shotTimeout);

  testWidgets('register personal and keyboard', (tester) async {
    if (!enabled) return;
    await _prepare(tester);
    final ime = ValueNotifier<bool>(false);
    addTearDown(ime.dispose);
    await _pumpHome(tester, const RegisterScreen(), ime: ime);
    await _fillPersonal(tester);
    await _shoot(tester, 'register-personal');

    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    ime.value = true;
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('register-mobile')));
    await tester.pump();
    await tester.showKeyboard(find.byKey(const Key('register-mobile')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _shoot(tester, 'register-personal-keyboard');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
  }, timeout: shotTimeout);

  testWidgets('register terms through pending', (tester) async {
    if (!enabled) return;
    await _prepare(tester);
    await _pumpHome(tester, const RegisterScreen());
    await _fillPersonal(tester);
    await _tapLabeled(tester, 'Continue');
    await _shoot(tester, 'register-terms');

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await _tapLabeled(tester, 'Continue');
    await tester.tap(find.text('PhilSys'));
    await tester.pump();
    await _shoot(tester, 'register-valid-id');

    await _tapLabeled(tester, 'Continue');
    await _shoot(tester, 'register-face');

    await _tapLabeled(tester, 'Continue');
    await _shoot(tester, 'register-review');

    await tester.ensureVisible(
      find.widgetWithText(AppButton, 'Submit for verification'),
    );
    await tester.tap(find.widgetWithText(AppButton, 'Submit for verification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await _shoot(tester, 'register-status-pending');
  }, timeout: shotTimeout);

  testWidgets('status approved and rejected', (tester) async {
    if (!enabled) return;
    await _prepare(tester);
    await _status(
      tester,
      MockCatalog.demoAccounts.last,
      'register-status-approved',
    );
    await _status(
      tester,
      CitizenAccount(
        id: 'ESP-RES-2024-9099',
        firstName: 'Sample',
        lastName: 'Resident',
        email: 'sample.resident@example.com',
        mobile: '0917 000 0000',
        barangay: 'Poblacion',
        purok: 'Purok 1',
        address: 'Purok 1, Barangay Poblacion, Teresa, Rizal',
        birthdate: '—',
        sex: '—',
        civilStatus: '—',
        occupation: '—',
        profileCompleteness: 10,
        status: 'Rejected',
      ),
      'register-status-rejected',
    );
  }, timeout: shotTimeout);
}

Future<void> _status(
  WidgetTester tester,
  CitizenAccount account,
  String name,
) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  await session.login(account);
  await _pumpHome(tester, const RegisterScreen(), session: session);
  await _shoot(tester, name);
}

class _ShotFrame extends StatelessWidget {
  final ValueNotifier<bool> ime;
  final Widget child;

  const _ShotFrame({required this.ime, required this.child});

  @override
  Widget build(BuildContext context) {
    // The frame sits above MaterialApp, so the overlay Stack has no ambient
    // Directionality unless this provides one.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: const Key('g4-frame'),
        child: ValueListenableBuilder<bool>(
          valueListenable: ime,
          builder: (context, show, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                child,
                if (show)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 336,
                    child: IgnorePointer(child: _SoftIme()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Harness-only phone pad. It fills the 336px view inset. No OS chrome.
class _SoftIme extends StatelessWidget {
  const _SoftIme();

  static const _bg = Color(0xFFE4E7EE);
  static const _key = Color(0xFFF4F6F8);
  static const _special = Color(0xFFD5D8DE);
  static const _ink = Color(0xFF3A4150);

  @override
  Widget build(BuildContext context) {
    const rows = <List<_ImeKey>>[
      [_ImeKey('1'), _ImeKey('2'), _ImeKey('3'), _ImeKey('-')],
      [_ImeKey('4'), _ImeKey('5'), _ImeKey('6'), _ImeKey('.')],
      [
        _ImeKey('7'),
        _ImeKey('8'),
        _ImeKey('9'),
        _ImeKey.icon(Icons.backspace_outlined, special: true),
      ],
      [
        _ImeKey('*'),
        _ImeKey('0'),
        _ImeKey('#'),
        _ImeKey.icon(Icons.keyboard_return_rounded, special: true),
      ],
    ];
    return ColoredBox(
      color: _bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
        child: Column(
          children: [
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
                                color: key.special ? _special : _key,
                                borderRadius: BorderRadius.circular(8),
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

  const _ImeKey(this.label) : icon = null, special = false;

  const _ImeKey.icon(this.icon, {this.special = false}) : label = null;

  Widget glyph() {
    if (icon != null) {
      return Icon(icon, size: 22, color: _SoftIme._ink);
    }
    return Text(
      label!,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: _SoftIme._ink,
        height: 1,
      ),
    );
  }
}
