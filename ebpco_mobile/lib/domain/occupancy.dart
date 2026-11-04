/// The use or character of occupancy (LGU initial findings, 4 Nov 2026: "step 1
/// is business type, no option for residential, institutional").
///
/// The National Building Code groups a building by its use, Groups A to J, and
/// the Unified Building Permit form asks for it. Asked on step 1 of a Building
/// Permit or Certificate of Occupancy application, right after "Applying as",
/// and kept in the application's form: `form.occupancyGroup`, plus
/// `form.occupancyOther` for "Others (specify)". The values, labels and
/// messages are the server's (ebpco-api 071, domain/occupancy.ts) and the same
/// as the citizen portal's `core/domain/occupancy.ts`: change them there first.
library;

/// "Others (specify)": the use is then typed in.
const occupancyOtherValue = 'other';

/// Every choice, in the order the field lists them: value and label.
const occupancyGroups = <({String value, String label})>[
  (value: 'A', label: 'Group A — Residential, Dwellings'),
  (value: 'B', label: 'Group B — Residential Hotel, Apartment'),
  (value: 'C', label: 'Group C — Educational, Recreational'),
  (value: 'D', label: 'Group D — Institutional'),
  (value: 'E', label: 'Group E — Business and Mercantile'),
  (value: 'F', label: 'Group F — Industrial'),
  (value: 'G', label: 'Group G — Industrial Storage and Hazardous'),
  (value: 'H', label: 'Group H — Recreational or Assembly (below 1,000)'),
  (value: 'I', label: 'Group I — Recreational or Assembly (1,000 or more)'),
  (value: 'J', label: 'Group J — Agricultural, Accessory'),
  (value: occupancyOtherValue, label: 'Others (specify)'),
];

const occupancyFieldLabel = 'Use or character of occupancy';
const occupancyHint = "The building's use, as grouped in the National Building Code.";
const occupancyOtherLabel = 'Specify the use';

/// How long the specified use may be, as the server checks it (after trimming).
const occupancyOtherMin = 3;
const occupancyOtherMax = 120;

/// The permit types whose application asks for it.
const _askedOf = {'Building Permit', 'Certificate of Occupancy'};

bool asksOccupancy(String? permitType) => permitType != null && _askedOf.contains(permitType);

bool isOccupancyGroup(Object? value) => value is String && occupancyGroups.any((g) => g.value == value);

bool _otherIsValid(String other) {
  final length = other.trim().length;
  return length >= occupancyOtherMin && length <= occupancyOtherMax;
}

/// Why the answer cannot be filed, in the server's own words; null when it can.
String? occupancyProblem(String? group, String other) {
  if (group == null) return 'Choose the use or character of occupancy.';
  if (group == occupancyOtherValue && !_otherIsValid(other)) {
    return 'Specify the use of the building, in 3 to 120 characters.';
  }
  return null;
}

/// The answer as the application's form keeps it. Nothing until chosen, and
/// nothing for "Others" while the use is not specified yet: the server checks a
/// value on every save, and a draft may be half-chosen (Save & Exit on step 1).
/// `occupancyOther` is null for a group, so a use typed earlier is not kept.
Map<String, dynamic> occupancyForm(String? group, String other) {
  if (group == null) return const {};
  if (group != occupancyOtherValue) return {'occupancyGroup': group, 'occupancyOther': null};
  return _otherIsValid(other) ? {'occupancyGroup': occupancyOtherValue, 'occupancyOther': other.trim()} : const {};
}

/// What a saved form holds, read defensively: an unknown value reads as not chosen.
({String? group, String other}) occupancyFromForm(Map<String, dynamic> form) {
  final group = form['occupancyGroup'];
  final other = form['occupancyOther'];
  if (!isOccupancyGroup(group)) return (group: null, other: '');
  return (group: group as String, other: group == occupancyOtherValue && other is String ? other : '');
}

/// The label for a choice: the group's, or `Others — (the use given)`.
String occupancyLabel(String group, String other) {
  if (group == occupancyOtherValue) {
    final text = other.trim();
    return text.isEmpty ? 'Others (specify)' : 'Others — $text';
  }
  return occupancyGroups.firstWhere((g) => g.value == group, orElse: () => (value: group, label: group)).label;
}

/// The label a filed application shows and prints; null when none was given
/// (an older filing, or another permit type).
String? occupancyLabelOf(Map<String, dynamic> form) {
  final (:group, :other) = occupancyFromForm(form);
  return group == null ? null : occupancyLabel(group, other);
}
