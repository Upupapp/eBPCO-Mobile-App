# FE 10 — Protect resident data at rest

**Status: PARTIAL.** The storage inventory and the sign-out erasure are done and enforced. The
encryption and filesystem moves are **not started**, for a stated reason, not an omission.
**Date:** 2026-08-29
**Gate:** `flutter analyze` clean · `flutter test` **521 passed**

---

## The storage inventory

This is the artefact FE 10 names as the deliverable and as "what a data-protection review will
ask for".

**There are 10 preference keys, not the 6 the mandate states.** Measured with
`grep -rhoE "'teresa_rizal_[a-z_]+'" lib/`. An inventory built to the mandate's number would have
been four keys short — including one holding a photograph.

| # | Key | Contains | Personal? | Encrypted | Erased on sign-out |
|---|---|---|---|---|---|
| 1 | `teresa_rizal_citizen_session` | name, email, mobile, barangay, address, birthdate, sex, civil status, occupation, status | **yes** | no | ✅ |
| 2 | `teresa_rizal_resident_profiles` | full resident profile + **base64 profile photo**, household, family members | **yes — the most sensitive** | no | ✅ |
| 3 | `teresa_rizal_service_requests` | complete request history, purposes, attachments metadata | **yes** | no | ✅ |
| 4 | `teresa_rizal_master_file_documents` | uploaded document records per account | **yes** | no | ✅ |
| 5 | `teresa_rizal_read_notification_ids` | which notifications were read | weakly | no | ✅ |
| 6 | `teresa_rizal_duplicate_alert_resolutions` | duplicate-registration decisions | weakly | no | ✅ |
| 7 | `teresa_rizal_unverified_duplicate_kept_account` | which duplicate account was kept | weakly | no | ✅ |
| 8 | `teresa_rizal_guest_mode` | browsing as guest | no | no | ✅ |
| 9 | `teresa_rizal_balita_posts` | public municipal announcements | **no** | no | ❌ by design — public content, identical for every citizen |
| 10 | `teresa_rizal_onboarding_complete` | has the welcome flow been seen | **no** | no | ❌ by design — device state; erasing it re-shows onboarding to whoever picks the phone up next |

Storage is `SharedPreferences`: **plaintext XML** on Android, an unencrypted plist in the iOS app
container. Readable on a rooted or jailbroken device and in a device backup.

---

## Fixed: signing out did not erase anything

`CitizenSessionService.logout()` cleared **2 of the 10 keys** — the session and the guest flag.
It left behind the resident profile *including the base64 photograph*, the entire request
history, the uploaded document records, and the notification bookkeeping.

That is not abstract for this app. It is a municipal service for a whole municipality and will
run on **shared and family handsets**, and on a barangay-hall device. The next person to sign in
would not *see* the previous citizen's data — every service keys by account id — but **"not
rendered" is not "erased"**. It is on disk, in plaintext, and recoverable.

### What changed

- Each data-owning service gained `forgetAccount(accountId)`: `RequestsService`,
  `ResidentProfileService`, `MasterFileService`, `NotificationsService`.
- A single coordinator, `lib/services/sign_out.dart`, knows what signing out must erase.

It is one coordinator, not logic at each call site, because there are **two** sign-out entry
points — the profile screen and the drawer — and two copies of a rule is how they end up
disagreeing. It deliberately does not live inside `CitizenSessionService`: that service owns the
session, not the other four, and handing it references to them would invert the app's dependency
direction.

Order matters and is commented: data is erased **first**, then the session is cleared. Clearing
the session first would leave nothing to identify whose data to erase if a later step failed.

`NotificationsService` clears all of its state rather than filtering by account. Its read ids
point at notifications derived from the very requests being erased, so keeping them would leave
orphaned references to a citizen who has signed out.

### The confirmation dialog was lying, and now isn't

Both sign-out dialogs said:

> "You can sign back in anytime with your registered email."

Once sign-out actually erases the data, and with **no backend holding a copy**, that is a promise
the app cannot keep. Signing back in gets an empty profile. Erasing a citizen's records while
telling them they can get them back is worse than not erasing at all.

