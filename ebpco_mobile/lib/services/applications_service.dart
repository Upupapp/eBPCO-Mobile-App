import 'package:flutter/foundation.dart';

import '../core/api/citizen_api.dart';
import '../domain/models.dart';

/// The citizen's own applications — real data from `GET /applications`,
/// held here so Dashboard and My Applications never issue their own
/// separate, possibly-inconsistent fetches for the same list.
class ApplicationsService extends ChangeNotifier {
  final _api = CitizenApi.instance;

  bool _loading = false;
  String? _error;
  List<ApplicationSummary> _applications = [];

  bool get loading => _loading;
  String? get error => _error;
  List<ApplicationSummary> get applications => _applications;

  List<ApplicationSummary> get active =>
      _applications.where((a) => a.applicantStatus != 'Rejected' && a.applicantStatus != 'Ready for Release').toList();

  int get awaitingActionCount => _applications.where((a) => a.requiresApplicantAction).length;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _applications = await _api.listApplications();
    } catch (e) {
      _error = 'Could not load your applications. Pull down to try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _applications = [];
    _error = null;
    notifyListeners();
  }
}
