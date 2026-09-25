import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'persistence_recovery.dart';
import 'dart:math';
import '../models/attachment.dart';
import '../models/receipt.dart';
import '../models/request_milestones.dart';
import '../models/service_request.dart';
import '../theme/app_status.dart'; // AppStatusX.label, used on RequestMilestones.canonicalStatusFor()'s return value

/// Local, frontend-only "database" for Dokyu + Tulong requests. Persists to
/// SharedPreferences as JSON so submissions survive app restarts during the
/// demo. This is intentionally the ONLY place that touches storage for
/// requests — screens call submit()/advanceStatus() and never read/write
/// SharedPreferences directly, so swapping this for real HTTP calls later
/// (once the backend developer builds the API — see MISSING Web Admin
/// processes in TERESA_RIZAL_MOBILE_WEB_ALIGNMENT.md) only touches this file.
class RequestsService extends ChangeNotifier {
  static const _key = 'teresa_rizal_service_requests';

  /// The verified demo resident's current identity — see
  /// _seedDemoStatusSimulationsIfNeeded and _migrateStaleDemoIdentity,
  /// which both reference these rather than duplicating the literals.
  static const _demoApplicantId = 'ESP-RES-2024-9002';
  static const _demoApplicantName = 'Perlita Quiambao';

  /// The demo identity these six seeded requests were originally created
  /// under, before the Perlita-Quiambao-to-Perlita-Quiambao correction — see
  /// _migrateStaleDemoIdentity's own doc comment.
  static const _staleDemoApplicantId = 'ESP-RES-2024-1203';
  static const _staleDemoApplicantName = 'Perlita Quiambao';

  final List<ServiceRequest> _requests = [];
  bool _loaded = false;

  /// Defaults to true for real app usage (see
  /// _seedDemoStatusSimulationsIfNeeded's own doc comment) — tests that
  /// need a pristine/empty or precisely-countable request list pass false
  /// to opt out.
  ///
  /// As of the live-demo cleanup, the real running app (see main.dart)
  /// passes false here — Dokyu/Tulong start clean, with nothing pre-
  /// submitted, so a client demo isn't showing fake completed history
  /// before the presenter has done anything. Every existing test keeps
  /// passing its own explicit value (mostly true) exactly as before, so
  /// this default only changes behavior for the one real construction site.
  final bool seedDemoData;

  /// True only for the real running app (see main.dart) — permanently
  /// strips the retired Dokyu/Tulong demo-status-simulation and paid-
  /// transaction seed records (see [_demoSeedIds]/[_paidTransactionSeedIds])
  /// from whatever's already persisted in SharedPreferences, once. Removing
  /// them from the seeding functions alone only affects a fresh install; a
  /// browser/device that already ran an earlier build with seeding on has
  /// these nine specific records permanently saved locally.
  ///
  /// Left false (the default) for every test — several deliberately
  /// construct their own [ServiceRequest] fixtures that reuse these exact
  /// literal ids on purpose (e.g. rejected_application_panel_test.dart's
  /// Tulong-eligibility-while-blocked scenario), and those must never be
  /// swept up by this cleanup, which only ever targets the real seeded
  /// records this app itself used to create.
  final bool retireLegacyDemoRequestSeeds;

  List<ServiceRequest> get all => List.unmodifiable(_requests);

