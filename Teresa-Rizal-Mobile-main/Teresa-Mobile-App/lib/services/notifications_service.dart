import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'persistence_recovery.dart';

/// Tracks which notifications a citizen has already opened/viewed — the
/// notification feed itself is entirely *derived* live from other services
/// (request status history, profile completion, illustrative sample
/// content — see notification_feed.dart), so there's no stored "list of
/// notifications" anywhere; this service only remembers a set of stable
/// notification IDs the citizen has already seen, same SharedPreferences
/// persistence pattern as every other local "database" in this app
/// (RequestsService, BalitaService, etc).
///
/// Also carries the Phase 6 duplicate-account demo's resolution state
/// ('confirmed' / 'reported', keyed by scenario id 'a'/'b') — folded into
/// this existing service rather than a new provider, since
/// [NotificationsService] is already threaded through every screen via
/// `AlertsAction`'s bell icon, so nothing else needs a new provider
/// registered just to read/react to it.
class NotificationsService extends ChangeNotifier {
  static const _readKey = 'teresa_rizal_read_notification_ids';
  static const _duplicateKey = 'teresa_rizal_duplicate_alert_resolutions';
  static const _unverifiedDuplicateKey = 'teresa_rizal_unverified_duplicate_kept_account';

  Set<String> _readIds = {};
  Map<String, String> _duplicateResolutions = {};
  String? _unverifiedDuplicateKeptAccountId;
  bool _loaded = false;

  bool get loaded => _loaded;

  NotificationsService() {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawRead = prefs.getString(_readKey);
      if (rawRead != null) {
        _readIds = (jsonDecode(rawRead) as List).cast<String>().toSet();
      }
      final rawDuplicate = prefs.getString(_duplicateKey);
      if (rawDuplicate != null) {
        _duplicateResolutions = Map<String, String>.from(jsonDecode(rawDuplicate) as Map);
      }
      _unverifiedDuplicateKeptAccountId = prefs.getString(_unverifiedDuplicateKey);
    } catch (error) {
      // A payload persisted by an earlier build can fail to decode after a
      // model or enum changes shape. Before this guard that throw escaped an
      // un-awaited future started in the constructor, so notifyListeners()
      // never fired and AuthGate spun on the splash forever - recoverable
      // only by clearing app data. Discard the unreadable state instead; the
      // migrations here already exist for exactly this class of change.
      _readIds = {};
      _duplicateResolutions = {};
      _unverifiedDuplicateKeptAccountId = null;
      // This service owns three keys and cannot tell which one failed, so all
      // three go. Splitting the restore per key would narrow it further; that is
      // a deliberate follow-up, not an oversight.
      await PersistenceRecovery.discardUnreadable(
        service: 'NotificationsService',
        keys: const [_readKey, _duplicateKey, _unverifiedDuplicateKey],
        error: error,
      );
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Clears read-state and duplicate-resolution bookkeeping on sign-out.
  ///
  /// Unlike the other services this is not keyed by account: read ids point at
  /// notifications derived from the requests being erased alongside them, so
  /// keeping them would leave orphaned references to a citizen who has signed
  /// out. Clearing all of it is both the private and the correct choice.
  Future<void> forgetAccount(String accountId) async {
    _readIds = {};
    _duplicateResolutions = {};
    _unverifiedDuplicateKeptAccountId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readKey);
    await prefs.remove(_duplicateKey);
    await prefs.remove(_unverifiedDuplicateKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readKey, jsonEncode(_readIds.toList()));
    await prefs.setString(_duplicateKey, jsonEncode(_duplicateResolutions));
    if (_unverifiedDuplicateKeptAccountId != null) {
      await prefs.setString(_unverifiedDuplicateKey, _unverifiedDuplicateKeptAccountId!);
    }
  }

  bool isRead(String id) => _readIds.contains(id);

  /// Whether any of [ids] (the notification feed's current full ID set)
  /// is still unread — what the bell's red dot and the notification list
  /// both key off of.
  bool hasUnread(Iterable<String> ids) => ids.any((id) => !_readIds.contains(id));

  Future<void> markRead(String id) async {
    if (_readIds.contains(id)) return;
    _readIds = {..._readIds, id};
    notifyListeners();
    await _persist();
  }

  /// Marks every id in the current feed read. Local inbox chrome only —
  /// there is no push backend behind this.
  Future<void> markAllRead(Iterable<String> ids) async {
    final next = {..._readIds, ...ids};
    if (next.length == _readIds.length) return;
    _readIds = next;
    notifyListeners();
    await _persist();
  }

  /// 'confirmed' (Yes, this is me), 'reported' (No, this is not me), or
  /// null if [scenarioId] hasn't been resolved yet — see
  /// screens/notifications/duplicate_account_details_screen.dart.
  String? duplicateResolutionFor(String scenarioId) => _duplicateResolutions[scenarioId];

  Future<void> resolveDuplicateAlert(String scenarioId, String resolution) async {
    _duplicateResolutions = {..._duplicateResolutions, scenarioId: resolution};
    notifyListeners();
    await _persist();
  }

  /// The Unverified+Unverified duplicate demo's own resolution — 'A', 'B',
  /// or null if the citizen hasn't chosen which registration to keep yet.
  /// Independent of [duplicateResolutionFor]/[resolveDuplicateAlert] above
  /// (the Verified-Perlita scenario's own state) — see
  /// MockCatalog.unverifiedDuplicateAccountA's doc comment.
  String? get unverifiedDuplicateKeptAccountId => _unverifiedDuplicateKeptAccountId;

  Future<void> resolveUnverifiedDuplicate(String keptAccountId) async {
    _unverifiedDuplicateKeptAccountId = keptAccountId;
    notifyListeners();
    await _persist();
  }
}
