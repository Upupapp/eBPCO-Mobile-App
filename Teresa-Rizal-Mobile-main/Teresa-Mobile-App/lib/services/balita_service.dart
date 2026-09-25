import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'persistence_recovery.dart';
import '../models/announcement.dart';
import 'mock_catalog.dart';

/// Local, frontend-only "database" for Balita posts — same shape as
/// RequestsService: persists to SharedPreferences as JSON so posts created
/// in the composer survive leaving/reopening Balita and app restarts,
/// without any backend. Centralizing this in a ChangeNotifier (instead of
/// BalitaScreen's own State, as before) also fixes a latent bug: Balita is
/// pushed via Navigator rather than living in RootShell's IndexedStack, so
/// its previous in-memory `_posts` was silently reset every time the
/// screen was reopened.
class BalitaService extends ChangeNotifier {
  static const _key = 'teresa_rizal_balita_posts';

  List<Announcement> _posts = List.of(MockCatalog.announcements);
  bool _loaded = false;

  List<Announcement> get posts => List.unmodifiable(_posts);
  bool get loaded => _loaded;

  BalitaService() {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _posts = PersistenceRecovery.decodeEach(
          jsonDecode(raw) as List,
          (e) => Announcement.fromJson(e),
          what: 'balita post',
        );
      }
    } catch (error) {
      // A payload persisted by an earlier build can fail to decode after a
      // model or enum changes shape. Before this guard that throw escaped an
      // un-awaited future started in the constructor, so notifyListeners()
      // never fired and AuthGate spun on the splash forever - recoverable
      // only by clearing app data. Discard the unreadable state instead; the
      // migrations here already exist for exactly this class of change.
      _posts = [];
      await PersistenceRecovery.discardUnreadable(
        service: 'BalitaService',
        keys: const [_key],
        error: error,
      );
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_posts.map((p) => p.toJson()).toList()));
  }

  Future<void> toggleLike(String postId) async {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.liked = !post.liked;
    post.likes += post.liked ? 1 : -1;
    notifyListeners();
    await _persist();
  }

  Future<void> addComment(String postId, PostComment comment) async {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.comments.add(comment);
    post.commentTotal += 1;
    notifyListeners();
    await _persist();
  }

  Future<void> share(String postId) async {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.shares += 1;
    notifyListeners();
    await _persist();
  }

  /// Called only when a citizen actually opens a post (its image/detail
  /// viewer) — never merely because the post scrolled into view in the
  /// feed. Frontend/demo counter only: no per-session unique-view
  /// deduplication, same as likes/comments/shares elsewhere in this
  /// service — reopening the same post again increments it again.
  Future<void> recordView(String postId) async {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.viewCount += 1;
    notifyListeners();
    await _persist();
  }
}
