DateTime? parseCatalogDate(String raw) {
  const months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
  };
  final parts = raw.replaceAll(',', '').split(RegExp(r'\s+'));
  if (parts.length < 3) return null;
  int? day;
  int? month;
  int? year;
  for (final part in parts) {
    final n = int.tryParse(part);
    if (n != null && n > 31) {
      year = n;
    } else if (n != null && day == null) {
      day = n;
    } else {
      month = months[part.toLowerCase()];
    }
  }
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}

String formatCatalogDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
