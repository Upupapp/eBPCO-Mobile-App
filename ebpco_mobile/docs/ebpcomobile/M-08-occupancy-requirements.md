# The Certificate of Occupancy asked for the wrong documents

*Found and fixed 31 August 2026. Front-end mobile only. Sourced entirely from a
file already in this repository.*

---

## What I set out to do, and what it turned into

The task was to reconcile the requirements catalogue against the bundled forms.
Reading the one document that settles that question — Castilla's own
`Building-Permit-and-Occupancy-Checklist.pdf` — showed there was nothing to
reconcile, because the two provenance flags describe two different documents.
It also showed something worse.

**The checklist has a `CERTIFICATE OF OCCUPANCY DOCUMENTARY REQUIREMENTS`
section, and only the building permit entry had ever cited that file.**

## The gap

Castilla's list, and what the app asked for:

| Castilla's checklist | Was the app asking? |
|---|---|
| Unified Form for Certificate for Occupancy — 4 copies | **no** |
| Certificate of Completion, notarised, signed & sealed — 4 copies | yes |
| Approved Plan | **no** |
| Approved Specifications | **no** |
| Construction Logbook | **no** |
| Photographs of Structure, all sides — 4 copies | **no** |
| Valid Licenses of all involved professionals — 3 copies | **no** |
| As Built Plans, in case of changes — 4 copies | yes, but as mandatory |
| Fire Safety Compliance and Commissioning Report (FSCCR) — 1 copy | **no** — it asked for an FSIC |

And five it asked for that Castilla does not list at all: Land Title or Tax
Declaration, Barangay Clearance, Locational Clearance / Zoning Certification, a
valid government ID, and a Certificate of Final Electrical Inspection.

**This is the permit that closes out a build.** An applicant turned away at the
counter here has already finished the work — and the five ghost documents are
each a trip to another office for a list nobody keeps.

Two details worth separating out:

- **The FSCCR is not the FSIC.** The Fire Safety Compliance and Commissioning
  Report is prepared by the project's own fire safety practitioner and precedes
  the inspection certificate. An applicant sent for the wrong one arrives with
  a document the office cannot accept and no way to know why.
- **The as-built plans are conditional.** The checklist says *"in case of
  changes in the building"*. They were listed as mandatory, which is exactly
  what `RequirementDocument.isRequired` exists to prevent: *"presenting an
  optional document as mandatory costs the applicant a trip they did not
  owe."*

## What changed

The entry is transcribed from the checklist: nine items in its order, with the
copy counts in the descriptions — the office counts them at the counter, and an
applicant who brings one of four is turned away as surely as one who brings
none. It now cites `_src0`, the checklist itself, and `verified` is true.

That takes the catalogue's Castilla-sourced entries from four to five. Both
gates that pin those counts failed on the change and were updated with the
reason, which is what they are for.

## The wizard followed, in the next commit

The catalogue was corrected first and the wizard was left behind it for one
commit, with the gap asserted by name. It is aligned now:

- **Six slots added** — the unified form, the certificate of completion, the
  approved plan, the approved specifications, the photographs and the
  professional licences. The certificate of completion is the one the first
  write-up missed: the app held a `dateOfCompletion` and no way to attach the
  document that proves it.
- **The FSIC slot became the FSCCR.**
- **Five slots removed** — land title, barangay clearance, locational
  clearance, valid ID and the electrical certificate of completion. Each was a
  trip to another office for a document nobody was going to ask for. Anything
  an evaluator does ask for beyond the published list still has somewhere to
  go: the optional slots and the applicant's own *Other Documents* list are
  untouched, because a checklist is a floor.
- **As-built plans are optional now**, labelled *"Only if the building differs
  from the approved plan"*, and counted with the optional documents rather
  than against the required eight — a review screen that says "3 of 9" when
  the applicant owes eight is its own small lie.

The gate is inverted with it: it now asserts the nine slots exist, the five
ghosts are gone, and `isValid` requires the eight without requiring the
conditional ninth.

**One consequence worth stating.** Removing a slot removes its snapshot key, so
a draft saved before today loses those five attachments on restore. They are
attachments for documents the office does not want, and the applicant is told
what is missing rather than left to discover it — but it is a loss, and it is
the reason the storage keys were *not* touched when the building permit's ID
fields were renamed yesterday. Removing a field and renaming one are different
decisions.

## The lesson, again

This is the fourth item this week filed as needing an external party that was
answerable from the repository — after the bundle identifier's domain, the
permit forms, and the office's contact details. Every one of them was in a file
the app already ships.
