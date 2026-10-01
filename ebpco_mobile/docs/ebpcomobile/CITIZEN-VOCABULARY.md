# "Citizen" — what changed, and the three things that did not

Owner ruling, 31 August 2026: *"lets use citizen from now on for citizen,
business owner and applicant."* The system has three user types — **PUBLIC** on
the website, **CITIZEN**, and **ADMIN** with sub-roles by accessibility.

## What the sweep found

**2,989 lines in `lib/` mention "applicant"**, 104 of them inside string
literals. The obvious way to obey the instruction — replace the word — would
have broken the app in three separate ways, so the sweep classified before it
changed anything.

| Category | Count | Verdict |
|---|---|---|
| Draft snapshot keys (`applicant.firstName`, …) | most of the 104 | **Frozen** |
| NBC form labels ("Applicant Information", "Applicant Address", …) | ~45 occurrences across 19 wizards | **Frozen** |
| Quoted sources (the checklist's ownership clause, the RA 9514 citation) | 2 | **Frozen** |
| The app's own voice — wizard subtitles and status prose | 13 files | **Changed** |

## Why three categories are frozen

**Snapshot keys are a storage surface and a wire surface.** They are what a
saved draft is written under, and — since `form` began being sent on submission
— what the Office of the Building Official receives. Renaming one orphans every
draft on every device *and* changes the field names arriving at the office. The
rule stands: rename Dart fields, never these keys.

**Form labels are the whole point of the field-parity work.** The wizards
mirror the Municipality's own forms box for box, verified field-for-field on 31
August against the bundled PDFs. The forms say **APPLICANT**. A citizen holding
the paper form and the phone should see the same words in the same order;
changing one side breaks the thing that audit was for.

**Quoted sources are transcriptions.** *"Or, if the applicant is not the
registered owner: Deed of Sale, Deed of Donation, Lease Contract…"* is the
checklist's sentence, not ours.

## What changed

Where the app **named the person in its own prose**, it now says **citizen**:

| Before | After |
|---|---|
| "Tell us about yourself so we can identify the applicant." | "…so we can identify the citizen." |
| "Provide the applicant details for the Fencing Permit." | "Provide the citizen details for the Fencing Permit." |
| "Provide the applicant address and location of the electrical work." | "Provide the citizen address and location of the electrical work." |
| "Confirm the applicant and lot owner information." | "Confirm the citizen and lot owner information." |

Ten address prompts, three detail prompts, two confirmations, one
introduction, across 15 files. The sentences keep their shape: *citizen
details* and *citizen address* are the same noun-modifier construction
*applicant details* and *applicant address* were.

And the timeline remark an ADMIN reads is now *"Corrections resubmitted by the
citizen."*

### A first pass got this wrong, and the correction is worth keeping

The first attempt rewrote these into second person — *"Provide your address and
the location of the electrical work"* — arguing that the app is addressing the
person it names, so a pronoun beats a noun.

The owner asked for the noun. It is the better answer for a reason the first
pass missed: **the rest of the system has exactly three user types — PUBLIC,
CITIZEN, ADMIN — and the UI should use the same word the architecture,
the permissions and the ADMIN-facing screens use.** One word for one user type.
A pronoun is invisible to anyone reading across surfaces to check that mobile
and the citizen web portal agree.

A test now asserts the second-person shape has not come back, so the two
readings cannot coexist across nineteen wizards.

## The gate

`test/features/citizen_vocabulary_test.dart`, 7 tests. Four assert the
rewording landed, that **no wizard subtitle still names the applicant**, and
that none has slipped back into second person — scanned, not listed, so a new
wizard cannot reintroduce either. Three assert the
frozen categories are still frozen: a snapshot key still reads
`applicant.firstName`, the form-mirroring labels still appear more than twenty
times, and the checklist's ownership clause is still quoted verbatim.

Falsified by renaming `applicant.firstName` to `citizen.firstName`: the frozen
guard goes red and names the consequence.

---

# Addendum — the product's own name, fixed at the same time

The strings that named the user also named the wrong product.

**The sign-in screen told a citizen the app managed their *business* permits.**
E-BPCO is the **Electronic Building Permit and Certificate of Occupancy**
system. Three sites corrected:

| Where | Before | After |
|---|---|---|
| Sign-in | "Log in to manage your business permits." | "…your building permits." |
| Registration success | "start applying for business permits and clearances" | "building permits and clearances" |
| Terms §2 Eligibility | "property owners, business owners, authorized representatives, and licensed professionals… building permit and business clearance applications" | "citizens filing for a permit, their authorized representatives, and the licensed professionals who prepare their applications… building permit, occupancy, and related clearance applications" |

The eligibility rewrite keeps all three legally distinct parties — the citizen,
whoever they authorise, and the professional who prepares the plans — while
using the word the ruling settled on.

## Why this was not a find-and-replace either

**"Business Permit" is load bearing in three places**, and a sweep takes all
three:

* **`serviceDomain`** — the contract has exactly two values, `Business Permit`
  and `Construction Permit`, and every filing declares one. Rewriting it means
  no conforming server accepts a submission.
* **The legacy business-permit flow** still exists at
  `/applications/new/business-permit`, with its own catalogue entry and wizard.
  It predates the construction-permit catalogue.
* **"Group E — Business and Mercantile"** is an NBC occupancy classification,
  printed on the forms.

That is why the standing rule says never to blanket-replace it: the count of
occurrences is not the measure, the *kind* is. Three tests now hold each of
those in place, and one of them names the consequence — rewriting the enum
would have every filing declare a serviceDomain no server accepts.
