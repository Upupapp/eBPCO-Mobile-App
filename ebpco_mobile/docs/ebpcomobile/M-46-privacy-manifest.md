# M-46 — the iOS privacy manifest

*Written 30 August 2026 in `eBPCO-Mobile-App`. Front-end only, iOS lane. Every
figure below was read from source, not estimated.*

---

## The premise the register was written on was too pessimistic

M-46 was filed as *"Owner + legal: what is collected, for what purpose, and
whether it is linked to identity"*, on the reasoning that
`NSPrivacyCollectedDataTypes` is a claim about what the LGU collects and a
guess would be a misrepresentation.

That reasoning is right about **guessing** and wrong about **measuring**.
Apple's question is narrower than the register assumed: not *what does the LGU
hold* but **what does this binary transmit off the device**. That is a fact in
`lib/core/repositories/http_*.dart`, and nobody had read it.

It is now read, and the manifest is written from it.

## What the app actually transmits

Every key inside a `body: {…}` in the HTTP repositories, and nothing else —
because a wizard holds far more than it sends.

| Sent | Where from | Apple data type |
|---|---|---|
| `firstName`, `lastName` | `POST /auth/register` | Name |
| `email` | `/auth/register`, `/auth/token` | Email Address |
| `mobileNumber` | `POST /auth/register` | Phone Number |
| `street`, `barangay`, `city`, `province` | `POST /businesses` | Physical Address |
| the account and its bearer token | every authenticated request | User ID |
| `password`, business `name` / `category`, `permitType`, `applicationAction`, `method`, `referenceNumber`, and document `label` / `fileName` | registration, submission, payment | Other Data Types |
| `grantType` | `POST /auth/token` | *not personal data* — the literal string `"password"`, naming the OAuth grant |

All of it is **linked** to the applicant: it travels under an account the LGU
issued and can trace to a named person. None of it is used for **tracking**.
Every purpose is **App Functionality** — this is a permit application, and the
office cannot act on one without knowing who filed it.

### The finding inside the finding

**No file bytes leave the device.** The app sends a document's *label and
filename*; the separate upload flow is not built, so a scan of `lib/core` for
`MultipartRequest`, `MultipartFile` and `readAsBytes` comes back empty.

So the manifest declares **no** photo or user-content collection — because
declaring it would be a false statement in the other direction, and Apple's
question is about what the app does, not what it will do. But this is exactly
the entry that goes stale first, so the day an upload path appears the guarding
test fails and names the two constants to add.

## The two empty arrays, which are the easiest thing to get wrong

**`NSPrivacyTrackingDomains` is empty and `NSPrivacyTracking` is false.** There
is no advertising, attribution or analytics SDK in `pubspec.yaml`, no IDFA
access anywhere, and one host: the LGU's own API.

**`NSPrivacyAccessedAPITypes` is empty, deliberately.** Apple requires the
binary that *calls* a required-reason API to declare it. The app's own native
code is two files — `AppDelegate.swift` and `SceneDelegate.swift` — and neither
touches UserDefaults, file timestamps, disk space, boot time or active
keyboards. The Dart layer reaches those APIs only through plugins, and **every
plugin with iOS code in this project ships its own manifest**:

| Plugin | Manifest |
|---|---|
| `shared_preferences_foundation` 2.5.6 | ✓ (declares the UserDefaults reason) |
| `path_provider_foundation` 2.4.0 | ✓ |
| `file_picker` 10.3.10 | ✓ |
| `file_selector_macos` 0.9.5 | ✓ |
| `image_picker_ios` 0.8.13+6 | ✓ |
| `permission_handler_apple` 9.5.0 | ✓ |
| `flutter_secure_storage_darwin` 0.3.2 | ✓ |
| `flutter_pdfview` 1.4.5 | ✓ |

The register's own worry — *"this app uses required-reason APIs, so it needs
the declarations"* — was true of the **app**, and not of the **Runner binary**.
Adding a UserDefaults reason here to be safe would be declaring a call this
binary does not make.

## A submission risk that turned out to be already handled

`permission_handler` has a long history of App Store rejections: it compiles in
every permission implementation, so a binary references HealthKit or Contacts
APIs the app never uses and has no usage string for. The documented fix is
preprocessor macros in the Podfile — and **this project has no Podfile**; it
uses Swift Package Manager.

Measured rather than assumed: `permission_handler_apple` 9.5.0's `Package.swift`
resolves each permission from the app's own `Info.plist`, and **defaults to
disabled for any permission whose plist key is absent**. `Info.plist` carries
`NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` and nothing
else; the app requests `Permission.camera` and `Permission.photos` and nothing
else. The two agree, and the rest is compiled out.

## What guards it

`test/architecture/privacy_manifest_test.dart`, six tests. It matches text — it
does not parse a plist, and a malformed manifest is `plutil -lint`'s job, not
its. What it catches is drift between the declaration and the code, which is
the failure that actually happens.

Falsified four ways before being believed:

| Breakage | Caught by |
|---|---|
| A new field added to a request body | *everything the app transmits is accounted for* |
| A declared data type removed from the manifest | *everything the app transmits is accounted for* |
| The manifest removed from the Runner build phase | *the manifest is part of the Runner build* |
| `firebase_analytics` added to `pubspec.yaml` | *the app still has nothing that could track* |

The build-phase test is the one worth explaining. A manifest can be present in
the repository, correct in every detail, and in **no build phase** — so it
never reaches the app bundle and Apple never sees it. Nothing else in this
project would say so until a submission was rejected. It is registered in the
Runner target's Resources phase, and the test slices the section *definition*
rather than the target's `buildPhases` list, which names the same id two
hundred lines earlier and would have sliced the wrong block.

The gate also found a trap in itself: the manifest's comments name the exact
constants to add when uploads land, so a scan of the raw text found
`NSPrivacyCollectedDataTypePhotosorVideos` inside a sentence saying it is
deliberately absent, and concluded it was declared. **A file that documents the
strings a test looks for will do this every time.** Comments are stripped
first, and the vacuity guard asserts the strip did not overreach.

## What is still not mine to decide

Two things, and neither blocks the manifest:

1. **The App Store Connect privacy label.** A separate declaration of the same
   facts, made in the web console, and Apple compares them. This document is
   the input for it; somebody with console access has to enter it.
2. **Whether the LGU intends any use beyond app functionality.** If applicants
   will ever be emailed anything that is not about their own application, the
   purposes change from App Functionality alone. Nothing in the code does that
   today, which is why the manifest says what it says.

## Scope

Front-end mobile, iOS. `ios/Runner/PrivacyInfo.xcprivacy` and the Xcode project
entry that ships it. Android's equivalent — the Play Data Safety form — is the
Windows lane's, and is not touched here.
