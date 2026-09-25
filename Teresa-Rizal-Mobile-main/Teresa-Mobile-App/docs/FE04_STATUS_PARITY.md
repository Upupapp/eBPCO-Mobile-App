# FE 04 — Status parity with the web platform

**Status:** complete except one item that is **not this lane's to decide** (see "Waiting
Requirements", below)
**Date:** 2026-08-29
**Gate:** `flutter analyze` clean · `flutter test` **536 passed** (466 when this command was first completed; the access-tier section below was added later the same day)

---

## The canonical list is 17, not 15

The master command names 15 statuses, quoting the web platform's `CLAUDE.md`. Measured against
`badge.blade.php` on the web repo's **`origin/main`** — the component that actually renders —
there are **17**. The prose list omits `Verified` and `Unverified`.

Where the two disagree, the component wins: prose describes, a component renders.

```
Draft · Submitted · Pending Review · Under Verification · Assigned · Processing
Under Review · Resubmitted · Approved · Verified · Unverified · Rejected
Mark to Release · Released · Completed · Cancelled · Archived
```

### Read `origin/main`, never a local clone

This nearly went wrong in the opposite direction. Checking mobile against a **local** clone of
the web platform produced a confident finding that the master command was wrong on three
counts. That clone was **64 commits stale**; it still contained `Waiting Requirements` and
`Ready for Release`, labels since replaced. Against the real remote, the command was right.

A stale peer clone does not look broken. It answers every grep fluently, with real paths and
line numbers, and it makes the repo under test look aligned with a contract nobody has enforced
for weeks. Both the test file and `app_status.dart` now say this in as many words.

---

## What was wrong, and what changed

### 1. `Resubmitted` was missing — added (sky)

Canonical web-side and written by mobile's own `requests_service.dart` into `statusHistory` as a
literal string. It rendered only because the timeline prints the raw label; anything routing
through `AppStatusX.fromLabel('Resubmitted')` got a silent `AppStatus.draft`, so a resubmitted
request would have shown as a grey **"Draft"**.

Added with the web's own sky treatment (`bg-sky-50 / text-sky-700 / bg-sky-500`).

### 2. `Verified` and `Unverified` were missing — and that was a live hazard, not a colour

This is the part the master command could not have specified, because it worked from the prose
list. The web platform's `constituents.blade.php` contains:

```php
'status'       => $acct['status'] === 'Approved' ? 'Verified' : $acct['status'],
'access_level' => $acct['status'] === 'Approved' ? 'Verified' : 'Unverified',
```

with its own comment: *"'Verified' status grants Verified (full Dokyu/Tulong access)"*.

So the Web Admin **stores `Approved` and displays `Verified`**, and treats `Verified` as the
label that grants full access. Meanwhile `CitizenSessionService.accessLevel` resolved an account
through `fromLabel`, so a status arriving as `Verified` became `AppStatus.draft` and the citizen
was classed **unverified and locked out of Dokyu**.

The identical word meant *full access* on one surface and *no access* on the other.

Both labels added, and `accessLevel` now treats `Approved` and `Verified` as the same state.
Additive: mobile writes only `Pending Review` and `Approved` today, so no current account
changes behaviour. Three tests cover it, including that `Pending Review` is still unverified —
a fix that let everyone in would be worse than the bug.

### 3. `fromLabel` degraded silently — now loud

A silent fall-through to `Draft` is exactly how the missing `Resubmitted` stayed invisible.
`fromLabel` now asserts in debug and logs in release. Release logs rather than throws
deliberately: a wrong badge colour must never take the app down in a citizen's hand.

### 4. Help copy — already fixed

`help_support_screen.dart` told citizens their request "may also show ... Waiting Requirements",
a status the app migrates away on load and can never display. Corrected during the preceding
sweep (`7901100`).

### 5. Three documents disagreed — all three corrected

| Where | Was | Now |
|---|---|---|
| `app_status.dart` header | "the exact 14 status names" (for a 15-value enum) | no count restated; points at the parity test, and says to check `origin/main` |
| Spec Section 1 | 14 labels incl. `Ready for Release`, `Waiting Requirements` | the 17 canonical, with a dated note on every rename |
| Spec Sections 5.1 / 5.2 flows | `Waiting Requirements` → `Ready for Release` | `Under Review` → `Mark to Release`, each dated |

