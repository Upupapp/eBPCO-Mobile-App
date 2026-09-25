import 'package:flutter/foundation.dart';

import '../core/api/citizen_api.dart';
import '../domain/models.dart';

class BusinessesService extends ChangeNotifier {
  final _api = CitizenApi.instance;

  bool _loading = false;
  String? _error;
  List<Business> _businesses = [];

  bool get loading => _loading;
  String? get error => _error;
  List<Business> get businesses => _businesses;
  List<Business> get active => _businesses.where((b) => b.isActive).toList();

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _businesses = await _api.listBusinesses();
    } catch (e) {
      _error = 'Could not load your businesses. Pull down to try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _businesses = [];
    notifyListeners();
  }
}