Now:

> "Your profile, photo, requests and uploaded documents will be removed from this device. You can
> register or sign in again anytime."

### Proven, not asserted

`test/sign_out_erasure_test.dart` — 5 cases, checking **what is left in `SharedPreferences`**
rather than that a code path ran. Trusting the code path is how the gap survived: `logout()`
looked like it cleaned up, and did, for its own two keys.

**Watched failing.** With erasure disabled, the two data-erasure cases fail; the three covering
what `logout()` already did keep passing — which is exactly right, and is the evidence that the
tests discriminate rather than all keying off one flag.

---

## Not started: encryption and moving binaries off `SharedPreferences`

Items 1, 2, 3 and 5 of the mandate — filesystem storage for the photo, `flutter_secure_storage`,
backup exclusion, and the biometric/PIN lock — are **not implemented**.

The reason, stated plainly rather than framed as scope:

1. **They need two new dependencies** (`path_provider`, `flutter_secure_storage`). Neither is in
   `pubspec.yaml`. Adding a dependency to a public LGU app is a supply-chain decision, not a
   refactor.
2. **They change the native surface on a platform this lane cannot build.** Secure storage means
   Keychain entitlements on iOS. **macOS owns iOS here**; Windows owns Android. Shipping
   unverifiable iOS entitlement changes from this lane is exactly the cross-platform breakage the
   standing rules forbid.
3. **The mandate's own guardrail rules out proving it from here**: *"Container inspection means an
   actual device or simulator container, not a unit test."* An emulator is not the iOS container.

Doing a half-migration — photos to the filesystem, sensitive fields still plaintext, no
verification on either container — would have produced a worse outcome than the honest gap: a
migration on every device, new failure modes in the restore path that FE 01 just hardened, and no
evidence it works.

### The plan, for whoever picks it up

1. `path_provider` → write photo bytes to the app's private directory; keep only a path in
   prefs. Migrate existing devices by decoding `photoBytesBase64` once and writing it out.
   **The migration must not brick the app** — FE 01's guards and its test file are the pattern.
2. `flutter_secure_storage` for keys 1–4, backed by Keychain and Keystore.
   **Do not ship the key next to the data**; if it is in the bundle, this is theatre.
3. `android:allowBackup="false"` and the iOS backup-exclusion attribute — a recorded decision,
   not a default.
4. Verify by **inspecting the container** on both platforms, not by a unit test.
5. Biometric/PIN app lock (spec Section 6) only if the owner agrees the scope.

Base64 in a preference value is also a plain performance problem worth fixing on its own: the
whole store is read and written as a unit, so a photograph makes every unrelated save more
expensive.

---

## Acceptance

| Criterion | Result |
|---|---|
| No image bytes remain in `SharedPreferences` | ❌ **not started** — needs `path_provider`; reason above |
| Resident profile fields in encrypted storage, verified by container inspection | ❌ **not started** — needs `flutter_secure_storage` + iOS entitlements this lane cannot verify |
| Sign-out demonstrably erases on-device resident data | ✅ **done and enforced**, proven against stored bytes, watched failing |
| Backup inclusion is a recorded decision | ❌ **not started** |
| A written storage inventory covering all the keys | ✅ **all 10**, not the 6 the mandate names |

Two of five done. Marked accurately rather than rounded up: the sign-out gap was the one that
leaks data during normal, correct use of the app, and it is closed.

## Guardrails observed

- No key was encrypted with a key stored beside the data.
- No existing device is orphaned — nothing about the stored shapes changed.
- Scope did not extend into transport security; there is no network layer.
- Container inspection was **not** simulated with a unit test and then reported as done.

## Follow-ups

1. The encryption work above, with iOS verified from the macOS lane.
2. `teresa_rizal_resident_profiles` still holds a photograph as base64 — the single largest and most
   sensitive value in the store.
3. FE 02 remains the bigger privacy item: the demo identities are real residents' records and
   ship inside every built binary.
