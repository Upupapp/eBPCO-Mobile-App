# Teresa, Rizal Mobile App — Sign-Up / User Access Process Document

This document describes **the actual behavior of the current codebase** (frontend-only simulation, no real backend — see `TERESA_RIZAL_MOBILE_WEB_ALIGNMENT.md`). It is a reference for developers and the client, not a redesign proposal. Anything requested previously that isn't in the code yet is explicitly marked **Not yet implemented**.

Source files referenced throughout:
- `lib/services/citizen_session_service.dart` — session state, `AccessLevel`
- `lib/models/access_level.dart` — the 3-tier access model
- `lib/widgets/access_guard.dart` / `lib/widgets/restricted_feature_notice.dart` — enforcement + messaging
- `lib/screens/auth/login_screen.dart` / `lib/screens/auth/register_screen.dart`
- `lib/widgets/verification_status_panel.dart`
- `lib/theme/app_status.dart` — the universal status vocabulary
- `lib/services/mock_catalog.dart` — demo accounts
- `lib/screens/home/root_shell.dart` — bottom-tab wiring

---

## 0. Two different "status" systems in this app (read this first)

The codebase has **two separate status systems**. Mixing them up is the easiest way to misread this document, so they're called out up front:

| System | Enum | Where it lives | What it controls |
|---|---|---|---|
| **Account Verification Status** | `AppStatus` (`Pending Review`, `Under Verification`, `Approved`, `Rejected`, …) | `CitizenAccount.status` | **This is what gates tab/feature access.** `AccessLevel` is derived from it. This is the subject of this document. |
| **Resident Profile completeness** | `VerificationStatus` (`draft`, `incomplete`, `pendingVerification`, `needsCorrection`, `verified`) | `ResidentProfileService` (Household & Family module) | A separate, informational profiling flow (Individual/Family/Household info, mirrors the Web Admin's Constituents module). **Does not gate any tab or feature.** Reachable from Profile → "Household & Family" regardless of account verification state. |

Everywhere below, "verification" / "verified" / "unverified" refers to **Account Verification Status**, not Resident Profile completeness.

---

## 1. Guest User — Continue as Guest

### Flow

```
Open App → Sign-In Screen → Tap "Continue as Guest" → Home (Guest view)
   → Browse Home + Balita (public)
   → Tap a restricted tab (Dokyu / Tulong / Emergency)
   → Restricted Feature Notice → "Create Account" or "Sign In"
```

### Where the button appears
On the Sign-In screen (`login_screen.dart`), directly below the **Sign In** button, styled as a secondary/ghost button so it's clearly tappable but visually subordinate:

```
[ Sign In ]
[ Continue as Guest ]   ← ghost/secondary style
— or try a demo account —
[ demo account cards ]
```

### What happens after tapping it
`CitizenSessionService.continueAsGuest()` runs:
- `_account` is cleared, `_isGuest` is set to `true`
- Persisted to `SharedPreferences` under the key `teresa_rizal_guest_mode` (boolean `true`)
- Any previously stored session (`teresa_rizal_citizen_session`) is removed
- The app's `_AuthGate` (in `main.dart`) re-evaluates: `isSignedIn == false` but `isGuest == true`, so it routes to `RootShell` instead of back to Sign-In

### Landing screen
**Home**, rendered in its reduced Guest variant:
- Hero greeting shows "Welcome, Guest" copy with **Create Account** / **Sign In** buttons instead of the signed-in stat tiles
- Account-specific sections (Resident Profile status card, Dokyu/Tulong stat tiles, Active Requests) are hidden entirely (`if (account != null)` gate in `home_screen.dart`)
- Balita preview section still renders (public content)

### Accessible as Guest
| Tab / Feature | Access |
|---|---|
| **Home** | ✅ Full (reduced/guest layout) |
| **Balita** (news feed, reading posts) | ✅ Full |
| **Balita — posting/composing** | ❌ Blocked — tapping compose shows `RestrictedFeatureNotice` (guest-only reason), even though the Balita tab itself is open |

### Restricted as Guest
| Tab / Feature | `AccessGuard` requirement | Result for Guest |
|---|---|---|
| **Dokyu** (Document Requests) | `AccessLevel.verified` | Restricted notice |
| **Tulong** (Assistance Requests) | `AccessLevel.verified` | Restricted notice |
| **Emergency** (Sakuna / Risk Reduction) | `AccessLevel.unverified` (i.e. "at least signed in") | Restricted notice |
| **Profile** | Not exposed at all — the drawer shows "Sign In" / "Create Account" instead of a Profile menu item when the session is a guest |

### Restricted-feature message (Guest)
Exact copy from `restricted_feature_notice.dart`:

> **[Feature name]**
> This feature is available to registered Teresa, Rizal users. Create an account or sign in to continue.
>
> `[ Create Account ]`  `[ Sign In ]`

Both buttons first call `endGuestSession()` (clears the guest flag) before navigating, so Sign-In/Register always start from a clean, non-guest state.

### How a Guest reaches Sign In / Create Account / Register
Three entry points, all present in the current code:
1. **The restricted-feature notice itself** (`Create Account` / `Sign In` buttons), triggered whenever a Guest hits a gated tab
2. **The hamburger drawer** (`teresa_rizal_drawer.dart`) — for a Guest session, the drawer shows `Sign In` and `Create Account` tiles up top instead of Profile/Settings
3. **The Home guest hero** — its own `Create Account` / `Sign In` buttons
4. Sign-In screen's own bottom link: *"Don't have an account? **Register**"*

### Data stored for a Guest
Only one boolean flag: `SharedPreferences['teresa_rizal_guest_mode'] = true`. No name, contact info, or any other guest-specific data is collected or persisted. This flag exists purely so the app remembers "last time you opened the app, you were browsing as a guest" across restarts — it does not identify a person.

### What happens when a Guest creates an account
Guest → Register flow runs the full registration wizard (Section 2 below). Once submitted, `CitizenSessionService.login(account)` is called, which:
- Sets `_account` to the newly created `CitizenAccount`
- Sets `_isGuest = false` and removes the guest flag from `SharedPreferences`
- Persists the new account under `teresa_rizal_citizen_session`

The user is now in the **Registered but Unverified** state (Section 2), not a Guest anymore.

---

## 2. New Registered User — Not Yet Verified

**Demo account: Ronaldo Bautista** (`ronaldo.bautista@email.com`, `status: 'Pending Review'`).

### Registration sequence (`register_screen.dart` — a 6-step wizard, not one long form)

```
Step 1              Step 2                 Step 3            Step 4              Step 5      Step 6
Personal   ───────▶ Terms &      ───────▶ Valid ID  ───────▶ Face         ─────▶ Review ───▶ Verification
Information          Conditions            Upload             Verification         & Submit    Status
```

| Step | What happens | Blocks "Continue" until |
|---|---|---|
| 1. Personal Information | First/last name, email, mobile, barangay, purok | Name + email + barangay filled in |
| 2. Terms & Conditions | Full terms text + checkbox | Checkbox is checked |
| 3. Valid ID Upload | File picker (jpg/png/pdf) via `image_picker`/`file_picker` | A file is selected |
| 4. Face Verification | Simulated scan — tap "Start Face Scan," a 1.2s delay, then a green checkmark. **No real camera/ML is used** — this is an explicit frontend simulation, stated on-screen | Scan marked "completed" |
| 5. Review | Read-only summary of every field, each with an "Edit" link that jumps back to the relevant step | — |
| 6. Verification Status | Shows the account's real status via `VerificationStatusPanel` | — |

A progress indicator (`OnboardingStepIndicator`) stays visible above steps 1–5, showing "Step X of 6: [label]" plus colored segment bars for completed/current/upcoming steps.

Tapping **Submit for Verification** on step 5:
1. A `CitizenAccount` is created with `status: 'Pending Review'` (always — there is no "Information Incomplete" account status; incomplete data simply can't reach this point because each step blocks progression until its required fields are filled)
2. `CitizenSessionService.login(account)` is called — the account now exists and the session is signed in
3. The wizard jumps to Step 6, showing the new "Pending Review" status

### What screen they land on after entering the app
`RootShell` → **Home**, now in its signed-in (non-guest) layout, with the full stat tiles, Resident Profile card, and Active Requests preview — these are gated only on `account != null`, not on verification status.

### Status displayed
`VerificationStatusPanel` (used on both the Profile screen and the registration wizard's final step) shows:
- A `StatusChip` with the exact label **"Pending Review"**
- Explanation: *"Teresa, Rizal LGU is reviewing your submitted information. This usually takes 1–3 business days — no action needed from you right now."*

### Feature access while unverified (`AccessLevel.unverified`)
| Tab / Feature | Access |
|---|---|
| Home | ✅ Full |
| Balita (read + post) | ✅ Full — posting is only Guest-restricted, not verification-restricted |
| **Dokyu** | ❌ `AccessLevel.verified` required |
| **Tulong** | ❌ `AccessLevel.verified` required |
| **Emergency** (Sakuna) | ✅ Allowed — only requires `AccessLevel.unverified` (i.e. "signed in, verified or not"). This is intentional: withholding incident reporting/emergency info behind LGU verification would be poor public-safety practice |
| Profile (via drawer) | ✅ Full — shows account info + `VerificationStatusPanel` |

### Restricted-feature message (Unverified — different from Guest)
Tapping Dokyu or Tulong shows:

> **[Feature name]**
> Complete your account verification to access this service.
>
> `[ Continue Verification ]`

This is a **different message and a different single action** than the Guest notice — no "Create Account" is ever shown to an unverified user, because `AccessGuard` checks `accessLevel == AccessLevel.guest` vs. anything else to pick the notice's reason. **An unverified registered user is never asked to create another account.**

"Continue Verification" pushes `RegisterScreen`. Because `CitizenSessionService.account != null`, the wizard's `initState` sets `_alreadyHasAccount = true` and jumps straight to Step 6 (Verification Status) — it does **not** restart the wizard from Step 1.

### What happens if information is incomplete
Not reachable as a persisted state — each wizard step validates its own required fields before allowing "Continue," so a user cannot submit with missing required data. (There is no separate "Information Incomplete" `AppStatus` value; this is enforced client-side during the wizard, not as an account status.)

### What happens if verification requires resubmission
The universal status system defines `Rejected`, and `VerificationStatusPanel` has a `Rejected` case (explanation: *"Your submission needs corrections before it can be verified. Please review and resubmit your information,"* action label "Resubmit Information"). However:
- **Not yet implemented**: nothing in the app currently transitions an account to `Rejected` — there is no simulated LGU-reviewer action, and neither demo account uses this status. The UI exists but this path is not currently reachable through normal use.
- **Not yet implemented**: even if an account were `Rejected`, the "Resubmit Information" action (wired only on the Profile screen, not inside the wizard's own final step) simply re-opens `RegisterScreen` — which, because the account already exists, jumps straight back to the read-only Step 6 status view. It does **not** currently let the user edit or re-upload their information. A real resubmission flow (reopening the wizard at an editable step) is not yet built.

### While verification is pending
No polling, push notification, or admin action exists to change the status. **Not yet implemented**: there is no in-app way (demo or otherwise) to simulate LGU staff approving/rejecting a submission — Ronaldo's account will show "Pending Review" indefinitely in this build. Status is only ever set at two points: registration submission (`Pending Review`) and the two hardcoded demo accounts in `mock_catalog.dart`.

### Once approved
If an account's `status` were `'Approved'` (as Cristy's demo account is, from the start — not via a live transition), `accessLevel` becomes `AccessLevel.verified` and the user immediately gets full access on the next rebuild — no separate "unlock" action needed, since `AccessGuard` re-evaluates on every `CitizenSessionService` change via `context.watch`.

---

## 3. Verified User

**Demo account: Cristy Bonghanoy** (`cristy.bonghanoy@email.com`, `status: 'Approved'`).

### Flow

```
Open App → Sign-In Screen → Sign In (or tap Cristy Bonghanoy demo card)
   → CitizenSessionService.login(account) → accessLevel = verified
   → Home (signed-in layout) → Full access to Dokyu / Tulong / Balita / Emergency / Profile
```

### After successful login
Same `login()` path as any registered user — the only difference is `account.status == 'Approved'`, which makes `accessLevel` resolve to `AccessLevel.verified` (`citizen_session_service.dart`: `AppStatusX.fromLabel(acc.status) == AppStatus.approved ? AccessLevel.verified : AccessLevel.unverified`).

### Status shown
`VerificationStatusPanel` on Profile shows a **"Approved"** `StatusChip` with explanation: *"Your account has been verified. You now have full access to Teresa, Rizal mobile services."* No action button (verified has no `_actionLabel`).

### Feature access
All five bottom tabs render their real screens — no `RestrictedFeatureNotice` anywhere, because `accessLevel.index (2) >= required.index` is true for every current `AccessGuard` (`verified` for Dokyu/Tulong, `unverified` for Emergency, no guard on Home/Balita).

### Are verification warnings still shown?
No. `AccessGuard` only renders `RestrictedFeatureNotice` when the level requirement isn't met — a verified user never triggers that branch anywhere in the app. `VerificationStatusPanel`'s "Approved" copy is informational only (confirms status), it is not a warning and has no action button.

### Accessing assistance-related features (Tulong)
Same shared `RequestListScreen` used by Dokyu, parameterized by `ServiceCategory.tulong` — Active/Done tabs, request tracking, and a **New Request** FAB that opens `ServiceCatalogScreen` (Medical/Burial/Educational/Financial/Food/Pension/Solo Parent assistance types from `MockCatalog.assistanceTypes`).

### Profile / account information available
Via the drawer → Profile: avatar/initials, full name, account ID + barangay, a profile-completeness progress bar (`account.profileCompleteness`, e.g. 82% for Cristy), an **Edit Profile** button, the `VerificationStatusPanel`, a `ResidentProfileStatusCard` (separate Household & Family completeness — see Section 0), Government Directory, Settings, Help & Support, and Sign Out.

### If account info needs to be updated later
`EditProfileScreen` (reachable from Profile → "Edit Profile") calls `CitizenSessionService.updateProfile(updated)`, which persists the edited `CitizenAccount` — this does **not** reset `status` back to `Pending Review`/unverified. **Not yet implemented**: there is no "changes require re-verification" rule in the current code; an already-verified user can edit their profile freely without losing verified status. Flag this if the client expects edits to trigger re-review.

---

## Access Comparison

| Feature | Guest | Registered, Unverified | Verified |
|---|:---:|:---:|:---:|
| Home | ✅ (reduced layout) | ✅ (full layout) | ✅ (full layout) |
| Balita — read | ✅ | ✅ | ✅ |
| Balita — post/compose | ❌ (guest notice) | ✅ | ✅ |
| Emergency (Sakuna) | ❌ (guest notice) | ✅ | ✅ |
| Dokyu (Document Requests) | ❌ (guest notice) | ❌ (verification notice) | ✅ |
| Tulong (Assistance Requests) | ❌ (guest notice) | ❌ (verification notice) | ✅ |
| Profile / Account Information | ❌ (not offered in drawer) | ✅ | ✅ |
| Registration | ✅ (entry point always offered) | N/A — already registered, never re-prompted | N/A |
| Verification process ("Continue Verification") | N/A | ✅ (jumps to status step) | N/A — already verified |
| Government Directory | ✅ (in drawer for everyone) | ✅ | ✅ |
| Household & Family (Resident Profile) | ❌ (Profile not offered) | ✅ | ✅ |

Notes:
- "❌ (guest notice)" and "❌ (verification notice)" are two **different messages/actions** — see Sections 1 and 2.
- Government Directory has no `AccessGuard` — it's open to everyone, including Guests, via the drawer.

---

## Registration and Verification Statuses

The app uses one universal 14-status vocabulary (`AppStatus`, shared verbatim with the Web Admin) rather than a separate onboarding-specific enum. Only a subset is relevant to account verification; the rest (`Assigned`, `Processing`, `Ready for Release`, etc.) apply to service *requests* (Dokyu/Tulong tickets), not accounts.

| Status (as shown to the user) | Meaning for an account | Next action | Currently reachable via… |
|---|---|---|---|
| *(no account — Guest)* | Browsing without an account | Register or Sign In | `continueAsGuest()` |
| **Pending Review** | Registration submitted, awaiting LGU review | None — wait | Registration wizard's `_submitForVerification()`; Ronaldo's demo account |
| **Under Verification** | LGU staff are actively reviewing details | None — wait | Defined in `AppStatus`/`VerificationStatusPanel`; **not yet implemented** — no path currently sets this on an account |
| **Approved** ("Verified" in this document) | Full access granted | None — full access | Cristy's demo account (hardcoded); not reachable via a live transition |
| **Rejected** | Submission needs correction | Resubmit (UI exists; editable resubmission flow **not yet implemented** — see Section 2) | **Not yet implemented** — no account currently reaches this status |
| **Draft** | Fallback shown only if `account.status` is missing/unrecognized | Continue Registration (label exists; not wired to an action on Profile) | Fallback of `AppStatusX.fromLabel()`, not a real onboarding state |

Statuses named in earlier requirements that **do not exist as separate persisted account statuses** in the current code — each is either enforced as a client-side wizard gate or not implemented at all:

| Requested status | Current implementation reality |
|---|---|
| Registered | Equivalent to "account exists" (`isSignedIn == true`), not a status string |
| Information Incomplete | Enforced as per-step validation in the wizard (blocks "Continue"); never becomes a saved account status |
| ID Pending | Wizard Step 3 ("Valid ID Upload") — a UI step, not a persisted status |
| Face Scan Pending | Wizard Step 4 ("Face Verification") — a UI step, not a persisted status |
| Pending Verification | → **Pending Review** (same concept, exact wording differs) |
| Requires Manual Review | → **Under Verification** (defined, not yet reachable) |
| Verified | → **Approved** (same concept, exact wording differs) |
| Rejected | Defined, not yet reachable (see above) |
| Resubmission Required | Same state as **Rejected** in this codebase — no separate status |

---

## Demo Accounts

### Ronaldo Bautista
- `email: ronaldo.bautista@email.com` (any password — sign-in is a mocked email lookup, `login_screen.dart`)
- `status: 'Pending Review'` → `AccessLevel.unverified`
- Login screen demo card shows an amber **"Unverified User"** badge (derived live from `account.status`, not a hardcoded label)
- Profile shows "Pending Review" via `VerificationStatusPanel`
- Dokyu/Tulong show the verification-restricted notice with "Continue Verification"
- Emergency is fully accessible (unverified-only gate)
- Represents: registered, awaiting LGU review

### Cristy Bonghanoy
- `email: cristy.bonghanoy@email.com`
- `status: 'Approved'` → `AccessLevel.verified`
- Login screen demo card shows an emerald **"Verified User"** badge
- Profile shows "Approved," no restrictions anywhere
- Represents: fully onboarded resident

Both cards live in the same `LoginScreen` "or try a demo account" section, built from `MockCatalog.demoAccounts` — tapping either calls `CitizenSessionService.login(account)` directly (no password check, consistent with the rest of this frontend-only build).

---

## Recommended User Journey

```
First App Launch
   │
   ▼
Sign-In Screen
   │
   ├──▶ Continue as Guest ──▶ Home (public) ──▶ hits a gated feature ──▶ prompted to Register/Sign In
   │
   └──▶ Register ──▶ Personal Info → Terms → ID Upload → Face Verification → Review → Submit
                        │
                        ▼
                Account Created (Pending Review / Unverified)
                        │
                        ▼
                Home + Balita + Emergency + Profile available now;
                Dokyu/Tulong show "Continue Verification"
                        │
                        ▼
                (LGU review — not yet simulated in-app)
                        │
                        ▼
                Verified (Approved) ──▶ Full access: Dokyu, Tulong, Emergency, Balita, Profile
```

Key principles already enforced by the current code, worth preserving in any future work:
1. A Guest is never silently given registered-user access, and a registered-but-unverified user is never asked to register again — both are read from one source of truth (`CitizenSessionService.accessLevel`), not re-derived per screen.
2. No tab ever shows a broken/empty screen for an access reason — `AccessGuard` always swaps in `RestrictedFeatureNotice` with a clear next step.
3. Registration is reachable from every place a restriction can occur (Sign-In, Guest's restricted-feature notice, the drawer), per the discoverability requirement.

The two biggest gaps versus a "complete" verification lifecycle are both flagged above and worth prioritizing next: **(a)** no simulated LGU approve/reject action exists, so an account can never actually move between statuses inside the app, and **(b)** the "Resubmit Information" action doesn't yet reopen an editable wizard.
