# FE 02 — Retire the real resident identities from the shipped app

**Status:** complete at HEAD. History is untouched and remains an owner decision.
**Date:** 2026-08-29
**Gate:** `flutter analyze` clean · `flutter test` **539 passed**

---

## Scope correction: seven real people, not three

FE 02's mandate speaks of **three** seeded identities. Measured
(`grep -ril` across `lib/`, `test/`, `assets/`), the app carried **seven real people** across
five account records:

| Role in the app | Named in the mandate? |
|---|---|
| Pending-Review demo account | yes |
| Approved / Verified demo account | yes |
| Duplicate-of-a-Verified-identity demo | yes |
| Both-still-Pending duplicate demo (×2 records) | **no** |
| Seeded **Father** in Family Information | **no** |
| Seeded **Mother**, including her maiden name | **no** |
| Seeded **Emergency Contact** (a sibling) | **no** |

The last four are **relatives** of the verified demo identity, plus a second duplicate scenario.
A rename limited to "the three demo identities" would have left four real people's names in the
shipped app — and three of them are family members who never consented to being demo data by any
reading.

Also retired: an earlier demo identity still referenced by a migration, and a *different* real
name printed on one of the ID card images.

## What was replaced

**933 substitutions across 61 files**, plus 6 image assets and 3 test filenames.

| Category | Count | Replaced with |
|---|---|---|
| Person names (given + surname + maiden) | 7 people | invented Filipino names |
| Real constituent / household / family record ids | 8 | a `9xxx` block chosen to be self-evidently synthetic |
| Email addresses | 5 | `@example.com` — reserved by RFC 2606, can never route |
| Mobile numbers | 4 | `0918 000 90xx` |
| Birthdates | 5 | invented, same age bands |
| Profile photographs | 3 | generated initials avatars |
| Government-ID scans | 3 | generated specimen cards |
| Code identifiers (`_cristyId`, `_pumpSignedInAsCristy`, …) | 22 | scenario-named (`_verifiedDemoId`, `_pumpSignedInAsVerifiedDemo`) |
| Test filenames | 3 | scenario-named |

Renaming the **identifiers** matters as much as the strings: `_cristyId` in a test file names a
real person just as surely as a string literal does, and it is the form most likely to be
copy-pasted into new code.

### The scenarios are intact

The mandate is explicit that the scenarios are the asset. All four survive with the same field
coverage, status mix and household shape:

- **Pending Review** — registered, unverified, restricted from Dokyu/Tulong, allowed into Sakuna.
- **Approved / Verified** — full access, Digital ID wallet, complete resident profile, seeded
  Father and Mother, single-member household.
- **Duplicate of a Verified identity** — the harder duplicate case.
- **Both registrations still Pending** — the second, independent duplicate case.

539 tests pass, including every duplicate-account test.

## The artwork

`tool/demo_identity_art/generate.py`. Generated, not drawn, so it can be regenerated, reviewed
and argued with — the previous images could only be trusted.

**No synthetic faces.** A generated portrait is either derived from real people or it is uncanny,
and neither belongs in a municipal app. The avatars are initials on the app's navy. A placeholder
that looks like a placeholder is more honest than a plausible stranger.

**The ID cards are unmistakably not IDs**: a full-width diagonal `DEMO ONLY` watermark, an
explicit `SPECIMEN — DEMONSTRATION DATA — NOT A VALID GOVERNMENT ID` band, and a photo box
carrying initials rather than a face. The originals already bore a demo watermark; this keeps it
and goes further, because these render inside a screen whose entire purpose is to look like a
real submitted document.

One older project note said there was a "rule against generating new ID images", which is why a
printed-vs-profile date mismatch had been left in place. FE 02 supersedes it: the reason not to
generate ID images is that fake IDs are dangerous, and the answer is to make them obviously fake,
not to keep real ones.

## The ban test, and why its denylist is hashed

`test/no_real_identities_test.dart`.

This repository is **public**. A ban test listing the retired names in plaintext would republish
exactly the index this command exists to remove — a machine-readable roster of real residents,
sitting in `test/`, with a comment explaining that these are real people.

