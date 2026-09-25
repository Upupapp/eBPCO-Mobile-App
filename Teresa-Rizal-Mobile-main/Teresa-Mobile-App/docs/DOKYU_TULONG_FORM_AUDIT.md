# Dokyu / Tulong Form Audit

Source-of-truth audit for every Dokyu (document/permit/certificate) and Tulong
(assistance/welfare) mobile form implemented in this app, and the reference
material under `Reference_forms/` (read-only — never modified, reorganized,
or converted to app assets) it was sourced from.

- **Priority 1 — Official Teresa, Rizal source**: `Reference_forms/Teresa, Rizal  File/`
  (note the double space in the on-disk folder name — copied verbatim from
  the client-supplied files, not a typo introduced here).
- **Priority 2 — Placeholder**: `Reference_forms/Placeholders/Dokyu/` and
  `Reference_forms/Placeholders/Tulong/`, used only where no official source
  exists or the official source was confirmed inadequate.
- **Priority 3 — Missing**: no reliable source in either location. These
  services either keep their pre-existing generic Purpose + Attachments flow
  (if they already existed in the app) or are not implemented at all, and are
  listed under "Needs Client Clarification" below rather than having fields
  invented for them.

Every sourced service is implemented as a real, data-driven multi-step
wizard (`ServiceRequestWizardScreen`, see `lib/models/service_form_spec.dart`
and `lib/screens/shared/service_request_wizard_screen.dart`) that mirrors the
step-by-step pattern of the existing Create Account wizard
(`lib/screens/auth/register_screen.dart`): step indicator, per-step
validation, Back/Continue, and a Review step with per-field Edit links. Step
count and labels are driven entirely by each service's `ServiceFormSpec` —
nothing forces a fixed number of steps. Services without a sourced
`formSpec` keep using the older single-step `NewRequestScreen` (Purpose +
Requirements + Attachments) they already had.

---

## 1. Official Teresa, Rizal Sources Used

### Dokyu