  List<ServiceRequest> byCategory(ServiceCategory category) =>
      _requests.where((r) => r.category == category).toList()..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  RequestsService({this.seedDemoData = true, this.retireLegacyDemoRequestSeeds = false}) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _requests.addAll(PersistenceRecovery.decodeEach(
          jsonDecode(raw) as List,
          (e) => ServiceRequest.fromJson(e),
          what: 'service request',
        ));
      }
      if (retireLegacyDemoRequestSeeds && _removeRetiredDemoRequestSeeds()) await _persist();
      if (_migrateStaleDemoIdentity()) await _persist();
      if (_migrateEducationalRejectionReason()) await _persist();
      if (_migrateSeniorCitizenIdCategory()) await _persist();
      if (_migrateObsoleteTrackingLabels()) await _persist();
      if (seedDemoData) {
        await _seedDemoStatusSimulationsIfNeeded();
        await _seedPaidTransactionDemoIfNeeded();
      }
    } catch (error) {
      // A payload persisted by an earlier build can fail to decode after a
      // model or enum changes shape. Before this guard that throw escaped an
      // un-awaited future started in the constructor, so notifyListeners()
      // never fired and AuthGate spun on the splash forever - recoverable
      // only by clearing app data. Discard the unreadable state instead; the
      // migrations here already exist for exactly this class of change.
      _requests.clear();
      await PersistenceRecovery.discardUnreadable(
        service: 'RequestsService',
        keys: const [_key],
        error: error,
      );
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Removes exactly the nine known Dokyu/Tulong demo seed ids (see
  /// [_demoSeedIds]/[_paidTransactionSeedIds]) from whatever's already
  /// persisted — never a citizen's own genuinely-submitted request, which
  /// is always assigned a `req-<timestamp>` id (see [submit]) and can never
  /// collide with one of these literal seed ids. Idempotent: once these
  /// nine ids are gone from local storage, later launches simply find
  /// nothing left to remove.
  bool _removeRetiredDemoRequestSeeds() {
    final before = _requests.length;
    _requests.removeWhere((r) => _demoSeedIds.contains(r.id) || _paidTransactionSeedIds.contains(r.id));
    return _requests.length != before;
  }

  /// A browser that already had the six demo requests seeded before the
  /// Perlita-Quiambao-to-Perlita-Quiambao identity correction has them
  /// permanently persisted under the old applicant id/name —
  /// _seedDemoStatusSimulationsIfNeeded's own "already present, skip" guard
  /// means a source-code fix alone never reaches an existing browser's
  /// saved copy. Corrects only the affected demo-seeded requests in place
  /// (and any receipt already generated for one of them), preserving every
  /// other field — a citizen's own genuinely-submitted requests are never
  /// touched, since they were never sourced from these stale constants.
  bool _migrateStaleDemoIdentity() {
    var changed = false;
    for (var i = 0; i < _requests.length; i++) {
      final r = _requests[i];
      if (!_demoSeedIds.contains(r.id) || r.applicantId != _staleDemoApplicantId) continue;
      final receipt = r.receipt;
      _requests[i] = ServiceRequest(
        id: r.id,
        referenceNumber: r.referenceNumber,
        applicantId: _demoApplicantId,
        applicantName: _demoApplicantName,
        typeName: r.typeName,
        category: r.category,
        office: r.office,
        purpose: r.purpose,
        submittedAt: r.submittedAt,
        status: r.status,
        statusHistory: r.statusHistory,
        attachments: r.attachments,
        citizenRemarks: r.citizenRemarks,
        adminRemarks: r.adminRemarks,
        expectedDays: r.expectedDays,
        formFields: r.formFields,
        requiresPayment: r.requiresPayment,
        fee: r.fee,
        paymentMethod: r.paymentMethod,
        receipt: receipt != null && receipt.residentName == _staleDemoApplicantName
            ? Receipt(
                type: receipt.type,
                amount: receipt.amount,
                referenceNumber: receipt.referenceNumber,
                dateTime: receipt.dateTime,
                residentName: _demoApplicantName,
                serviceName: receipt.serviceName,
                requestReferenceNumber: receipt.requestReferenceNumber,
              )
            : receipt,
      );
      changed = true;
    }
    return changed;
  }

  /// Senior Citizen ID Application (OSCA Membership) moved from Tulong to
  /// Dokyu — it's an ID/membership registration, not an assistance/benefit
  /// program (see mock_catalog.dart's dokyu_senior_citizen_id doc comment
  /// for why, and how it differs from the genuinely-Tulong Social Pension
  /// item). A device that already has a resident's own real Senior Citizen
  /// ID request persisted under the old Tulong category gets it corrected
  /// here, in place — reference number, attachments, status/history, and
  /// every other field carry over completely unchanged; only [category]
  /// itself moves to Dokyu, so My Requests / Request Detail / Track This
  /// Request keep working exactly as before, now consistently filed
  /// alongside the service's own new location. Matched by [typeName]
  /// rather than an id, since — unlike the demo-seed migrations above —
  /// this must also catch a citizen's own genuinely-submitted request, not
  /// just a seeded one.
  static const _seniorCitizenIdTypeName = 'Senior Citizen ID Application (OSCA Membership)';

  bool _migrateSeniorCitizenIdCategory() {
    var changed = false;
    for (var i = 0; i < _requests.length; i++) {
      final r = _requests[i];
      if (r.typeName != _seniorCitizenIdTypeName || r.category != ServiceCategory.tulong) continue;
      _requests[i] = ServiceRequest(
        id: r.id,
        referenceNumber: r.referenceNumber,
        applicantId: r.applicantId,
        applicantName: r.applicantName,
        typeName: r.typeName,
        category: ServiceCategory.dokyu,
        office: r.office,
        purpose: r.purpose,
        submittedAt: r.submittedAt,
        status: r.status,
        statusHistory: r.statusHistory,
        attachments: r.attachments,
        citizenRemarks: r.citizenRemarks,
        adminRemarks: r.adminRemarks,
        rejectionGuidance: r.rejectionGuidance,
        expectedDays: r.expectedDays,
        formFields: r.formFields,
        requiresPayment: r.requiresPayment,
        fee: r.fee,
        paymentMethod: r.paymentMethod,
        receipt: r.receipt,
      );
      changed = true;
    }
    return changed;
  }

  /// A browser that already had the seeded Educational Assistance demo
  /// request persisted before its rejection reason/guidance placeholder was
  /// added (see _seedDemoStatusSimulationsIfNeeded) has it saved with
  /// adminRemarks/rejectionGuidance still null — the seeding function's own
  /// "already present, skip" guard means a source-code fix alone never
  /// reaches that already-persisted copy, same reasoning as
  /// _migrateStaleDemoIdentity above. Backfills both fields (and the
  /// matching statusHistory entry's own remarks) in place; a citizen's own
  /// genuinely-submitted/rejected request is never touched, since this only
  /// ever matches the one specific seeded id.
  bool _migrateEducationalRejectionReason() {
    const reason = 'Submitted school enrollment document could not be verified for the current academic term. '
        'Please submit an updated Certificate of Enrollment or Registration issued by the school.';
    const guidance = 'Upload an updated school document and submit a new Educational Assistance application.';

    final index = _requests.indexWhere((r) => r.id == 'demo-tulong-educational');
    if (index == -1) return false;
    final r = _requests[index];
    if (r.adminRemarks != null && r.rejectionGuidance != null) return false;

    r.adminRemarks = reason;
    r.rejectionGuidance = guidance;
    final lastIndex = r.statusHistory.length - 1;
    if (lastIndex >= 0 && r.statusHistory[lastIndex].status == 'Rejected') {
      r.statusHistory[lastIndex] = StatusHistoryEntry(
        status: 'Rejected',
        at: r.statusHistory[lastIndex].at,
        actor: r.statusHistory[lastIndex].actor,
        remarks: reason,
      );
    }
    return true;
  }

  /// Mobile-only final request-flow correction pass: a device that already
  /// persisted requests using a retired tracking label (Pending Review,
  /// Processing, Waiting for Payment, Payment Method Selected, Payment
  /// Processing, Receipt Generated, Paid, Ready for Release, Ready for Pick
  /// Up, Completed, Waiting Requirements) gets them converted in place to
  /// the new simplified citizen lifecycle — never wiped, never duplicated,
  /// no other field touched. Applied to both a request's current
  /// [ServiceRequest.status] and every recorded [StatusHistoryEntry] (so the
  /// timeline never shows a stage name that no longer exists), then
  /// collapses any consecutive duplicate history entries the remapping
  /// itself produced (e.g. the old Pending Review -> Under Verification ->
  /// Processing chain all collapsing onto a single Under Verification
  /// entry), keeping an old request's timeline exactly as tidy as a
  /// freshly-submitted one's — see A29's "avoid a huge vertical timeline
  /// caused by obsolete stages."
  ///
  /// 'Ready for Pick Up' and 'Completed' were themselves only briefly the
  /// live Dokyu/Tulong labels (before the status-terminology correction
  /// pass retired them in favor of the Web Admin's own current wording) —
  /// included here for the same reason as the older Web-Admin-parity labels
  /// above: nothing already persisted under them should ever show a stage
  /// name this build no longer recognizes.
  static const _obsoleteStatusMigration = <String, String>{
    'Pending Review': RequestMilestones.underVerification,
    'Processing': RequestMilestones.underVerification,
    'Waiting for Payment': RequestMilestones.approved,
    'Payment Method Selected': RequestMilestones.approved,
    'Payment Processing': RequestMilestones.approved,
    'Receipt Generated': RequestMilestones.approved,
    'Paid': RequestMilestones.approved,
    'Ready for Release': RequestMilestones.markToRelease,
    'Ready for Pick Up': RequestMilestones.markToRelease,
    'Completed': RequestMilestones.released,
    // The earlier "admin flagged a document" simulation used this Web-
    // Admin-shared label; the Mobile-only tracking timeline now uses
    // "Under Review" instead (same meaning, citizen-facing wording).
    'Waiting Requirements': RequestMilestones.underReview,
  };

  bool _migrateObsoleteTrackingLabels() {
    var changed = false;
    for (final r in _requests) {
      if (r.category == ServiceCategory.sakunaIncident) continue; // never used milestones
      final newStatus = _obsoleteStatusMigration[r.status];
      if (newStatus != null) {
        r.status = newStatus;
        changed = true;
      }
      for (var i = 0; i < r.statusHistory.length; i++) {
        final entry = r.statusHistory[i];
        final mapped = _obsoleteStatusMigration[entry.status];
        if (mapped == null) continue;
        r.statusHistory[i] = StatusHistoryEntry(
          status: mapped,
          at: entry.at,
          actor: entry.actor,
          remarks: entry.remarks,
        );
        changed = true;
      }
      final collapsed = <StatusHistoryEntry>[];
      for (final entry in r.statusHistory) {
        if (collapsed.isNotEmpty && collapsed.last.status == entry.status) continue;
        collapsed.add(entry);
      }
      if (collapsed.length != r.statusHistory.length) {
        r.statusHistory
          ..clear()
          ..addAll(collapsed);
        changed = true;
      }
    }
    return changed;
  }

  /// Pre-made Dokyu/Tulong requests covering the three primary tracking
  /// outcomes (Under Verification, Approved, Rejected — see
  /// RequestMilestones) so the client can see what each looks like —
  /// request list tile, request detail, and the matching notification (via
  /// the same statusHistory-derived feed every other request notification
  /// already comes from, see notification_feed.dart) — without submitting
  /// anything first. Seeded exactly once, guarded by [_demoSeedIds] already
  /// being present, so relaunching the app or a hot-reload never re-adds or
  /// duplicates them, and any requests the citizen has actually submitted
  /// are never touched.
  static const _demoSeedIds = [
    'demo-dokyu-barangay-clearance',
    'demo-dokyu-business-permit',
    'demo-dokyu-certificate-indigency',
    'demo-tulong-medical',
    'demo-tulong-financial',
    'demo-tulong-educational',
  ];

  Future<void> _seedDemoStatusSimulationsIfNeeded() async {
    if (_requests.any((r) => _demoSeedIds.contains(r.id))) return;

    const applicantId = _demoApplicantId; // Perlita Quiambao — verified, has Dokyu/Tulong access.
    const applicantName = _demoApplicantName;
    final now = DateTime.now();
    DateTime daysAgo(int d) => now.subtract(Duration(days: d));

    ServiceRequest demo({
      required String id,
      required String refSuffix,
      required String typeName,
      required ServiceCategory category,
      required String office,
      required String expectedDays,
      required String purpose,
      required String finalStatus,
      required String actorRole,
      required String remarks,
      bool requiresPayment = false,
      String fee = '',
      // Only ever set for a seeded Rejected demo request — mirrors what
      // RequestsService.rejectDemo() itself sets for a live-rejected one
      // (adminRemarks == the same text as the rejection statusHistory
      // entry's own remarks), so RequestDetailScreen's Application Rejected
      // panel renders identically either way. rejectionGuidance is the
      // panel's optional "what you can do" line — see ServiceRequest's own
      // doc comment for its fallback when left null.
      String? adminRemarks,
      String? rejectionGuidance,
    }) {
      final submittedAt = daysAgo(5);
      final request = ServiceRequest(
        id: id,
        referenceNumber: '${category == ServiceCategory.dokyu ? 'DR' : 'AR'}-${now.year}-DEMO$refSuffix',
        applicantId: applicantId,
        applicantName: applicantName,
        typeName: typeName,
        category: category,
        office: office,
        purpose: purpose,
        submittedAt: submittedAt,
        status: finalStatus,
        statusHistory: [
          StatusHistoryEntry(
            status: 'Submitted',
            at: submittedAt,
            actor: 'Citizen',
            remarks: 'Request submitted via mobile app.',
          ),
          StatusHistoryEntry(status: finalStatus, at: daysAgo(1), actor: actorRole, remarks: remarks),
        ],
        attachments: const [],
        expectedDays: expectedDays,
        requiresPayment: requiresPayment,
        fee: fee,
        adminRemarks: adminRemarks,
        rejectionGuidance: rejectionGuidance,
      );
      // Every Dokyu request gets a receipt at submission time now (see
      // RequestsService.submit) — these seeded demo rows mirror that so
      // "View Receipt" behaves consistently even for pre-made content.
      if (category == ServiceCategory.dokyu) {
        final method = requiresPayment ? 'GCash' : null;
        request.paymentMethod = method;
        request.receipt = _generateReceiptFor(request, paymentMethod: method);
      }
      return request;
    }

    _requests.addAll([
      demo(
        id: 'demo-dokyu-barangay-clearance',
        refSuffix: '01',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        expectedDays: '1-2 working days',
        purpose: 'Proof of Residency',
        finalStatus: 'Approved',
        actorRole: 'Barangay Staff',
        remarks: 'Your Barangay Clearance request has been approved.',
        requiresPayment: true, // ₱50.00 — see mock_catalog.dart's dokyu_barangay_clearance fee
        fee: '₱50.00',
      ),
      demo(
        id: 'demo-dokyu-business-permit',
        refSuffix: '02',
        typeName: 'Business Permit (New Application)',
        category: ServiceCategory.dokyu,
        office: 'Business Permits and Licensing Office',
        expectedDays: '7 working days',
        purpose: 'New business registration',
        finalStatus: 'Under Verification',
        actorRole: 'Business Permits and Licensing Office Staff',
        remarks: 'Your Business Permit request is being verified.',
        requiresPayment: true, // ₱500.00 and up — see dokyu_business_new fee
        fee: '₱500.00 and up (based on capital)',
      ),
      demo(
        id: 'demo-dokyu-certificate-indigency',
        refSuffix: '03',
        typeName: 'Certificate of Indigency',
        category: ServiceCategory.dokyu,
        office: 'Municipal Social Welfare and Development Office',
        expectedDays: '2-3 working days',
        purpose: 'Medical Assistance',
        finalStatus: 'Rejected',
        actorRole: 'Municipal Social Welfare and Development Office Staff',
        remarks: 'Your Certificate of Indigency request was rejected.',
        // Free — see dokyu_indigency fee; requiresPayment left false.
      ),
      demo(
        id: 'demo-tulong-medical',
        refSuffix: '04',
        typeName: 'Medical Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'Municipal Social Welfare and Development Office',
        expectedDays: '3-5 working days',
        purpose: 'Hospital bill assistance',
        finalStatus: 'Under Verification',
        actorRole: 'Municipal Social Welfare and Development Office Staff',
        remarks: 'Your Medical Assistance request is being verified.',
        // Free — see tulong_medical fee; requiresPayment left false.
      ),
      demo(
        id: 'demo-tulong-financial',
        refSuffix: '05',
        typeName: 'Financial Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'Municipal Social Welfare and Development Office',
        expectedDays: '3-5 working days',
        purpose: 'Social case study assistance',
        finalStatus: 'Approved',
        actorRole: 'Municipal Social Welfare and Development Office Staff',
        remarks: 'Your Financial Assistance request has been approved.',
        // Free — see tulong_financial fee; requiresPayment left false.
      ),
      demo(
        id: 'demo-tulong-educational',
        refSuffix: '06',
        typeName: 'Educational Assistance',
        category: ServiceCategory.tulong,
        office: 'Office of the Municipal Mayor',
        expectedDays: '10-15 working days',
        purpose: 'Tuition and allowance support',
        finalStatus: 'Rejected',
        actorRole: 'Office of the Municipal Mayor Staff',
        // Placeholder rejection reason for demonstration purposes only —
        // see RequestDetailScreen's Application Rejected panel, which reads
        // this straight from adminRemarks (same value as this status
        // entry's own remarks, matching how a live Reject (Demo) already
        // sets both).
        remarks: 'Submitted school enrollment document could not be verified for the current academic term. '
            'Please submit an updated Certificate of Enrollment or Registration issued by the school.',
        adminRemarks: 'Submitted school enrollment document could not be verified for the current academic term. '
            'Please submit an updated Certificate of Enrollment or Registration issued by the school.',
        rejectionGuidance: 'Upload an updated school document and submit a new Educational Assistance application.',
        // Free — see tulong_educational fee; requiresPayment left false.
      ),
    ]);
    await _persist();
  }

  /// Three already-Paid demo requests (one per payment method) so the
  /// Transactions screen has real content to demonstrate immediately,
  /// without having to manually walk a request through an application's
  /// own Payment Method step first. Same request+receipt architecture as a
  /// genuinely-submitted paid Dokyu request (see [submit]/
  /// [_generateReceiptFor]) — Transactions has no separate data source, so
  /// these appear there exactly the same way a live one would. Dokyu only —
  /// Tulong never has a payment method or receipt (assistance applications
  /// have no receipt concept; see the Mobile-only final request-flow
  /// correction pass). Seeded exactly once, guarded by
  /// [_paidTransactionSeedIds] already being present (same pattern as
  /// [_seedDemoStatusSimulationsIfNeeded]).
  static const _paidTransactionSeedIds = ['demo-paid-dokyu-residency-gcash', 'demo-paid-dokyu-rpt-maya'];

  Future<void> _seedPaidTransactionDemoIfNeeded() async {
    if (_requests.any((r) => _paidTransactionSeedIds.contains(r.id))) return;

    final now = DateTime.now();
    DateTime daysAgo(int d) => now.subtract(Duration(days: d));

    ServiceRequest paid({
      required String id,
      required String refSuffix,
      required String typeName,
      required String office,
      required String expectedDays,
      required String purpose,
      required String fee,
      required int submittedDaysAgo,
      required String paymentMethod,
      required ReceiptType receiptType,
      required String receiptRefDigits,
    }) {
      final submittedAt = daysAgo(submittedDaysAgo);
      final referenceNumber = 'DR-${now.year}-DEMO$refSuffix';
      final receiptPrefix = switch (receiptType) {
        ReceiptType.gcash => 'GC',
        ReceiptType.maya => 'MY',
        ReceiptType.onsite => 'DEMO-PAY',
        ReceiptType.free => 'FR',
        // Unreachable: `unknown` is only ever decoded, never generated.
        ReceiptType.unknown => 'RC',
      };
      return ServiceRequest(
        id: id,
        referenceNumber: referenceNumber,
        applicantId: _demoApplicantId,
        applicantName: _demoApplicantName,
        typeName: typeName,
        category: ServiceCategory.dokyu,
        office: office,
        purpose: purpose,
        submittedAt: submittedAt,
        status: RequestMilestones.approved,
        statusHistory: [
          StatusHistoryEntry(
            status: RequestMilestones.submitted,
            at: submittedAt,
            actor: 'Citizen',
            remarks: 'Request submitted via mobile app.',
          ),
          StatusHistoryEntry(
            status: RequestMilestones.approved,
            at: daysAgo(submittedDaysAgo - 1),
            actor: 'Demo Simulation',
            remarks: 'Your request has been approved.',
          ),
        ],
        attachments: const [],
        expectedDays: expectedDays,
        requiresPayment: true,
        fee: fee,
        paymentMethod: paymentMethod,
        receipt: Receipt(
          type: receiptType,
          amount: fee,
          referenceNumber: '$receiptPrefix-$receiptRefDigits',
          dateTime: submittedAt,
          residentName: _demoApplicantName,
          serviceName: typeName,
          requestReferenceNumber: referenceNumber,
        ),
      );
    }

    _requests.addAll([
      paid(
        id: 'demo-paid-dokyu-residency-gcash',
        refSuffix: '07',
        typeName: 'Certificate of Residency', // mock_catalog.dart: dokyu_residency
        office: 'Civil Registrar',
        expectedDays: '1-2 working days',
        purpose: 'Proof of Residency',
        fee: '₱50.00', // dokyu_residency's own configured fee
        submittedDaysAgo: 10,
        paymentMethod: 'GCash',
        receiptType: ReceiptType.gcash,
        receiptRefDigits: '5820147736',
      ),
      paid(
        id: 'demo-paid-dokyu-rpt-maya',
        refSuffix: '08',
        typeName: 'Real Property Tax Clearance', // mock_catalog.dart: dokyu_rpt
        office: "Treasurer's Office",
        expectedDays: 'Same day',
        purpose: 'Loan requirement',
        fee: '₱100.00', // dokyu_rpt's own configured fee
        submittedDaysAgo: 8,
        paymentMethod: 'Maya',
        receiptType: ReceiptType.maya,
        receiptRefDigits: '3391208465',
      ),
    ]);
    await _persist();
  }

  bool get loaded => _loaded;

  /// Erases every request belonging to [accountId] from memory and from disk.
  ///
  /// Called on sign-out. Before this existed, `logout()` cleared only the
  /// session, so a citizen's full request history stayed on the device — which
  /// matters for a municipal app that will be used on shared and family
  /// handsets.
  Future<void> forgetAccount(String accountId) async {
    _requests.removeWhere((r) => r.applicantId == accountId);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_requests.map((r) => r.toJson()).toList()));
  }

  String _generateReference(ServiceCategory category) {
    final prefix = switch (category) {
      ServiceCategory.dokyu => 'DR',
      ServiceCategory.tulong => 'AR',
      ServiceCategory.sakunaIncident => 'IR',
      // Unreachable: `unknown` is only ever decoded, never generated.
      ServiceCategory.unknown => 'RQ',
    };
    final year = DateTime.now().year;
    final seq = (_requests.where((r) => r.category == category).length + 1).toString().padLeft(4, '0');
    return '$prefix-$year-$seq';
  }

  /// Citizen submits a new request — the mobile-side half of the "Mobile
  /// Action -> Web Admin Destination" flow documented per-process in the
  /// alignment doc. Starts at "Submitted"; a citizen-only initial status
  /// history entry is recorded immediately.
  ///
  /// [paymentMethod] ('GCash'/'Maya'/'Onsite') is passed only by a paid
  /// Dokyu service's own Payment Method application step — payment now
  /// happens as part of submitting the application itself, never as a
  /// later tracking milestone (see RequestMilestones' own doc comment), so
  /// there is exactly one call site per completed application and never a
  /// second, payment-only request. Every Dokyu request (paid or free) gets
  /// a [Receipt] generated synchronously right here, in the same call that
  /// creates the request — Tulong requests never get one (assistance
  /// applications have no receipt concept).
  Future<ServiceRequest> submit({
    required String applicantId,
    required String applicantName,
    required String typeName,
    required ServiceCategory category,
    required String office,
    required String purpose,
    required String expectedDays,
    required List<Attachment> attachments,
    Map<String, dynamic> formFields = const {},
    bool requiresPayment = false,
    String fee = '',
    String? paymentMethod,
  }) async {
    final now = DateTime.now();
    final request = ServiceRequest(
      // The current request count is folded in alongside the timestamp —
      // two submissions made in quick succession (e.g. a presenter
      // submitting several demo requests back-to-back) can land on the same
      // DateTime.now() value on some platforms/clock resolutions, which
      // would otherwise produce a duplicate id and silently merge two
      // distinct requests under one identity (see the matching fix on
      // FlaggedRequirement's own id generation).
      id: 'req-${_requests.length}-${now.microsecondsSinceEpoch}',
      referenceNumber: _generateReference(category),
      applicantId: applicantId,
      applicantName: applicantName,
      typeName: typeName,
      category: category,
      office: office,
      purpose: purpose,
      submittedAt: now,
      status: 'Submitted',
      statusHistory: [
        StatusHistoryEntry(
          status: 'Submitted',
          at: now,
          actor: 'Citizen',
          remarks: 'Request submitted via mobile app.',
        ),
      ],
      attachments: attachments,
      expectedDays: expectedDays,
      formFields: formFields,
      requiresPayment: requiresPayment,
      fee: fee,
    );
    if (category == ServiceCategory.dokyu) {
      request.paymentMethod = paymentMethod;
      request.receipt = _generateReceiptFor(request, paymentMethod: paymentMethod);
    }
    _requests.add(request);
    await _persist();
    notifyListeners();
    return request;
  }

  Future<void> cancel(String requestId) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = 'Cancelled';
    request.statusHistory.add(
      StatusHistoryEntry(status: 'Cancelled', at: DateTime.now(), actor: 'Citizen', remarks: 'Cancelled by citizen.'),
    );
    await _persist();
    notifyListeners();
  }

  /// Whether [requestId] can still advance along the primary lifecycle
  /// (i.e. hasn't reached Completed, and isn't Rejected/Cancelled/Under
  /// Review) — drives the demo-only "Next Demo Step" control's enabled
  /// state. Under Review is deliberately excluded: it's a branch the
  /// citizen leaves via resubmission (see [resolveUnderReview]/
  /// [resumeVerification]), never via the linear advance control.
  bool canAdvance(String requestId) {
    final request = _requests.firstWhere((r) => r.id == requestId);
    // A restored record can have no history at all (see
    // ServiceRequest.fromJson) — with nothing recorded there is no position in
    // the sequence to advance from, so the control stays disabled.
    final latest = request.statusHistory.lastOrNull;
    if (latest == null) return false;
    final currentIndex = RequestMilestones.sequence.indexOf(latest.status);
    return currentIndex != -1 && currentIndex < RequestMilestones.sequence.length - 1;
  }

  /// The milestone this request would move to if advanced right now, or
  /// null if it's already at the end (or off the normal sequence, e.g.
  /// Rejected/Under Review/Cancelled).
  String? nextMilestone(String requestId) {
    final request = _requests.firstWhere((r) => r.id == requestId);
    final latest = request.statusHistory.lastOrNull;
    if (latest == null) return null;
    final currentIndex = RequestMilestones.sequence.indexOf(latest.status);
    if (currentIndex == -1 || currentIndex >= RequestMilestones.sequence.length - 1) return null;
    return RequestMilestones.sequence[currentIndex + 1];
  }

  /// DEMO-ONLY: manually advances [requestId] to its next milestone (see
  /// [RequestMilestones]) — this is a frontend simulation control, not
  /// something a real citizen ever sees; a real deployment's status
  /// changes would come from the Web Admin / backend instead. No-op if
  /// already at the end of the sequence. Payment/receipt no longer happen
  /// here — they're already settled by the time a request exists at all
  /// (see [submit]) — so this only ever walks the plain 5-stage lifecycle.
  Future<void> advanceMilestone(String requestId) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    final next = nextMilestone(requestId);
    if (next == null) return;
    request.status = RequestMilestones.canonicalStatusFor(next).label;
    request.statusHistory.add(
      StatusHistoryEntry(
        status: next,
        at: DateTime.now(),
        actor: 'Demo Simulation',
        remarks: _demoRemarksFor(next, request),
      ),
    );
    await _persist();
    notifyListeners();
  }

  String? _demoRemarksFor(String milestone, ServiceRequest request) {
    switch (milestone) {
      case RequestMilestones.underVerification:
        return 'Your request is now being verified by our staff.';
      case RequestMilestones.approved:
        return 'Your request has been approved.';
      case RequestMilestones.markToRelease:
        return request.category == ServiceCategory.dokyu
            ? 'Your document has been marked for release at the issuing office.'
            : 'Your request has been marked for release.';
      case RequestMilestones.released:
        return request.category == ServiceCategory.dokyu
            ? 'Your document has been released.'
            : 'Your request has been released.';
      default:
        return null;
    }
  }

  static final _receiptRandom = Random();

  /// Builds this Dokyu request's own receipt, generating local/demo-only
  /// transaction values — never a real gateway's reference number, never a
  /// value copied from a visual reference screenshot. Uses the request's
  /// own catalog fee/applicant/type/reference number, exactly as
  /// submitted, never an invented amount. [paymentMethod] is null exactly
  /// when [ServiceRequest.requiresPayment] is false (a Free service) —
  /// that combination generates a no-amount formality receipt instead of a
  /// paid one; a paid service always has a non-null [paymentMethod] by the
  /// time this is called, since the wizard's Payment Method step requires
  /// choosing one before submitting.
  Receipt _generateReceiptFor(ServiceRequest request, {String? paymentMethod}) {
    if (!request.requiresPayment) {
      final digits = List.generate(10, (_) => _receiptRandom.nextInt(10)).join();
      return Receipt(
        type: ReceiptType.free,
        amount: 'Free',
        referenceNumber: 'FR-$digits',
        dateTime: DateTime.now(),
        residentName: request.applicantName,
        serviceName: request.typeName,
        requestReferenceNumber: request.referenceNumber,
      );
    }
    final type = switch (paymentMethod) {
      'GCash' => ReceiptType.gcash,
      'Maya' => ReceiptType.maya,
      _ => ReceiptType.onsite,
    };
    final prefix = switch (type) {
      ReceiptType.gcash => 'GC',
      ReceiptType.maya => 'MY',
      ReceiptType.onsite => 'DEMO-PAY',
      ReceiptType.free => 'FR',
      // Unreachable: `unknown` is only ever decoded, never generated.
      ReceiptType.unknown => 'RC',
    };
    final digits = List.generate(10, (_) => _receiptRandom.nextInt(10)).join();
    return Receipt(
      type: type,
      amount: request.fee,
      referenceNumber: '$prefix-$digits',
      dateTime: DateTime.now(),
      residentName: request.applicantName,
      serviceName: request.typeName,
      requestReferenceNumber: request.referenceNumber,
    );
  }

  /// DEMO-ONLY: branches [requestId] straight to Rejected with [reason] —
  /// a placeholder for what would eventually be an admin-provided reason
  /// from the Web Admin, not a real rejection decision made here.
  Future<void> rejectDemo(String requestId, {required String reason}) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = RequestMilestones.canonicalStatusFor(RequestMilestones.rejected).label;
    request.adminRemarks = reason;
    request.statusHistory.add(
      StatusHistoryEntry(status: RequestMilestones.rejected, at: DateTime.now(), actor: 'Demo Simulation', remarks: reason),
    );
    await _persist();
    notifyListeners();
  }

  /// DEMO-ONLY: the Web Admin "Flagged for Replacement" action — distinct
  /// from [rejectDemo]. Unlike a rejection, this never ends the request: it
  /// stays active, branches to Under Review with [requirementLabel] added to
  /// [ServiceRequest.flaggedRequirements] as a new, unresolved entry (see
  /// that field's own doc comment) for a targeted re-upload — never
  /// replacing/clearing any requirement already flagged, so calling this
  /// again for a *different* requirement while already Under Review is how
  /// more than one requirement ends up flagged at once. Resolved one
  /// requirement at a time via [replaceFlaggedRequirement]; the request only
  /// leaves Under Review once the citizen explicitly calls
  /// [resubmitApplication] — replacing a document alone never resubmits.
  Future<void> flagAdditionalDocuments(
    String requestId, {
    required String requirementLabel,
    required String reason,
  }) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    final now = DateTime.now();
    request.status = RequestMilestones.underReview;
    request.adminRemarks = reason;
    request.flaggedRequirements.add(
      // The list's own current length is folded in alongside the
      // timestamp — two calls in quick succession (e.g. flagging a second
      // requirement right after the first, as the "multiple flagged
      // documents" demo does) can land on the same DateTime.now() value on
      // some platforms/clock resolutions, which would otherwise produce a
      // duplicate id (and a duplicate GlobalKey crash in the corrections
      // UI, which keys each card by this id).
      FlaggedRequirement(
        id: '$requestId-${request.flaggedRequirements.length}-${now.microsecondsSinceEpoch}',
        requirementLabel: requirementLabel,
        reason: reason,
        flaggedAt: now,
      ),
    );
    request.statusHistory.add(
      StatusHistoryEntry(status: RequestMilestones.underReview, at: now, actor: 'Demo Simulation', remarks: reason),
    );
    await _persist();
    notifyListeners();
  }

  /// DEMO-ONLY: the Web Admin "Needs Manual Verification" action — also
  /// branches to Under Review, same as [flagAdditionalDocuments], but with
  /// no specific requirement flagged: nothing the citizen needs to do,
  /// just a plain-language explanation that staff need more time. Never
  /// presented as Rejected. Resolved by [resumeVerification], not a
  /// citizen re-upload.
  ///
  /// The Request Detail screen's own "Needs Manual Verification (Demo)"
  /// trigger button was removed (targeted UI + demo control cleanup pass) —
  /// this method and its resolution UI ([_ManualVerificationCard]/"Continue
  /// Verification (Demo)" in request_detail_screen.dart) are kept intact as
  /// legitimate lifecycle logic, still exercised directly by
  /// request_milestone_simulation_test.dart.
  Future<void> flagManualVerification(String requestId, {required String reason}) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = RequestMilestones.underReview;
    request.adminRemarks = reason;
    request.statusHistory.add(
      StatusHistoryEntry(status: RequestMilestones.underReview, at: DateTime.now(), actor: 'Demo Simulation', remarks: reason),
    );
    await _persist();
    notifyListeners();
  }

  /// The resident replaced the document for exactly one requirement flagged
  /// by [flagAdditionalDocuments] (matched by [flaggedId], the specific
  /// [FlaggedRequirement.id] — never "whichever is flagged", since more than
  /// one can be at once) — replaces the matching attachment (by
  /// [Attachment.documentTypeLabel], falling back to appending if none was
  /// previously attached) and marks that one entry resolved. Deliberately
  /// does NOT touch [ServiceRequest.status] or add any status-history entry:
  /// replacing a document is not the same as resubmitting the application
  /// (see [resubmitApplication]) — a citizen can replace several flagged
  /// documents one at a time before finally resubmitting once. No-op if
  /// [flaggedId] doesn't match any still-unresolved entry (e.g. it was
  /// already resolved, or belongs to a different request) — guards a stale
  /// notification's action from acting twice.
  Future<void> replaceFlaggedRequirement(
    String requestId, {
    required String flaggedId,
    required Attachment newAttachment,
  }) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    FlaggedRequirement? flagged;
    for (final f in request.flaggedRequirements) {
      if (f.id == flaggedId && !f.isResolved) {
        flagged = f;
        break;
      }
    }
    if (flagged == null) return;
    final resolvedFlag = flagged;
    final index = request.attachments.indexWhere((a) => a.documentTypeLabel == resolvedFlag.requirementLabel);
    if (index != -1) {
      request.attachments[index] = newAttachment;
    } else {
      request.attachments.add(newAttachment);
    }
    resolvedFlag.resolvedAt = DateTime.now();
    await _persist();
    notifyListeners();
  }

  /// The resident explicitly resubmits the whole application once every
  /// currently-flagged requirement has been replaced (see
  /// [replaceFlaggedRequirement]) — the one and only way Under Review moves
  /// forward for the flagged-requirement flavor (contrast
  /// [resumeVerification], which resolves the no-specific-requirement
  /// "Needs Manual Verification" flavor instead). No-op if the request isn't
  /// Under Review, or if any flagged requirement is still unresolved —
  /// mirrors the "Resubmit Application" button's own disabled state, so a
  /// stale/duplicate call can never skip ahead. Records a citizen
  /// "Resubmitted" event, then re-enters the sequence at Under Verification
  /// (re-verification) — from there the request can loop back to Under
  /// Review again (if flagged afresh), or continue on to Approved, exactly
  /// like a first-time review.
  Future<void> resubmitApplication(String requestId) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    if (request.status != RequestMilestones.underReview) return;
    if (request.flaggedRequirements.any((f) => !f.isResolved)) return;
    request.statusHistory.add(
      StatusHistoryEntry(
        status: 'Resubmitted',
        at: DateTime.now(),
        actor: 'Citizen',
        remarks: 'Application resubmitted for review.',
      ),
    );
    request.status = RequestMilestones.underVerification;
    request.statusHistory.add(
      StatusHistoryEntry(
        status: RequestMilestones.underVerification,
        at: DateTime.now(),
        actor: 'Demo Simulation',
        remarks: 'Re-verifying the resubmitted application.',
      ),
    );
    await _persist();
    notifyListeners();
  }

  /// DEMO-ONLY: resolves the "Needs Manual Verification" flavor of Under
  /// Review (see [flagManualVerification]) — staff finished the extra
  /// check, no citizen action was needed, so this goes straight back to
  /// Under Verification without a "Resubmitted" entry (nothing was
  /// resubmitted).
  Future<void> resumeVerification(String requestId) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    if (request.status != RequestMilestones.underReview) return;
    request.status = RequestMilestones.underVerification;
    request.statusHistory.add(
      StatusHistoryEntry(
        status: RequestMilestones.underVerification,
        at: DateTime.now(),
        actor: 'Demo Simulation',
        remarks: 'Manual verification complete — continuing review.',
      ),
    );
    await _persist();
    notifyListeners();
  }
}
