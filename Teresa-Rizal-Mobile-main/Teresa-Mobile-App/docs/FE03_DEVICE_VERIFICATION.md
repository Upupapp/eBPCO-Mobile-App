# FE 03 — Device verification (iOS, macOS lane)

**Date:** 2026-09-03 · **Commit gated:** `9ea3a40` · **Toolchain:** Flutter 3.47.0 / Dart 3.13.0,
Xcode 26.6, Apple M4 · **Device:** iPhone 17 simulator (1206×2622, aspect 0.460), iOS 26.

**Status: PARTIAL.** The command asks for all 46 screens on two platforms with the platform
channels exercised. What was achievable from this lane is below, and what blocks the rest is
stated precisely rather than left as "not done".

---

## 1. iOS builds — for the first time in this project's life

Spec Section 9 said the app had never been built for a device from either lane, and
`CLAUDE.md` recorded "iOS has never been built from either lane". That is now false:

```
Building ph.gov.teresarizal.teresaRizal for simulator (ios)...
Xcode build done.    36.5s
✓ Built build/ios/iphonesimulator/Runner.app
```

It installs, launches and renders. Renderer is **Impeller (Metal)**. No Flutter exception, no
assertion and no missing-asset error appears in the runtime log across four launches.

## 2. Measured: the iOS deployment target is 15.0, and 13.0 was never real

`project.pbxproj` claimed `IPHONEOS_DEPLOYMENT_TARGET = 13.0` in all three configurations. The
build **raises it itself**:

```
Updating minimum iOS deployment target to 15.0.
Upgrading project.pbxproj
Upgrading AppFrameworkInfo.plist
```

Measured rather than assumed: the value was reverted to 13.0 and the build re-raised it. So
Flutter 3.47 enforces 15.0, and the repo's 13.0 was a stale claim — **iOS 13 and 14 devices were
never supported**, whatever the project file said. This matters for a municipal app whose
audience skews to older hardware: it excludes the iPhone 6s, 7 and 1st-gen SE. It is a fact to
plan around, not a choice this lane made, and FE 11's "confirm the minimum OS against the
audience" mandate should be read against 15.0.

The raised value is committed, because otherwise every iOS build dirties the tree.

## 3. Finding — the onboarding screen letterboxes over 30% of a modern iPhone

The onboarding pages are full-bleed artwork with `BoxFit.contain` and two readability scrims.
Measured on the screenshot rather than reasoned about:

| | |
|---|---|
| Artwork | 1023×1537, aspect **0.666** |
| iPhone 17 | 1206×2622, aspect **0.460** |
| Drawn height with `contain` | 1812 px |
| **Letterbox** | **810 px — 30.9% of the screen**, ~405 px top and bottom |

Sampled pixel values down the centre line: `rgb(165,165,165)` at the top edge,
`rgb(225,225,225)` just above the artwork, `rgb(144,144,144)` at the bottom edge.

Two things follow. The letterbox is **grey, not white** — the code comment at
`onboarding_screen.dart` says the artwork is "letterboxed onto this screen's own white
background", but the top and bottom scrims (`black38` and `black45`) are drawn over the full
`Stack`, so on a tall phone they darken the *empty margin* rather than the artwork they exist to
sit over. The result reads as unfinished.

`BoxFit.contain` is itself a deliberate, well-argued choice — the comment records that `cover`
cropped baked-in messaging off the sides on an Android device. The defect is not the fit; it is
that nothing handles the margin the fit necessarily creates.

**Why no test caught it:** `flutter_test`'s default surface is 800×600, aspect **1.33**. At that
aspect `contain` fits by *height* and letterboxes at the sides instead — a different picture
entirely. The four `*_overflow_test.dart` files cannot see this, and neither could a desktop-web
preview.

## 4. Verified on device — the FE 01 persistence guard

An unreadable session payload was written into the app's own preferences via `cfprefsd` and the
app relaunched:

```
flutter: [teresa_rizal.persistence] CitizenSessionService discarded teresa_rizal_citizen_session:
         FormatException: Unexpected character (at character 2)
```

The app booted to the sign-in screen. Before FE 01 this exact state left `AuthGate` spinning
forever. This is the first time that guard has been exercised outside a widget test.

**Not verified:** whether the narrow key-clearing actually lands in the container. The read-back
is confounded by `cfprefsd` caching and by this lane's own writes to the same key. Worth
confirming properly; do not treat the clearing half as proven.

