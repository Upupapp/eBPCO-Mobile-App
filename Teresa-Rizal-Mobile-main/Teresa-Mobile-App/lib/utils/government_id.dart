import '../models/citizen_account.dart';
import '../models/government_id_record.dart';
import '../services/mock_catalog.dart';

/// Every account id that resolves to a seeded government ID record — a
/// resident with more than one account (a verified account and its
/// duplicate registration, or two duplicate registrations of the same
/// person) submitted the same physical document each time, so every one of
/// their account ids maps to the SAME record, never a separate copy. An
/// account seeing a record here is what makes "ID submitted" true for it
/// even while still Pending Review; it never implies the account is
/// verified — that's decided entirely by `account.status`/`accessLevel`,
/// never by whether an ID record exists.
Map<String, GovernmentIdRecord> get _governmentIdByAccountId => {
  'ESP-RES-2024-9002': MockCatalog.verifiedDemoGovernmentId,
  'ESP-RES-2024-9002-DUP': MockCatalog.verifiedDemoGovernmentId,
  'ESP-RES-2024-9001': MockCatalog.pendingDemoGovernmentId,
  'ESP-RES-2026-9003': MockCatalog.duplicateDemoGovernmentId,
  'ESP-RES-2026-9004': MockCatalog.duplicateDemoGovernmentId,
};

/// The one seeded government ID record for [account], or null if none is
/// seeded for them. Profile > Personal Information's own "Submitted
/// Government ID" section calls this rather than keeping its own copy —
/// see each MockCatalog record's own doc comment for why a resident with
/// multiple accounts still has exactly one record. This is the document the
/// resident *submitted*, a different concept from the Teresa, Rizal Digital ID
/// (see screens/profile/digital_id_screen.dart), which is never built from
/// this record.
GovernmentIdRecord? governmentIdFor(CitizenAccount? account) {
  if (account == null) return null;
  return _governmentIdByAccountId[account.id];
}