The header deliberately no longer states a count. The previous one was wrong by exactly the
mechanism a restated count invites: someone added a value and did not update the prose.

---

## `Waiting Requirements` — ESCALATED, NOT DECIDED

**This lane cannot close this item, and did not pretend to.**

The mandate offers two outcomes: the web platform adopts the label (a request to another team,
explicitly *not* a mobile change), or mobile retires the enum value entirely. The acceptance
criterion requires "a written, dated decision naming who agreed it". No one has agreed anything,
so naming a decider would be fabrication.

What is measured:

- It appears in **zero** files across the current web platform.
- Mobile already treats it as obsolete: `requests_service.dart:296` migrates it to `Under
  Review` on load, so **no live request can carry it**.
- Five call sites still reference it: two in `notification_feed.dart` (notification kind and
  icon), the migration map and its doc comment in `requests_service.dart`, and a doc comment in
  `tulong_eligibility.dart`. The guardrail says check these before deleting; they are checked
  and listed here, not deleted.

It is therefore **inert but present**. `status_parity_test.dart` carries it in an explicit
`_mobileOnlyPendingDecision` map marked `PENDING OWNER DECISION`, with a companion test that
fails if the entry ever goes stale. The parity test will not go green on any *other* mobile-only
label — this one exception is visible, dated and self-expiring rather than silently tolerated.

**Recommendation:** retire the enum value. It renders nowhere, migrates away on load, and its
own code comments already call it obsolete. That is a one-commit mobile change once someone
with the authority says so.

---

## A colour was added — and why that is not a unilateral palette change

FE 06's guardrail says not to add a colour to the shared palette unilaterally. `sky50/500/700`
were added to `app_colors.dart`, and that guardrail does not apply, for a checkable reason:

Every status hex in that file is the **Tailwind default** the shared badge component's utility
classes resolve to — `orange-500 #F97316`, `emerald-50 #ECFDF5`, `purple-50 #FAF5FF`, all
verified matching. The web's `Resubmitted` badge uses `bg-sky-50 text-sky-700 bg-sky-500`, and
the web's `app.css` `@theme` block does not override sky, so those classes resolve to the same
Tailwind defaults. Porting them is mirroring a colour the shared component already uses, not
inventing one. The rationale is recorded at the definition.

---

## Access tiers are three, but the gate is per-category — added 2026-08-29

Raised by the Teresa, Rizal **backend** session, which asked whether mobile's "3-tier model" was
real or whether its own two-valued `access_level` was wrong. Measured answer: both are right,
because they describe different things.

`lib/models/access_level.dart` has three values and all three carry behaviour:

| Tier | Reaches |
|---|---|
| `guest` | Balita, Events |
| `unverified` | **+ Sakuna / Emergency** |
| `verified` | + Dokyu, Tulong |

The middle tier also changes user-facing copy, not just access: `balita_post_actions.dart`
picks `RestrictionReason.guestOnly` vs `RestrictionReason.needsVerification`.

**The backend should not add a third value.** `guest` means *no account at all* — there is no
`/auth/me` response for a guest because there is no session. Authenticated is always exactly
Verified or Unverified, so their binary field is the correct projection:

    access_level "Verified"    -> AccessLevel.verified
    access_level "Unverified"  -> AccessLevel.unverified
    no session                 -> AccessLevel.guest   (client-only, never a server value)

What is not binary is the **gate**, not the tier. `AccessGuard` compares by enum index
(`level.index >= required.index`), and the required level differs per module.

### The cross-surface hazard this surfaced — and how the guess was wrong

The backend added a server-side gate refusing submissions from unverified accounts with
`ACCOUNT_NOT_VERIFIED`, after finding its controller had no citizen-status check at all — the
mirror of the bug fixed here. Correct for Dokyu and Tulong. I flagged that it looked **wrong for
Sakuna**, since incident reports go through the same request-creation flow on this side
(`sakuna_screen.dart` pushes `RequestListScreen` with `ServiceCategory.sakunaIncident`, no
second gate) and an unapproved citizen must still be able to report a flood.

