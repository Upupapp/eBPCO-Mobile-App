# Teresa, Rizal Mobile ↔ Web Admin Alignment

Living reference for keeping the Teresa, Rizal Mobile App (Flutter, this repo) and the Teresa, Rizal Web Admin (Laravel, `Teresa-Rizal-Web-Platform--main`, **read-only** — never modified from this project) in sync. Both projects are currently **pure frontend** — no real backend exists for either. This document is what gets handed to the Web Admin / backend developer.

Last updated: **2026-08-29**. Previously 2026-08-11.

> **How to read the dates in this document.** Every claim that is a *measurement* — a count, a
> parity assertion, a compatibility statement — carries the date it was measured, inline. A claim
> without a date is either structural (it describes intent, not a fact about the code) or it has
> not been re-measured since 2026-08-11 and should be treated as inherited rather than verified.
> Do not mark a claim verified because it was true when it was written: date it or re-measure it.
>
> Corrections made on 2026-08-29 by the front-end programme (FE 01 – FE 14) are marked inline
> where they occur, with the command that made them. The full reasoning for each lives in
> `docs/FE0*.md`.

---

## Section 1 — Design System

Extracted read-only from the Web Admin's `resources/css/app.css` (`@theme` block) and `resources/views/components/ui/*.blade.php`. Ported 1:1 into `lib/theme/*.dart`. Never invent colors outside this list.

*Measured 2026-08-29: all 23 navy/brand/gold hexes in `app_colors.dart` match `app.css` exactly. `sky-50/500/700` were added on the same date for the `Resubmitted` badge — not an invented colour, but the Tailwind defaults the Web Admin's own `bg-sky-*` classes resolve to, sourced the same way every other status hex in that file is (FE 04).*

### Colors (exact hex from `app.css`) — verified matching 2026-08-29

| Token | Hex | Used for |
|---|---|---|
| navy-950 → navy-600 | `#070F24` → `#24396B` | Sidebar, hero gradients, dark surfaces |
| brand-50 → brand-900 | `#EEF4FF` → `#14276A` | Primary accent (blue) — buttons, links, active states |
| gold-50 → gold-700 | `#FDF9E7` → `#8A6412` | Teresa, Rizal's own identity color (from the municipal seal), used sparingly |
| slate-50 → slate-800 | Tailwind default | Neutrals — text, backgrounds, borders |
| Status colors | see below | The universal 14-status system |

### Universal status system (exact, from `badge.blade.php` — never invent new labels)

Draft, Submitted, Pending Review, Under Verification, Assigned, Processing, Under Review, Resubmitted, Approved, Verified, Unverified, Rejected, Mark to Release, Released, Completed, Cancelled, Archived — seventeen, each with a fixed bg/text/dot colour tint (see `lib/theme/app_status.dart`, ported line-for-line from `badge.blade.php`).

> **Corrected 2026-08-29 (FE 04).** This list previously named fourteen and included `Ready for Release` and `Waiting Requirements`. Measured against `badge.blade.php` on the web repo's **`origin/main`**: `Ready for Release` has been renamed `Mark to Release`, `Waiting Requirements` no longer exists web-side at all, and `Under Review`, `Resubmitted`, `Verified` and `Unverified` were missing here. Check this list against `origin/main`, never a local clone — a clone a few dozen commits stale still carries the old labels and will make mobile look correct when it is not. `test/status_parity_test.dart` now enforces it.
>
> `Waiting Requirements` still exists in mobile's enum **pending an owner decision** — see `docs/FE04_STATUS_PARITY.md`. It is inert in practice: `requests_service.dart` migrates it to `Under Review` on load, so no live request can carry it.

### Typography

