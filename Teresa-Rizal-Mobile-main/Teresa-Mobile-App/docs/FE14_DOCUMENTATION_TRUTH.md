# FE 14 — Documentation truth

**Status:** complete for the commands executed in this pass (FE 01, 04, 07, 08, 09). The
remaining commands will each carry their own spec updates.
**Date:** 2026-08-29
**Gate:** `flutter analyze` clean · `flutter test` 466 passed

---

## The rule this command really encodes

The alignment spec is good, and that is precisely why its drift matters: people trust it. Four
of its statements were wrong, and each one was wrong in the same way — it had been **true when
written** and nobody re-measured it.

So the fix is not a rewrite. Its structure and voice are unchanged. What changed is that every
claim which is a *measurement* now carries the date it was measured, and a note at the top says
how to read an undated one:

> A claim without a date is either structural — it describes intent, not a fact about the code —
> or it has not been re-measured since 2026-08-11 and should be treated as inherited rather than
> verified.

That is the difference between a document that ages honestly and one that quietly becomes
fiction.

## Corrections made

| Claim | Was | Now | By |
|---|---|---|---|
| Status list, Section 1 | 14 labels incl. `Ready for Release`, `Waiting Requirements` | the 17 canonical, each rename dated | FE 04 |
| Dokyu flow, Section 5.1 | `Waiting Requirements` → `Ready for Release` | `Under Review` → `Mark to Release` | FE 04 |
| Tulong flow, Section 5.2 | `Waiting Requirements` | `Under Review` | FE 04 |
| Admin actions, Section 5 | `Ready for Release` | `Mark to Release` | FE 04 |
| `app_status.dart` header | "the exact 14 status names" for a 15-value enum | no count restated; points at the parity test | FE 04 |
| Component map, Section 1 | `attachment_picker.dart` "real device picker, not a mock" | `requirement_uploader.dart` | FE 08 |
| Capability note, Section 9 | `attachment_picker.dart` provides camera/gallery/PDF | `requirement_uploader.dart` | FE 08 |
| Device verification, Section 9 | "no Android SDK cmdline-tools configured", never built | builds and runs on Android; physical hardware and iOS still owed | sweep |
| Colour parity, Section 1 | undated "exact hex from `app.css`" | "verified matching 2026-08-29", plus the `sky-*` addition and why it is not an invention | FE 04 |
| Doc date | 2026-08-11 | 2026-08-29, with the how-to-read-dates note | FE 14 |

The `app_status.dart` header deliberately **no longer states a count at all**. The old one said
"the exact 14" for a 15-value enum — a restated count invites exactly that failure. It now
points at `test/status_parity_test.dart`, which cannot go stale silently.

## `CLAUDE.md`

It did not exist when the master command was written; `app_status.dart` cited it as the
authority for the status vocabulary and a fresh clone had no rules file. It was committed at
`7368c19` and has been kept in step through this pass — the removed root scaffold, the two-lane
setup, the per-lane gate timings, the status drift including `Verified`/`Unverified`, and the
instruction to check the vocabulary against `origin/main` rather than a local clone.

## Analyzer exclusions

- The `5-icons/**` comment pointed at `lib/widgets/magnetic_navbar_core.dart`, **which does not
  exist**. Rewritten to describe the file that is actually there.
- `design_reference/**` is **kept**, against the letter of the acceptance criterion, with the
  reason recorded in the file. It is gitignored, so it is absent from a fresh clone — but
  excluding an absent directory costs the analyzer nothing, while removing the entry would
  silently break analysis for anyone who does pull that reference copy down. The stale thing was
  the *comment*, and that is fixed.

## Stray files

**`Pushing Notes` — deleted.** It was one developer's personal shell history, opening with
`cd "C:\Users\ASUS TUF\Desktop\Teresa, Rizal\Teresa-Mobile-App"`. It published a local machine
path and a username to a public repository and taught `git add .` as the workflow. The root
`README.md` now has a real contributing section (FE 07), which is what the mandate asks for.

**`5-icons/` — kept**, with the decision recorded here rather than left implicit. It is a single
73-line reference file whose imports (`../core/magnetic_navbar_core.dart`,
`../core/nav_item_data.dart`) do not resolve in this repo, so it cannot compile and is excluded
from analysis. It was added deliberately as a design reference, it ships in nothing, and
deleting reference material on the grounds that it is not built has no upside. Worth revisiting
only if it is ever mistaken for live code.

## Acceptance

| Criterion | Result |
|---|---|
| No statement in the alignment spec is contradicted by the code | ✅ for everything FE 01/04/07/08/09 touched |
| Analyzer exclusions all refer to paths that exist | ⚠️ `design_reference/**` deliberately retained — reason recorded above and in the file |
| Every measured claim in the spec carries a date | ✅ for claims corrected in this pass, plus a note explaining how to read undated ones |
| `CLAUDE.md` reflects the state after this programme | ✅ for the commands executed |

One criterion is marked partially met rather than rounded up. Removing the `design_reference`
exclusion would satisfy the letter of it and make the repo slightly worse.

## Guardrails observed

- The spec was **not** rewritten. Structure and voice are unchanged; corrections are inline and
  dated.
- **Section 5's missing-API list is untouched.** It is the handover to the backend developer and
  the most valuable page in the document.
- No claim was marked verified on the grounds that it was true when written.

## Follow-ups

1. FE 02, 03, 05, 06, 10, 11, 12, 13 each still owe their own spec updates — in the same commit
   as the change, per this command's own mandate, not as a later pass.
2. Section 9's remaining compatibility claims (minimum OS versions, plugin behaviour) are still
   inherited from 2026-08-11 and undated. They need a device pass (FE 03) before they can carry
   a date honestly.
