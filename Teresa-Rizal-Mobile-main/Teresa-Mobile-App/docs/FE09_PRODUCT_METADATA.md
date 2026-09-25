# FE 09 — Product metadata

**Status:** complete for Android. The launch blocker below was **found, escalated, decided by
the owner, and closed** in the same session — the app now ships the municipal seal.
**Date:** 2026-08-29
**Lane:** Windows / Android. iOS items are flagged for the macOS lane, not guessed at.
**Verified on:** Pixel 8 emulator, Android 16 / API 36 — screenshots below

---

## Before / after

| Where | Was | Now |
|---|---|---|
| `AndroidManifest.xml` `android:label` | `teresa_rizal` | **`Teresa, Rizal`** *(snake_case fixed in `7901100`; shortened on the owner's call — see 3)* |
| `ios/Runner/Info.plist` `CFBundleDisplayName` | `Teresa, Rizal Mobile` | **`Teresa, Rizal`** — was already a real name, shortened to match Android and to stop truncating |
| `ios/Runner/Info.plist` `CFBundleName` | `teresa_rizal` | `Teresa, Rizal` |
| `web/manifest.json` `name` | `teresa_rizal` | `Teresa, Rizal Mobile` |
| `web/manifest.json` `short_name` | `teresa_rizal` | `Teresa, Rizal` |
| `web/manifest.json` `description` | "A new Flutter project." | real description |
| `web/manifest.json` theme + background | `#0175C2` (Flutter blue) | `#0B1730` (`AppColors.navy900`) |
| `web/index.html` `<title>` | `teresa_rizal` | `Teresa, Rizal Mobile` |
| `web/index.html` description | "A new Flutter project." | real description |
| `web/index.html` `apple-mobile-web-app-title` | `teresa_rizal` | **`Teresa, Rizal`** — "Add to Home Screen" is a home screen |
| `web/index.html` `theme-color` | absent | `#0B1730` |
| root + app `README.md` | Flutter template | rewritten *(FE 07)* |
| `drawable/launch_background.xml` | `@android:color/white` | `@color/teresa_rizal_navy_900` |
| `drawable-v21/launch_background.xml` | `?android:colorBackground` | `@color/teresa_rizal_navy_900` |

`CFBundleName` is capped at 15 characters by Apple's own guidance. `Teresa, Rizal Mobile` is 16, and
it is also what was measured truncating on the launcher — which is how the short name ended up
being the right answer in both places. **Bundle identifiers were not touched** —
`ph.gov.teresarizal.teresa_rizal` and `ph.gov.teresarizal.teresaRizal` are correct, and
changing one breaks store identity and existing installs.

---

## Found on the device, not in the source

### 1. The cold start flashed white — fixed

`launch_background.xml` was the untouched Flutter template: plain **white**. `SplashScreen`
paints `AppColors.navy900`. The OS draws the launch window before Flutter's first frame, so
every cold start flashed white and then snapped to navy. The app is **light-mode only**, and
`values-night` used the same white drawable, so this was not a dark-mode nicety — it was simply
the wrong colour on every launch.

Both `drawable/` and `drawable-v21/` now reference a new `values/colors.xml` entry carrying
`#FF0B1730`, with a comment tying it back to `app_colors.dart` so the two cannot drift apart
silently.

**Verified on device**: the launch window is navy. Screenshot: `splash_check.png`.

### 2. ~~LAUNCH BLOCKER~~ — RESOLVED: the app now ships the municipal seal

Measured, not inferred: `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` is **byte-identical**
(md5 `13e9c72ec37fac220397aa819fa1ef2d`) to
`flutter_tools/templates/app/android.tmpl/.../ic_launcher.png` in the pinned Flutter 3.47.0 SDK.

This is not cosmetic and not hidden. On Android 12+, the system splash centres the **launcher
icon**, so the very first thing a citizen sees on every cold start is the **Flutter logo** on
Teresa, Rizal navy. It is also the icon in the app drawer. Both screenshots show it.

Ironically, fixing the splash colour made this *more* visible: the Flutter logo now sits on a
correct navy field instead of blending into white.

**Resolved 2026-08-29.** The owner's instruction was explicit: *no Flutter logo, the LGU logo*.

Icons are now generated from the municipality's own seal with `flutter_launcher_icons`
(dev-dependency; config in `pubspec.yaml`, sources and the recipe in `tool/icon/`). One command
regenerates Android legacy + adaptive, iOS and web on either lane — nothing is hand-drawn, so
this cannot drift.

Three decisions worth recording, each measured rather than guessed:

- **White background, not the app's navy.** The seal is drawn for a light ground — a black outer
  ring around a yellow band — and on `#0B1730` the ring disappears into the background.
- **Foreground at 84 % of its canvas.** The generator adds `android:inset="16%"`, so the
  drawable paints at 68 % of the 108 dp layer. 84 % lands the seal at ~57 % of the finished
  icon: inside even a circular mask, with margin, and still legible at launcher size. The first
  attempt used 60 % and rendered the seal at ~41 % — correct, but lost in white.
- **`values-v31/styles.xml` added.** Android 12+ derives the splash from the launcher icon, and
  by default paints the adaptive **foreground alone** on the window background — which stripped
  the seal's white plate and sank its ring into the navy. Naming the full adaptive icon as
  `windowSplashScreenAnimatedIcon` puts the same white-backed seal from the launcher onto the
  navy window.

Verified on the Pixel 8 emulator: the launcher shows the seal, and the cold-start splash shows
the white-backed seal on Teresa, Rizal navy. `test/launcher_icon_test.dart` guards it — it was
watched failing by restoring Flutter's hdpi icon, which produced
`These densities still ship Flutter's logo: hdpi`. It also asserts no iOS icon carries an alpha
channel, which is an App Store rejection rule.

### 3. ~~The app name truncates on the launcher~~ — RESOLVED: the name is `Teresa, Rizal`

FE 09 asks for truncation to be checked on a small launcher. It truncates: the app drawer shows
**"Teresa, Rizal M…"**. Neighbouring apps ("Play Store", "Messages", "Calendar") fit; sixteen
characters does not.

`CFBundleDisplayName` on iOS is the same sixteen characters, so iOS will truncate the same way.

**Resolved 2026-08-29 — the owner chose `Teresa, Rizal`.** The guardrail was to confirm the wording
before setting it in three places rather than decide it here; that confirmation happened.

| Surface | Value | Why |
|---|---|---|
| `android:label` | `Teresa, Rizal` | home screen |
| `CFBundleDisplayName` | `Teresa, Rizal` | home screen — the two now match, which is the acceptance criterion |
| `CFBundleName` | `Teresa, Rizal` | already short; within Apple's 15-character guidance |
| `web/manifest.json` `short_name` | `Teresa, Rizal` | PWA home screen — this is exactly what `short_name` is for |
| `apple-mobile-web-app-title` | `Teresa, Rizal` | iOS "Add to Home Screen" is a home screen |
| `web/manifest.json` `name` | `Teresa, Rizal Mobile` | install prompt / store listing — room for the full name |
| `web/index.html` `<title>` | `Teresa, Rizal Mobile` | browser tab, not length-constrained |

Verified on the Pixel 8 drawer: **"Teresa, Rizal" renders in full**, no ellipsis, beside the seal.

`test/app_name_parity_test.dart` holds it: the two platforms must agree, the name must not be a
package identifier, it must fit the measured 13-character budget, and the *full* product name
must survive where there is room — so shortening the home-screen name cannot quietly shorten the
product everywhere. Watched failing by setting Android back to the long name, which produced
`the home-screen name differs between platforms`.

---

## Acceptance

| Criterion | Result |
|---|---|
| No default Flutter scaffold **string** is reachable by a user on any platform | ✅ all eleven replaced |
| The app name is identical on Android and iOS, verified on a device home screen | ✅ identical (`Teresa, Rizal`), renders in full on the Pixel 8 drawer and is enforced by a test. iOS home screen still not seen from this lane |
| The root README gets a newcomer to a green test run with no other input | ✅ FE 07 |
| Launcher icon and splash verified on both platforms | ⚠️ **Android done and verified** — seal icon + white-backed seal on the navy splash. iOS icons regenerated with alpha stripped, but **not built or seen on an iOS device** from this lane |

Two criteria are partially met and are marked as such rather than rounded up. The iOS half needs
the macOS lane; an emulator is also not a phone.

---

## Screenshots

| File | Shows |
|---|---|
| `splash_check.png` | **Before.** Navy launch window fixed — but the Flutter logo on the Android 12+ system splash |
| `launcher.png` | **Before.** App drawer with the Flutter icon, label truncated to "Teresa, Rizal M…" |
| `splash_seal.png` | Seal on the splash, before `values-v31` — no white plate, ring sinking into the navy |
| `splash_v31.png` | **After.** White-backed seal on Teresa, Rizal navy |
| `launcher_seal.png` | The seal in the app drawer, name still truncated to "Teresa, Rizal M…" |
| `launcher_name.png` | **After.** Seal + "Teresa, Rizal" in full, no ellipsis |

Kept outside the repository: the repo is public and already carries a real-data problem, so no
new binaries were added to it for this.

---

## Follow-ups

1. ~~Design and ship a real launcher icon~~ — **done**, see above.
2. ~~Owner decision on the home-screen name~~ — **decided: `Teresa, Rizal`**, applied and enforced.
3. **macOS lane**: verify `CFBundleName`, the iOS home-screen name and truncation, the iOS app
   icon, and the iOS launch screen. `CFBundleName` was changed here and has **not** been built
   or seen on an iOS device.
4. Confirm the icon and name on a **physical** handset — FE 03. An emulator's launcher grid is
   not every launcher's grid, and truncation is launcher-dependent.