**A trap for whoever repeats this.** Seeding preferences by editing
`Library/Preferences/<bundle>.plist` directly does **not** work reliably — `cfprefsd` caches, and
`plutil -replace` silently fails on these keys because it reads the `.` in
`flutter.teresa_rizal_citizen_session` as a key path. `PlistBuddy` writes a value that reads back as
absent. The one that works is
`xcrun simctl spawn <UDID> defaults write <bundle> flutter.<key> -string '<value>'`. An earlier
run of this test appeared to pass and did not: the app was treating the key as absent rather than
undecodable, which produces the identical screen for an entirely different reason.

## 5. Verified on device — FE 02's synthetic identities

The sign-in screen renders the demo accounts as **Nicanor Sarmiento** and **Perlita Quiambao**,
with correct verification chips. The real residents' records are gone from the running app, not
just from the source.

## 6. Finding — two iOS dependencies are pinned to a branch, not a version

`Package.resolved` (now committed, both copies) pins six transitive Swift packages pulled in by
`file_picker`. Four are pinned to versions; **two track a branch**:

| Package | Pin |
|---|---|
| `DKCamera` | branch `master` |
| `DKPhotoGallery` | branch `master` |
| `DKImagePickerController` | branch `4.3.9` (a branch, not a tag) |
| SDWebImage / SwiftyGif / TOCropViewController | versions |

An iOS build is therefore not reproducible from `pubspec.lock` alone. Committing
`Package.resolved` pins the revisions and is the only thing making it reproducible today.

---

## 7. The walk is automated, and no longer needs an Accessibility grant

**Update, later the same day.** The blocker below was solved rather than waited on.

OS-level synthetic taps were the wrong tool. `integration_test` (now a dev dependency, shipped
with the SDK) drives the app **from inside its own process**, so it taps *widgets* rather than
screen coordinates. It needs no Accessibility permission, works on any machine, runs on a
simulator or real hardware, and — unlike a manual walk — lives in the repo and can be re-run.

```sh
flutter test integration_test/app_walk_test.dart -d <simulator-udid>
```

**Result: 13 screens reached, 0 problems**, in 57s on an iPhone 17 simulator:

Splash → Onboarding → Skip → Sign in → *tap the verified demo account* → Home → Balita →
Events → Emergency → Home → Drawer → Government Directory → Drawer → Help & Support.

The walk installs a `FlutterError.onError` hook, so a layout overflow on any visited screen is
recorded rather than allowed to fail the run at the first one. Zero were seen at default text
scale.

### The bug in the first version of this walk, which is the point

The first run reported reaching **Home**. It had not. It was still on the sign-in screen, and
the `visited: Home` entry came from an unconditional `visited.add('Home')` in the walk itself —
the harness asserting a screen it never saw.

Two causes, both worth knowing:

- The verified account's card sits **below the fold**. A target that is off-screen is hit-tested
  at a location nothing occupies, so the tap silently does nothing. `tester.ensureVisible` before
  every tap fixes it.
- `warnIfMissed: false` was silencing the one diagnostic that reports exactly this. It is now on,
  and a missed tap is recorded as a problem.

Both were only found because the walk dumps every `Text` on screen when a finder misses. **A walk
that records what it attempted rather than what it confirmed is worse than no walk**, because it
manufactures evidence. Screens are now confirmed by a marker only that screen renders — Home by
the nav bar, not by the tap having returned.

Also fixed: `find.textContaining('Perlita')` matched both the verified account and
"Demo: Duplicate Perlita Account". The exact full name is the correct finder.

## 8. The walk now covers 48 destinations — and found a real defect

Extended across the drawer, the centre "+" launcher and the notifications bell.

**48 destinations reached, 0 problems**, in 2m56s. That is every bottom-nav tab, every one of
the nine drawer destinations (Profile, Settings, My Requests, Transactions, Digital ID,
Documents Uploaded, Government Directory, Help & Support, Privacy Policy), notifications, and
both service flows through their request list into the catalogue.

### The defect it found: four controls with no feedback under the finger

The walk reported, four times on the Settings path:

```
ListTile background color or ink splashes may be invisible.
```

Four errors, and Settings has exactly four tiles — two notification switches and two language
radios. Root cause in `widgets/app_card.dart`: `AppCard` wrapped itself in a `Material` **only
when it had an `onTap`**. A non-tappable card gave its children no `Material` ancestor, so a
`ListTile` inside one had nowhere to paint ink.

For a citizen that means the notification toggles and the language radios changed value with
**no ripple and no highlight at all** — controls that look dead while working. On a government
app whose audience includes people who need clear affordances, that is not cosmetic.