So the denylist stores only **SHA-256 of each lowercased token**. The test recognises a name it
can no longer state. The names live in a retired-identity record kept **outside** this
repository, which is also the source of truth if the hashes need regenerating.

It scans `lib/`, `test/`, `assets/`, `web/`, `android/app/src/main` and `ios/Runner` — both file
**contents** and file **names**, because three of the retired ID scans were named after their
subject.

### Watched failing, twice — and the first catch was mine

1. **On its first run it flagged its own source file.** The doc comment explaining the tokeniser
   used a real retired record id as the illustrative example. The test caught its author
   reintroducing a real identifier, in the test written to prevent exactly that. Fixed; the
   example is now synthetic, and the incident is recorded at the line.
2. Reintroducing a retired given name into `mock_catalog.dart` produces:

   ```
   A retired real identity has come back in:
     lib/services/mock_catalog.dart
   ```

   naming the file without printing the name.

Three anti-vacuity guards, because a scanner that reads nothing passes beautifully:

- at least 150 text files scanned, and at least 50,000 tokens checked — a broken path or pattern
  fails rather than going green;
- a canary asserting the denylist and tokeniser actually match a known retired hash;
- an **inverse** guard asserting the synthetic identities are still present, since deleting the
  demo data entirely would also satisfy the denylist.

## What the first pass missed, and how it was caught

**Running the app on a device found a real resident still shipping in it.**

FE 02 replaced three ID images and three profile photos. The **Digital ID wallet** uses four
*different* assets — `BarangayID_Front/Back.png` and `PWD_Front/Back.png` — and those were left
untouched. The result was a screen whose text layer read `Perlita Quiambao` while the card image
directly above it printed a real resident's **photograph, full name, birthdate, civil status,
address, occupation, mobile number and signature**.

Two things make this worth recording rather than quietly fixing:

1. **The source told me.** A comment in `mock_catalog.dart` named
   `BarangayID_Front.png / PWD_Front.png` as carrying the identity, in the same sentence as the
   third file I *did* replace. I read that comment during the rename and acted on part of it.
2. **The ban test cannot see pixels.** It scans text and filenames, so it went green over an
   image printing the very name it exists to deny. I had claimed it covered `assets/`; it covers
   asset *names*. That limit is now written into the test itself.

Fixed by extending `tool/demo_identity_art/generate.py` to all four wallet cards, rebuilt, and
re-verified on the device — the wallet now shows initials, no photograph, the DEMO watermark and
the SPECIMEN band. The APK dropped again, 84.0 MB → **77.2 MB**.

The lesson generalises: a text-based privacy check is necessary and nowhere near sufficient when
the data can be rendered into an image. Only a human looking at the running app closes that gap,
which is an argument for FE 03 rather than against automation.

## Acceptance

| Criterion | Result |
|---|---|
| No real person's name, birthdate, address, household id or ID-card image under `lib/`, `test/`, `assets/` | ✅ enforced by the ban test, filenames included |
| The three demo scenarios still work end to end, including the duplicate flow; suite green | ✅ **four** scenarios; 539 tests pass |
| The ban test exists, was observed failing before, and passes after | ✅ twice, once against its own author |
| The alignment spec says the demo identities are synthetic | ✅ Section 7, and `CLAUDE.md`'s privacy section rewritten |

## Guardrails observed

- **HEAD only.** No history rewrite, no force-push, none attempted. See below.
- No *different* real record was swapped in. Every replacement name is invented.
- No field was renamed while keeping the underlying photograph or scan — the images are new files
  produced by a script, not the originals relabelled.
- The duplicate-account scenarios were not deleted to make this easier. Both survive.

## Still open — owner decisions

1. **Git history.** Every retired name remains in the history of a public repository and in every
   existing clone and fork. Removing it means a history rewrite, a force-push, and treating the
   data as already fetched — with a notification obligation attached. Explicitly out of scope,
   and not attempted.
2. **`Reference_forms/`** — real residents' scanned documents, ~66 MB, untouched for the same
   reason. Note these are *not* declared assets and do not ship in the binary; they are a
   repository-contents problem, not a distribution one.
3. The retired-identity record lives outside the repo. It needs to go somewhere durable that is
   **not** this repository.
