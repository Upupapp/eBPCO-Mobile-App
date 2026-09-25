import '../models/citizen_account.dart';
import '../services/mock_catalog.dart';
import '../theme/app_status.dart';

/// One switch for how Dokyu and Tulong are entered from the Services sheet.
///
/// Flip [kCatalogGatePolicy] to [CatalogGatePolicy.hubRestricted] to restore
/// the Cluster 4 full-hub block (AccessGuard / RestrictedFeatureNotice) and
/// drop the "Browse any service…" subline. Emergency always opens the Sakuna
/// catalog: 911 stays available to guests.
///
/// The same switch decides the duplicate-account intercept. Under
/// [browseThenSheet] a duplicate browses and the intercept fires at Start
/// request. Under [hubRestricted] a duplicate is treated as Unverified.
enum CatalogGatePolicy { browseThenSheet, hubRestricted }

const kCatalogGatePolicy = CatalogGatePolicy.browseThenSheet;

/// Non-const so the hub-restricted branch is not flagged as dead code while
/// the default stays browse-then-gate.
CatalogGatePolicy currentCatalogGatePolicy() => kCatalogGatePolicy;

/// Where a Services-sheet row goes under [policy].
enum CatalogEntry { dokyuCatalog, tulongCatalog, sakunaCatalog, guardedRequestList }

CatalogEntry catalogEntryFor(String targetName, CatalogGatePolicy policy) {
  if (targetName == 'emergency') return CatalogEntry.sakunaCatalog;
  if (policy == CatalogGatePolicy.hubRestricted) {
    return CatalogEntry.guardedRequestList;
  }
  if (targetName == 'tulong') return CatalogEntry.tulongCatalog;
  return CatalogEntry.dokyuCatalog;
}

/// Demo account states for the catalog gate. [duplicate] is the Unverified
/// registration that copies a verified resident. [rejected] browses like
/// Unverified and is stopped only at Start request.
enum CatalogAccountKind { guest, unverified, verified, duplicate, rejected }

CatalogAccountKind catalogAccountKind(CitizenAccount? account) {
  if (account == null) return CatalogAccountKind.guest;
  if (account.id == MockCatalog.duplicateVerifiedDemoAccount.id) {
    return CatalogAccountKind.duplicate;
  }
  final status = AppStatusX.fromLabel(account.status);
  if (status == AppStatus.rejected) return CatalogAccountKind.rejected;
  if (status == AppStatus.approved || status == AppStatus.verified) {
    return CatalogAccountKind.verified;
  }
  return CatalogAccountKind.unverified;
}

enum StartRequestGate { proceed, guestSheet, unverifiedSheet, rejectedSheet, duplicateDialog }

/// What Start request does. Emergency reports stay open for everyone except guests.
StartRequestGate startRequestGate(
  CatalogAccountKind kind,
  CatalogGatePolicy policy, {
  bool emergency = false,
}) {
  if (emergency) {
    return kind == CatalogAccountKind.guest
        ? StartRequestGate.guestSheet
        : StartRequestGate.proceed;
  }
  return switch (kind) {
    CatalogAccountKind.guest => StartRequestGate.guestSheet,
    CatalogAccountKind.verified => StartRequestGate.proceed,
    CatalogAccountKind.duplicate => policy == CatalogGatePolicy.hubRestricted
        ? StartRequestGate.unverifiedSheet
        : StartRequestGate.duplicateDialog,
    CatalogAccountKind.rejected => StartRequestGate.rejectedSheet,
    CatalogAccountKind.unverified => StartRequestGate.unverifiedSheet,
  };
}
