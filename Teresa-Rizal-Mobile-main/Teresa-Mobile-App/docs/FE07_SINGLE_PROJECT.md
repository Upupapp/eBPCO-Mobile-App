# FE 07 — One buildable project

**Status:** complete
**Date:** 2026-08-29
**Gate:** `flutter analyze` clean · `flutter test` 461 passed · fresh-clone transcript below

---

## What was wrong

The repository root held a **second Flutter project that could not build**: a `pubspec.yaml`
declaring four images and four font files under `assets/`, with no `lib/` and no `assets/`
directory to satisfy them. Anyone opening the repository root — a newcomer, an IDE, a future CI
job — got that one and a confusing failure. Left over from `8ea7fbe`, "Merge existing Teresa, Rizal
Mobile repository with local project".

The cost was paid entirely by newcomers, which is why it survived: people who know the repo
never open the root.

## What was deleted

Duplication verified by `md5sum` before removal, not assumed — all seven were byte-identical to
their counterparts in `Teresa-Mobile-App/`:

| File | Why |
|---|---|
| `README.md` | identical duplicate — **replaced**, not just deleted (see below) |
| `.metadata` | identical duplicate |
| `package-lock.json` | identical duplicate, and an npm artifact in a Flutter project. Content was `{"packages": {}}` — an empty package set |
| `screenshot_dokyu.png` | identical duplicate |
| `screenshot_home.png` | identical duplicate |
| `screenshot_login.png` | identical duplicate |
| `TERESA_RIZAL_MOBILE_WEB_ALIGNMENT.md` | identical duplicate. One copy now, next to the code that cites it |
| `pubspec.yaml` | the broken scaffold's own — differs from the app's, declares assets that do not exist |
| `pubspec.lock` | the broken scaffold's own |
| `analysis_options.yaml` | the broken scaffold's own |
| `teresa_rizal.iml` | root-only IntelliJ module for the scaffold; the app has no `.iml` |
| `Teresa-Mobile-App/package-lock.json` | the app-level npm artifact, same empty package set |

**Kept at the root, deliberately:**

- `.gitignore` — carries entries the app-level one does not, notably
  `/Teresa-Mobile-App/design_reference/`. The guardrail names this explicitly.
- `CLAUDE.md` — agent and contributor rules; the first thing anyone reads.
- `SWEEP_2026-08-29.md` — the current audit and its open findings.
- `README.md` — rewritten (see below).

**Not touched:** `Reference_forms/`. It contains real residents' documents and its removal is an
owner decision with a notification obligation attached. The guardrail says so and the standing
rules say so; this command did not go near it.

### Checked before deleting

`TERESA_RIZAL_MOBILE_WEB_ALIGNMENT.md` is cited by **bare filename** from eight `lib/` files, from
`CLAUDE.md`, and from `docs/USER_SIGNUP_AND_VERIFICATION_FLOW.md`. Since the citing code lives
in `Teresa-Mobile-App/`, the app-level copy is the one those references mean, so the root
copy was the safe one to drop. `CLAUDE.md` was updated to give the full path, because it sits at
the root and its reader no longer has the file beside them.

The three screenshots are referenced by **nothing** — no doc, no pubspec, no Dart source.

## The promote-to-root decision: NO

The mandate asks for a deliberate decision, recorded with its reason. The answer is **do not
promote**, for now.

`Teresa-Mobile-App/` at the repository root is the cleaner end state, and nothing about the
code argues against it. What argues against it is timing:

- **Two lanes work this one repository** — macOS owns iOS/App Store, Windows owns
  Android/Google Play. The macOS lane swept this repo the same day this command was executed.
- Promoting rewrites **every path in every open branch**. The guardrail is explicit: do not do
  it while another developer has work in flight without agreeing it first.
- The benefit is ergonomic; the cost lands on someone else's uncommitted work.

Revisit when both lanes are known to be idle and agree. It is a single `git mv` plus a README
update at that point — the deletion done here is what makes it a clean move rather than a merge
of two projects.

## The new README

The root `README.md` was the untouched Flutter template ("A new Flutter project"). It now
states what the app is, where the code lives, how to run it, and — per FE 12's concern — **how
long the gates take on each lane**, so a fast run is not mistaken for a skipped one. It also
carries the public-repo privacy warning and the Windows `MAX_PATH` cloning caveat, both of which
a newcomer hits before they hit anything else.

The app-level `README.md` was also the Flutter template; it now describes the layout and the
three things that genuinely surprise people (no network layer at all, the persistence guards,
and the two "never invent" rules).

## Acceptance

| Criterion | Result |
|---|---|
| Repository contains exactly one buildable Flutter project | ✅ root now holds only `.gitignore`, `README.md`, `CLAUDE.md`, `SWEEP_2026-08-29.md`, `Teresa-Mobile-App/` |
| Fresh clone, following nothing but the README, reaches a green `flutter test` | ✅ transcript below |
| No duplicated screenshots, metadata or lockfiles remain | ✅ |
| Promote-to-root decision recorded with its reason | ✅ above |

### Fresh-clone transcript

Cloned to a short path — the repository cannot be cloned into a deep directory on Windows
(`MAX_PATH`; longest tracked path is 210 characters, all under `Reference_forms/`). That caveat
is now in the README, because a newcomer would otherwise get a silently empty checkout that
looks like 504 deleted files.

```
$ git clone https://github.com/Upupapp/Teresa-Rizal-Mobile.git
$ cd Teresa-Rizal-Mobile/Teresa-Mobile-App
$ flutter pub get
Got dependencies!                      # pubspec.lock unchanged — the lock is reproducible
$ flutter analyze
No issues found!
$ flutter test
All tests passed!                      # 461
```

## Follow-ups this opened

1. The promote-to-root move, once both lanes agree.
2. Five root files were committed with CRLF and there is still no `.gitattributes`; a
   `* text=auto` renormalises them end-to-end. Cheaper to do now that four of those five files
   are gone — only `.gitignore` and `README.md` remain from that set, and `README.md` has just
   been rewritten anyway.
