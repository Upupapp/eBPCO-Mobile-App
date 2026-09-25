# FE 08 — Reachability

**Status:** complete
**Date:** 2026-08-29
**Gate:** `flutter analyze` clean · `flutter test` **456 passed** (see the arithmetic below —
the reduction is the authorised one, not a masked failure)

---

## Import-graph result

Reproduced independently rather than taken from the master command. Walking relative
`import`/`export`/`part` directives transitively from `lib/main.dart`:

| | |
|---|---|
| Dart files under `lib/` | 134 |
| Reachable from `main.dart` | 133 |
| **Unreachable** | **1** — `lib/widgets/attachment_picker.dart` |

The check was **watched failing** against the code as it stood, printing exactly that one path,
before anything was changed.

## The `AttachmentPicker` decision: DELETE

The mandate requires a decision — wire it or delete it, never leave it in the third state. The
evidence supports deletion on three independent counts:

1. **The capability was never missing, only misattributed.** `RequirementUploader` offers the
   same three sources through the *same* helpers — `pickImageProtected` for camera and gallery,
   `pickDocumentProtected` for documents. Nothing a citizen can do is lost.
2. **A live test already asserted its absence.** `dokyu_requirement_uploads_test.dart` contained
   `expect(find.byType(AttachmentPicker), findsNothing)` — the suite was documenting that the
   shipping screen deliberately does *not* use it.
3. **Wiring it in would have been worse.** There is no screen that needs a second uploader.
   Adding one to satisfy a reachability check changes the product to please a test.

318 lines of widget, plus its 7 dedicated tests, removed.

### The five permission tests were re-hosted, not deleted

`protected_action_test.dart` used `AttachmentPicker` only as a **host** — its actual subject is
the permission explanation dialogs in `utils/protected_action.dart`. Those 5 tests now host on
`RequirementUploader`.

This is a strict improvement, and it is the point of the whole command: those tests previously
proved the permission dialogs behaved correctly **inside a widget no citizen could open**. If
the shipping uploader had wired the camera message to the document action, they would not have
noticed. They now exercise the widget Dokyu and Tulong actually render, through its real
per-requirement entry point (`Upload Valid ID`, not a generic `Add photo or document`).

The sheet labels differ between the two widgets — `Take Photo` / `Choose Image` /
`Choose File / PDF` rather than `Take a photo` / `Choose from gallery` /
`Choose a document (PDF/DOCX)` — which is itself evidence the tests had drifted from the
shipping UI. The permission dialog strings are shared and unchanged.

### Suite arithmetic, stated plainly

```
461  before FE 08
 -7  attachment_picker_test.dart, deleted with the widget it tested
 +2  reachability_test.dart (import graph, asset declarations)
----
456
```

The standing rule is *never reduce the suite total to go green*. This reduction is not that: the
7 tests exercised code that no longer exists, and FE 08's own guardrail requires exactly this —
"if the widget goes, its test goes with it, in the same commit, with the reason in the message."
Nothing was skipped, nothing was marked pending, and no failing test was removed. 456 still
clears the programme's stated floor of 450.

## The repeatable check

`test/reachability_test.dart`, not a script under `tool/`.

**Why a test:** there is no CI in this repository, so `flutter test` is the only thing that
actually runs. The guardrail says "it fails the gate or it is not a check" — and the only gate
here is the suite. A script in `tool/` would have joined `flutter analyze` as something a
developer has to remember.

It contains two checks:

1. **Every file under `lib/` is reachable from `main.dart`**, with a documented allowlist —
   currently **empty**, which is the desired state. An allowlist entry is a promise that a file
   earns its place another way, never a way to silence the check.
2. **Every asset declared in `pubspec.yaml` exists on disk.** All 37 currently do.

Two anti-vacuity guards, because a reachability check that examines nothing passes beautifully:

- The file count must exceed 100, so a path bug cannot turn "zero unreachable" into "zero
  examined". This is the `Executed 0 of 0 reads as a pass` failure mode in another costume.
- Every allowlist entry must still actually be unreachable, so a stale allowlist fails rather
  than quietly lying about a file that is gone or has since been wired in.

### Known limit, stated rather than glossed

**Import-reachability is not user-reachability.** A widget can be imported by a live screen and
still sit behind a condition nobody can satisfy. Only the FE 03 device walk catches that. This
test proves the weaker property because it is the one that can be automated — that is a reason
to run it, not a reason to claim more from it.

The walk also ignores `package:teresa_rizal/` self-imports, since this codebase uses
relative imports inside `lib/`. Noted at the call site as the line to revisit if that convention
changes.

## Asset audit

The master command reports two asset discrepancies as of its measurement:
`assets/images/Logo/labangtaytay-seal.png` declared but unreferenced, and
`assets/images/teresa-rizal-seal.png` present but undeclared while a `Logo/` variant was used.

Measured now: **all 37 declared assets exist**, and that direction is enforced by the new test.
The reverse direction — files present on disk but undeclared — is *not* enforced, deliberately:
`assets/` legitimately holds working files that are not meant to ship, and failing the gate on
those would train people to ignore it. Flagged as a follow-up for a human pass rather than
automated badly.

## Spec corrections

The alignment spec named `attachment_picker.dart` as the shipped component in two places:

- **Section 1** (component map row for `ui/file-picker.blade.php`) — "real device picker, not a
  mock".
- **Section 9** (platform capability notes) — named it as the provider of camera, gallery and
  PDF upload.

Both now name `requirement_uploader.dart`, each with a dated inline note saying what was
corrected and why, so a reader can tell a fix from an inheritance.

## Acceptance

| Criterion | Result |
|---|---|
| Zero unreachable files under `lib/`, or an allowlist with a written reason per entry | ✅ zero, allowlist empty |
| The check runs as part of the standard gate, observed failing against today's code | ✅ ran red on `attachment_picker.dart` first |
| Asset declarations and asset files agree | ✅ forward direction enforced; reverse direction is a documented follow-up |
| The spec names the components that actually ship | ✅ Sections 1 and 9 corrected |

## Follow-ups this opened

1. Undeclared-but-present asset files — needs a human pass to separate working files from
   shipping ones before it can be automated.
2. Navigation reachability (every route reachable by a user action, not merely imported) is a
   manual pass during FE 03's device walk. Not automatable here.