| Service (catalog key) | Source file | Notes |
|---|---|---|
| Barangay Clearance (`dokyu_barangay_clearance`) | `BRGY.CLEARANCE NEW .docx` | Enhanced existing item with the source's purpose checklist. |
| Certificate of Residency (`dokyu_residency`) | `BRGY. RESIDENCY.docx` | Enhanced with residency type + same purpose checklist. |
| Certificate of Indigency (`dokyu_indigency`) | `BRGY.INDIGENCY 2024-1.docx` | Enhanced with the source's purpose checklist. |
| Barangay Business Clearance (`dokyu_barangay_business_clearance`) | `BRGY. BUSINESS CLEARANCE .docx` | New — barangay-level, distinct from the existing BPLO-level Business Permit. |
| Barangay Certification (General Purpose) (`dokyu_barangay_certification`) | `Barangay Certification.docx`, `PSA CERTIFICATION.docx` | New — both are batches of already-issued sample certifications from Barangay Villa covering many purposes (residency, unemployment for TESDA, property ownership, event permits, etc.); confirms the need for a generic, free-text-purpose certification service. |
| First Time Job Seeker Certificate (`dokyu_first_time_jobseeker`) | `First Time Job Seeker Certificate.docx` | New — RA 11261. |
| Application for Marriage License (`dokyu_marriage_license`) | `MCRO - Application for Marriage License.pdf` (Municipal Form 90) | New. "Consent to a Marriage of Person" and "Advice Upon Intended Marriage" (found inside `MCRO - Certificate of Marriage.pdf`) are folded in as **requirements**, not separate services — they only support this application. |
| Certified Copy of Marriage Certificate (`dokyu_marriage_certificate_copy`) | `Certified Copy of Marriage certificate.pdf` (Municipal Form 97 — image-based PDF, inspected visually rather than via text extraction) | New. Distinct from Application for Marriage License above: this is for a couple already married requesting a copy of their existing record, not people preparing to marry. The certificate is the issued-output civil registry record (parties' full bio-data, parents, consent, solemnizing officer's certification, witnesses, LCRO/OCRG processing boxes) — none of that is citizen-fillable, so only the handful of facts needed to locate the existing record are asked (husband/wife full name, date and place of marriage, registry number if known), plus a practical Number of Copies field with no source equivalent. Positioned immediately next to `dokyu_marriage_license` in the catalog list. |
| Delayed Registration of Birth (`dokyu_delayed_birth_registration`) | `MCRO - Certificate of Live Birth.pdf`, pages 2-3 ("Affidavit for Delayed Registration of Birth") | New. Page 1 of that PDF is the issued-output birth record, filled by the hospital/registrar — excluded as a source of citizen-input fields. |
| Delayed Registration of Death (`dokyu_delayed_death_registration`) | `MCRO - Certificate of Death.pdf`, page 2 ("Affidavit for Delayed Registration of Death") | New. Page 1 is the issued-output death record — excluded. |
| Certificate of Fetal Death (`dokyu_fetal_death`) | `MCRO - Certificate of Fetal Death.pdf` (Municipal Form 103A) | New. Page 1's Fetus/Mother/Father/Marriage-of-Parents sections are the citizen-known identifying facts an informant can actually supply. The Medical Certificate's clinical cause-of-death entries (item 19a-19e), the attending physician's/health officer's own certification, the Postmortem Certificate, the Embalmer's Certification, and the civil registrar's processing boxes are all filled and signed by medical/registrar staff — excluded, same principle as the two Delayed Registration items above. "Cause of Fetal Death" and "Reason for Delay" instead come from page 2's "Affidavit for Delayed Registration of Fetal Death", phrased as the informant's own lay statement. Item 21 "Length of Pregnancy (in completed weeks)" is gestational age, not a person's age — kept as a plain number field, deliberately never folded into the birthdate/age rule below. |
| Barangay Certification for Late Registration of Birth (`dokyu_barangay_cert_late_birth`) | `BRGY.CERTIFICATION LATE REGISTRATION.docx` | New — barangay-level pre-requisite supporting the above. |
| Barangay Certification for Registration of Death (`dokyu_barangay_cert_death`) | `BRGY.CERTIFICATION REGISTRATION OF DEATH.docx` | New — barangay-level pre-requisite. |
| Pet Registration (`dokyu_pet_registration`) | `PET REGISTRATION FORM.docx` | New — genuinely citizen-fillable, addressed to the Municipal Agriculture Office. |

### Tulong

| Service (catalog key) | Source file | Notes |
|---|---|---|
| Solo Parent Cash Assistance (`tulong_solo_parent`) | `MSWD - SOLO Parent Application Form.xlsx` (DSWD Annex B, 2023) | Heavily enhanced — the richest single source found in the entire audit: identifying info, family composition, a 12-option classification of circumstances, needs, and emergency contact. |
| Senior Citizen ID Application / OSCA Membership (`tulong_senior_citizen_id`) | `MSWD - Senior Citizen Application Form.docx` (duplicate pair, identical) | New — distinct from the existing Social Pension item, which is a cash-benefit program rather than plain ID/membership registration. |
| PWD Registration / PRPWD (`tulong_pwd_registration`) | `MSWD - PRPWD Form 2.pdf` (DOH Philippine Registry for PWD, v3.0) | New. |
| TUPAD Emergency Employment (`tulong_tupad`) | `MPESO - DOLE TUPAD PROFILE FORM.pdf` (duplicate pair, identical) | New. |
| TESDA Skills Training Registration (`tulong_tesda_registration`) | `MPESO - TESDA-DPA Form 1 Registration Form (MIS 03-01).pdf` (duplicate pair, identical; also duplicated in Placeholders — see Duplicates section) | New. |
| ERPAT Program Registration (`tulong_erpat_registration`) | `MSWD - ERPAT FORMS.docx` (duplicate pair, identical) — **Registration Form portion only** | New, lower priority. The same file also contains ERPAT/BVAW/KALIPI quarterly meeting-minutes forms, which are internal staff records and were excluded — see Internal-Admin section. |

---

## 2. Placeholder Sources Used

