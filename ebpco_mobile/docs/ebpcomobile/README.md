# Reference docs merged from eBPCOMobile

Brought over on 2026-10-01 from the earlier citizen app,
[`Upupapp/eBPCOMobile`](https://github.com/Upupapp/eBPCOMobile) (last change
2026-09-08), when its applicable parts were merged into this app. This app is
the one that ships; these are kept for what they record about the Municipality,
the permits and App Store readiness.

**File paths inside them point at eBPCOMobile's code** (`lib/core/...`,
`lib/features/...`), not this app's. What was ported, and where it lives here:

| From eBPCOMobile | Here |
|---|---|
| Bundled blank permit forms (`M-10`) | `assets/permits/`, `lib/domain/permit_forms.dart`, `lib/screens/permits/blank_form_screen.dart`. Since 2026-10-01 only the forms a requirement asks the citizen to sign and upload (the Building Permit's Unified form and its ancillary forms), linked from that document's card |
| iOS privacy manifest (`M-46`) | `ios/Runner/PrivacyInfo.xcprivacy`, re-measured for this app |
| Letter of Instruction | the returned-application card in `lib/screens/applications/application_detail_screen.dart` |
| Contact verification | `lib/screens/profile/verify_email_screen.dart` |
| Text-scale clamp | `lib/theme/text_scale_clamp.dart` |

## What is here

- **The Municipality and its permits:** `M-08-occupancy-requirements.md`,
  `M-11-claim-procedure.md`, `M-16-lgu-facts-audit.md`,
  `M-16-office-contact-found.md`, `PERMIT-CONDITIONS-AUDIT.md`,
  `RULING-renewal-amendment-reuse.md`, `CITIZEN-VOCABULARY.md`.
- **The forms:** `M-10-forms-already-bundled.md`, `FORM-AUDIT-METHOD.md`.
- **App Store readiness:** `APP-STORE-READINESS-2026-08-31.md`,
  `ATS-AND-THE-API-HOST.md`, `DECISION-M-29-bundle-identifier.md`,
  `M-46-privacy-manifest.md`, `M-50-app-store-privacy-label.md`,
  `MANUAL-TASKS.md` (tasks only a person can do: signing, store accounts, LGU
  facts still to be supplied).
- **Design decisions:** `decisions/0001-secure-session-storage.md`,
  `decisions/0002-offline-queue.md`.
- **`reference-assets/`:** kept out of the app bundle on purpose (see its README).

## What was not brought over, and why

- **The sixteen per-permit wizards and the mock data.** This app files every
  permit type through one wizard driven by the server's own requirements
  catalog, the same way the citizen portal does.
- **Its app structure, blue theme and Poppins font.** This app keeps its own
  red Castilla design.
- **The FSEC and FSIC wizards and forms.** The BFP issues both on BFP-FSIS.
- **Certificate pinning.** The API's certificate is a Let's Encrypt one that
  renews every few months; a pinned app would stop working at each renewal.
- **The service-pledge countdown.** The server sends no pledge yet, and this
  app does not compute a legal deadline the server has not stated.
- **The offline upload queue** (`decisions/0002`). Worth doing later; it is a
  change to how every upload is sent.
- **Language, Professionals and other display-only or on-device-only screens.**
