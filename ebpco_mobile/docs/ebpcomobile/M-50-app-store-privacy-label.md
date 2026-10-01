# M-50 — the App Store Connect privacy label

The label is a **separate declaration of the same facts** as
`ios/Runner/PrivacyInfo.xcprivacy`. Only the manifest was updated when the app
began transmitting the wizard contents on 31 August 2026; the label can only be
edited in Apple's web console, so this is what to transcribe.

Prepared from the shipped manifest and the bytes the wire test observes, so it
is a reading of this build rather than a recollection.

## App Privacy → Data Collection

**"Do you or your third-party partners collect data from this app?" → Yes.**

Nine types. For **every one**: *Used for Tracking* → **No**; *Linked to the
user's identity* → **Yes**; purpose → **App Functionality** only. Nothing here
is used for analytics, personalisation, or any kind of advertising, and the
manifest says so — `NSPrivacyTracking` is `false` with an empty
`NSPrivacyTrackingDomains`.

| Apple's category | Apple's type | Manifest key | What it is |
|---|---|---|---|
| Contact Info | Name | `Name` | The applicant, and **the professionals they name** |
| Contact Info | Email Address | `EmailAddress` | Account and notices |
| Contact Info | Phone Number | `PhoneNumber` | Account, and the contact number on the forms |
| Contact Info | Physical Address | `PhysicalAddress` | The applicant's address and the construction site |
| Identifiers | User ID | `UserID` | The account the filing belongs to |
| Financial Info | Other Financial Info | `OtherFinancialInfo` | Payments reported to the LGU: method, reference, amount, date |
| User Content | Photos or Videos | `PhotosorVideos` | Uploaded plans, titles, IDs, structure photographs |
| User Content | Other User Content | `OtherUserContent` | The documents that are not images |
| Other Data | Other Data Types | `OtherDataTypes` | The application itself — permit type, scope, occupancy, costs, licence numbers. Apple has no category for a building permit |

**What changed, and why the label is stale.** Until 31 August a filing carried
the permit type, the applicant's name and a site line. It now carries the whole
wizard — up to 239 fields — **including other people's details**: every
construction wizard collects the designing professional and the full-time
supervisor by name, PRC licence, PTR, address and contact number. Apple's
questionnaire has no axis for whose data it is, so the *types* are unchanged and
the four Contact Info answers now cover people who are not the account holder.
That is worth knowing before answering, not after.

**Not collected**, and each checked rather than assumed:

* **Location** — no location plugin is in `pubspec.yaml`. The `location` field
  on a filing is a typed address string, not a device reading.
* **Device ID** — no push plugin, no Firebase, no APNs registration. The app's
  notifications are in-app.
* **Sensitive Info** — Apple defines this narrowly (race, sexual orientation,
  pregnancy, disability, religious or political belief, trade union membership,
  genetic, biometric). A government ID number is not in that list; it is Other
  Data Types.
* **Contacts, Browsing History, Search History, Purchases, Diagnostics,
  Advertising Data** — none.

## Before you answer: what "Other Data Types" is actually carrying

Apple has no category for a government identifier, so the wizards' identity
fields all land under **Other Data Types**. That answer is correct and it hides
how much is in there, so it is written out here — measured from the 212 field
paths the nineteen wizards persist and send:

* **Tax Identification Number (TIN) — in nine places.** The citizen's, the
  building owner's, and five categories of licensed professional (design
  architect, design engineer, master plumber, design professional, supervisor).
* **PRC licence number and validity date**, and **PTR number, place and date of
  issue**, for each professional.
* **Community Tax Certificate** number, place and date of issue.
* **Government-issued ID** number, place and date of issue, on the consent
  authorisation.

All of it has gone on the wire since `form` began being sent on 31 August.

**Two consequences worth carrying into the questionnaire.** First, none of this
changes an answer — Other Data Types is declared, linked to identity, App
Functionality, not used for tracking. Second, **most of these identifiers
belong to somebody who is not your user.** A citizen types their engineer's TIN
and PRC number. Apple's form has no axis for that, but a reviewer reading the
label alongside the app will see the fields.

**The in-app Privacy Policy now names them.** It said "information about an
authorized representative or licensed professional", which is true and tells
nobody what is collected; it now lists the TIN, the CTC, the ID details, and
the PRC and PTR numbers, and asks the citizen to tell anyone whose details they
enter. Gated by `test/architecture/privacy_label_test.dart`, in both
directions — the policy must name them, and the wizards must still collect
them, so the disclosure cannot outlive what it describes.

## App Privacy → Tracking

**"Does this app track users?" → No.** No IDFA, no ATT prompt, no advertising
SDK, no third-party analytics. `NSPrivacyAccessedAPITypes` is empty on purpose:
the required-reason APIs the app relies on are called by Flutter plugins, which
ship their own manifests, not by this binary. See `docs/M-46-privacy-manifest.md`.

---

## Resolved before answering: the typeface

**The app used to download its typeface from a Google server at runtime.** It
no longer does, and the answers above were prepared after that was fixed rather
than around it.

`google_fonts` downloads a family from `fonts.gstatic.com` on first use unless
told otherwise, and nothing told it otherwise: `GoogleFonts.poppins()` was
called from `app_theme.dart` and `app_typography.dart`, no Poppins was bundled,
and `allowRuntimeFetching` was never set. So every applicant's device made a
request to a third party, carrying its IP address, before they had agreed to
anything — undeclared by both the Privacy Policy and the manifest. It also made
the typeface non-deterministic: a first launch offline got the platform font
and kept it, in an app whose 6.6 MB of blank forms are bundled precisely so it
works away from a connection.

**Not a theoretical finding.** Five hashed Poppins files were sitting in the
iOS Simulator's app container under `Library/Application Support` — one per
weight, which is `google_fonts`' download cache. The request had been happening.

**Fixed 31 August 2026 by the owner's decision (M-51):** Poppins is bundled at
the five weights the design uses — 400/500/600/700/800, 788 KB with the licence
— and `main.dart` sets `GoogleFonts.config.allowRuntimeFetching = false`. The
app looks exactly as it did, always, offline included, and reaches no third
party for it. `OFL.txt` ships beside the files because the SIL Open Font
License conditions redistribution on the licence travelling with the font.

So the label answer stands unqualified: **no data is collected by third-party
partners.** There is no third party.

## The gate

`test/architecture/privacy_label_test.dart` asserts this document against the
shipped manifest: the nine types listed here are exactly the nine the manifest
declares, the tracking answers agree, and the runtime-font finding stays stated
until either fonts are bundled or fetching is turned off. If the manifest gains
a type, this checklist fails and names it — which is the failure that should
have happened when `form` started being transmitted.
