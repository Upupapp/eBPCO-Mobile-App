import '../../domain/models.dart';
import 'api_client.dart';
import 'token_store.dart';

/// Typed methods over [ApiClient] for every citizen endpoint Phase 1 needs
/// — ported one-for-one from `citizen-api.client.ts` /
/// `citizen-identity.api.ts`, same paths, same request/response shapes.
/// Businesses and Payments endpoints are deliberately not here yet
/// (Phase 2/3 — see the approved plan).
class CitizenApi {
  CitizenApi._();
  static final CitizenApi instance = CitizenApi._();

  final _client = ApiClient.instance;

  // ── Auth ─────────────────────────────────────────────────────────────

  Future<void> requestEmailVerification(String email) =>
      _client.post('/auth/register/email/request', body: {'email': email}, auth: false);

  Future<void> confirmEmailVerification(String email, String code) =>
      _client.post('/auth/register/email/confirm', body: {'email': email, 'code': code}, auth: false);

  Future<void> register({
    required String firstName,
    String? middleName,
    required String lastName,
    required String dateOfBirth,
    required String sex,
    required String civilStatus,
    required String nationality,
    required String email,
    required String mobileNumber,
    required String street,
    required String barangay,
    required String city,
    required String province,
    required String postalCode,
    required String password,
  }) =>
      _client.post('/auth/register', auth: false, body: {
        'firstName': firstName,
        if (middleName != null && middleName.isNotEmpty) 'middleName': middleName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'sex': sex,
        'civilStatus': civilStatus,
        'nationality': nationality,
        'email': email,
        'mobileNumber': mobileNumber,
        'street': street,
        'barangay': barangay,
        'city': city,
        'province': province,
        'postalCode': postalCode,
        'password': password,
      });

  /// Signs in and stores the resulting tokens. Throws [ApiError] on a wrong
  /// email/password (the server's own `title` is the citizen-facing
  /// message — see `ApiError.citizenMessage`).
  Future<void> login(String email, String password) async {
    final body = await _client.post<Map<String, dynamic>>(
      '/auth/token',
      auth: false,
      // grantType is required by the server (auth.controller.ts's
      // `credentials` schema) — anything else is refused 400 with a
      // pointer at this field. Missing here originally; caught live on a
      // real device, where it surfaced as an opaque "request did not
      // validate" with no indication which field was the problem.
      body: {'grantType': 'password', 'email': email, 'password': password},
    );
    await TokenStore.instance.save(
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String?,
      expiresInSeconds: body['expiresIn'] as int?,
    );
  }

  Future<void> logout() async {
    final refreshToken = await TokenStore.instance.refreshToken();
    if (refreshToken != null) {
      try {
        await _client.post('/auth/revoke', body: {'refreshToken': refreshToken}, auth: false);
      } catch (_) {
        // Best-effort, same as the web portals: the local session clears
        // either way, and a citizen tapping "Log Out" must not be told it
        // failed because the network dropped mid-revoke.
      }
    }
    await TokenStore.instance.clear();
  }

  Future<void> requestPasswordReset(String email) => _client.post('/auth/password/forgot', auth: false, body: {'email': email});

  Future<void> resetPassword(String token, String password) =>
      _client.post('/auth/password/reset', auth: false, body: {'token': token, 'password': password});

