import 'package:flutter/foundation.dart';

import '../core/api/citizen_api.dart';
import '../domain/models.dart';
import 'live_updates.dart';

/// The citizen's own applications — real data from `GET /applications`,
/// held here so Dashboard and My Applications never issue their own
/// separate, possibly-inconsistent fetches for the same list.
class ApplicationsService extends ChangeNotifier {
  final _api = CitizenApi.instance;

  bool _loading = false;
  String? _error;
  List<ApplicationSummary> _applications = [];

  /// Numbers each read, so an answer landing after a newer one (or after
  /// [clear], at sign-out) is dropped instead of shown.
  int _reads = 0;
  int _shownRead = 0;

  bool get loading => _loading;
  String? get error => _error;
  List<ApplicationSummary> get applications => _applications;

  List<ApplicationSummary> get active =>
      _applications.where((a) => a.applicantStatus != 'Rejected' && a.applicantStatus != 'Ready for Release').toList();

  int get awaitingActionCount => _applications.where((a) => a.requiresApplicantAction).length;

  Future<void> refresh() async {
    final read = ++_reads;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final fresh = await _api.listApplications();
      if (read > _shownRead) {
        _shownRead = read;
        _applications = fresh;
      }
    } catch (e) {
      if (read > _shownRead) _error = 'Could not load your applications. Pull down to try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  late final _quietly = SerialRefresh(() async {
    final read = ++_reads;
    final fresh = await _api.listApplications();
    if (read <= _shownRead) return;
    _shownRead = read;
    _applications = fresh;
    _error = null;
    notifyListeners();
  });

  /// Reads the list again in the background (live updates): no spinner, and
  /// a failed read keeps what is on screen.
  Future<void> refreshQuietly() => _quietly();

  void clear() {
    _shownRead = ++_reads;
    _applications = [];
    _error = null;
    notifyListeners();
  }
}