| Service (catalog key) | Placeholder file | Why a placeholder was needed | Adaptation made |
|---|---|---|---|
| Locational Clearance (`dokyu_locational_clearance`) | `Placeholders/Dokyu/CPDO-Application-for-Locational-Clearance.pdf` | No official Teresa, Rizal Locational Clearance form exists in the client-supplied files. | Source form is from a City Planning & Development Office (CPDO) of a different LGU. Office renamed to the standard municipal-level equivalent, **Municipal Planning & Development Office (MPDO)**; no other city-specific branding or detail was carried over. Fields themselves (applicant/representative, project details, lot information, zoning classification) are a normal, generic Philippine LGU locational-clearance shape. |
| Educational Assistance field shape (`tulong_educational`) | `Placeholders/Tulong/2F5.Application-for-Scholarship.pdf` | The existing generic "Educational Assistance" item had no official Teresa, Rizal source form describing its citizen-input fields. | This placeholder is actually a **National Commission on Indigenous Peoples (NCIP)** scholarship application for Indigenous Peoples/ICC members — a different agency's program, not confirmed to be what Teresa, Rizal's MSWDO/Mayor's Office administers. Only the general applicant/school/family-background field *shape* was reused; NCIP/IP-specific fields (ethnolinguistic group, ancestral domain/CADT references, congressional district) were deliberately excluded so the form doesn't imply an ethnicity-gated program that isn't confirmed. |

---

## 3. Missing Official Forms (Placeholder exists, official does not)

These already appear in the Placeholder table above — listed again here per
the requested doc structure:

- **Locational Clearance** — no official Teresa, Rizal source; Placeholder used (City CPDO form, adapted to MPDO).
- **Educational Assistance detailed field shape** — no official Teresa, Rizal source; Placeholder used (NCIP scholarship form, IP-specific fields stripped).

---

## 4. Missing From Both Sources (kept on the generic flow, not implemented with sourced fields)

No official or usable Placeholder source was found for these, so — per the
"do not invent fields" rule — they keep the pre-existing generic Purpose +
Requirements + Attachments flow instead of a sourced `formSpec`:

- **Cedula (Community Tax Certificate)** — no citizen-fillable source form found.
- **Business Permit (New Application)** — Placeholders/Dokyu has a generic `BUSINESS-PERMIT-FORM.pdf`, but the existing catalog item is already a reasonable BPLO-level generic form; not re-sourced this pass.
- **Real Property Tax Clearance** — no citizen-fillable source form found.
- **Certificate of Live Birth (Certified Copy)** — no separate *request* form found (only the issued-output record itself, which is not a citizen-input source).
- **Medical Assistance, Burial Assistance, Financial Assistance, Food/Relief Assistance (AICS programs)** — no official Teresa, Rizal AICS application form was in the supplied files.
- **Social Pension (Indigent Senior Citizen)** — no official Teresa, Rizal pension-specific application form was found (only the *separate* OSCA Membership form, which is now its own new item — see above).

---

## 5. Needs Client Clarification

Forms that exist in the reference material but were not implemented this
pass, or that could not be reliably inspected — flagged here rather than
silently dropped, per the "report the gap" instruction:

