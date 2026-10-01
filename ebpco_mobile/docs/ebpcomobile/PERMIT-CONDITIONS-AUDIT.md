# Permit conditions — what the app tells an applicant their permit requires

Audited 31 August 2026, against Box 8 (Box 9 on the mechanical form, Box 10 on
the interior design one) of the permit forms bundled in `assets/forms/`.

Twelve models declare `permitConditions`. **Nine wizards render it**, on the
Evaluation & Permit Status step, under a heading that reads as the conditions
the Office of the Building Official attaches to the permit. So a wrong entry is
not a wording problem: an applicant who never hears about the ten-day written
notice to their neighbour does not give it, and finds out when the office stops
the work.

Page two, where these boxes live, went unread until 31 August because
`qlmanage -t` renders only page one and nobody had looked for a second
renderer. `tool/render-form.sh <form> <page>` (JXA + PDFKit) is that renderer.

## What was wrong

| Wizard | Defect | Now |
|---|---|---|
| Fencing | Four real obligations absent — relocation survey, ten-day written notice to the adjoining owner, jobsite logbook, Article 1723 | Stated, with what the notice must show |
| Fencing | **Invented**: "Required signed and sealed professional documents must be authentic." | Removed |
| Plumbing | Notice of Construction softened to "when required" | "Before any plumbing work begins…" |
| Mechanical | Same softening | "Before any mechanical installation…" |
| Electrical | Same softening, and the form names **who** submits it | "you as the owner or permittee must submit…" |
| Electrical | "a PCAB-licensed specialty contractor is required for **qualifying installations**" | "200 amperes and above at 230 volts nominal and above" |
| Interior Design | Article 1723 and the completion documents absent; same invented "must be authentic" | Corrected, and caveated — see below |
| Civil/Structural | Article 1723 reduced to "remains professionally accountable" — no period, no consequence, and only one of the two professionals it binds | Fifteen years, and the supervisor's solidary liability with the contractor |
| Civil/Structural, Electronics, Sanitary | Same "when required" softening; and "applicable codes" where the form names a specific statute | Corrected; each names its own code |
| Excavation | "Larger excavations **may require a cash bond** per the permit conditions" | The threshold, both amounts, and the forfeiture — see below |
| Excavation, Sign | Same invented "must be authentic" — third and fourth occurrence | Removed |

Two patterns, each appearing more than once:

* **Softening a "shall" into "when required".** Four forms print the Notice of
  Construction as unconditional. Nobody in this lane had the authority to make
  it conditional, and the applicant is the party who bears the consequence.
* **Generalising away the number.** "Qualifying installations" tells an
  applicant a rule exists and not whether it binds them. 200 amperes at 230
  volts is the entire content of that condition.

And one in the other direction: **an invented condition**, in two wizards. It
is the same defect as an omitted one, and it reads as a rule about the
applicant's honesty standing where the office's obligations belong.

## The interior design form is not Castilla's

Reading page two settled what `isOfficialCastillaForm: false` means in
practice. The interior design form's signature block names **another
municipality's** Municipal Engineer — Engr. Florentino J. Destacamento — and
two of its Processing and Evaluation Division staff. Castilla's own forms
(fencing, plumbing, mechanical, electrical) are signed by **Jesus D. Abitria,
Jr., Municipal Engineer**.

So its Box 10 is that municipality's conditions, not Castilla's, and the three
wizards whose forms are reference templates — **Architectural, Demolition,
Interior Design** — may not print "these conditions will apply once the permit
is issued". They now carry `LguSourceNotice.conditionsFromReferenceForm`
instead, the same rule the form viewer already applies to the document itself.

What those three still state is limited to what is **national law** and holds
whichever LGU issues the permit: Article 1723 of the Civil Code, R.A. 8534,
the National Building Code and its IRR.

## The cash bond

The single worst entry found. The excavation form's Box 7 condition 7 says:
for an excavation of **more than 50 cubic metres and more than 2 metres deep**,
the owner posts **P50,000.00** for the first fifty cubic metres and **P300.00**
per cubic metre after, with the Office of the Building Official; the excavation
may not exceed 100 cubic metres or 3 metres deep until the building permit
issues, nor be left open with no work for **120 days**, after which the bond is
**forfeited**.

The app said: *"Larger excavations may require a cash bond per the permit
conditions."*

Every number an owner needs to budget for it, and the one consequence they need
to avoid, were absent — replaced by a sentence that reads as a footnote.

## Two lists nobody can see

**The excavation and sign wizards have no evaluation step.** Excavation ends at
step 9 (consent and review), sign at step 10 (review and submission), so their
`permitConditions` render nowhere — which is why they were not caught by the
per-wizard reading and only fell out of the class-level sweep below.

**Closed 31 August 2026.** Both now render their conditions on their final
review step — `PermitConditionsCard`, placed **before the declaration** rather
than after it, because these are the obligations the applicant is about to
certify they understand. The nine other wizards show the same list on their
Evaluation & Permit Status step, which is the right place there: that screen is
about what the office is doing, and this one is about what the applicant is
taking on.

Deliberately **not** done by cloning the evaluation step. That screen carries
Document Evaluation and Progress Flow tables of office-controlled placeholders
reading "Pending", and adding two more copies of a fabricated status table to
show one real list would be the defect this audit exists to remove, in the
other direction.

Sign carries the reference-form caveat; excavation does not, and the gate
delegates that distinction to `permit_forms.dart` rather than restating it.

The render count is pinned at **eleven**.

## A second signature block, and a plainer one

The sign form is signed by **Rex G. Bundac, CE, EnP — City Building Official**.
Castilla is a *municipality*. That is the cheapest confirmation of a reference
form found so far: it needs no comparison against another document.

So the method generalises. **To establish whose form a bundled PDF is, read the
signature block on page two.** Nothing else in the repository carries it, and
it settled two forms' provenance in one day.

## Nothing left unread

All ten two-page forms have now been read. The remaining forms are single-page
and carry no conditions box.

## The gate

`test/features/permit_conditions_test.dart`, 21 tests. It asserts the corrected
text, the absence of both softenings and the invented condition, that the three
reference-form wizards carry the caveat and do not carry the promise, and that
that set of three is **exactly** the set `permit_forms.dart` flags as not
Castilla's — delegated, so if the LGU publishes its own architectural form and
the flag flips, the test fails and the caveat comes off that screen.

It also pins the render count at nine: if a tenth wizard starts showing
conditions, they have not been checked against a form.

**Two of its assertions are class-level sweeps over all twelve lists**, not
per-wizard readings: no list may soften an obligation to "when required", and
no list may invent one about the applicant's honesty. Those two caught the
excavation and sign lists, which no per-wizard reading would have reached
because nothing renders them. A list added or edited later cannot reintroduce
either defect without failing. Both are guarded against vacuity by a test that
the scan finds exactly twelve lists — if a model moves or a declaration is
reformatted, that fails rather than the sweeps quietly passing against
nothing.
