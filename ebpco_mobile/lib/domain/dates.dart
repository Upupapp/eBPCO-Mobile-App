/// The app's two date formats, the same as both portals' (design review I22,
/// 4 Nov 2026): "Nov 4, 2026", and "Nov 4, 2026 · 4:00 PM" where the time
/// matters. Documents, lists, timelines and document footers use these.
library;

import 'package:intl/intl.dart';

/// "Nov 4, 2026"; the text as given when it is not a date.
String formatDate(String iso) {
  final when = DateTime.tryParse(iso)?.toLocal();
  return when == null ? iso : DateFormat('MMM d, y').format(when);
}

/// "Nov 4, 2026 · 4:00 PM"; the text as given when it is not a date.
String formatDateTime(String iso) {
  final when = DateTime.tryParse(iso)?.toLocal();
  return when == null ? iso : formatMoment(when);
}

/// [when] as "Nov 4, 2026 · 4:00 PM" (a document's "Generated" line).
String formatMoment(DateTime when) => '${DateFormat('MMM d, y').format(when)} · ${DateFormat('h:mm a').format(when)}';
