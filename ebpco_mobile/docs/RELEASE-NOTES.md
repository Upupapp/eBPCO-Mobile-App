# eBPCO app release notes

Android release builds, newest first, signed with the debug key (there is no store channel yet; see
`ebpcomobile/MANUAL-TASKS.md`). Since 1.0.2 the APK is built with
`flutter build apk --release --dart-define=EBPCO_API_BASE_URL=https://api.castilla-ebpco.online`
(the live API's own name; without it the app uses the server's sslip.io name, `lib/core/config/app_config.dart`).

## 1.0.3 (build 4), 4 Nov 2026

The app says and does what the Citizen Portal does (a parity check against the portal). No APK was
built here for this version: the team releases it through the App Store / TestFlight.

- **Requirements before you start.** Each Permit Services card has "Requirements": the reviewing
  office, New / Renewal / Amendment tabs for the Building Permit (the one type with a list per
  action), and per document Required or If applicable, what it is and the hard copies line, read
  live from the server. "Start application" opens the wizard (on the tab's action).
- **Apply for a permit from a business.** A business's page has "Apply for a permit": Permit
  Services, then the wizard as Business with that business chosen (an inactive one is told to
  reactivate it first).
- **Wizard.** Titled "New <permit type> application"; steps "Applicant & type", "Details",
  "Documents", "Review & submit". Documents are grouped "Required — Needed before you can submit."
  and "If applicable — Attach only if your project includes this work.", under "n of m required
  attached" (required documents only). Business reads "For a business or commercial establishment
  you registered."
- **Account verification.** The banner shows on Home, Permit Services and every wizard step, in the
  portal's words ("Send a photo of a valid government ID. You can prepare applications while the
  Municipality checks it."); a pending account reads "Your account is being verified. You can
  prepare applications now and submit once it is verified." The officer's reason for a refused ID
  now ends with a full stop. The ID button reads "Send ID for verification".
- **Fire Safety notice.** A Certificate of Occupancy asks for the Fire Safety Compliance and
  Commissioning Report (FSCCR), not the FSIC, as the server's checklist does; the notice is one line
  with "What to upload here" a tap away.
- **Catalog chips.** "Business only" / "Residential only" shows only on a type the Municipality
  restricted; "Homes & businesses" on every card is gone.
- **Printed permit, receipt and Order of Payment.** "Property" reads the application's own property
  address (with its barangay when it names one); the business's address only when the application
  gave none. A Residential application printed "Not on file".
- **Permit validity.** A Certificate of Occupancy with no expiry reads "Valid until: No fixed expiry
  (valid while the building's use and occupancy stay the same)"; any other type with no date (the
  server now fills 12 or 6 months) reads "Not recorded", as do a missing approving official or
  office on an old permit.
- A permit type that does not ask the use or character of occupancy no longer carries an earlier
  answer in its form. Notifications show the date and time like the rest of the app.

Then aligned with the Citizen Portal's design-review fixes (4 Nov 2026, portal d830f3a), so the app
and the portal say and show the same things. Some lines above are superseded by these:

- **Where to pay.** One place, named the same everywhere: "Pay at the Municipal Treasurer's Office
  (Cashier), Castilla Town Hall. Bring your Order of Payment." (the pay screen, the Order of
  Payment, Help, the Payments list). The Onsite card reads "Pay at the Treasurer's Office, then tell
  us here."; GCash reads "Pay online." with a "Test mode" chip, and its note says "test checkout"
  once. "Mark as Paid" is "I Have Paid", asked once ("Not Yet" / "Yes, I Have Paid") with an
  optional "OR number on your receipt", sent as the reference "OR <number>". The Office of the
  Municipal Engineer is no longer named as a place to pay.
- **Office names.** One registry, the backend's issuing-office names: "Office of the Building
  Official (Municipal Engineering Office)", "Municipal Planning and Development Office (Zoning
  Administrator)", "Bureau of Fire Protection — Castilla Fire Station", "Municipal Treasurer's
  Office"; OBO / MPDO only as short forms. The Requirements sheet, document headers, Help and the
  approval's fallback read it.
- **Printed permit.** The portal's field map, label for label and in order: "Owner / Permittee
  name", "Business name" (business applications only), "Contact number", the full "Address",
  one "Location" row, "Application type", "Date applied", then the occupancy and scope; one
  assessment table (fees, "Total amount due", "Balance", "Order of Payment No."); "No conditions
  were recorded by the office."; "Signed copy available at the release desk" on an issued permit;
  the approving office falls back to the issuing office; the QR caption names the address, then
  the permit number whole; "Document Ref." is the application's reference, never an internal id.
- **Receipt and Order of Payment.** Headed by the Municipal Treasurer's Office; "Collecting agency:
  Municipal Treasurer's Office"; signed "Cashier" over "Municipal Treasurer's Office"; a GCash
  receipt's footer says it was paid online through GCash. The Order of Payment prints its fee
  schedule and its own number as the document reference. Sentence-case labels, dates as
  "Nov 4, 2026" and "Nov 4, 2026 · 4:00 PM".
- **Documents on a phone.** The permit, receipt and Order of Payment reflow to the screen and
  scroll (one field to a line, nothing cut off or shrunk); a tablet keeps the A4 page. Placeholders
  are upright grey, not pale italic.
- **Private individual.** The stored 'residential' reads "Private individual" ("For yourself or your
  family's property. No business needed."); the catalog chip reads "Private individuals only".
- **Wizard.** The title follows the application type ("Renewal Building Permit application");
  step 1's messages sit under their own field (Applying as, the occupancy, the business) with a
  light red fill, and the field is brought on screen. The Documents step says "Upload everything
  online. Paper copies only where marked." once; a "Hard copies: n" chip only on a document that
  needs paper; no per-document tag (its group says Required or If applicable).
- **Requirements sheet.** "Required (n)" and "If applicable (n)" sections, a business's own rows
  under "Business applications only", the online-only line once, a leading "Only if applicable:"
  left off descriptions, and Close / Start Application at the foot.
- **Timeline.** Each step in the status pill's words ("Under Review"), a second line only where it
  names the step ("Document check", "For approval"), back-to-back steps under one word shown once.

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
