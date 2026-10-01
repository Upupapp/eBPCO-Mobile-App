# Auditing a wizard against its official form

*Written 31 August 2026. Front-end mobile lane.*

---

## The register was wrong about who can do this

`docs/M-10-forms-already-bundled.md` said auditing the wizards against the
bundled forms was *"work this lane cannot do — reading a scanned form is not a
source scan"*, and needed someone who could open a PDF.

**That was wrong, and it was wrong because I did not try.** Every Mac ships
`qlmanage`, which renders a PDF page to PNG; the PNG can then be read directly.
`tool/render-form.sh` is the two lines it takes.

## The limit was not a limit

This section used to say `qlmanage` renders page one only, that there is no
poppler and no Homebrew here, and that page two therefore *"remains unread"*.
The first two are true. **The conclusion was not**, and it stood as a blocker
for a day.

Every Mac ships PDFKit, reachable from JavaScript for Automation with no
install at all:

```js
ObjC.import('Quartz'); ObjC.import('AppKit');
var doc = $.PDFDocument.alloc.initWithURL($.NSURL.fileURLWithPath(src));
var page = doc.pageAtIndex(n);            // any page
```

`tool/render-pdf-page.js` is that, and `tool/render-form.sh <form> [page]` now
takes a page number. **That is the fourth thing this week filed as blocked on
something external that was answerable here** — after the LGU's domain, the
forms themselves, and the office's contact details.

Say which pages an audit covered, all the same. A wizard audited on page one is
a different claim from one audited against the whole form.

## The method

1. `tool/render-form.sh <Form-Name>` and read the PNG.
2. Walk the form box by box. For each printed field, find the model field that
   holds it.
3. Record three things separately: fields **on the form and missing from the
   wizard**; fields **in the wizard and not on the form**; and anything the
   form says that the app's comments contradict.

That third one is where the first audit found its defect.

## First audit: the Fencing Permit

**The form is genuine.** `NBC FORM NO. B–03`, headed *Republic of the
Philippines / MUNICIPALITY OF CASTILLA / Province of Sorsogon / OFFICE OF THE
BUILDING OFFICIAL / FENCING PERMIT*. That settles `isOfficialCastillaForm` for
this one by reading rather than by trust — the earlier audit could corroborate
only two of fourteen flags and said so; this is a third method, and a better
one.

