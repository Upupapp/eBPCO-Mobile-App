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

  bool get loading => _loading;
  String? get error => _error;
  List<NotificationEntry> get items => _items;

  /// Same definition as the citizen portal's badge (`readAt == null`). Not
  /// the API's `unresolvedCount`, which counts only action-required items.
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.notifications();
      _items = result.data;
    } catch (e) {
      _error = 'Could not load your notifications. Pull down to try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    await _api.markNotificationRead(id);
    await refresh();
  }

  void clear() {
    _items = [];
    _error = null;
    notifyListeners();
  }
}
