import 'package:flutter/foundation.dart';

import '../core/api/citizen_api.dart';
import '../domain/models.dart';

/// The citizen's real notification feed (`GET /notifications`) — Phase 1
/// has no push, so this is also the ONLY way a citizen sees a status
/// change happened; see the approved plan's note on why push is deferred.
class NotificationsService extends ChangeNotifier {
  final _api = CitizenApi.instance;

  bool _loading = false;
  String? _error;
  List<NotificationEntry> _items = [];
  int _unresolvedCount = 0;

  bool get loading => _loading;
  String? get error => _error;
  List<NotificationEntry> get items => _items;
  int get unresolvedCount => _unresolvedCount;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.notifications();
      _items = result.data;
      _unresolvedCount = result.unresolvedCount;
    } catch (e) {
      _error = 'Could not load your notifications. Pull down to try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    await _api.markNotificationRead(id);
    final index = _items.indexWhere((n) => n.id == id);
    if (index != -1 && !_items[index].isRead) {
      _unresolvedCount = (_unresolvedCount - 1).clamp(0, 1 << 30);
    }
    await refresh();
  }

  void clear() {
    _items = [];
    _error = null;
    _unresolvedCount = 0;
    notifyListeners();
  }
}