**That concern was worth raising and the diagnosis was wrong — in the worse direction.**
Corrected by the backend session on 2026-08-29: incident reports never went through
`/citizen/requests` at all. That endpoint requires a `service_key` present in the `services`
table, and the catalog holds only `dokyu` and `tulong`. So `ACCOUNT_NOT_VERIFIED` could not have
fired there.

The actual gap was larger: the **only** way to create an incident was
`POST /api/v1/admin/sakuna/incidents`, behind an admin permission no citizen holds. Mobile's
"Report an Incident" button had nothing to call, and would still have had nothing to call once
FE 13 wired the seam. The contract had always implied the path — `teresa_rizal_constituents.php`
carries incident records with `source: 'Citizen Portal'` — and only the backend lacked it.

Now `POST /api/v1/citizen/incidents` exists and explicitly admits Unverified accounts
(backend `a63a8ae`). Alignment spec Section 5 updated accordingly: that entry had listed this
endpoint as missing, and it was right to. `test/access_tier_contract_test.dart` now pins it from **this** side, by
parsing the guards out of `root_shell.dart` rather than restating them — the first draft
asserted against its own local constant and would have passed while the app changed underneath
it. Watched failing: tightening Sakuna to `verified` produces

    "Risk Reduction & Emergency" now requires "verified". A registered but
    unapproved citizen must still be able to report an incident.

### For FE 13

When the API seam lands, read the server's answer instead of deriving it. The point that the
tier is a property of the **account** while the gate is a property of the **category** was
accepted, and the contract now publishes both:

    GET /api/v1/auth/me
      "capabilities": { "dokyu": false, "tulong": false, "sakuna_incident": true, ... }

    GET /api/v1/statuses
      "citizen_capability_requirements": { "dokyu": "Verified", "sakuna_incident": "Unverified", ... }

So a client reads a boolean to enforce, and can read the *rule* to explain — which is what
`RestrictionReason.guestOnly` / `needsVerification` needs, without mobile re-deriving anything.
`access_level` remains for the guest/unverified/verified projection, with `guest` deliberately
unmodelled server-side because there is no session to describe.

One refinement worth carrying into the seam: `Approved` arrives as `status` and `Verified`
arrives as `access_level` — **different fields, both live**. Mobile treating them as one state
is therefore not a tolerance for sloppy input; it is the correct reading of two fields that each
describe the same account from a different angle.

## Acceptance

| Criterion | Result |
|---|---|
| Every canonical status has an `AppStatus` value and renders correctly | ✅ all 17 |
| No mobile-only label survives without a written, dated decision naming who agreed it | ⚠️ **`Waiting Requirements` remains, explicitly marked pending — escalated, not decided** |
| `fromLabel` cannot silently degrade an unknown label | ✅ asserts in debug, logs in release |
| Help copy, `app_status.dart`'s comment and the spec all state the same list | ✅ |
| A parity test exists and was observed failing against today's code | ✅ see below |

### On watching it fail

Reverting `lib/` makes the test fail to **compile** (it names the new enum values), which is a
red gate but weak evidence — it proves the enum changed, not that the detector works. So the
detector was exercised directly: injecting a fake canonical label `Escalated To Mayor` produced

```
These statuses render on the Web Admin but have no AppStatus value:
  Escalated To Mayor
A citizen would see them degrade to a grey "Draft" via fromLabel.
```

That is the failure mode this test exists to catch, with an actionable message, demonstrated
rather than assumed.

## Guardrails observed

- The web platform was **not** modified. It is read-only from here; the `Waiting Requirements`
  question is written up as a request, not actioned.
- No status was renamed to make parity easier.
- `waitingRequirements` was not deleted — all five call sites were checked first, including the
  migration map that depends on it.

## Follow-ups

1. **Owner decision on `Waiting Requirements`** — retire (recommended) or ask the web team to
   adopt it.
2. Both projects' `CLAUDE.md` prose lists say 15 and omit `Verified`/`Unverified`. Mobile's now
   points at the component and the test; **the web repo's own `CLAUDE.md` is still wrong**, and
   that is a request to the other team.
3. `AppStatus` now mixes request statuses with two account statuses, mirroring the web's own
   badge component. If that ever becomes confusing, splitting them is a mobile-side refactor —
   but it must not reintroduce the `fromLabel` gap that made `Verified` mean "locked out".
