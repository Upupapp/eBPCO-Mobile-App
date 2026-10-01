# M-11 — how a permit is claimed

Worked 31 August 2026. **Partly closed from the repository**, which is now
the fifth time a task filed as blocked on an external party was answerable from
a file already bundled with the app.

## The defect, which was larger than the missing facts

`ReleaseRecord.claimLocation`, `.officeHours` and `.bringWithYou` come from the
backend. The contract omits them **on purpose** — reconciliation note R-13:

> The logistics values are LGU-specific (M-11 / decision E-15) and are omitted
> rather than guessed.

Every one of them was null-guarded on the digital permit screen. So with the
backend behaving exactly as the contract specifies, the section headed **Claim
instructions** rendered a heading and one paragraph about Special Powers of
Attorney. Nothing about where to go, when, or what to bring.

That is not a cosmetic gap, because of how hard the app pushes an applicant at
it:

* `readyForRelease` sets `requiresApplicantAction`, which drives the Home
  action stack, the tab badge and push priority.
* The action item is labelled **"Claim instructions"**.
* The notification reads *"…is ready to claim. Tap for claim instructions and
  requirements."*

An action item that points at nothing is worse than no action item: it spends
the applicant's trip. Castilla is a municipality in Sorsogon and the office
keeps no published hours — a wasted journey is a real cost.

## What the repository could answer

`assets/permits/Building-Permit-and-Occupancy-Checklist.pdf`, the office's own
document under the municipal seal:

* **Letterhead** — Republic of the Philippines / Municipality of Castilla /
  Province of Sorsogon / **Office of the Municipal Engineer**. That is the
  claim location at the granularity the LGU has actually published.
* **STEPS, item 3** — *"Claiming the Building Permit and Ancillary Permits."*
  The ancillaries are claimed **with** the building permit, in one visit,
  matching the way they are filed as one submission. Worth stating because this
  app models each ancillary as its own application, so an applicant holding six
  has no reason to expect one trip rather than six.
* **Footer** — the MEO's mobile number and email, already carried by
  `OfficeContact`.

## What it could not, and is now said plainly

* **A street address.** The checklist has none — no street, no building, no
  room. This corrects two comments in `office_contact.dart` that said the
  checklist gave the office's address; re-reading it for this task showed it
  does not. `OfficeContact.addressPending` now says so, and gives the phone and
  email instead.
* **Opening hours.** Philippine government offices commonly open 8:00–5:00 on
  weekdays, and RA 11032 requires service without a noon break. "Commonly" is
  not Castilla. The hours are exactly what an applicant plans a trip around,
  and this app has printed a plausible-and-wrong location once already — a
  Quezon City hall for a Sorsogon municipality. Not stated;
  `OfficeContact.officeHoursPending` says so.
* **A bring-with-you list for release.** Nothing publishes one. The screen
  keeps the Special Power of Attorney note, which is about who may claim rather
  than what to carry.

## Still the LGU's to supply

The street address, the opening hours and the bring-with-you list. M-11 stays
open for those three; what closes is the applicant reaching an empty screen.

## The gate

`test/features/applications/detail/claim_instructions_test.dart`, 4 tests.
It renders the screen with the release record the contract actually specifies —
status only, every logistics field null — and asserts the section names the
office and the municipality; that it does **not** print an invented 8:00 or
"Monday to Friday" or a street; that it carries the checklist's step-3 fact
with its provenance; and that a backend which *does* send real values still
wins, with the caveats suppressed.

Falsified by restoring the null-guard: the first test goes red.
