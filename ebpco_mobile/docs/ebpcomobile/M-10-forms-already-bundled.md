# M-10 asks for forms the app already ships — for ten of the nineteen

*Audited 31 August 2026 in `eBPCO-Mobile-App`. Front-end mobile only. Every
figure measured, and the one thing that could not be measured is named as
such.*

---

## Why this audit happened

M-10 sits in the register as *"Provide the Unified Building Permit Application
Form and Unified Application Form for Certificate of Occupancy so wizard fields
can be audited field-for-field"*, against an external party.

Before asking anyone for anything, the question worth answering is what the app
already has. It has more than the register assumed.

## What is on disk

**Eighteen blank PDFs under `assets/permits/`**, registered in `pubspec.yaml`,
~6.6 MB: seventeen application forms plus the OBO's documentary checklist. All
nineteen permit types resolve to one. Three building sub-types share a single
file, because Castilla's Unified Application Form covers New Construction,
Renovation / Alteration and Addition / Extension through its own Scope of Work
checkboxes.

`permit_forms.dart` flags **fourteen** of them as genuine Castilla or BFP
documents. The other five are generic reference templates standing in for forms
the LGU has not published — and the screen labels them as such, which is the
part of that promise a test can hold, and now does.

## The finding

The requirements catalogue makes a second provenance judgement about the same
nineteen permits: `verified` — *"true only where this entry was built from an
actual Castilla or BFP form rather than a national-law baseline or a
placeholder"*. **Four are true.**

Fourteen against four. **Ten permits ship a form the app calls Castilla's own
while their requirements were built from a national baseline instead:**

Renovation / Alteration · Addition / Extension · Civil/Structural · Electrical ·
Electronics · Mechanical · Plumbing · Sanitary/Plumbing · Fencing · Excavation

### Correction, 31 August: this is not a disagreement at all

The paragraph that stood here offered two explanations — the catalogue is
behind the forms, or the form flag is optimistic — and both were wrong, because
**the two flags describe two different documents**.

- `isOfficialCastillaForm` is about the blank **application form** an applicant
  fills in. Reading all nine confirmed every one of them is Castilla's.
- `verified` is about the **documentary requirements** — what to bring with the
  form. Its sources are named in the catalogue: PD 1096, the Fire Code, a
  Puerto Princesa checklist marked `SAMPLE_REFERENCE_ONLY`, and Castilla's own
  charter marked `PENDING_CASTILLA_VERIFICATION`. Only **one** entry cites
  Castilla's own OBO checklist.

So `verified: false` on the ancillary permits is **correct**, and nothing needs
reconciling. Fourteen and four are answers to different questions.

What that leaves is a real and smaller task: Castilla's own checklist **is**
bundled — `Building-Permit-and-Occupancy-Checklist.pdf` — and it names the
building permit's documentary requirements, the Certificate of Occupancy's, and
the ancillary forms that go with them. Only one catalogue entry cites it. The
others could be raised against a document already in this repository.

### The sharpest case is a three-way one

New Construction, Renovation / Alteration and Addition / Extension share **one
physical form**. The catalogue records the first as built from a Castilla form
and the other two as not. Same paper, three permits, two verdicts. They cannot
all be right, and no external party is needed to work out which.

## What could not be measured, and why it is said out loud

The `isOfficialCastillaForm` flag is a human judgement, and this audit could not
verify it. Of the fourteen forms flagged as genuine, **two** — Fencing and
Sanitary/Plumbing — carry the words *CASTILLA* and *SORSOGON* in text these
tools can extract, by two independent extraction methods.

For the other twelve, the absence of those words is **not evidence of
anything**: the pages are images, and neither `strings` nor a stream-level text
extractor reads them. A first attempt found the marker in Sanitary/Plumbing and
missed it in Fencing, which is exactly how a measurement tool proves itself
unreliable. So the gate **pins** the flags rather than verifying them, and says
so where somebody might otherwise assume it had checked.

## What guards it

`test/architecture/bundled_forms_test.dart`, six tests:

- every declared form is on disk, non-empty, and resolves for all nineteen
  types — the failure being a form dropped from the bundle while its entry
  stays, so the screen offers an applicant a document that does not exist,
  offline, which is exactly when they cannot go and look;
- no PDF ships unreferenced;
- the assets are registered, without which none of the above ships at all;
- a stand-in form is labelled as one on screen;
- the 14-against-4 counts;
- and the ten disagreements **by name**, so resolving one fails the test and
  says which, and adding an eleventh does too.

## What this changes about M-10

It does not close it. The Certificate of Occupancy form is one of the five
stand-ins, and the DPWH/JMC unified forms are still worth having as the
national reference.

What it changes is the size and the order. **Ten of the nineteen wizards can be
audited now**, against files already committed here.

### Correction, same day: this lane can read them

The paragraph that stood here said the audit needed *"someone who can open a
PDF and read a form"* and that this was *"work this lane cannot do — reading a
scanned form is not a source scan"*. **Wrong, and wrong because I did not
try.** Every Mac ships `qlmanage`, which renders a PDF page to an image that
can then be read directly. `tool/render-form.sh` is the two lines it takes, and
`docs/FORM-AUDIT-METHOD.md` records the method, its real limit — page one only,
since there is no poppler and no Homebrew on this machine — and the first
audit's findings.

That first audit, on the Fencing Permit, found a field the form asks for and
the wizard did not collect, sitting behind a comment that asserted the form had
no such field. It also settles that form's `isOfficialCastillaForm` flag by
reading its letterhead — the third method tried, and the only conclusive one.
