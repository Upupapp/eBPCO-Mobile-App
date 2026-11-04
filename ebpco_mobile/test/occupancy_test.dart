import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ebpco_mobile/domain/applying_as.dart';
import 'package:ebpco_mobile/domain/occupancy.dart';
import 'package:ebpco_mobile/screens/permits/application_wizard_screen.dart';
import 'package:ebpco_mobile/services/applications_service.dart';
import 'package:ebpco_mobile/services/businesses_service.dart';
import 'package:ebpco_mobile/services/earlier_records_service.dart';
import 'package:ebpco_mobile/services/session_service.dart';

/// The use or character of occupancy (LGU, 4 Nov 2026; ebpco-api 071): the
/// National Building Code's Groups A to J, asked on step 1 of a Building
/// Permit or Certificate of Occupancy application, right after "Applying
/// as". The same values, labels and messages as the server and the portal.
Widget _wizard(String permitType) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionService()),
        ChangeNotifierProvider(create: (_) => ApplicationsService()),
        ChangeNotifierProvider(create: (_) => BusinessesService()),
        ChangeNotifierProvider(create: (_) => EarlierRecordsService()),
      ],
      child: MaterialApp(home: ApplicationWizardScreen(permitType: permitType)),
    );

Future<void> _tapContinue(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Continue'));
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.byType(DropdownButton<String>));
  await tester.tap(find.byType(DropdownButton<String>));
  await tester.pumpAndSettle();
  // The open menu is the last list on screen; it builds only the rows in view.
  await tester.scrollUntilVisible(find.text(label), 48, scrollable: find.byType(Scrollable).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  group('the options', () {
    test('the eleven labels, exactly as the server and the portal word them', () {
      expect(occupancyGroups.map((g) => g.label).toList(), [
        'Group A — Residential, Dwellings',
        'Group B — Residential Hotel, Apartment',
        'Group C — Educational, Recreational',
        'Group D — Institutional',
        'Group E — Business and Mercantile',
        'Group F — Industrial',
        'Group G — Industrial Storage and Hazardous',
        'Group H — Recreational or Assembly (below 1,000)',
        'Group I — Recreational or Assembly (1,000 or more)',
        'Group J — Agricultural, Accessory',
        'Others (specify)',
      ]);
      expect(occupancyGroups.map((g) => g.value).toList(), ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'other']);
    });

    test('asked of a Building Permit and a Certificate of Occupancy only', () {
      expect(asksOccupancy('Building Permit'), isTrue);
      expect(asksOccupancy('Certificate of Occupancy'), isTrue);
      for (final other in ['Business Permit', 'Electrical Permit', 'Locational Clearance', '', null]) {
        expect(asksOccupancy(other), isFalse, reason: '$other');
      }
    });

    test('required, and Others needs the use in 3 to 120 characters, in the server\'s words', () {
      expect(occupancyProblem(null, ''), 'Choose the use or character of occupancy.');
      expect(occupancyProblem('D', ''), isNull);
      expect(occupancyProblem('other', ' ab '), 'Specify the use of the building, in 3 to 120 characters.');
      expect(occupancyProblem('other', 'x' * 121), 'Specify the use of the building, in 3 to 120 characters.');
      expect(occupancyProblem('other', 'Chapel'), isNull);
    });
  });

  group('in the form', () {
    Map<String, dynamic> form({Map<String, dynamic> previous = const {}, Map<String, dynamic>? occupancy}) => applicationForm(
          previous: previous,
          applyingAs: applyingAsResidential,
          scopeOfWork: 'Two-storey house',
          professionalName: '',
          prcNumber: '',
          occupancy: occupancy,
        );

    test('a group is kept as occupancyGroup, with no occupancyOther', () {
      final saved = form(occupancy: occupancyForm('A', 'typed earlier'));
      expect(saved['occupancyGroup'], 'A');
      expect(saved.containsKey('occupancyOther'), isTrue);
      expect(saved['occupancyOther'], isNull);
      expect(saved['applyingAs'], applyingAsResidential);
    });

    test('Others keeps the use, trimmed', () {
      final saved = form(occupancy: occupancyForm('other', '  Chapel  '));
      expect(saved['occupancyGroup'], 'other');
      expect(saved['occupancyOther'], 'Chapel');
    });

    test('a new answer replaces the saved one; one half-made saves nothing rather than the old one', () {
      const previous = {'occupancyGroup': 'A', 'occupancyOther': null, 'portalKey': 'kept'};
      expect(form(previous: previous, occupancy: occupancyForm('D', ''))['occupancyGroup'], 'D');
      final halfMade = form(previous: previous, occupancy: occupancyForm('other', 'ab'));
      expect(halfMade.containsKey('occupancyGroup'), isFalse);
      expect(halfMade.containsKey('occupancyOther'), isFalse);
      expect(halfMade['portalKey'], 'kept');
    });

    test('a type that does not ask it carries none, not even an answer saved earlier', () {
      expect(form().containsKey('occupancyGroup'), isFalse);
      final carried = form(previous: const {'occupancyGroup': 'other', 'occupancyOther': 'Chapel', 'portalKey': 'kept'});
      expect(carried.containsKey('occupancyGroup'), isFalse);
      expect(carried.containsKey('occupancyOther'), isFalse);
      expect(carried['portalKey'], 'kept');
      expect(carried['scopeOfWork'], 'Two-storey house');
    });

    test('a draft reopens on what it saved; an unknown value reads as not chosen', () {
      expect(occupancyFromForm(const {'occupancyGroup': 'D', 'occupancyOther': null}), (group: 'D', other: ''));
      expect(occupancyFromForm(const {'occupancyGroup': 'other', 'occupancyOther': 'Chapel'}), (group: 'other', other: 'Chapel'));
      expect(occupancyFromForm(const {'occupancyGroup': 'Z'}), (group: null, other: ''));
      expect(occupancyFromForm(const {}), (group: null, other: ''));
    });

    test('shown as the group\'s label, or "Others — <the use>"; nothing for an older filing', () {
      expect(occupancyLabelOf(const {'occupancyGroup': 'A'}), 'Group A — Residential, Dwellings');
      expect(occupancyLabelOf(const {'occupancyGroup': 'other', 'occupancyOther': 'Chapel'}), 'Others — Chapel');
      expect(occupancyLabelOf(const {'scopeOfWork': 'Fence'}), isNull);
    });
  });

  group('the wizard\'s step 1', () {
    for (final permitType in ['Building Permit', 'Certificate of Occupancy']) {
      testWidgets('$permitType asks it, with the hint, right after Applying as', (tester) async {
        await tester.pumpWidget(_wizard(permitType));
        await tester.pumpAndSettle();

        expect(find.text(occupancyFieldLabel), findsOneWidget);
        expect(find.text(occupancyHint), findsOneWidget);
        expect(find.text("Select the building's use"), findsWidgets);
        final applyingAs = tester.getTopLeft(find.text('Applying as')).dy;
        final occupancy = tester.getTopLeft(find.text(occupancyFieldLabel)).dy;
        final applicationType = tester.getTopLeft(find.text('Application Type')).dy;
        expect(occupancy, greaterThan(applyingAs));
        expect(occupancy, lessThan(applicationType));
      });
    }

    testWidgets('another permit type does not ask it', (tester) async {
      await tester.pumpWidget(_wizard('Business Permit'));
      await tester.pumpAndSettle();

      expect(find.text(occupancyFieldLabel), findsNothing);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });

    testWidgets('Continue is refused until it is chosen', (tester) async {
      await tester.pumpWidget(_wizard('Building Permit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Residential / Private Individual'));
      await tester.pumpAndSettle();

      await _tapContinue(tester);

      expect(find.text('Choose the use or character of occupancy.'), findsOneWidget);
      expect(find.text('Project details'), findsNothing);
    });

    testWidgets('Others (specify) asks for the use, and refuses one too short', (tester) async {
      await tester.pumpWidget(_wizard('Certificate of Occupancy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Residential / Private Individual'));
      await tester.pumpAndSettle();
      expect(find.text(occupancyOtherLabel), findsNothing);

      await _choose(tester, 'Others (specify)');
      expect(find.text(occupancyOtherLabel), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('wizard-occupancy-other')), 'ab');
      await _tapContinue(tester);

      expect(find.text('Specify the use of the building, in 3 to 120 characters.'), findsOneWidget);
      expect(find.text('Project details'), findsNothing);
    });

    testWidgets('choosing a group shows it as chosen and clears the refusal', (tester) async {
      await tester.pumpWidget(_wizard('Building Permit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Residential / Private Individual'));
      await tester.pumpAndSettle();
      await _tapContinue(tester);
      expect(find.text('Choose the use or character of occupancy.'), findsOneWidget);

      await _choose(tester, 'Group D — Institutional');

      expect(find.text('Choose the use or character of occupancy.'), findsNothing);
      expect(tester.state<FormFieldState<String>>(find.byType(DropdownButtonFormField<String>)).value, 'D');
      expect(find.text('Group D — Institutional'), findsWidgets);
      expect(find.text(occupancyOtherLabel), findsNothing);
    });
  });
}
