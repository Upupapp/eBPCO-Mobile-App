import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/screens/auth/auth_soft_chrome.dart';
import 'package:teresa_rizal/screens/auth/login_screen.dart';
import 'package:teresa_rizal/screens/auth/register_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';
import 'package:teresa_rizal/theme/soft_widget.dart';
import 'package:teresa_rizal/utils/teresa_rizal_seal.dart';
import 'package:teresa_rizal/widgets/app_button.dart';
import 'package:teresa_rizal/widgets/app_text_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<CitizenSessionService> pumpLogin(WidgetTester tester) async {
    final session = CitizenSessionService();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: session,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return session;
  }

  Future<void> pumpRegister(
    WidgetTester tester, {
    CitizenSessionService? session,
    bool settle = true,
  }) async {
    final resolved = session ?? CitizenSessionService();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: resolved,
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> fillPersonal(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(AppTextField, 'Full name'),
      'Sample Resident',
    );
    await tester.enterText(
      find.widgetWithText(AppTextField, 'Birth date'),
      '12 Apr 1992',
    );
    await tester.tap(find.text('Female'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(AppTextField, 'Mobile'),
      '09170000000',
    );
    await tester.enterText(
      find.widgetWithText(AppTextField, 'Email'),
      'sample.resident@example.com',
    );
    await tester.enterText(
      find.widgetWithText(AppTextField, 'Address / Barangay'),
      'Purok 3, Dalig, Teresa, Rizal',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.ensureVisible(find.widgetWithText(AppButton, 'Continue'));
    await tester.tap(find.widgetWithText(AppButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('guest continue is an inline link and does not open a sheet', (
    tester,
  ) async {
    final session = await pumpLogin(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Mag-sign in'), findsOneWidget);
    expect(find.text('Teresa, Rizal'), findsOneWidget);
    expect(find.text('Verified resident'), findsOneWidget);
    expect(find.text('Unverified'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
    final guestAvatar = tester.widget<CircleAvatar>(
      find.descendant(
        of: find.byKey(const Key('demo-guest')),
        matching: find.byType(CircleAvatar),
      ),
    );
    final verifiedAvatar = tester.widget<CircleAvatar>(
      find.descendant(
        of: find.byKey(const Key('demo-verified')),
        matching: find.byType(CircleAvatar),
      ),
    );
    expect(guestAvatar.radius, verifiedAvatar.radius);
    expect(guestAvatar.radius, 18);
    expect(guestAvatar.backgroundColor, SoftColors.muted);
    final guestInitial = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('demo-guest')),
        matching: find.text('G'),
      ),
    );
    expect(guestInitial.style?.color, SoftColors.white);
    expect(guestInitial.style?.fontSize, 12);
    expect(guestInitial.style?.fontWeight, FontWeight.w600);
    expect(
      _boxShadows(tester, find.widgetWithText(AppButton, 'Sign in')),
      SoftShadows.primary,
    );
    expect(
      find.text(
        'Frontend simulation. Demo cards below do not call a live LGU backend. Data stays on this device.',
      ),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);
    final seal = tester.widget<Image>(find.byType(Image));
    expect((seal.image as AssetImage).assetName, teresaRizalSealAsset);

    final guest = find.text('Continue as Guest');
    expect(guest, findsOneWidget);
    expect(
      find.ancestor(of: guest, matching: find.byType(AppButton)),
      findsNothing,
    );
    expect(
      find.ancestor(of: guest, matching: find.byType(TextButton)),
      findsOneWidget,
    );
    expect(find.text('Create account'), findsOneWidget);

    await tester.ensureVisible(guest);
    await tester.tap(guest);
    await tester.pump();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpAndSettle();
    expect(session.isGuest, isTrue);
  });

  testWidgets('login muted copy uses soft ink and muted, not slate 400', (
    tester,
  ) async {
    await pumpLogin(tester);
    final subtitle = tester.widget<Text>(
      find.text(
        'Use your demo account or continue as Guest to browse public content.',
      ),
    );
    expect(subtitle.style?.color, SoftColors.muted);
    expect(subtitle.style?.color, isNot(AppColors.slate400));
    final title = tester.widget<Text>(find.text('Teresa, Rizal'));
    expect(title.style?.fontFamily, 'Inter');
    expect(title.style?.fontWeight, FontWeight.w600);
    expect(title.style?.color, SoftColors.ink);
  });

  testWidgets('register barangays are the Teresa sample list', (tester) async {
    await pumpRegister(tester);
    expect(teresaRegisterBarangays, [
      'Bagumbayan',
      'Calumpang',
      'Dalig',
      'Dulumbayan',
      'May-Iba',
      'Poblacion',
      'Prinza',
      'San Gabriel',
      'San Roque',
    ]);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.textContaining('Bagumbayan'), findsOneWidget);
    expect(find.textContaining('San Roque'), findsOneWidget);
    expect(find.text('Agoho'), findsNothing);
    expect(find.text('Labangtaytay'), findsNothing);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Prefer not'), findsOneWidget);
    expect(find.widgetWithText(AuthOutlineButton, 'Back'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Continue'), findsOneWidget);
  });

  testWidgets('face step says it is not real biometrics', (tester) async {
    await pumpRegister(tester);
    await fillPersonal(tester);
    await tapContinue(tester);
    expect(find.text('Terms & privacy'), findsOneWidget);
    expect(find.text('Municipality of Teresa, Rizal'), findsOneWidget);
    expect(
      find.text(
        'By continuing you acknowledge this is a demo flow for the Teresa, Rizal app.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('soft portal'), findsNothing);
    expect(find.textContaining('soft-widget'), findsNothing);
    expect(find.textContaining('[TO BE PROVIDED]'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    final blocked = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Continue'),
    );
    expect(blocked.onPressed, isNull);
    final blockedFill = tester.widget<Material>(
      find.descendant(
        of: find.widgetWithText(AppButton, 'Continue'),
        matching: find.byType(Material),
      ),
    );
    expect(blockedFill.color, SoftColors.chipWash);
    expect(blockedFill.elevation, 0);
    expect(
      tester
          .widget<AuthOutlineButton>(
            find.widgetWithText(AuthOutlineButton, 'Back'),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.widgetWithText(AppButton, 'Continue'));
    await tester.pump();
    expect(find.text('Terms & privacy'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tapContinue(tester);
    expect(find.text('PhilSys'), findsOneWidget);
    expect(find.text("Driver's license"), findsOneWidget);
    expect(find.text('UMID'), findsOneWidget);
    final disabled = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Continue'),
    );
    expect(disabled.onPressed, isNull);
    await tester.tap(find.text('PhilSys'));
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Continue'))
          .onPressed,
      isNotNull,
    );
    await tapContinue(tester);
    expect(find.textContaining('Not real biometrics'), findsOneWidget);
    expect(find.text('Preview · simulated'), findsOneWidget);
    expect(
      find.textContaining('does not enroll biometric data'),
      findsOneWidget,
    );
  });

  testWidgets('focused mobile field and Continue stay above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await pumpRegister(tester, settle: false);
    await tester.ensureVisible(find.byKey(const Key('register-mobile')));
    await tester.pump();
    await tester.showKeyboard(find.byKey(const Key('register-mobile')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final keyboardTop = 844 - 336;
    final mobile = tester.getRect(find.byKey(const Key('register-mobile')));
    final cont = tester.getRect(find.widgetWithText(AppButton, 'Continue'));
    expect(mobile.bottom, lessThan(keyboardTop));
    expect(cont.bottom, lessThanOrEqualTo(keyboardTop));
    expect(cont.top, greaterThan(mobile.bottom));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
  });

  testWidgets('rejected status is a simulated frame with reapply', (
    tester,
  ) async {
    final session = CitizenSessionService();
    await session.login(_account(status: 'Rejected'));
    await pumpRegister(tester, session: session, settle: false);
    expect(find.text('Verification'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.textContaining('unclear or cropped'), findsOneWidget);
    expect(find.text('Reapply'), findsOneWidget);
    await tester.tap(find.text('Reapply'));
    await tester.pump();
    expect(find.text('Tell us about you'), findsOneWidget);
    expect(find.textContaining('Bagumbayan'), findsOneWidget);
    expect(find.text('Select your barangay'), findsNothing);
  });

  testWidgets('enabled primary AppButton uses one soft blue shadow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Sign in', onPressed: () {}),
        ),
      ),
    );
    final shadows = _boxShadows(
      tester,
      find.widgetWithText(AppButton, 'Sign in'),
    );
    expect(shadows, hasLength(1));
    expect(shadows.single.color, SoftColors.primaryShadow);
    expect(shadows.single.color, const Color(0x402F6CF0));
    expect(shadows.single.blurRadius, 20);
    expect(shadows.single.spreadRadius, 0);
    expect(shadows.single.offset, const Offset(0, 8));
    expect(shadows, SoftShadows.primary);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppButton(label: 'Sign in', onPressed: null)),
      ),
    );
    expect(
      _boxShadows(tester, find.widgetWithText(AppButton, 'Sign in')),
      isEmpty,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Back',
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(
      _boxShadows(tester, find.widgetWithText(AppButton, 'Back')),
      isEmpty,
    );
  });
}

List<BoxShadow> _boxShadows(WidgetTester tester, Finder of) {
  return tester
      .widgetList<DecoratedBox>(
        find.descendant(of: of, matching: find.byType(DecoratedBox)),
      )
      .map((box) => box.decoration)
      .whereType<BoxDecoration>()
      .expand((decoration) => decoration.boxShadow ?? const <BoxShadow>[])
      .toList();
}

CitizenAccount _account({required String status}) {
  return CitizenAccount(
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
    status: status,
  );
}
