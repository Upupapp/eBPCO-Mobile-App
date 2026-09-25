import 'package:flutter/material.dart';
import 'service_request.dart';

/// Barangay-level vs LGU/Municipality-level — derived from
/// [ServiceRequest.office] rather than stored as a new persisted field, so
/// existing saved requests (SharedPreferences JSON) never need a schema
/// migration. Matches how Philippine LGU offices are actually named: a
/// "Barangay Hall" issues barangay-level documents/assistance; every other
/// office (Treasurer's, Municipal Social Welfare and Development Office,
/// Civil Registrar, Business Permits and Licensing Office, etc.) is a
/// municipal/LGU-level office.
enum RequestScope { barangay, lgu }

extension RequestScopeX on RequestScope {
  String get label => switch (this) {
        RequestScope.barangay => 'Barangay',
        RequestScope.lgu => 'LGU / Municipality',
      };
}

RequestScope scopeOfOffice(String office) =>
    office.toLowerCase().contains('barangay') ? RequestScope.barangay : RequestScope.lgu;

enum RequestSort { newest, oldest }

extension RequestSortX on RequestSort {
  String get label => switch (this) {
        RequestSort.newest => 'Newest first',
        RequestSort.oldest => 'Oldest first',
      };
}

/// One immutable snapshot of the active Dokyu/Tulong filter state —
/// search text, barangay/LGU scope, request type, status, submitted-date
/// range, and sort order. [RequestListScreen] applies this to its
/// category's requests; [FilterBottomSheet] edits a working copy and
/// returns a new instance rather than mutating in place.
@immutable
class RequestFilters {
  final String search;
  final RequestScope? scope;
  final String? typeName;
  final String? status; // AppStatus.label string, or null for "any"
  final DateTimeRange? dateRange;
  final RequestSort sort;

  const RequestFilters({
    this.search = '',
    this.scope,
    this.typeName,
    this.status,
    this.dateRange,
    this.sort = RequestSort.newest,
  });

  bool get isActive =>
      search.trim().isNotEmpty || scope != null || typeName != null || status != null || dateRange != null;

  /// How many distinct filter facets are active — drives the "Filter (3)"
  /// badge and the active-chip row, not counting sort (sort always has a
  /// value, so it's never "off").
  int get activeCount => [
        search.trim().isNotEmpty,
        scope != null,
        typeName != null,
        status != null,
        dateRange != null,
      ].where((f) => f).length;

  RequestFilters copyWith({
    String? search,
    RequestScope? scope,
    bool clearScope = false,
    String? typeName,
    bool clearTypeName = false,
    String? status,
    bool clearStatus = false,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    RequestSort? sort,
  }) {
    return RequestFilters(
      search: search ?? this.search,
      scope: clearScope ? null : (scope ?? this.scope),
      typeName: clearTypeName ? null : (typeName ?? this.typeName),
      status: clearStatus ? null : (status ?? this.status),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      sort: sort ?? this.sort,
    );
  }

  List<ServiceRequest> apply(List<ServiceRequest> requests) {
    var result = requests.where((r) {
      if (search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        final matches = r.typeName.toLowerCase().contains(q) ||
            r.referenceNumber.toLowerCase().contains(q) ||
            r.office.toLowerCase().contains(q);
        if (!matches) return false;
      }
      if (scope != null && scopeOfOffice(r.office) != scope) return false;
      if (typeName != null && r.typeName != typeName) return false;
      if (status != null && r.status != status) return false;
      if (dateRange != null) {
        final d = DateTime(r.submittedAt.year, r.submittedAt.month, r.submittedAt.day);
        final start = DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day);
        final end = DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day);
        if (d.isBefore(start) || d.isAfter(end)) return false;
      }
      return true;
    }).toList();

    result.sort((a, b) => sort == RequestSort.newest
        ? b.submittedAt.compareTo(a.submittedAt)
        : a.submittedAt.compareTo(b.submittedAt));
    return result;
  }
}