| Item | Source(s) searched | Placeholder exists? | What's missing | What to ask the client |
|---|---|---|---|---|
| Occupational Permit | `Placeholders/Dokyu/657a9b3d3e6be1702533949OCCAPFORM V2 (1).pdf` | Yes | Not implemented this pass (time-boxed scope). | Confirm whether Teresa, Rizal issues Occupational Permits municipally and, if so, request the official form. |
| Barangay Clearance for Building Permit | `Placeholders/Dokyu/9.-Barangay-Clearance-for-Building-Permit.pdf` | Yes | Not implemented this pass. | Confirm if this is distinct from the existing general Barangay Clearance for Teresa, Rizal's process. |
| MSWD General Intake Sheet | `MSWD - General Intake Sheet.xls` (both copies) | N/A | Legacy binary `.xls` format — this environment's available tooling (Python `zipfile`/`ElementTree`, no `xlrd`/pandoc/LibreOffice) cannot parse pre-2007 Excel binary format. | Ask the client to re-supply as `.xlsx`, `.csv`, or `.pdf` if this needs to be sourced. |
| MPESO TSSD Business-Mapping / Beneficiary-Profile / Individual-Business-Plan forms | `MPESO - TSSD-EFIS02-002/003/004...` (3 forms, each duplicated) | No | Not inspected/implemented this pass — likely livelihood/business-assistance Tulong candidates, not yet confirmed by content. | Prioritize for a follow-up pass if a livelihood-assistance Tulong service is wanted. |
| MCRO supporting-attachment forms | `MCRO - Affidavit of 2 Disinterested Person Form.pdf`, `MCRO - MUSLIM Attachment.pdf` | No | Not fully inspected — believed to be requirement attachments for delayed-registration/Muslim-marriage cases rather than standalone services, consistent with how the other MCRO affidavits were classified, but not confirmed by content this pass. | Confirm these are attachment-only documents, not separate citizen-facing services. |
| Various unopened Placeholder forms | `Placeholders/Dokyu`: `Barangay_Certification (1/2).pdf`, `Form 2-Barangay Certification for the IEPs.pdf`, `SOLO PARENT APPLICATION FORMS REVISED...pdf`; `Placeholders/Tulong`: `2022-DAFAC-FORM.pdf`, `Burial-Assistance.pdf`, `DO-239-23-Guideline...DILEEP` (×3), `INTAKE-SHEET-Social-Pension.pdf`, `INTAKE-SHEET.pdf`, `MAP-Application-Form...pdf`, `NSRP-Form-1-Jobseeker-Reg-Form.pdf` | — | Not opened this pass (time-boxed scope; the official-source items above already cover their subject areas more authoritatively). | Available for a follow-up expansion pass if additional Tulong services are wanted beyond what's implemented. |

---

## 6. Internal-Admin Files Excluded

Verified by content (not filename or department alone) to be LGU-staff
paperwork, not citizen self-service — never turned into mobile forms:

