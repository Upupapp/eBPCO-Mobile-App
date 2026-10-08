# Android internal-testing sweep — 7 October 2026

Source: `Upupapp/eBPCO-Mobile-App`, remote main at
`e608a3e181647be97031c74349bbb28199f790d6`.

## Verified

- Flutter 3.47.0 / Dart 3.13.0, Android SDK available.
- `flutter analyze`: no issues.
- `flutter test`: all 82 tests passed.
- Android bundle compilation completed (64.0 MB); certificate inspection
  confirmed the original configuration used `CN=Android Debug`.
  This diagnostic bundle is not suitable for Play upload.
- After the signing fix, `flutter build appbundle --release --no-pub` fails
  explicitly when `android/key.properties` is absent, as intended.
- `flutter build apk --debug --no-pub` succeeds without upload credentials.
- Merged release manifest targets Android API 36, contains no broad media
  permissions, and marks camera hardware optional.
- Signing properties, keystores, and Kotlin build caches are ignored by Git.

## Fixed

- Release signing reads the existing upload key from local properties instead
  of falling back to debug signing. Missing credentials stop release tasks.
- Removed `READ_MEDIA_IMAGES`: gallery and document uploads use system pickers.
  The installed image picker implementation uses photo-picker / `GET_CONTENT`
  intents, and the file picker uses system content selection.
- Added optional camera and autofocus hardware to avoid excluding devices that can upload
  documents but do not have a camera.
- Added the [internal-testing runbook](PLAY-INTERNAL-TESTING.md).

## Submission blockers

- The previously open publisher account (`5143238911617930399`) hits
  `ERR_TOO_MANY_REDIRECTS` at Google sign-in.
- The reachable UpUp Technologies account (`5088446055149648531`) has no apps
  and disables app creation pending identity, website, and phone verification.
- The eBPCO upload keystore and matching local signing properties were not
  supplied. The correct key must be matched against Play's upload certificate
  before building and submitting; an unrelated app's key is not a substitute.
- Existing Play version codes and tester configuration cannot be checked until
  the correct publisher account is accessible.

No Play release was uploaded or submitted. No authenticated device journey was
performed; automated tests and Android compilation do not establish live API,
camera, or notification behavior on a handset. AGP/Kotlin emit future-support
warnings; the current pinned toolchain nevertheless compiled successfully.
