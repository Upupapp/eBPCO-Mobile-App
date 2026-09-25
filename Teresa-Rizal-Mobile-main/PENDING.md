# Teresa, Rizal Mobile — pending register

> **Cross-lane:** `HANDOFF_FROM_WEB_LANE.md` answers the web lane's sweep — the
> device walk aborts for a **harness** reason (not the onboarding rebuild), and
> `rectangle_cityhall.jpg` was the LGU sign-in hero on the web side and is fixed
> there. Read it before the next mobile push.


Every unfinished item, with **why** it is unfinished. Updated 2026-09-25 (macOS lane).

This exists because a tracker held only in a chat session is lost when the session ends, and
this repository is worked by two lanes that cannot see each other's terminals. If you finish an
item, move it to **Done** with its commit — do not delete it, so the arc stays visible.

---

## Blocked on the owner — do not attempt

| # | Item | Why it is blocked |
|---|---|---|
| 1 | **Public-repo PII — git history** | `Reference_forms/` holds real residents' scanned documents, and every retired real identity is still in the history of a repo that **was public** (private since at least 2026-09-25) and in every existing clone and fork. FE 02 fixed HEAD only. Removing it means a history rewrite, a force-push, and treating the data as already fetched. That is an owner decision with a notification obligation attached. |
| 2 | **Release signing** (FE 11) — **iOS resolved 2026-09-25, Android still blocked** | iOS: the owner chose UPUP TECHNOLOGIES PTE. LTD (`2K2SF7NRQP`); set on every target, with `ios/ExportOptions.plist`, in `97138af`. Android `release` still signs with the **debug** keystore; that needs the owner's upload key. |
| 20 | ~~App Store Connect app record~~ — **DONE 2026-09-25** | App *Teresa, Rizal*, Apple ID `6816007380`, SKU `teresa-rizal-mobile`, team UPUP. Build 1.0.0 (1) from `605c8ca` uploaded via `xcodebuild -exportArchive` (destination `upload`, Xcode's UPUP account). Internal group **Teresa Demo** (automatic distribution), tester: the Account Holder. Next build: bump `version:` in `pubspec.yaml` (build number must be unique). **Blocker to watch:** the updated Developer Program License Agreement is unaccepted, and only the Account Holder can accept it; it blocks App Store submission, not internal TestFlight. |

## Ready to start — nothing blocking

| # | Item | Notes |
|---|---|---|
| 21 | **G2 hub goldens are stale — Cursor (Linux) lane** | `test/goldens/01..04-*.png` predate Cluster 6: `02-balita-comments` still shows the old card and an empty comments sheet while the app renders seeded comments (37–57% pixel diff). Re-record them on the Linux agent with `flutter test --update-goldens test/g2_hub_shots_test.dart`. Since `c6e3075` the pixel compare runs on Linux only (macOS rasterises Inter ~6% differently on identical frames), so **only the Linux agent will see this fail**. |
| 22 | ~~Is the repo public or private?~~ — **DONE 2026-09-25** | Owner: **PRIVATE**. `CLAUDE.md` corrected; the privacy rules stay, because the history was public. |
| 14 | **Paid-service wizard flow** | **In progress, not shipped.** The branch is written and demonstrably enters the paid wizard (`Step 1 of 5` — one step more than the free service, i.e. the payment step), but the walk's tap-effect detector false-positives on it and aborts before submission, so the receipt is still unwalked. Work preserved at `/Users/user/teresa-rizal-fe14-wip/app_walk_test.STASHED-60-25.dart` (macOS lane). See §11 of the FE 03 deliverable. |
| 18 | ~~"New Request" is inert on first arrival~~ — **RETRACTED, not an app defect** | Disproved by `test/new_request_fab_reachability_test.dart`: the FAB opens the catalogue after a single frame, for both Dokyu and Tulong. The IndexedStack "two FABs" theory was also wrong — finders skip offstage widgets, so only one is found. What remains is an **unexplained harness artifact** in the device walk, folded into item 19. Do not go looking for a bug in the button. |
| 19 | **The walk's coverage figure is an upper bound, and something absorbs its taps** — *2026-09-25: its 12 NOT REACHED entries are walk drift, not app defects. `test/menu_and_services_reachability_test.dart` proves all 9 menu screens, both Services catalogues and Start request open. The walk still looks for a "Menu" tooltip (Home opens the menu from its avatar) and cannot return from the pushed Notifications screen. Owner: no integration work on this screens-only app, so the walk is left as is.* | `_tapIfPresent` counts a tap as a visit whenever `tester.tap` does not throw — which it does not when a tap lands on an inert widget. The `_confirm` markers are trustworthy; the raw 62 is not. **The web lane independently hit-tested the failing taps** (`HANDOFF_FROM_WEB_LANE.md` §2) and found the cause is pointer interception, not dead controls: the nav taps land on `AbsorbPointer`/`IgnorePointer`/`_RenderTheater`, and the "New Request" tap lands on a **`RenderImage`** at a completely different offset. An overlay or a full-bleed image is sitting over the controls. They also diagnosed the run's abort: `warnIfMissed` reports through `FlutterError`, which the walk redirects to collect layout errors, so the framework kills the run before it prints. **Fix the redirect first** — everything else is unmeasurable until the report survives. |
| 15 | **Tulong wizard end to end** | Only Dokyu is walked to submission. Tulong reaches its request list and catalogue only. |
| 16 | **Remaining wizard breadth** | 62 destinations are walked. Registration, the resident-profile sub-screens (family, household, review, submission confirmation), report-a-problem and the Sakuna incident flow are reached shallowly or not at all. |
| 17 | **Backend Master Command** | Offered, not started. Spec Section 5 already enumerates the missing Web-Admin APIs; the front-end contract from FE 13 would feed it. |

## Deferred by decision

| # | Item | Decision |
|---|---|---|
| 12 | **FE 05 — 200% text-scale walk** | **Cancelled by the owner, 2026-09-03.** Reverted; nothing shipped. The technical blocker *was* solved before cancelling: a second `runApp` in one process hangs, but pumping `TeresaRizalMobileApp` directly avoids `runApp`, and `platformDispatcher.textScaleFactorTestValue` propagates. One run reached 44/48 destinations with **no layout overflows** — the 2 misses were drawer entries pushed below the fold by the larger text, unconfirmed. Restorable in one commit if revisited. |
| — | **`Waiting Requirements` status** | Mobile carries a status that appears in **zero** files on the current web platform. Inert (migrated to `Under Review` on load) and marked `PENDING OWNER DECISION` in `test/status_parity_test.dart`. Recommendation: retire it. Not this lane's call. |

## Known and accepted, worth not rediscovering

- **The pre-push gate must be installed by hand** (`sh scripts/install-hooks.sh`). Git does not
  version `.git/hooks`, so a fresh clone has no gate and nothing says so — the push just
  succeeds. Mitigated by putting the command in `CLAUDE.md`, which agents load automatically;
  not eliminated. Raised by the backend lane (bus #0004) after losing exactly this way.


- **`ServiceRequest.fromJson` scalars.** `statusHistory` and `attachments` now default, but required
  non-null scalars (`expectedDays`, `fee`, `office`, …) still throw per record if absent. Entry-tolerant
  decoding contains the blast radius to one record; the asymmetry is not closed.
- **`PersistenceRecovery` narrow-clearing is unverified on device.** The guard demonstrably fires and
  logs, but whether the key removal lands in the container was confounded by `cfprefsd` caching.
- **`NotificationsService` clears three keys at once** because it restores all three under one `try`
  and cannot tell which failed. Noted at the call site by the Windows lane as a follow-up.
- **Two iOS Swift packages track branch `master`** (`DKCamera`, `DKPhotoGallery`, via `file_picker`), so
  `Package.resolved` is the only thing making an iOS build reproducible.

## Done this programme

FE 01 persistence hardening (both lanes merged) · FE 02 synthetic identities · FE 03 iOS build +
62-destination automated device walk · FE 04 status parity · FE 05 partial · FE 06 design tokens ·
FE 07 single project · FE 08 reachability · FE 09 product metadata · FE 10 data at rest ·
FE 12 gate ergonomics · FE 14 documentation truth · the fabricated-enum ruling (`a10a3fc`) ·
unguarded list casts (`9ea3a40`) · `AppCard` ink fix (`1426035`) · onboarding rebuild verified
closed on device (`904cc5d`).
