/// The property an application is for, as its printed documents (the permit,
/// the payment receipt, the Order of Payment) show it.
///
/// The application's own "Project / Property Address" (`location`) comes
/// first: a Residential application names no business, so reading the
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

/// The "Property" section's rows: the application's address as filed, with
/// its barangay when it names one; else the business's address; else the
/// four rows marked "Not on file".
List<(String, String)> propertyRows({String? location, Business? business}) {
  final address = location?.trim() ?? '';
  if (address.isNotEmpty) {
    return [
      if (barangayIn(address) case final barangay?) ('Barangay', barangay),
      ('Street / Location', address),
    ];
  }
  return [
    ('Barangay', business?.barangay ?? 'Not on file'),
    ('City / Municipality', business?.city ?? 'Not on file'),
    ('Street / Location', business?.street ?? 'Not on file'),
    ('Province', business?.province ?? 'Not on file'),
  ];
}

/// The one-line "Property" on the Order of Payment, by the same rule.
String propertyLine({String? location, Business? business}) {
  final address = location?.trim() ?? '';
  if (address.isNotEmpty) return address;
  return business == null ? 'Not on file' : '${business.street}, ${business.barangay}, ${business.city}';
}
