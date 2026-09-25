// Verifies the single source of truth for turning a birthdate into a
// completed-years age (lib/utils/age_calculator.dart) — every Dokyu/Tulong
// form that needs an age derives it through this function instead of
// letting the citizen type it independently of their Date of Birth.
import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/utils/age_calculator.dart';

void main() {
  test('birthday already passed this year counts the year that just turned', () {
    expect(calculateAge(DateTime(1995, 5, 14), asOf: DateTime(2026, 8, 14)), 31);
  });

  test('birthday is today: the year turns exactly on the birthdate', () {
    expect(calculateAge(DateTime(2000, 8, 14), asOf: DateTime(2026, 8, 14)), 26);
  });

  test(
    'birthday has not occurred yet this year — must not use naive currentYear - birthYear',
    () {
      // The exact worked example from the global birthdate/age rule: as of
      // Aug 14, 2026, someone born Dec 20, 2000 is still 25, not 26 — a
      // naive year-subtraction would wrongly report 26 months before their
      // December birthday actually arrives.
      expect(calculateAge(DateTime(2000, 12, 20), asOf: DateTime(2026, 8, 14)), 25);
    },
  );

  test('month matches but day has not occurred yet', () {
    expect(calculateAge(DateTime(2000, 8, 20), asOf: DateTime(2026, 8, 14)), 25);
  });

  test('newborn (birthdate is today) is 0, never negative', () {
    expect(calculateAge(DateTime(2026, 8, 14), asOf: DateTime(2026, 8, 14)), 0);
  });
}