- `New BDRRMC Profile of Evacuees.docx`, `...HUMAN & HOUSING Damages...docx`, `...AGRICULTURE Damages...docx`, `...FISHING Damages...docx`, `...BUSINESS Damages...docx`, `...RDS Relief Distribution Sheet.docx` — Barangay Disaster Risk Reduction Committee staff forms, signed by named barangay officials; internal disaster-response paperwork.
- `MSWD - FACED Form.pdf` (both copies) — DSWD "Family Assistance Card in Emergencies and Disasters"; partly family-filled but the assistance-record ledger is staff-maintained, and it's an emergency/disaster-response document, outside this task's Dokyu/Tulong scope.
- `ACCOMPLISHMENT REPORT 2026.docx`, `ANIMAL HEALTH MONITORING 2026.docx`, `LIVESTOCK AND POULTRY ANNUAL TARGET 2026.xlsx`, `LIVESTOCK INVENTORY 2026.xlsx` — internal MAO planning/reporting.
- `DOG VACCINATION FORM.xlsx` — an internal Livestock Technician's per-household vaccination campaign log, filled by MAO staff — distinct from the genuinely citizen-facing `PET REGISTRATION FORM.docx`, which *was* implemented.
- All `MGSO -` files (Borrower's Slip, Driver's Trip Ticket, Fuel Pass, Inspection, Inventory Custodian Slip, Return Slip) — internal General Services logistics forms.
- All `MHRMO -` files (CS Form 211 Medical Certificate, CS Form 212 Personal Data Sheet, CS Form 6 Leave Application, CS Form 7 Clearance, Locator Slip, Pass Slip) — internal HR/Civil Service Commission forms for LGU employees, not citizens.
- `History Brgy.Labangtaytay.docx` — a historical narrative document, not a form.
- `orga. profile.docx` — an org-profile reference document with no extractable citizen-fillable content.
- `MSWD - ERPAT FORMS.docx` meeting-minutes portions (ERPAT quarterly meetings, BVAW/KALIPI meeting minutes) — internal staff meeting records; only that same file's separate Registration Form portion was implemented.
- Personal photographs (named individuals' `.jpg` files, UUID-named images) and `Messenger_creation_...-removebg-preview.png` — personal photos or a logo asset, not form templates; deliberately not further described given several depict real, named private individuals.

---

## 7. Duplicates

Exact duplicate file pairs found in the official source folder (both copies
have identical content; one canonical source was used):

- `MPESO - DOLE TUPAD PROFILE FORM.pdf` and `MPESO - DOLE TUPAD PROFILE FORM (1).pdf`
- `MPESO - TESDA-DPA Form 1 Registration Form (MIS 03-01).pdf` and `...(1).pdf` — also duplicated a third time in `Placeholders/Tulong/TESDA-DPA Form 1 Registration Form (MIS 03-01).pdf`.
- `MPESO - TSSD-EFIS02-002-Rev01-Business-Mapping-Form.pdf` and `...(1).pdf`
- `MPESO - TSSD-EFIS02-003-Rev07-Beneficiary-Profile-Form.pdf` and `...(1).pdf`
- `MPESO - TSSD-EFIS02-004-Rev05-Individual-Business-Plan.pdf` and `...(1).pdf`
- `MSWD - ERPAT FORMS.docx` and `...(1).docx`
- `MSWD - FACED Form.pdf` and `...(1).pdf`
- `MSWD - General Intake Sheet.xls` and `...(1).xls`
- `MSWD - PRPWD Form 2.pdf` and `...(1).pdf`
- `MSWD - SOLO Parent Application Form.xlsx` and `...(1).xlsx`
- `MSWD - Senior Citizen Application Form.docx` and `...(1).docx`

Per the "treat Reference_forms as read-only" rule, no duplicate files were
deleted, renamed, or reorganized — they're only noted here.

---

## Birthdate / Age Fields

A global rule applies everywhere a form needs a citizen's age: **never ask
for Date of Birth and Age as two separate inputs.** Even where a source
paper form has separate "Date of Birth: ___" and "Age: ___" blanks (e.g.
`BRGY.CLEARANCE NEW .docx`, `BRGY. RESIDENCY.docx`, `BRGY. BUSINESS
CLEARANCE .docx`, `First Time Job Seeker Certificate.docx`, `MSWD - SOLO
Parent Application Form.xlsx`, `MSWD - ERPAT FORMS.docx`), the mobile form
only asks for Date of Birth via the standard date picker; Age is a
read-only field computed live from it (`ServiceFieldType.derivedAge` in
`lib/models/service_form_spec.dart`), using the shared, month/day-aware
`calculateAge()` helper in `lib/utils/age_calculator.dart` — never
`currentYear - birthYear`. Age is still included in the submitted
`formFields` (for services whose backend/paper equivalent expects it), it's
just never independently typed or validated. Where a citizen's Date of
Birth already exists in their Resident Profile, `ServiceRequestWizardScreen`
prefills it automatically rather than asking again on every application.
The Resident Profiling model's own pre-existing `Individual.age` getter was
refactored to call the same shared helper instead of duplicating the
calculation.

## Implementation Summary

- **15 Dokyu catalog items** now carry a sourced `formSpec` (3 enhanced existing items, 12 new); 4 pre-existing items remain on the generic flow (no reliable source found — see Section 4).
- **7 Tulong catalog items** now carry a sourced `formSpec` (2 enhanced existing items, 5 new); 5 pre-existing items remain on the generic flow.
- Full catalog: `lib/services/mock_catalog.dart` (`documentTypes`, `assistanceTypes`).
- Wizard framework: `lib/models/service_form_spec.dart`, `lib/screens/shared/service_request_wizard_screen.dart`. `ServiceFormField` also supports an optional `visibleWhenKey`/`visibleWhenValueIn` conditional-visibility gate (added for Certificate of Fetal Death's "If Multiple Delivery, Fetus Was" and "Attended By" fields) — a field with no gate is always visible, so every pre-existing formSpec is unaffected.
- Routing: `lib/screens/shared/service_catalog_screen.dart` sends an item to the new wizard when it has a `formSpec`, otherwise to the existing `NewRequestScreen` — no existing item's behavior changed.
- Test coverage: `test/service_request_wizard_test.dart` (step count/labels adapt per service, Applicant Info prefill, required-field validation, non-sourced items still use the old screen), plus a scroll fix in `test/service_catalog_progressive_filter_test.dart` for the now-larger department lists.
