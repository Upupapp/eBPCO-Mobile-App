# Municipal ruling — renewal, amendment and re-certification

**Owner, via HUB, 2026-09-03. Confirmed 2026-09-03 (bus #0042, #0045).**
Recorded here because a ruling that lives only on the bus is one the next
session has to ask for again.

## The ruling

**1. Renewal — nothing may be omitted.** The document list does not shrink. All
twenty-two remain required. What changes is who supplies them: a document
already on file is **reused by default** — carried over pre-selected, not
re-uploaded. The citizen **may** change it; replacing a reused document with a
fresh one is always available and never forced. Every reused document is
**flagged to the admin** as reused.

**2. Amendment — the amendment scopes what is superseded.** Amended items remove
the old items; everything else is reused in place and changes only if the
citizen changes it. Amending a contractor replaces the contractor documents and
leaves the structural ones untouched.

**3. Re-certification — not required.** A reused document past its validity is
accepted and validated as it stands. The admin sees a note saying it is reused
**and the date it was certified**, and the officer decides. It is not a hard
block and the citizen is not sent away.

## What it requires of this app

- Reuse is the **default state** of a renewal or amendment form, not an opt-in.
- The **change affordance must be obvious** on every reused document.
- Carry and display the **original certification date** — an `expiresOn` cannot
  answer "when was this certified", and the admin note is built from the
  certification date where both exist.
- **Nothing client-side may refuse a reused document for age**: no blocked
  submission, no greyed control, and no warning worded so that it reads as a
  refusal.

## State on this surface, measured 2026-09-05 at `9813b4d`

**Unimplemented.** `ApplicationIntentProvider` carries a renewal or amendment
lineage into a wizard, and that is as far as it goes:

- `SavedDocumentModel` is referenced nowhere under
  `lib/features/applications/presentation` — there is no document library on any
  filing screen.
- No `step*documents*.dart` reads `lineage`.
- So a renewing citizen is asked to re-upload all twenty-two documents.

No client-side age refusal exists on the reuse path either, because the path
does not exist. `SavedDocumentModel.isTimeBound` and `needsAttention` are
declared and consulted by no wizard — which means there is nothing to remove,
but also nothing that would honour the ruling if the path were wired naively.

## The contract, settled 2026-09-05 to 09-08 (bus #0387, #0391, #0406, #0425)

citizen-web and this lane wrote proposals independently and converged on the
same three names; backend adopted them (#0391).

| field | type | meaning |
|---|---|---|
| `certifiedOn` | `string \| null` | the ORIGINAL certification date, `YYYY-MM-DD` |
| `reused` | `boolean` | carried over rather than uploaded on THIS filing |
| `supersedesDocumentId` | `string \| null` | set when a citizen replaces a reused one |

**A replacement never inherits the certification date.** It is
`reused: false`, `certifiedOn: null`, `supersedesDocumentId: <old>`. Without
that rule the natural implementation copies the record and swaps the file, and
the admin note then reads "certified «old date»" over a document uploaded
today — misinforming the officer in the exact direction the ruling protects.
Agreed with citizen-web and built on their side (#0406).

**`certifiedOn` must NEVER fall back to `uploadedAt`.** Null means NOT
RECORDED — never that the document was uncertified, and never a blank that
reads as a date. citizen-web removed such a fallback; it would have told an
officer a document was certified on the day it reached the office.

**One neutral line, agreed verbatim across both surfaces:**
"Reused from your previous permit, certified «date»". Neutral typography, never
a warning colour.

## State elsewhere, measured — read before building

- **`certifiedOn` is BUILT** (backend migration 037), nullable, exposed on
  `GET /documents/me`, `GET /applications/:id/documents` and
  `GET /staff/applications/:id`. Null everywhere on arrival by design: nobody
  supplies it yet, and telling the officer "not recorded" is a true statement
  they can act on.
- **`supersedesDocumentId` ALREADY SHIPS** — since D-8 (`18028a8`), on the
  application document list and in the recorded sample. Both citizen surfaces
  should already be reading it. This lane is not.
- **`reused` CANNOT BE BUILT TODAY, and the obstacle is structural** (#0425).
  Measured on the backend: `documents.application_id` is a SINGLE FK,
  `application_documents` does not exist, and `documents.storage_key` is
  `UNIQUE`. A document therefore belongs to exactly one application and two
  rows cannot share a stored object — so a boolean on the existing row would
  describe a relationship the schema cannot hold, and would be permanently
  false or a lie. **Do not plan around a `reused` flag until the model can
  express reuse.**

## Sequencing

Names and the affordance are **settled** (above). Backend has confirmed by
measurement (#0347, `6155e47`) that **no server-side guard rejects a reused
document on expiry** — every `expires_on` in production source is a read or a
projection, not one comparison, and no filing-refusal reason involves expiry.
Neither surface has to build around one, and neither may add the client-side
equivalent.

What blocks the build here is `reused` itself, and that is the backend's model
to change, not this lane's. `certifiedOn` and `supersedesDocumentId` can be
read and rendered now.
