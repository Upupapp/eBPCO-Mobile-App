# eBPCO app release notes

Android release builds, newest first, signed with the debug key (there is no store channel yet; see
`ebpcomobile/MANUAL-TASKS.md`). Since 1.0.2 the APK is built with
`flutter build apk --release --dart-define=EBPCO_API_BASE_URL=https://api.castilla-ebpco.online`
(the live API's own name; without it the app uses the server's sslip.io name, `lib/core/config/app_config.dart`).

## 1.0.2 (build 3), 4 Nov 2026

From the LGU's first test of the app (needs ebpco-api migration 071).

- **Use or character of occupancy.** A Building Permit or Certificate of Occupancy application asks
  it on step 1, right after "Applying as": the National Building Code's Groups A to J, or
  "Others (specify)" with the use (3 to 120 characters). Required to continue and to submit; saved
  in the draft and read back when it reopens. Shown on the review, the application page and the
  permit document.
- **Documents step.** "Optional" now reads "If applicable" (Road Clearance, the approved CSHP, Soil
  Analysis and Structural Design and Analysis are needed only when the project calls for them).
  Each document says "Online only, no hard copy" or "Hard copies: n" with the office's note (the
  BFP's fire-safety documents ask for one copy at the Castilla Fire Station).
- **GCash.** The payment screen lists the methods the Municipality accepts right now (Onsite when the
  list cannot be read; still no Bank Transfer until a deposit account is published). "Pay with
  GCash" opens the checkout in the browser; back in the app, the screen checks the payment and
  shows "Payment Submitted", or how to finish the checkout. Test mode until the LGU has a GCash
  merchant account: no real money is charged. Payments and receipts show method GCash and its
  GC-TEST reference.
- Sign-up no longer asks Residential or Business; each application asks "Applying as".

## 1.0.1 (build 2), 3 Nov 2026

- Permit delivery: pick up at the office, or delivered by courier.
- The permit's QR code opens citizen.castilla-ebpco.online/verify.