- **Inter** (`--font-sans`) — all UI/body text. Bundled as a variable font (`assets/fonts/Inter.ttf` + `Inter-Italic.ttf`, downloaded from Google's official open-source `google/fonts` GitHub repo, OFL-licensed, license files bundled alongside).
- **Lora** (`--font-display`) — reserved for ceremonial/document-preview contexts only, matching the Web Admin's narrow, deliberate use (not a general heading font).

### Components ported

| Web Admin component | Mobile equivalent |
|---|---|
| `ui/button.blade.php` (5 variants: primary/secondary/ghost/danger/gold, 3 sizes) | `lib/widgets/app_button.dart` |
| `ui/badge.blade.php` (status pill + dot) | `lib/widgets/status_chip.dart` |
| `ui/card.blade.php` (rounded-2xl, shadow-card) | `lib/widgets/app_card.dart` |
| `ui/input.blade.php` | `lib/widgets/app_text_field.dart` |
| `ui/empty-state.blade.php` | `lib/widgets/empty_state.dart` (+ `SkeletonBox`, `ErrorState`) |
| `ui/stat-card.blade.php` | `lib/widgets/stat_tile.dart` |
| `ui/file-picker.blade.php` (category icons: IMG/PDF/DOCX/VID) | `lib/widgets/requirement_uploader.dart` (real device picker, not a mock) — one uploader per requirement. Corrected 2026-08-29: this row named `attachment_picker.dart`, which no screen ever rendered and which was deleted in FE 08. |

### Brand assets

Copied (not linked) from the Web Admin's `public/images/teresa_rizal/` into `assets/images/`: the official municipal seal (`teresa-rizal-seal.png`) and one barangay seal sample. Copying, not modifying the source files, keeps the Web Admin untouched.

---

## Section 2 — Mobile Features (built in this pass)

- Citizen auth (frontend-simulated: local login/register, no real backend — same pattern as the Web Admin's own `Alpine.store('citizenSession')`)
- Home dashboard: hero greeting, quick-action tiles, active requests preview, Balita preview, upcoming events preview
- **Dokyu** (Document Requests): catalog → new request wizard (requirements checklist, purpose, **real** camera/gallery/document attachment) → confirmation → status tracking with timeline
- **Tulong** (Assistance Requests): same flow, different catalog (7 DSWD/MSWDO programs)
- **Sakuna** (Risk Reduction, citizen-scoped): emergency hotlines, evacuation centers, incident reporting reusing the same request pipeline
- Balita & Events (community feed with like/comment counts, events list)
- Government Directory (real municipal office names/numbers from the Web Admin, tap-to-call)
- Notifications — **derived live** from every request's status history (see Section 3)
- Profile (view/edit, profile-completeness bar) + Settings (notifications, language, about)
- Bottom nav: Home / Dokyu / Tulong / Alerts / Profile (5 items — see Section 9 for why this differs from the Web Admin's 7-item sidebar)

Not yet built (see Section 6): push notifications (real FCM), offline queueing, biometric login, document/certificate preview rendering (the Web Admin has rich certificate-preview components — `barangay-certificate-preview.blade.php`, `municipal-request-preview.blade.php` — that mobile doesn't yet mirror).

---

## Section 3 — Mobile → Web Admin Flow Matrix

**Alignment Status legend:** ALIGNED · PARTIALLY ALIGNED · WEB ADMIN FLOW MISSING · MOBILE FLOW MISSING · NEEDS DECISION

| Mobile Screen / Action | Mobile Result | Web Admin Tab | Admin Sees | Admin Actions | Mobile Reflection | Alignment Status |
|---|---|---|---|---|---|---|
| Dokyu > Submit document request | New card in "Active", status **Submitted**, ref. `DR-YYYY-####` | Admin > Document Requests | *(page exists as a static mock view only — no live data)* | Review, Verify, Approve, Reject, Release | Status chip + timeline update on request detail | **WEB ADMIN FLOW MISSING** — no backend table/API for Dokyu at all |
| Tulong > Submit assistance request | New card, status **Submitted**, ref. `AR-YYYY-####` | Admin > Assistance Requests | *(static mock view only)* | Review, Assign, Approve, Reject, Release | Status chip + timeline update | **WEB ADMIN FLOW MISSING** |
| Sakuna > Report an Incident | New card, status **Submitted**, ref. `IR-YYYY-####` | Admin > Sakuna > Incidents | *(static mock view only)* | Validate, Assign, Dispatch, Escalate, Resolve, Close | Status chip + timeline update | **WEB ADMIN FLOW MISSING** |
| Auth > Register | Local account created, status "Pending Review" | *(no citizen-facing registration/verification queue exists in Web Admin)* | — | — | — | **WEB ADMIN FLOW MISSING** |
| Profile > Edit Profile | Local profile updated instantly | Admin > Constituents > Resident Profiles | *(static mock registry, unconnected to any citizen account)* | Verify, Merge, Resolve (Data Quality module) | — | **WEB ADMIN FLOW MISSING** — no residents API to submit a correction request against; mobile currently just edits the local copy directly rather than filing a correction request (documented as a simplification, see Section 8) |
| Request Detail > "Demo: Simulate Web Admin Action" | Status + remarks update, timeline entry added, Notifications screen updates live | *(local-only simulation, clearly labeled, never a real admin action)* | — | — | Immediate — same device, same session | **ALIGNED** *(as a demo mechanism only — not a substitute for a real Web Admin connection)* |
| Home > View Balita / Events | Read-only feed | Admin > Communications (Balita) | Full CRUD (Draft → Review → Publish → Archive) exists in Web Admin's own UI, but no API to read it from mobile | — | — | **WEB ADMIN FLOW MISSING** — content is real and well-modeled in config, but has no API surface |
| Profile > Directory | Read-only office list + tap-to-call | Admin > Communications > Directory | Same source data | Add/edit offices | — | **WEB ADMIN FLOW MISSING** — no API |

---

## Section 4 — Web Admin → Mobile Reflection (target behavior once a backend exists)

For every request category, the intended lifecycle once the backend developer builds real endpoints:

1. Citizen submits on mobile → `POST /api/dokyu` (or `/tulong`, `/sakuna/incidents`) → status `Submitted`.
2. Admin staff opens the matching Web Admin tab, sees the request with all fields + uploaded attachments.
3. Admin acts (Review → Approve/Reject/Request Additional Requirements → Release), each action appending a status-history row with actor + remarks.
4. Mobile polls/receives a push notification, request detail screen shows the new status + admin remarks, Notifications screen surfaces it.
5. Terminal states (Completed/Released/Rejected/Cancelled/Archived) move the request out of "Active" into "Done" on both sides.

This is exactly the loop the "Demo: Simulate Web Admin Action" panel fakes locally today — once real endpoints exist, only `lib/services/requests_service.dart` needs to change (HTTP calls instead of SharedPreferences), no screen changes required.

---

## Section 4a — Citizen access tiers and per-category capabilities

*Added 2026-08-29, agreed with the backend session. This is the contract FE 13 should consume
instead of deriving anything client-side.*

Mobile has **three** access tiers (`lib/models/access_level.dart`), and `AccessGuard` compares
them by enum index, so declaration order is part of the contract:

| Tier | Reaches |
|---|---|
| `guest` | Balita, Events |
| `unverified` | + Sakuna / Emergency — a registered but unapproved citizen may still report an incident |
| `verified` | + Dokyu, Tulong |

**The server deliberately models only two.** `guest` means no account and therefore no session,
so there is nothing for `/auth/me` to describe. Authenticated is always exactly Verified or
Unverified:

    access_level "Verified"    -> AccessLevel.verified
    access_level "Unverified"  -> AccessLevel.unverified
    no session                 -> AccessLevel.guest   (client-only, never a server value)

### The tier is a property of the ACCOUNT; the gate is a property of the CATEGORY

Conflating those is what produced the `Verified`-means-locked-out bug in Section 1, and a
single `full_service_access` boolean would have reintroduced it — it answers Dokyu/Tulong and
says nothing about incident reporting. So the contract publishes both:

    GET /api/v1/auth/me
      "status": "Approved",              // the stored value
      "access_level": "Verified",        // the derived tier — SAME state, different field
      "capabilities": { "dokyu": false, "tulong": false,
                        "sakuna_incident": true,
                        "satisfaction_survey": true, "community_post": true }

    GET /api/v1/statuses
      "citizen_capability_requirements": { "dokyu": "Verified", "tulong": "Verified",
                                           "sakuna_incident": "Unverified", ... }

A client reads `capabilities` to **enforce**, and `citizen_capability_requirements` to
**explain** — which is what mobile's `RestrictionReason.guestOnly` / `needsVerification` copy
needs, without re-deriving the rule.

`Approved` and `Verified` arrive from *different fields* and both are live. Mobile treats them
as one state (`CitizenSessionService.accessLevel`), which is the correct reading of two fields
describing the same account from different angles — not a tolerance for inconsistent input.

Pinned from this side by `test/access_tier_contract_test.dart`, which parses the guards out of
`root_shell.dart` rather than restating them.

---

## Section 5 — Missing Web Admin Processes

*(For the Web Admin / backend developer — nothing below was built or implied in the Web Admin project itself.)*

### Dokyu (Document Requests) API
- **Missing:** `document_requests` table, model, controller, API routes, admin review UI wired to real data (current `admin.document-requests` route is a static Blade mock).
- **Required fields:** applicant_id, type, office, purpose, submitted_at, status, status_history, attachments (file refs), remarks, admin_remarks.
- **Required admin actions:** Review, Verify, Approve, Reject, Mark to Release, Release, Archive. *(2026-08-29: `Ready for Release` renamed `Mark to Release` to match the web platform.)*
- **Statuses:** Submitted → Under Verification → Under Review (optional loop) → Approved → Mark to Release → Released / Rejected. *(2026-08-29: was `Waiting Requirements` → `Ready for Release`; both renamed — see Section 1.)*
- **Mobile reflection:** status chip + timeline, as built.

### Tulong (Assistance Requests) API
- Same shape as Dokyu. **Statuses:** Submitted → Assigned → Processing → Under Review (optional) → Approved → Released / Rejected → Completed. *(2026-08-29: was `Waiting Requirements` — see Section 1.)*

### Sakuna Incidents (citizen-reported) API
- **~~Missing~~ — DELIVERED 2026-08-29** (backend `a63a8ae`). This entry was correct: there was no citizen path. The only way to create an incident was `POST /api/v1/admin/sakuna/incidents`, behind an admin permission no citizen holds, so mobile's "Report an Incident" button had nothing to call.
- **Now available:** `POST /api/v1/citizen/incidents` (session required, **Unverified accounts allowed** — see Section 4a), `GET /api/v1/citizen/incidents` for the citizen's own reports. Throttled 20/min and idempotent on `client_uuid`, so a report replayed after a phone loses signal returns the filed incident (200) rather than creating a duplicate (201). Lands with `source: "Citizen Portal"` and enters the responders' queue on the same verb chain as a field-reported incident.
- **Body:** `title`, `type`, `severity`, `barangay`, `sitio`, `lat`, `lng`, `description`, `client_uuid`.
- **Statuses:** Submitted → Validated → Dispatched → Resolved / Closed.
- The Web Admin's own Sakuna module (Command Center, Incidents) remains mock data — the citizen submission path is what now exists.

### Citizen Registration & Verification
- **Missing:** any citizen self-registration endpoint, `residents` table, verification queue for barangay staff. Currently registration only exists as static demo accounts in `config/teresa_rizal_citizens.php`.

### Constituent Profile Correction Requests
- **Missing:** a citizen-initiated "request a correction" flow distinct from direct self-editing, so barangay staff can verify changes before they apply (mirrors the Web Admin's own "Data Quality Management" module intent, which currently has no backend either).

### Balita / Directory Read APIs
- **Missing:** any API to read announcements or the office directory. Both are fully modeled, real content in `config/teresa_rizal_balita.php` and inline in `directory.blade.php` — they just need to be exposed, not redesigned.

### Notifications
- **Missing:** any notifications table/channel/push integration on the Web Admin side. See the separate backend-readiness report for detail — this needs new scaffolding regardless of mobile.

---

## Section 6 — Missing / Recommended Mobile Processes

*(Things worth building next on mobile — not yet implemented, not silently assumed.)*

- **RECOMMENDED / MISSING SYSTEM FEATURE — Document preview rendering.** The Web Admin has real certificate-preview Blade components (`barangay-certificate-preview.blade.php`, `municipal-request-preview.blade.php`) that render an official-looking document once released. Mobile has no equivalent viewer yet. **Why needed:** citizens should be able to view/download their released certificate in-app. **Mobile behavior:** a read-only styled preview screen once status = Released. **Web Admin reflection:** none needed beyond serving the final file. **Backend need:** yes, once file serving exists.
- **RECOMMENDED — Push notifications.** Currently notifications are derived locally from status history; there's no real push channel. Needs backend FCM/APNs work first (see Section 5 of the separate backend audit).
- **RECOMMENDED — Offline request queueing.** Attachments/forms filled with no connectivity should queue and auto-submit on reconnect. Not built; not needed until a real API exists to submit against.
- **RECOMMENDED — Biometric/PIN app-lock.** Common for LGU citizen apps holding personal data; not implemented, no blocker to add later (`local_auth` package).

---

## Section 7 — Mock Data / Simulation

- **Demo identities are SYNTHETIC** *(FE 02, 2026-08-29)*. The three seeded citizens, their household and family members, their emergency contact, their record ids, contact details, profile images and government-ID scans are all invented. Until that date they were real residents' records and real scans, in a public repository. Artwork is generated by `tool/demo_identity_art/generate.py` and carries no photograph of anyone; `test/no_real_identities_test.dart` fails if a retired real name or record id reappears.
- All catalog data (document types, assistance programs, incident types, offices, barangays, sample announcements/events) is copied from real values found in the Web Admin's Blade files and config, trimmed to a representative subset rather than the full per-barangay catalogs (e.g., only Labangtaytay's barangay-specific documents exist in the Web Admin; mobile doesn't attempt to replicate that per-barangay branching yet).
- Session, requests, and profile data persist locally via `shared_preferences` (JSON-encoded), so the demo survives app restarts — mirrors the Web Admin's own `localStorage`-based frontend simulation pattern exactly.
- Reference numbers (`DR-/AR-/IR-YYYY-####`) are generated locally and are **not** guaranteed unique against a real backend's eventual numbering — this must be reconciled once a real API exists (likely: server assigns the reference number on submit, not the client).

---

## Section 8 — Backend Integration Notes for Later

When the backend developer builds real APIs (see the separate Laravel backend-readiness audit for what's needed on that side):

1. `lib/services/requests_service.dart` and `lib/services/citizen_session_service.dart` are the **only** files that touch persistence. Replace their SharedPreferences calls with HTTP calls; no screen or widget needs to change, because they only ever call these services' public methods.
2. Model shapes (`ServiceRequest`, `Attachment`, `CitizenAccount`, `StatusHistoryEntry`) were deliberately kept close to what a Laravel API Resource would return (`id`, `referenceNumber`, `status`, `statusHistory`, etc.) — see each model file's doc comment.
3. `Attachment.localPath` becomes a `remoteUrl` once real upload exists; everything else about the model is unchanged.
4. The "Demo: Simulate Web Admin Action" panel in `request_detail_screen.dart` must be deleted (or hidden behind a debug flag) once a real Web Admin exists — it should never ship to citizens in production.
5. Client-generated reference numbers must be replaced by server-assigned ones (see Section 7).

---

## Section 9 — Android/iOS Compatibility Notes

- **Permissions declared:** Camera + photo library (`READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` on Android; `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` on iOS) — see `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`.
- **Requirement uploader** (`lib/widgets/requirement_uploader.dart`) uses `image_picker` (camera + gallery) and `file_picker` (PDF/DOCX/images), both of which have first-class Android and iOS implementations — no platform-specific code was needed. Corrected 2026-08-29: this named `attachment_picker.dart`, which was unreachable from `main.dart` and was deleted in FE 08; the capability itself was never missing, only misattributed.
- **Bottom nav IA** deliberately trimmed to 5 items (Home/Dokyu/Tulong/Alerts/Profile) rather than mirroring the Web Admin's 7-item sidebar, since a 7-tab bottom bar doesn't fit comfortably on smaller Android/iOS screens. Balita, Events, Directory, and Help remain fully reachable from Home and Profile.
- **SafeArea** wraps every screen's scaffold body where content could collide with a notch/Dynamic Island or Android gesture nav.
- **Keyboard handling:** form screens (`NewRequestScreen`, `RegisterScreen`, `EditProfileScreen`) use `SingleChildScrollView` so the keyboard never covers the active field.
- **Verified on an Android emulator (2026-08-29) and an iOS simulator (2026-09-03); still not on physical hardware on either platform.** The claim that this environment has no Android SDK is out of date for the Windows lane: `flutter build apk --release` succeeds there and the APK installs and runs on a Pixel 8 emulator (Android 16 / API 36), reaching onboarding with no app-level error in `logcat`. **iOS is no longer owed:** `flutter build ios --simulator --debug` succeeds on the macOS lane in 36.5s and the app installs, launches and renders on an iPhone 17 simulator under Impeller/Metal with no Flutter exception across four launches. The minimum iOS is **15.0, not the 13.0 this project claimed** — Flutter 3.47 raises it during the build, verified by reverting to 13.0 and watching it re-raise, so iOS 13 and 14 were never actually supported. `integration_test/app_walk_test.dart` now drives the app on a device automatically; treat its coverage count as unreliable until item 19 in `PENDING.md` is closed. A run on real handset hardware is still owed on both platforms. `flutter analyze` is clean and `flutter test` passes; both are proxy signals, and neither substitutes for the device runs above.
