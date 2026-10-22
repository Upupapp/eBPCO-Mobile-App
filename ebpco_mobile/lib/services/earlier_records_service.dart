import 'package:flutter/foundation.dart';

import '../core/api/citizen_api.dart';
import '../domain/earlier_records.dart';

/// The signed-in citizen's records before eBPCO (ebpco-api 069): the permits
/// an officer matched to the account (`GET /me/earlier-permits`) and the
/// citizen's own "this earlier permit is mine" requests (`GET`/`POST
/// /me/record-claims`). The portal's `EarlierRecordsStore`.
///
/// Kept apart from `ApplicationsService` on purpose: these are not filings,
/// and nothing here may reach the application counts or lists.
class EarlierRecordsService extends ChangeNotifier {
  final _api = CitizenApi.instance;

  List<EarlierPermit> _permits = const [];
  List<RecordClaim> _claims = const [];

  /// Bumped by [clear], so an answer that arrives after sign-out is dropped
  /// instead of showing one citizen's records to the next.
  int _generation = 0;

  /// Newest first, as the server sends them.
  List<EarlierPermit> get permits => _permits;
  List<RecordClaim> get claims => _claims;

  /// Requests the Municipality has not answered yet.
  int get waitingCount => _claims.where((c) => c.isWaiting).length;

  /// The earlier permits a Renewal or Amendment of [permitType] could be about.
  List<EarlierPermit> permitsOfType(String permitType) =>
      _permits.where((p) => p.permitType == permitType).toList();

  /// Fetches both lists. A failure keeps what was there: a dropped
  /// connection must not make a citizen's records vanish while they look.
  Future<void> refresh() async {
    final asked = _generation;
    final (permits, claims) = await (_orNull(_api.earlierPermits()), _orNull(_api.recordClaims())).wait;
    if (asked != _generation) return;
    if (permits != null) _permits = permits;
    if (claims != null) _claims = claims;
    notifyListeners();
  }

  /// `POST /me/record-claims`. Null when sent — the new request then heads
  /// [claims]; otherwise the words to show (409 already waiting, 429 ten
  /// waiting, 400).
  Future<String?> claim({required String permitNumber, String? dateIssued, String? orNumber}) async {
    final asked = _generation;
    try {
      final claim = await _api.claimEarlierPermit(permitNumber: permitNumber, dateIssued: dateIssued, orNumber: orNumber);
      if (asked == _generation) {
        _claims = [claim, ..._claims.where((c) => c.id != claim.id)];
        notifyListeners();
      }
      return null;
    } catch (error) {
      return earlierClaimMessage(error);
    }
  }

  /// What the screens show, without the server.
  @visibleForTesting
  void seed({List<EarlierPermit> permits = const [], List<RecordClaim> claims = const []}) {
    _permits = permits;
    _claims = claims;
    notifyListeners();
  }

  void clear() {
    _generation++;
    _permits = const [];
    _claims = const [];
    notifyListeners();
  }
}

Future<T?> _orNull<T>(Future<T> request) async {
  try {
    return await request;
  } catch (_) {
    return null;
  }
}