  Future<void> changePassword(String currentPassword, String newPassword) => _client.post(
        '/auth/password/change',
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

  // ── Profile ──────────────────────────────────────────────────────────

  Future<MeProfile> me() async => MeProfile.fromJson(await _client.get<Map<String, dynamic>>('/me'));

  Future<MeProfile> patchMe(Map<String, dynamic> patch) async =>
      MeProfile.fromJson(await _client.patch<Map<String, dynamic>>('/me', body: patch));

  Future<ErasureReceipt> eraseAccount() async => ErasureReceipt.fromJson(await _client.delete<Map<String, dynamic>>('/me'));

  Future<Map<String, dynamic>> requestExport() => _client.post<Map<String, dynamic>>('/me/export');

  Future<Map<String, dynamic>> exportStatus(String requestId) => _client.get<Map<String, dynamic>>('/me/export/$requestId');

  /// A short-lived signed URL to the finished export archive, not the bytes
  /// — same shape as every other document-content route this app touches.
  Future<String> exportContent(String requestId) async =>
      (await _client.get<Map<String, dynamic>>('/me/export/$requestId/content'))['url'] as String;

  // ── Applications ─────────────────────────────────────────────────────

  Future<List<ApplicationSummary>> listApplications() async {
    final body = await _client.get<Map<String, dynamic>>('/applications');
    return (body['data'] as List<dynamic>).map((e) => ApplicationSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ApplicationSummary> getApplication(String id) async =>
      ApplicationSummary.fromJson(await _client.get<Map<String, dynamic>>('/applications/$id'));

  Future<List<TimelineEntry>> getTimeline(String id) async {
    final body = await _client.get<List<dynamic>>('/applications/$id/timeline');
    return body.map((e) => TimelineEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DocumentEntry>> listApplicationDocuments(String id) async {
    final body = await _client.get<List<dynamic>>('/applications/$id/documents');
    return body.map((e) => DocumentEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// The live, pre-filing checklist for a permit type — what the wizard
  /// shows before any application row exists yet.
  Future<List<RequirementDoc>> requirementsForPermitType(String permitType) async {
    final body = await _client.get<Map<String, dynamic>>('/requirements/${Uri.encodeComponent(permitType)}');
    return (body['documents'] as List<dynamic>)
        .map((e) => RequirementDoc.fromCatalogJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The checklist SNAPSHOT taken at filing — once a Draft/application row
  /// exists, this (not the catalog above) is the source of truth for what's
  /// required and what's already provided, so a resumed draft shows real
  /// progress rather than starting the checklist over.
  Future<List<RequirementDoc>> applicationRequirements(String applicationId) async {
    final body = await _client.get<Map<String, dynamic>>('/applications/$applicationId/requirements');
    return (body['requirements'] as List<dynamic>).map((e) => RequirementDoc.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Files a new application, or a Draft when [saveAsDraft] is true.
  Future<ApplicationSummary> submit({
    required String permitType,
    required String applicationAction,
    String? renewsPermitNumber,
    String? priorPermitClaim,
    String? businessId,
    String? location,
    List<String> documentIds = const [],
    Map<String, dynamic> form = const {},
    bool saveAsDraft = false,
  }) async =>
      ApplicationSummary.fromJson(await _client.post<Map<String, dynamic>>(
        '/applications',
        idempotencyKey: _client.newIdempotencyKey(),
        body: {
          'permitType': permitType,
          'applicationAction': applicationAction,
          if (renewsPermitNumber != null) 'renewsPermitNumber': renewsPermitNumber,
          if (priorPermitClaim != null) 'priorPermitClaim': priorPermitClaim,
          if (businessId != null) 'businessId': businessId,
          if (location != null) 'location': location,
          'documentIds': documentIds,
          'form': form,
          'saveAsDraft': saveAsDraft,
        },
      ));

  /// Keeps editing a Draft — a partial patch, only the fields that changed.
  Future<ApplicationSummary> updateDraft(String applicationId, Map<String, dynamic> patch) async =>
      ApplicationSummary.fromJson(await _client.patch<Map<String, dynamic>>('/applications/$applicationId', body: patch));

  /// Finalizes a Draft — `Draft -> Submitted`.
  Future<ApplicationSummary> submitDraft(String applicationId) async => ApplicationSummary.fromJson(
        await _client.post<Map<String, dynamic>>('/applications/$applicationId/submit', idempotencyKey: _client.newIdempotencyKey()),
      );

  Future<void> cancelApplication(String applicationId, {String? reason}) => _client.post(
        '/applications/$applicationId/cancel',
        idempotencyKey: _client.newIdempotencyKey(),
        body: reason == null ? {} : {'reason': reason},
      );

  // ── Documents ────────────────────────────────────────────────────────

  /// `POST /documents` — bytes travel as base64 in the JSON body (same
  /// `base64-in-json` encoding `GET /limits` describes), not multipart.
  Future<String> uploadDocument({
    required String fileName,
    required String label,
    required String contentBase64,
    String? applicationId,
    String? requirementCode,
  }) async {
    final body = await _client.post<Map<String, dynamic>>(
      '/documents',
      idempotencyKey: _client.newIdempotencyKey(),
      body: {
        'fileName': fileName,
        'label': label,
        'contentBase64': contentBase64,
        if (applicationId != null) 'applicationId': applicationId,
        if (requirementCode != null) 'requirementCode': requirementCode,
      },
    );
    return body['documentId'] as String;
  }

  Future<Map<String, dynamic>> limits() => _client.get<Map<String, dynamic>>('/limits', auth: false);

  // ── Notifications ────────────────────────────────────────────────────

  Future<({List<NotificationEntry> data, int unresolvedCount})> notifications() async {
    final body = await _client.get<Map<String, dynamic>>('/notifications');
    final data = (body['data'] as List<dynamic>).map((e) => NotificationEntry.fromJson(e as Map<String, dynamic>)).toList();
    return (data: data, unresolvedCount: body['unresolvedCount'] as int? ?? 0);
  }

  Future<void> markNotificationRead(String id) => _client.patch('/notifications/$id/read');
}
