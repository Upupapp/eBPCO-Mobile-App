# Teresa, Rizal Mobile — the Flutter app

This directory **is** the app. Every `flutter` command runs from here, not from the repository
root. Start with the [root README](../README.md) and [CLAUDE.md](../CLAUDE.md) for the rules,
the privacy warning, and the two-machine setup.

```sh
flutter pub get
flutter analyze          # expect: No issues found
flutter test             # expect: 461+ passed — this total is a floor, never reduce it
```

Requires **Flutter 3.47.0 / Dart 3.13.0**. The committed `pubspec.lock` is that exact
resolution, so `flutter pub get` should leave it untouched; if it changes four packages, the
toolchain is wrong.

## Layout

| Path | What is in it |
|---|---|
| `lib/screens/` | 46 screens |
| `lib/widgets/` | 41 widgets |
| `lib/services/` | 9 services — all local, no network |
| `lib/models/` | 17 models |
| `lib/theme/` | design tokens: `app_colors.dart` is a verified 1:1 port of the web platform's `app.css`; `app_status.dart` is the universal status vocabulary |
| `test/` | the suite |
| `docs/` | front-end programme deliverables (FE 01 – FE 14) |
| `TERESA_RIZAL_MOBILE_WEB_ALIGNMENT.md` | the spec and intent authority; names the Web-Admin APIs that do not exist yet |
| `Reference_forms/Placeholders/` | Blank form templates only. Named resident scans from the seed were not copied. |
| `5-icons/` | one reference-only navbar source; excluded from analysis, never built |

## Things that will surprise you

- **No HTTP client at all.** Auth, requests, notifications and the profile are simulated into
  `shared_preferences` across **10** keys. Deliberate — see the alignment spec.
- **Persisted state is version-skew hardened.** Every restore path is guarded and clears only
  its own narrowest key on failure; see `docs/FE01_PERSISTENCE_HARDENING.md`. If you add a
  service that reads preferences, guard it the same way — an unguarded read in an unawaited
  future strands the citizen on the splash forever.
- **Never invent a status label.** The vocabulary is shared with the web platform and checked
  against `origin/main` there, not against a local clone.
- **Never introduce a colour outside `lib/theme/app_colors.dart`.** The palette is shared.
