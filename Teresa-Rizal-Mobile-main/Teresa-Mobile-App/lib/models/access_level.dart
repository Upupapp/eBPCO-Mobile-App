/// The three-tier access model for the mobile app — Guest / Authenticated
/// (unverified) / Verified. Declaration order matters: comparing
/// `.index` gives a correct "at least this level" check
/// (`level.index >= required.index`), which is what [AccessGuard] uses.
///
/// This is deliberately a thin, derived concept rather than new stored
/// state: [CitizenSessionService.accessLevel] computes it from the
/// existing `isGuest` flag and `CitizenAccount.status` (the same
/// universal status string already used for service requests — see
/// theme/app_status.dart), so there is exactly one place that decides
/// what a citizen currently is.
enum AccessLevel {
  guest,
  unverified,
  verified,
}