Fixed by wrapping the card's child in `Material(type: MaterialType.transparency)`, which paints
nothing itself, so the card's own fill, border and shadow are untouched. `AppCard` is used
throughout the app, so this repairs every non-tappable card containing a tile, not just Settings.

**Why 584 passing widget tests never saw it.** This is a *painting* fault. It needs a real
render pass on a device; a pumped widget tree does not paint ink. The device walk found it on
its first extended run.

Regression coverage: `test/app_card_material_test.dart`, 3 cases, break-checked — all 3 fail
without the fix, including one asserting the Material stays `transparency` so the card's own
decoration is not quietly taken over.

### Two navigation facts the walk had to learn

Both cost a run each, and both are now encoded in the harness:

- **The bottom nav swaps the shell's body; it does not push a route.** `pageBack()` does not
  undo a tab change, and the drawer button only exists on Home — so every drawer destination
  starts with an explicit return to Home.
- **One `pageBack()` is not enough.** Some destinations are pushed routes, some replace the
  body, some go two deep. `_popToShell` pops until the nav bar is visible again. Before it
  existed, a single failed pop left the walk on the wrong screen and reported *every* later
  destination as missing — 10 false "NOT REACHED" entries from one real problem.

## 9. The core product journey now completes on a device

The walk previously stopped at the service catalogue, which is the point at which nothing
interesting has happened yet. The wizard is where the forms, the validation, the requirement
attachments and the submission live — and it is the only part of this app a citizen actually
has to get through.

**62 destinations, 0 problems**, 3m55s. The added leg:

`"+" launcher → Dokyu → New Request → LGU / Municipality → MSWDO → Certificate of Indigency →
wizard steps 1-3 → attach both requirements → Submit Request → confirmation`

A **free** service is used deliberately: a paid one diverts through a payment step whose
"Confirm Payment" button is a different flow that deserves its own pass.

### What the first attempt found, and why it was right to stall

Before the Master File was seeded, the walk got four steps in and stopped:

```
WIZARD STALLED at step 4 — Continue did not advance.
On screen: Step 3 of 4 | Requirements | ... |
Please attach: One (1) valid government-issued ID, Barangay Certification of Indigency.
```

That is the app behaving **correctly** — submission is gated on the required documents. It is
recorded here because "the walk cannot finish" and "the app is broken" look identical in a
summary line, and the difference is the whole point of the stall detector.

### How it gets past it without a file picker

Attaching normally means the platform file picker, which no automated walk can drive. But the
uploader already offers **"Use Existing Document"** when the resident's Master File holds a
document of the matching type — the path a returning citizen takes. So the walk pre-files the
two required documents and takes that path. This covers a real journey rather than inventing a
shortcut around the validation.

The fixture is built from the app's own data, never hand-copied:

- the service is looked up by key from `MockCatalog.documentTypes`;
- the document types come from the app's own `resolveRequirements()` applied to the
  catalogue's own requirement text;
- the account id is `MockCatalog.demoAccounts.last.id`, not a pasted string.

So a change to the catalogue's requirements, to the type resolver, or to the demo identities
shows up here as a **stalled wizard** rather than as a fixture that silently no longer matches
anything. This is the same rule the unit tests learned the hard way earlier in this programme:
build fixtures from the model, so drift breaks the test instead of hollowing it out.

## 11. Correction — "62 destinations, 0 problems" counts taps issued, not effects verified

**Recorded against my own earlier claim in this document.** The walk's `_tapIfPresent` treated a
tap as successful whenever `tester.tap` did not throw. It does not throw when a tap lands on a
widget that ignores it, so a control that is present and inert is counted as a visited screen.

A prototype that verified each tap by comparing the screen **before and after** found at least
one reproducible case across three runs:

> `Dokyu → New Request` and `Tulong → New Request` — exactly one match, the FAB is on screen, and
> two taps change nothing. The **same finder taps the same control successfully later in the same
> run** during the wizard leg.

### RETRACTED — that is not an app defect

Chased down and disproved. `test/new_request_fab_reachability_test.dart` pumps the request list
and taps the FAB after **a single frame** — no warm-up, exactly the citizen who taps the moment
the screen appears — and it opens the catalogue. For both Dokyu and Tulong.

The leading explanation was also wrong and is kept in that file rather than deleted: RootShell
holds Dokyu and Tulong in an `IndexedStack`, so the guess was that two FABs exist and
`finder.first` taps the off-screen one. Measured — finders skip offstage widgets, so exactly one
is found, which matches the walk's own `Matches: 1`.

