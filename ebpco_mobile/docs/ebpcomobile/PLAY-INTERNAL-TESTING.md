# Google Play internal testing

Package: `ph.gov.castillasorsogon.ebpco`.

Use the existing eBPCO upload key if Play already has this package registered.
Do not use another app's upload key or an Android debug key. Keep the keystore
and its backup outside the repository. `android/.gitignore` excludes
`key.properties`, `*.jks`, and `*.keystore`.

Create local `android/key.properties` with these four fields:

```properties
storeFile=C:/secure/location/ebpco-upload.jks
storePassword=<local secret>
keyAlias=<existing upload alias>
keyPassword=<local secret>
```

Use forward slashes in Windows paths. Relative paths resolve from `android/`.
Release tasks fail when credentials are missing; debug builds need no upload key.

Before submission, read the highest used version code in Play Console and pick
a larger build number. Confirm the upload certificate matches Play's registered
upload certificate, and confirm the API and citizen portal URLs for this pilot.
Defaults are in `lib/core/config/app_config.dart`.

```powershell
flutter analyze
flutter test
flutter build appbundle --release --build-number=<unused code>
```

Bundle output: `build/app/outputs/bundle/release/app-release.aab`.
Upload it to the matching app's **Testing > Internal testing** release, inspect
Play's validation results, add release notes, and publish to the internal track.
Confirm availability and the existing tester group's opt-in link in the console.
Account creation or verification may need the publisher to complete it first.

The app uses system file/photo selection; it does not need broad media-library
access. Camera and autofocus hardware are optional so phones without a camera can still upload
files selected from storage.

References: [Flutter Android release guide](https://docs.flutter.dev/deployment/android)
and [Android media access](https://developer.android.com/training/data-storage/shared/media).
See also [Android hardware filtering](https://developer.android.com/develop/adaptive-apps/guides/increase-app-availability).
