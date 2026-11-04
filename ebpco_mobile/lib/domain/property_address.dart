/// The property an application is for, as its printed documents (the permit,
/// the payment receipt, the Order of Payment) show it.
///
/// The application's own "Project / Property Address" (`location`) comes
/// first: a private individual's application names no business, so reading the
/// business's address printed "Not on file" for every home (found while
/// recording, 4 Nov 2026; fixed in both portals the same way). The business's
/// registered address is used only for an application that gave none.
library;

import 'castilla.dart';
import 'models.dart';

/// The one Castilla barangay [address] names, or null when it names none, or
/// more than one (a street can share a barangay's name), so nothing is guessed.
String? barangayIn(String address) {
  final text = address.toLowerCase();
  final named = <String>{
    for (final barangay in castillaBarangays)
      if (RegExp('(^|[^a-z])${RegExp.escape(barangay.toLowerCase())}(\$|[^a-z])').hasMatch(text)) barangay,
  };
  return named.length == 1 ? named.single : null;
}

/// The parts of an address that are filled in, joined on one line: "10 Rizal
/// Street, Bonga, Castilla, Sorsogon". Empty when none is.
String addressLine(List<String?> parts) =>
    parts.map((part) => part?.trim() ?? '').where((part) => part.isNotEmpty).join(', ');

/// The "Property" section: one "Location" row, printed once (design review,
/// 4 Nov 2026: a Barangay row repeated what the address already said, beside
/// an owner address that said it a third time) — the portal's `propertyRows`.
List<(String, String)> propertyRows({String? location, Business? business}) =>
    [('Location', propertyLine(location: location, business: business))];

/// The one-line property, by the same rule: the application's address as
/// filed; else the business's registered address on one line; else "Not on
/// file". The Order of Payment's "Property", and the permit's "Location".
String propertyLine({String? location, Business? business}) {
  final address = location?.trim() ?? '';
  if (address.isNotEmpty) return address;
  final registered = addressLine([business?.street, business?.barangay, business?.city, business?.province]);
  return registered.isNotEmpty ? registered : 'Not on file';
}