**So the button is fine and the walk's report is a harness artifact.** Its mechanism was then
explained by the **web lane**, which hit-tested the failing taps independently and recorded the
result in `HANDOFF_FROM_WEB_LANE.md` §2:

| Tap | What the hit test found instead |
|---|---|
| "Balita" / "Emergency" (bottom nav) | `AbsorbPointer` / `IgnorePointer` / `_RenderTheater` |
| "New Request" | a **`RenderImage`**, at a different offset entirely |

So the taps are being **intercepted**, not ignored — an overlay or a full-bleed image sits over
the controls. They also found why the run aborts before printing: `warnIfMissed` reports a miss
through `FlutterError`, which this walk redirects in order to collect layout errors, so the
framework believes the test is already failing and kills it. That redirect has to be fixed first;
until the report survives, nothing else about the walk is measurable.

Worth stating plainly: two lanes reached the same place from opposite directions, and the one that
did **not** write the harness found the mechanism. That is the argument for the handoff files. It is recorded here as an open question about the harness, not as a defect in the
app, because reporting a working control as broken is the more expensive mistake: it sends the
other lane to fix something that is not wrong.

**The prototype is not shipped**, and the reason is itself worth recording. Its detector produced a
**false positive** on the paid wizard: it reported `Barangay Clearance` as having had no effect
while the dump printed `Step 1 of 5` — the wizard was open. A pushed route whose text overlaps the
route beneath can read as "unchanged". Raising the settle window to 4s did not help, so it is not
timing. Making the detector non-aborting instead pushed the run past the ten-minute mark.

So the honest position: **the 62 figure is an upper bound.** It is the number of taps issued along
a route that completes, not the number of screens proven to have rendered. The confirmations via
`_confirm` (a marker only that screen renders) are the trustworthy part; the raw `visited` count is
not. Do not quote 62 as verified coverage.

Preserved out-of-repo at `/Users/user/teresa-rizal-fe14-wip/app_walk_test.STASHED-60-25.dart` (macOS
lane): the paid-service branch, the effect detector, and the tap retry. The paid branch itself
**works** — it reached `Step 1 of 5`, one step more than the free service, which is the payment
step. It is the detector around it that is not trustworthy yet.

## What is blocked, and on what

**Superseded — see section 7.** 13 of 46 screens are now walked automatically. The remaining 33
are flows behind a form or a wizard step; extending the harness to them is ordinary work now that
it exists, not a blocked task.

Still genuinely unverified:

- Camera capture, gallery pick, document pick (PDF/DOCX)
- All three permission outcomes — grant, deny, permanently-denied — including
  `protected_action.dart`'s two distinct dialogs, which no permission system has ever triggered
- `tel:` links, the Google Maps launcher, and all five share targets
- Keyboard behaviour on the wizard and registration forms
- **200% text scale (FE 05).** Attempted and not working: a second `testWidgets` has to call
  `app.main()` again, and a second `runApp` in one process hangs — two attempts were killed at
  ten minutes with no output. The fix is a separate entry point that pumps the tree under a
  `MediaQuery` rather than re-running `main()`. Deliberately **not** shipped as a skipped test,
  because a skipped test reads as a passing one in the summary line.

**Android was not attempted from this lane.** The Windows lane owns Play and has already built a
release APK; duplicating it here would prove nothing new.

**No longer blocked on a permission.** Extend `integration_test/app_walk_test.dart`.

---

## 10. Finding 3 is closed — verified on device, not assumed

The Windows lane rebuilt onboarding (`fb4ee65`) in response to the letterbox measurement in
section 3, and went further than the finding did: it also caught that page two advertised
**"Business Permit · Approved"** — an outcome this app cannot produce, since there is no backend
and nothing approves anything — and that the empty grey panel visible in the original screenshot
was a control mocked up in the artwork and never built.

Re-measured on the same iPhone 17 simulator after merging, by sampling the centre column of a
fresh screenshot:

| | Before (`37d4068`) | After (`22e3af6`) |
|---|---|---|
| Flat-grey letterbox rows | ~31% of the screen | **0 of 262 sampled** |
| Bottom edge | `rgb(144,144,144)` grey | `rgb(9,17,38)` — navy-950, full bleed |
| Headline | baked into a 1.4 MB PNG | real `Text`, scales and reaches a screen reader |

The walk was re-run against the rebuilt onboarding before this was accepted: **62 destinations,
0 problems**, unchanged. That is the point of having the walk in the repo — the other lane can
replace the first screen of the app and this lane can confirm in four minutes that nothing
downstream broke.

Merged result gated at `22e3af6`: analyze clean, **615 tests** (587 + 28 from their onboarding
suite).
