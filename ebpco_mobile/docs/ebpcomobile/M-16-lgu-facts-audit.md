# What the app claims about the LGU, and what it can actually source

*Audited 30 August 2026 in `eBPCO-Mobile-App`. Front-end mobile only. Every
figure read from source.*

---

## Why this audit happened

M-16 asks the LGU to publish its contact details. Preparing that turned up
something bigger: the app had been **inventing** them — a support address at a
domain no government entity holds, a Metro Manila phone number for a Sorsogon
municipality, and an office address in Quezon City. Those are fixed.

The obvious follow-up question is the one this audit answers: **what else does
the app assert about the LGU that it cannot source?**

## The finding

The requirements catalogue already models provenance properly. Per permit type
it records `verified` — *"true only where this entry was built from an actual
Castilla or BFP form rather than a national-law baseline or a placeholder"* —
and per source a `verificationStatus`. **Fifteen of the nineteen permits are
`verified: false`.**

`RequirementSource`'s own doc comment states the rule:

> Carry this to the applicant. A requirement the LGU has not confirmed must not
> be shown in the same voice as PD 1096.

**The pre-flight screen carried it. The Citizen's Charter screen did not.**

That is the wrong way round. The charter screen is:

- **titled with the name of a statutory document** the LGU is required to
  publish under RA 11032;
- the place that lists **which offices are involved**;
- and the place with the **"where to secure"** column against every
  requirement.

An applicant makes trips on the strength of that column. It is the same defect
class as the fabricated support address and a more expensive one: that cost an
email, this costs a journey to the wrong counter.

## What was true and what was not

| Shown on the charter screen | Sourced? |
|---|---|
| 3 / 7 / 20 working-day ceiling | **Yes** — RA 11032, national law, and correctly attributed on screen |
| Fees are assessed, never quoted | **Yes** — the screen says the amount comes on the Order of Payment |
| Which offices are involved | **No** — national practice |
| What to bring, and where to secure it | **No** — national practice |
| Fee basis | **No** — national practice |

Note what is *not* wrong: the pledged days are national law and may be stated
plainly, and the screen already refuses to quote an amount. Blanketing the
whole screen in doubt would understate RA 11032 — which is the thing an
applicant can actually hold the office to.

## What changed

`lib/core/contract/lgu_source_notice.dart` — one notice, used by every surface
that shows this data.

- The charter screen now states, **always**, that it is compiled from national
  practice and that Castilla's own published charter has not been supplied, so
  the offices and the where-to-secure notes are a guide to confirm.
  Unconditional on purpose: even the four permits built from a genuine Castilla
  *form* have no *charter* entry from Castilla's published charter.
- It also carries the per-permit caveat for the fifteen unconfirmed types —
  the same sentence the pre-flight screen shows.
- That sentence had been written out inline in the pre-flight screen. It is now
  a constant both read. **This repository has already corrected one surface and
  missed its sibling twice** — the draft copy, and the contact details.

Confirmation is read from the requirements catalogue rather than held a second
time. Two answers to one question is how they drift apart.

## What guards it

`test/features/lgu_source_notice_test.dart`, six tests: the 15/4 measurement
itself, that confirmation is delegated rather than duplicated, that an unknown
permit reads as *unconfirmed* rather than confirmed-by-absence, that both
surfaces use the one notice and neither keeps a private copy of the sentence,
and that the statutory pledge is still stated as statutory.

## What is still the LGU's to supply

Unchanged by this audit, and now visible to applicants rather than papered
over:

- **M-16** — the OBO's real phone, email and office address, and the Data
  Protection Officer's contact.
- **M-08** — Castilla's published Citizen's Charter entry per permit type:
  classification, pledged days, fee schedule, requirements.
- **M-11** — the claim location, office hours and bring-with-you list for
  release.
- **M-10** — the DPWH/JMC unified forms, which also block the `form` payload on
  submission (M-47).

The app now says which of these it is missing, on the screens where it matters,
instead of filling the gap with something plausible.