**One field was missing.** Box 1's address row is
`ADDRESS NO. · STREET · BARANGAY · CITY/MUNICIPALITY · ZIP CODE · TELEPHONE NO.`
The wizard collected every part of it except the telephone number — and the
model carried a comment saying the form *"has no contact number or province
field (unlike other ancillary permits')"*.

Half of that is right: there is no province field. The other half is not, and
it was load-bearing. **Fencing was the only one of the nineteen wizards without
a contact number**; the other eighteen collect one. The comment is why nobody
questioned it. Both are fixed.

**Everything else on page one matches**, box for box: the six Scope of Work
options are exactly the app's six; Boxes 2 and 3 are the same professional
shape twice, which is how the model has it; Box 4's applicant and lot-owner
consent pair matches; Box 5's notarial fields are a subset of what the model
carries.

**One oddity in the LGU's own form, recorded rather than acted on.** Box 5's
notarial block is pre-printed `REPUBLIC OF THE PHILIPPINES ) S.S. / CITY OF
LEGAZPI` — Legazpi is in Albay, not Sorsogon. That is the municipality's form
to correct, not the app's; the app leaves the notarial venue blank, which is
the right behaviour either way.

## A spot check that came back clean

The Electrical Permit form's `SUMMARY OF ELECTRICAL LOADS/CAPACITIES APPLIED
FOR` asks for Total Connected Load, Total Transformer Capacity and Total
Generator/UPS Capacity, all in kVA. The model has
`totalConnectedLoadKva`, `totalTransformerCapacityKva` and
`generatorCapacityKva`, with a conditional document requirement when the
generator capacity is above zero. No gap.

## The rest of the audit, 31 August 2026

All nine remaining forms rendered and read. **Every one carries the Castilla
letterhead**, so the ten `isOfficialCastillaForm: true` flags among them are now
verified by reading rather than pinned on trust — the earlier audit could
corroborate two of fourteen by machine and said so.

| Permit | Form | Page-one verdict |
|---|---|---|
| New Construction · Renovation · Addition/Extension | Unified Application Form for Building Permit | **four findings** |
| Civil / Structural | NBC A-02 | exact — 12 scope options, 15 natures of work |
| Electrical | NBC A-03 | exact — 8 scope options, all three supervisor types |
| Mechanical | NBC A-04 | exact — 12 scope options, 2 supervisor types; the app's 29 equipment kinds are a superset of the form's 19 grouped ones |
| Sanitary | NBC A-05 | exact — 12 scope, 4 water supplies, 8 disposal systems. Title wrong |
| Plumbing | NBC A-06 | exact — 12 scope, 4 systems; the app offers one fixture more than page one prints (swimming pool) |
| Electronics | NBC A-07 | exact — 3 scope options, 14 systems |
| Excavation | NBC B-02 | exact — 6 scope options. Title wrong |
| Fencing | NBC B-03 | audited first; the telephone number was missing |

**That settles the 14-against-4 disagreement.** The forms are Castilla's and the
wizards were built from them — nine of the ten match box for box. The
requirements catalogue's `verified: false` is the stale party for these
permits, not the form flag.

### Fixed

- **`LEGALIZATION OF EXISTING BUILDING`** was missing from the building
  permit's Scope of Work. The form prints twelve options and the app had
  eleven, so an applicant regularising an unpermitted structure had to choose
  *Others* and type it — on the one permit where the office most needs to know,
  since legalisation follows a different assessment path under PD 1096.
- **Two form titles named the permit rather than the document**, against
  `PermitForm.title`'s own rule. NBC B-02 is headed *Excavation and Ground
  Preparation Permit*; NBC A-05 is headed *Sanitary Permit*, not "Sanitary /
  Plumbing".

### Also fixed, on the Unified Application Form

Three findings bigger than an enum value, all on the app's most-filed permit,
all closed on 31 August:

- **`NUMBER OF STOREY` was not collected.** The form asks for it beside Number
  of Units, Total Floor Area and Lot Area — all three of which the app already
  required. Storey count drives occupancy and structural review under PD 1096.
  Now collected and required like its neighbours.
- **The estimated cost was one figure where the form prints six.** TOTAL
  ESTIMATED COST split across *Building · Electrical · Mechanical · Electronics
  · Plumbing*, plus *Cost of Equipment Installed*. **Building permit fees are
  assessed from those components**, so a total alone is materially less than
  the office needs. All six are collected now, and all six are optional — a
  simple residential permit may have nothing against electronics, and demanding
  a zero would ask a question the paper does not.
- **Boxes 3 and 4 ask for a `Gov't Issued ID No.`; the app asked for a CTC
  Number.** The ancillary forms *do* ask for C.T.C. No., which is why the app
  modelled a cedula everywhere and why the building permit's exception went
  unnoticed. The fields and labels are corrected.

**The storage keys were not renamed with the fields.** A snapshot key is a
compatibility surface: drafts have persisted since M-48, and changing a key
silently loses whatever the applicant had already typed. The codec writes the
new key and reads the old one as a fallback, and a test holds both halves.

### One oddity in the LGU's own paperwork

The Excavation form is headed **Office of the Municipal Engineer**, not Office
of the Building Official. The app shows the OBO for it. In many municipalities
these are the same officer and `FormIssuingOffice.obo` documents both, so this
is recorded rather than changed — but an applicant reads the app's label and
then the paper's.

## What guards the audit

`test/architecture/form_field_parity_test.dart` pins every count read off the
paper — twelve scope options here, eight there, fifteen natures of work, three
electrical supervisor types. A count that lives only in a document is a count
nobody checks; an option quietly added or dropped now fails a test and has to
be justified against the form.

---

## The document steps, 31 August 2026

The audits above compared each wizard's **fields** against its application
form. This compares the **document steps** against Castilla's
`Building Permit Documentary Requirements` checklist — the other half of what
an applicant is asked for, and the half that costs trips rather than typing.

### The building permit

The catalogue entry was a faithful transcription of the checklist's fourteen
lines. **The wizard was not.**

| Finding | |
|---|---|
| **Proof of ownership was "Land Title"** | The checklist prints *"Certified True Copy of OCT/TCT"* with indented alternatives — deed of sale, deed of donation, lease contract, assignment of rights, *"or any valid proof of ownership"*. The app demanded a title, so **an applicant building on leased land or land taken by deed could not file at all** |
| **No slot for the applicant's and owner's ID** | The checklist asks for *"Valid ID of Applicant and Owner of Lot"* on every application. The consent step collects the lot owner's ID, and only when the applicant is not the registered owner — a different question |
| **Four documents were mandatory and are not on the checklist** | Tax declaration, real property tax receipt, bill of materials, barangay clearance. Each was a trip to another counter for a list the office does not keep |

All four unlisted documents keep their slots and are simply no longer required
— an evaluator may still ask, and an applicant who has one should be able to
send it. The tax declaration's label now says the more useful thing: that it
can serve as the proof of ownership.

`landTitleUpload` keeps its field name so drafts saved before today still
restore. The name is now slightly wrong and the storage key is right, which is
the trade this repository settled on when the building permit's ID fields were
renamed: **a snapshot key is a compatibility surface.**

### What that means for the ancillary permits

The checklist treats them as **one submission**: *"Building permit & Ancillary
Forms — 4 Copies"*, with the nine ancillary forms listed under it, and the
documentary requirements above shared across the lot. So there is no separate
ancillary document list to audit against — which is itself the finding, and it
is why the catalogue's ancillary entries cite national law rather than a
Castilla checklist that does not exist for them.

---

## Page two, 31 August 2026

Page one carries Boxes 1–5 — the applicant, the site, the scope, the
professionals, the consent block. **Page two carries Box 8: the conditions the
permit is issued subject to.** The app renders those to the applicant on the
Evaluation & Permit Status step of nine wizards, and they had been written
without the form.

### Fencing — the conditions were a paraphrase, and it lost the obligations

NBC Form B-03's Box 8 puts four things on the applicant. **Three were absent
from the app entirely:**

- a licensed **Geodetic Engineer** must carry out an actual relocation survey
  before work starts;
- before any excavation, the owner of the **adjoining building** must be
  notified **in writing at least ten days beforehand**, showing how their
  building will be protected;
- a **logbook** must be kept at the jobsite at all times and made available to
  the OBO representative under Section 207 of the National Building Code.

The fourth, full-time supervision by a licensed architect or engineer, was
there. The app also carried one condition the form does not print — that
professional documents *"must be authentic"*.

**This is not a wording problem.** An applicant who never hears about the
ten-day notice does not give it, and the neighbour finds out when the digging
starts.

Article 1723 of the Civil Code — fifteen years' liability for the engineer or
architect if the structure collapses through a defect in the plans — is on the
form and is now shown too.

### Plumbing — right in substance, softened in one place

NBC Form A-06's Box 8 says a Notice of Construction *"shall be submitted"*
before any plumbing work begins. The app said *"when required"*. Nobody had the
authority for that word, and it is gone.

The rest of that list was a fair paraphrase, which is worth recording: the
plans-and-codes condition, the supervising Master Plumber, the logbook and
as-built plans on completion, and that the permit is void without the building
permit are all on the form.

### Two facts about the office, from the signature blocks

Both forms are signed by **Jesus D. Abitria, Jr.** — as *Building Official* on
the fencing form and as *Municipal Engineer* on the plumbing one. One person,
both titles, which corroborates the OBO/MEO equivalence `OfficeContact` states.

### And a documentary requirement page one does not show

The plumbing form's Box 7 asks for **five sets** of plumbing documents: plans
and specifications, bill of materials, cost estimates. Worth noting beside the
building permit audit, which correctly made the bill of materials optional —
it is not on the building permit checklist, and it *is* on the plumbing form.

### What is left

Box 8 of the seven other two-page forms — Architectural, Civil/Structural,
Demolition, Electrical, Electronics, Interior Design, Mechanical, Sign,
Excavation and the Unified form. Each is one render and one read, and nine
wizards render a conditions list.
