import '../models/announcement.dart';
import '../models/catalog_item.dart';
import '../models/citizen_account.dart';
import '../models/digital_credential.dart';
import '../models/evacuation_center.dart';
import '../models/government_id_record.dart';
import '../models/resident_profile.dart';
import '../models/service_form_spec.dart';

/// Static reference data copied out of the Web Admin (read-only source —
/// see config/teresa_rizal.php, teresa_rizal_citizens.php, teresa_rizal_balita.php,
/// and the inline $documentTypes / $assistanceTypes arrays in
/// citizen/document-requests.blade.php + assistance-requests.blade.php).
/// This is a representative subset, not a byte-for-byte copy of every
/// barangay-specific document — see TERESA_RIZAL_MOBILE_WEB_ALIGNMENT.md
/// Section 7 for what's intentionally trimmed for the mobile demo.
class MockCatalog {
  MockCatalog._();

  /// Teresa, Rizal barangays. Labangtaytay stays so the second demo
  /// account still matches an entry.
  static const barangays = [
    'Bagumbayan',
    'Calumpang',
    'Dalig',
    'Dulumbayan',
    'May-Iba',
    'Poblacion',
    'Prinza',
    'San Gabriel',
    'San Roque',
    'Labangtaytay',
  ];

  /// Reusable purpose options sourced from BRGY.CLEARANCE NEW.docx / BRGY.
  /// RESIDENCY.docx — both official Teresa, Rizal barangay forms use the same
  /// purpose checklist.
  static const _barangayPurposeOptions = [
    'Proof of Residency',
    'Local Employment',
    'Travel Abroad',
    'Postal ID Application',
    'Bank Requirement',
    'NBI Clearance',
    'Loan Purpose',
    'Medical / Financial Assistance',
    'Others',
  ];

  static const documentTypes = <CatalogItem>[
    CatalogItem(
      key: 'dokyu_cedula',
      name: 'Cedula (Community Tax Certificate)',
      office: "Treasurer's Office",
      fee: '₱5.00 base + ₱1.00 per ₱1,000 income',
      days: 'Same day',
      requirements: [
        'One (1) valid government-issued ID',
        'Proof of income or Certificate of Employment (if applicable)',
      ],
      process: ['Submit Request', 'Compute Tax Due', 'Pay Fee', 'Release'],
      icon: 'receipt',
      // Web Admin's own record for Perlita (DR-2026-2350).
      demoPurpose: 'For submission as a government transaction requirement.',
      demoRejectionReason:
          'The declared income used to compute your Community Tax could not be verified against your '
          'submitted Certificate of Employment. Please submit an updated proof of income.',
    ),
    CatalogItem(
      key: 'dokyu_barangay_clearance',
      name: 'Barangay Clearance',
      office: 'Barangay Hall',
      fee: '₱50.00',
      days: '1-2 working days',
      requirements: ['One (1) valid government-issued ID', 'Proof of residency'],
      process: ['Submit Request', 'Verify Residency', 'Approval', 'Release'],
      icon: 'file-check',
      // Sourced: BRGY.CLEARANCE NEW.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Clearance Details',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(
                key: 'purpose',
                label: 'Purpose',
                type: ServiceFieldType.select,
                options: _barangayPurposeOptions,
              ),
            ],
          ),
        ],
      ),
      // Web Admin's own record for Perlita's Barangay Clearance request
      // (DR-2026-2255 — see config/teresa_rizal_constituents.php and
      // resources/views/admin/document-requests.blade.php in the Web
      // Admin's GIT_FETCH_WEB reference) gives this exact free-text
      // Purpose: "For local transaction and identification purposes."
      // This wizard's own Purpose field is a constrained select sourced
      // from the official BRGY.CLEARANCE NEW.docx checklist and has no
      // matching option for that exact phrase (per this project's own
      // "do not overwrite legitimate official form structure" rule, no new
      // option is invented here) — 'Proof of Residency' is the closest
      // official category to what she's actually requesting it for. The
      // exact Web Admin wording is instead surfaced verbatim on the
      // Requirements step's own "Additional notes (optional)" field via
      // demoPurpose below, so the real submitted reason is still visible
      // and never confused with the Purpose select itself.
      demoDefaults: {'purpose': 'Proof of Residency'},
      demoPurpose: 'For local transaction and identification purposes.',
      demoRejectionReason:
          'Your Proof of Residency document could not be verified against Barangay Bagumbayan records. Please '
          'submit an updated utility bill or lease contract showing your current address.',
    ),
    CatalogItem(
      key: 'dokyu_residency',
      name: 'Certificate of Residency',
      office: 'Civil Registrar',
      fee: '₱50.00',
      days: '1-2 working days',
      requirements: [
        'One (1) valid government-issued ID',
        'Barangay Clearance',
        'Proof of residency (utility bill or lease contract)',
      ],
      process: ['Submit Request', 'Verify Residency', 'Approval', 'Release'],
      icon: 'home',
      // Sourced: BRGY. RESIDENCY.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Residency Details',
            fields: [
              ServiceFormField(
                key: 'residencyType',
                label: 'Residency Type',
                type: ServiceFieldType.select,
                options: ['Permanent Resident', 'Temporary Resident', 'Renter / Lessee'],
              ),
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(
                key: 'purpose',
                label: 'Purpose',
                type: ServiceFieldType.select,
                options: _barangayPurposeOptions,
              ),
            ],
          ),
        ],
      ),
      demoDefaults: {'residencyType': 'Permanent Resident', 'purpose': 'Bank Requirement'},
      // Web Admin's own record for Perlita (DR-2026-2331): "For submission
      // to a requesting government agency" — same treatment as Barangay
      // Clearance above: the exact free-text wording doesn't match any
      // official Purpose select option, so it's surfaced verbatim via the
      // Requirements step's own Additional Notes field instead.
      demoPurpose: 'For submission to a requesting government agency.',
      demoRejectionReason:
          'The Barangay Clearance you attached has already expired. Please secure a current Barangay '
          'Clearance and resubmit your request.',
    ),
    CatalogItem(
      key: 'dokyu_indigency',
      name: 'Certificate of Indigency',
      office: 'Municipal Social Welfare and Development Office',
      fee: 'Free',
      days: '2-3 working days',
      requirements: [
        'One (1) valid government-issued ID',
        'Barangay Certification of Indigency',
        'Brief interview / case assessment with the Municipal Social Welfare and Development Office',
      ],
      process: ['Submit Request', 'Municipal Social Welfare and Development Office Interview', 'Case Assessment', 'Release'],
      icon: 'heart-handshake',
      // Sourced: BRGY.INDIGENCY 2024-1.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Indigency Details',
            fields: [
              ServiceFormField(
                key: 'purpose',
                label: 'Purpose',
                type: ServiceFieldType.select,
                options: [
                  'Medical Assistance',
                  'Financial Assistance',
                  'Burial Assistance',
                  'Educational Assistance (e.g. Scholarship)',
                  'Others',
                ],
              ),
            ],
          ),
        ],
      ),
      demoDefaults: {'purpose': 'Educational Assistance (e.g. Scholarship)'},
      // Web Admin's own record for Perlita (DR-2026-2332): "For scholarship
      // and financial assistance application requirement" — matches the
      // select default above; surfaced verbatim on Additional Notes too.
      demoPurpose: 'For scholarship and financial assistance application requirement.',
      demoRejectionReason:
          'The Municipal Social Welfare and Development Office interview/case assessment found your '
          'household income above the indigency threshold for this certification. You may reapply if your '
          'circumstances change.',
    ),
    CatalogItem(
      key: 'dokyu_business_new',
      name: 'Business Permit (New Application)',
      office: 'Business Permits and Licensing Office',
      fee: '₱500.00 and up (based on capital)',
      days: '7 working days',
      requirements: [
        'DTI or SEC Registration',
        'Barangay Business Clearance',
        'Locational / Zoning Clearance',
        'Sanitary Permit',
        'Cedula',
      ],
      process: ['Submit Requirements', 'Zoning & Fire Inspection', 'Assessment & Payment', 'Release'],
      icon: 'store',
      // Web Admin's own record for Perlita (DR-2026-2333).
      demoPurpose: 'New business permit application.',
      demoRejectionReason:
          'Your Locational/Zoning Clearance and Sanitary Permit could not be verified during the zoning and '
          'fire inspection. Please coordinate with the Business Permits and Licensing Office to schedule a '
          're-inspection.',
    ),
    CatalogItem(
      key: 'dokyu_rpt',
      name: 'Real Property Tax Clearance',
      office: "Treasurer's Office",
      fee: '₱100.00',
      days: 'Same day',
      requirements: [
        'Latest Tax Declaration',
        'Official Receipt of last RPT payment',
        'One (1) valid government-issued ID',
      ],
      process: ['Submit Request', 'Verify Tax Records', 'Settle Balance (if any)', 'Release'],
      icon: 'landmark',
      // Web Admin's own record for Perlita (DR-2026-2334).
      demoPurpose: 'Real property tax clearance for a property transaction.',
      demoRejectionReason:
          'Our records show an outstanding Real Property Tax balance for this property. Please settle the '
          "balance at the Treasurer's Office before a clearance can be issued.",
    ),
    CatalogItem(
      key: 'mcro_live_birth',
      name: 'Certificate of Live Birth (Certified Copy)',
      office: 'Office of the Municipal Civil Registrar',
      fee: '₱155.00',
      days: '3-5 working days',
      requirements: ['One (1) valid government-issued ID', 'Details of the record being requested'],
      process: ['Submit Request', 'Records Verification', 'Payment', 'Release'],
      icon: 'file-text',
      // Web Admin's own record for Perlita (DR-2026-2335).
      demoPurpose: 'For submission as a scholarship and school enrollment requirement.',
      demoRejectionReason:
          'The record details you provided did not match the civil registry entry on file. Please verify '
          'the exact registered name and date, then resubmit your request.',
    ),
    CatalogItem(
      key: 'dokyu_barangay_business_clearance',
      name: 'Barangay Business Clearance',
      office: 'Barangay Hall',
      fee: '₱100.00',
      days: '1-2 working days',
      requirements: ['One (1) valid government-issued ID', 'Proof of business location (lease contract or land title)'],
      process: ['Submit Request', 'Barangay Verification', 'Approval', 'Release'],
      icon: 'store',
      // Sourced: BRGY. BUSINESS CLEARANCE.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Business Details',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(key: 'businessName', label: 'Business Name', type: ServiceFieldType.text),
              ServiceFormField(key: 'businessNature', label: 'Nature of Business', type: ServiceFieldType.text),
              ServiceFormField(key: 'yearsOperating', label: 'Years Operating', type: ServiceFieldType.number),
              ServiceFormField(key: 'capitalAmount', label: 'Capital Amount (₱)', type: ServiceFieldType.number),
            ],
          ),
        ],
      ),
      demoDefaults: {
        'businessName': "Quiambao's Sari-Sari Store",
        'businessNature': 'Retail - Sari-Sari Store',
        'yearsOperating': '3',
        'capitalAmount': '15000',
      },
      // Web Admin's own record for Perlita (DR-2026-2233).
      demoPurpose: 'Market stall permit renewal.',
      demoRejectionReason:
          'The proof of business location you submitted could not be verified against the barangay '
          'records for this address. Please submit an updated lease contract or land title.',
    ),
    CatalogItem(
      key: 'dokyu_barangay_certification',
      name: 'Barangay Certification (General Purpose)',
      office: 'Barangay Hall',
      fee: '₱50.00',
      days: '1-2 working days',
      requirements: ['One (1) valid government-issued ID'],
      process: ['Submit Request', 'Barangay Verification', 'Approval', 'Release'],
      icon: 'file-text',
      // Sourced: Barangay Certification.docx / PSA CERTIFICATION.docx — a
      // batch of issued examples covering many purposes (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Certification Details',
            fields: [
              ServiceFormField(
                key: 'purpose',
                label: 'State the purpose of this certification',
                type: ServiceFieldType.textarea,
                hint: 'e.g. proof of residency, unemployment for TESDA, property ownership, event permit...',
              ),
            ],
          ),
        ],
      ),
      // Web Admin's own record for Perlita (DR-2026-2312).
      demoDefaults: {'purpose': 'For submission as a requirement for a local government transaction.'},
      demoRejectionReason:
          'The stated purpose requires supporting documentation that was not included with your request. '
          'Please attach the required supporting document and resubmit.',
    ),
    CatalogItem(
      key: 'dokyu_first_time_jobseeker',
      name: 'First Time Job Seeker Certificate (RA 11261)',
      office: 'Barangay Hall',
      fee: 'Free',
      days: 'Same day',
      requirements: ['One (1) valid government-issued ID or Birth Certificate', 'Proof of Barangay residency'],
      process: ['Submit Request', 'Barangay Verification', 'Approval', 'Release'],
      icon: 'user-check',
      // Sourced: First Time Job Seeker Certificate.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Applicant Details',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(
                key: 'confirmFirstTime',
                label: 'I confirm this is my first time seeking employment and I have never been previously employed.',
                type: ServiceFieldType.checkbox,
              ),
            ],
          ),
        ],
      ),
      demoDefaults: {'confirmFirstTime': true},
      // Web Admin's own record for Perlita (DR-2026-2336).
      demoPurpose: 'For local job application requirement.',
    ),
    // Moved here from Tulong (assistanceTypes) — this is an ID/membership
    // registration, not an assistance/benefit program (unlike e.g. Social
    // Pension, a genuine cash-benefit item that correctly stays in
    // Tulong), so it belongs in Dokyu alongside this project's other
    // resident identification/registration services. Reclassification
    // only — form fields, requirements, and behavior are byte-for-byte
    // unchanged from before the move; key renamed dokyu_* to match this
    // module's own naming convention (RequestsService has a matching
    // migration for any already-persisted request submitted before this
    // move, under the old Tulong category — see
    // _migrateSeniorCitizenIdCategory).
    CatalogItem(
      key: 'dokyu_senior_citizen_id',
      name: 'Senior Citizen ID Application (OSCA Membership)',
      office: 'Office for Senior Citizens Affairs',
      fee: 'Free',
      days: '3-5 working days',
      requirements: [
        'PSA Birth Certificate or valid ID showing birthdate',
        '2 recent 1x1 ID photos',
        'Barangay Certification',
      ],
      process: ['Submit Requirements', 'Office for Senior Citizens Affairs Verification', 'Approval', 'ID Release'],
      icon: 'id-card',
      // Sourced: MSWD - Senior Citizen Application Form.docx, OSCA
      // Membership Application (official). Distinct from the existing
      // Social Pension item, which is a cash-benefit program, not plain
      // membership/ID registration.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Personal Information',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(
                key: 'educationalAttainment',
                label: 'Educational Attainment',
                type: ServiceFieldType.select,
                options: ['None', 'Elementary', 'High School', 'Vocational', 'College', 'Post Graduate'],
              ),
              ServiceFormField(
                key: 'presentOccupation',
                label: 'Present Occupation',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'annualIncome',
                label: 'Annual Income (₱)',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'receivingPension',
                label: 'Currently Receiving a Pension',
                type: ServiceFieldType.checkbox,
                required: false,
              ),
              ServiceFormField(
                key: 'philsysIdNumber',
                label: 'PhilSys ID Number',
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: "Government Service Record",
            description: 'Fill in if you previously worked in government.',
            fields: [
              ServiceFormField(
                key: 'lastGovtOffice',
                label: 'Last Government Office',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'lastGovtPosition',
                label: 'Position',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(key: 'lastGovtYear', label: 'Year', type: ServiceFieldType.text, required: false),
            ],
          ),
        ],
      ),
      // 'presentOccupation', not 'occupation' — the wizard's generic
      // Master-Profile prefill only auto-matches the exact key 'occupation'
      // (see ServiceRequestWizardScreen's _masterEligibleKeys), so this
      // differently-named-but-same-meaning field needs its own explicit
      // demoDefault to actually get Perlita's real occupation instead of
      // silently staying blank. annualIncome/philsysIdNumber/lastGovt* are
      // deliberately left blank — she has no income, no PhilSys ID on
      // file, and no prior government employment to report.
      // 'educationalAttainment' — this field's own option list predates
      // the K-12 Senior High tier (no such option exists here at all), so
      // the wizard's generic Master-Profile select prefill safely skips it
      // rather than crashing; 'High School' is the closest valid,
      // non-fabricated approximation. Web Admin's own record for Perlita
      // (DR-2026-2345) includes this application under her account too
      // (generic purpose, no age claim), even though she's 25 — this
      // project's own catalog has no eligibility gate on this service
      // either, so it's treated the same as Web Admin's own approach:
      // filled where ordinary, never claiming she's actually a senior.
      demoDefaults: {'presentOccupation': 'Student', 'educationalAttainment': 'High School'},
      demoPurpose: 'Senior Citizen ID / OSCA membership application.',
    ),
    CatalogItem(
      key: 'dokyu_marriage_license',
      name: 'Application for Marriage License',
      office: 'Office of the Municipal Civil Registrar',
      fee: '₱300.00',
      days: '10 working days (includes 10-day posting period)',
      requirements: [
        'PSA Birth Certificate of both parties',
        'Community Tax Certificate (Cedula) of both parties',
        'Certificate of No Marriage (CENOMAR) from PSA',
        "Parent's Consent (if 18-20 y/o) or Advice (if 21-25 y/o)",
        '2x2 ID photos of both parties',
      ],
      process: ['Submit Application', '10-Day Posting Period', 'Payment', 'Release of License'],
      icon: 'heart',
      // Sourced: MCRO - Application for Marriage License.pdf, Municipal
      // Form 90 (official). "Consent to a Marriage of Person" / "Advice
      // Upon Intended Marriage" folded in as a requirement rather than a
      // separate service, per docs/DOKYU_TULONG_FORM_AUDIT.md.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: "First Party's Information",
            fields: [
              ServiceFormField(key: 'party1FullName', label: 'Full Name', type: ServiceFieldType.text),
              ServiceFormField(key: 'party1DateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'party1PlaceOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(key: 'party1Citizenship', label: 'Citizenship', type: ServiceFieldType.text),
              ServiceFormField(key: 'party1Residence', label: 'Residence', type: ServiceFieldType.text),
              ServiceFormField(key: 'party1Religion', label: 'Religion', type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'party1CivilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Widowed', 'Divorced / Annulled'],
              ),
              ServiceFormField(key: 'party1FatherName', label: "Father's Name", type: ServiceFieldType.text),
              ServiceFormField(
                key: 'party1MotherMaidenName',
                label: "Mother's Maiden Name",
                type: ServiceFieldType.text,
              ),
            ],
          ),
          ServiceFormStep(
            label: "Second Party's Information",
            fields: [
              ServiceFormField(key: 'party2FullName', label: 'Full Name', type: ServiceFieldType.text),
              ServiceFormField(key: 'party2DateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'party2PlaceOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(key: 'party2Citizenship', label: 'Citizenship', type: ServiceFieldType.text),
              ServiceFormField(key: 'party2Residence', label: 'Residence', type: ServiceFieldType.text),
              ServiceFormField(key: 'party2Religion', label: 'Religion', type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'party2CivilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Widowed', 'Divorced / Annulled'],
              ),
              ServiceFormField(key: 'party2FatherName', label: "Father's Name", type: ServiceFieldType.text),
              ServiceFormField(
                key: 'party2MotherMaidenName',
                label: "Mother's Maiden Name",
                type: ServiceFieldType.text,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Consent / Advice',
            description: 'Required only if either party is 18–25 years old.',
            fields: [
              ServiceFormField(
                key: 'consentGuardianName',
                label: 'Name of person giving consent/advice',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'consentGuardianRelationship',
                label: 'Relationship to applicant',
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
        ],
      ),
      // Web Admin's own record for Perlita (DR-2026-2337) includes this
      // application under her account with a generic purpose, but never
      // names a second party (nothing in her Constituents record
      // establishes who she's marrying) — First Party's Information is
      // legitimately her own real identity (party1DateOfBirth already
      // auto-fills via the wizard's generic birthdate rule), so it's
      // filled from her Resident Master Profile the same as any other
      // form; Second Party's Information is deliberately left blank rather
      // than inventing a fiancé's identity Web Admin never specified.
      demoDefaults: {
        'party1FullName': 'Perlita Quiambao',
        'party1PlaceOfBirth': 'Teresa, Rizal',
        'party1Citizenship': 'Filipino',
        'party1Residence': 'Purok 2, Barangay Bagumbayan, Teresa, Rizal',
        'party1CivilStatus': 'Single',
        'party1FatherName': 'Anselmo Quiambao',
        'party1MotherMaidenName': 'Lourdes Escano',
      },
      demoPurpose: 'Application for marriage license.',
    ),
    CatalogItem(
      key: 'dokyu_marriage_certificate_copy',
      name: 'Certified Copy of Marriage Certificate',
      office: 'Office of the Municipal Civil Registrar',
      fee: '₱155.00',
      days: '3-5 working days',
      requirements: [
        'One (1) valid government-issued ID',
        'Details of the record being requested (names of husband and wife, date of marriage)',
      ],
      process: ['Submit Request', 'Records Verification', 'Payment', 'Release'],
      icon: 'file-text',
      // Sourced: "Certified Copy of Marriage certificate.pdf" (official,
      // Municipal Form 97 — the same Certificate of Marriage record also
      // referenced by MCRO - Certificate of Marriage.pdf). This is a
      // request for a copy of an ALREADY-REGISTERED marriage — distinct
      // from dokyu_marriage_license above, which is for couples preparing
      // to marry. The certificate itself is the issued-output civil
      // registry record (parties' full bio-data, parents, consent,
      // solemnizing officer's certification, witnesses, LCRO/OCRG
      // processing boxes) — none of that is citizen-fillable, so only the
      // handful of identifying facts needed to actually locate the
      // existing record are asked here, per the same "the certificate is
      // the output, not the request form" principle already applied to
      // the Delayed Registration of Birth/Death items and Certificate of
      // Fetal Death.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Marriage Record Information',
            fields: [
              ServiceFormField(key: 'husbandFullName', label: "Husband's Full Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'wifeFullName', label: "Wife's Full Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'dateOfMarriage', label: 'Date of Marriage', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'placeOfMarriage',
                label: 'Place of Marriage',
                type: ServiceFieldType.text,
                hint: 'City/Municipality, Province',
              ),
              ServiceFormField(
                key: 'registryNumber',
                label: 'Registry Number',
                type: ServiceFieldType.text,
                required: false,
                hint: 'If known',
              ),
              ServiceFormField(
                key: 'numberOfCopies',
                label: 'Number of Copies',
                type: ServiceFieldType.number,
                required: false,
                hint: 'Defaults to 1 if left blank',
              ),
            ],
          ),
        ],
      ),
      // Web Admin's own record for Perlita (DR-2026-2338, purpose "For
      // submission as proof of civil status") never establishes her as
      // married — her Civil Status is Single (see the Perlita Master
      // Profile Web Admin sync) — so this is her requesting a copy of her
      // PARENTS' marriage certificate instead (a genuine, common real-world
      // reason to need one "as proof of civil status": establishing her
      // own legitimacy/parentage), reusing their already-established real
      // names rather than inventing a spouse for her. Previously this
      // prefilled 'Jerome Villaruel' as her own husband and a 2022 marriage
      // date, both inconsistent with her Single status and, for a
      // 25-year-old, a marriage date that couldn't predate her own birth.
      demoDefaults: {
        'husbandFullName': 'Anselmo Quiambao',
        'wifeFullName': 'Lourdes Quiambao',
        // ISO date string — CatalogItem's demoDefaults must stay a const
        // map (documentTypes/assistanceTypes are const lists), and
        // DateTime has no const constructor. Parsed back to DateTime by
        // ServiceRequestWizardScreen's own demoDefaults application. Set
        // safely before Perlita's own birthdate (February 4, 2001).
        'dateOfMarriage': '1999-05-10',
        'placeOfMarriage': 'Teresa, Rizal',
      },
      demoPurpose: 'For submission as proof of civil status.',
    ),
    CatalogItem(
      key: 'dokyu_delayed_birth_registration',
      name: 'Delayed Registration of Birth',
      office: 'Office of the Municipal Civil Registrar',
      fee: '₱200.00',
      days: '5-7 working days',
      requirements: [
        'Certificate of Non-Registration of Birth (PSA)',
        'Barangay Certification for Late Registration',
        'Baptismal Certificate or School Record, if available',
        'Affidavit of two (2) disinterested persons',
      ],
      process: [
        'Submit Application',
        'Office of the Municipal Civil Registrar Evaluation',
        'Posting (if required)',
        'Registration & Release',
      ],
      icon: 'file-text',
      // Sourced: "Affidavit for Delayed Registration of Birth" within MCRO
      // - Certificate of Live Birth.pdf (official — pages 2-3 of that
      // file; page 1 is the issued-output record, excluded).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Birth Details',
            fields: [
              ServiceFormField(key: 'childFullName', label: "Child's Full Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(key: 'fatherFullName', label: "Father's Full Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'motherMaidenName', label: "Mother's Maiden Name", type: ServiceFieldType.text),
              ServiceFormField(
                key: 'reasonForDelay',
                label: 'Reason for Delayed Registration',
                type: ServiceFieldType.textarea,
              ),
            ],
          ),
        ],
      ),
      // Web Admin's own record for Perlita (DR-2026-2339) includes this
      // application under her account with only a generic purpose — it
      // never names a specific child, so the Birth Details fields
      // (childFullName, father/mother, etc.) are deliberately left blank
      // rather than inventing a sibling or relative Web Admin never
      // established (see this pass's own report on why a deceased/
      // third-party subject is never fabricated).
      demoPurpose: 'Delayed registration of birth.',
    ),
    CatalogItem(
      key: 'dokyu_delayed_death_registration',
      name: 'Delayed Registration of Death',
      office: 'Office of the Municipal Civil Registrar',
      fee: '₱200.00',
      days: '5-7 working days',
      requirements: [
        'Certificate of Non-Registration of Death (PSA)',
        'Barangay Certification for Registration of Death',
        'Death records from attending physician/hospital, if available',
        'Affidavit of two (2) disinterested persons',
      ],
      process: [
        'Submit Application',
        'Office of the Municipal Civil Registrar Evaluation',
        'Posting (if required)',
        'Registration & Release',
      ],
      icon: 'file-text',
      // Sourced: "Affidavit for Delayed Registration of Death" within MCRO
      // - Certificate of Death.pdf (official — page 2 of that file; page 1
      // is the issued-output record, excluded).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Death Details',
            fields: [
              ServiceFormField(key: 'deceasedFullName', label: "Deceased's Full Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'dateOfDeath', label: 'Date of Death', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfDeath', label: 'Place of Death', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(key: 'religion', label: 'Religion', type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'citizenship', label: 'Citizenship', type: ServiceFieldType.text),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(key: 'fatherName', label: "Father's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'motherMaidenName',
                label: "Mother's Maiden Name",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'reasonForDelay',
                label: 'Reason for Delayed Registration',
                type: ServiceFieldType.textarea,
              ),
            ],
          ),
        ],
      ),
      // Web Admin's own record for Perlita (DR-2026-2340): "Delayed
      // registration of a deceased grandparent's death for civil registry
      // purposes" — an already-established Web Admin scenario, not
      // fabricated by this pass. No specific grandparent is named there,
      // so deceasedFullName/dateOfDeath/etc. stay blank rather than
      // inventing one; note this form's own 'sex'/'civilStatus' fields
      // describe the deceased grandparent, not Perlita herself, but the
      // wizard's generic Master-Profile prefill has no way to tell a
      // "this is about someone else" field apart from an ordinary one
      // sharing the same key name — see this pass's own report.
      demoPurpose: "Delayed registration of a deceased grandparent's death for civil registry purposes.",
    ),
    CatalogItem(
      key: 'dokyu_fetal_death',
      name: 'Certificate of Fetal Death',
      office: 'Office of the Municipal Civil Registrar',
      fee: '₱200.00',
      days: '5-7 working days',
      requirements: [
        'Medical Certificate of Fetal Death, signed by the attending physician, nurse, midwife, or hilot/traditional birth attendant',
        'Burial or Cremation Permit',
        'One (1) valid government-issued ID of the applicant/informant',
        'Affidavit of two (2) disinterested persons (for delayed registration)',
      ],
      process: [
        'Submit Application',
        'Office of the Municipal Civil Registrar Evaluation',
        'Posting (if required)',
        'Registration & Release',
      ],
      icon: 'file-text',
      // Sourced: MCRO - Certificate of Fetal Death.pdf (official, Municipal
      // Form 103A). Page 1's Fetus/Mother/Father/Marriage-of-Parents
      // sections are the citizen-known identifying facts the informant can
      // actually supply; the Medical Certificate's clinical
      // disease/condition entries (item 19a-19e), the physician's/health
      // officer's own certification, the Postmortem Certificate, the
      // Embalmer's Certification, and the civil registrar's processing
      // boxes are all filled and signed by medical/registrar staff, not
      // the applicant — excluded as a source of citizen-input fields, same
      // principle already applied to the sibling Delayed Registration of
      // Birth/Death items above. "Cause of Fetal Death" and "Reason for
      // Delay" instead come from page 2's "Affidavit for Delayed
      // Registration of Fetal Death", phrased as the informant's own lay
      // statement. Item 21 "Length of Pregnancy (in completed weeks)" is
      // gestational age, not a person's age — kept as its own plain number
      // field, deliberately never folded into the Date of Birth/Age rule.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Fetal Information',
            fields: [
              ServiceFormField(
                key: 'fetusFullName',
                label: "Fetus's Name",
                type: ServiceFieldType.text,
                required: false,
                hint: 'Leave blank if the fetus was not given a name',
              ),
              ServiceFormField(
                key: 'fetusSex',
                label: 'Sex',
                type: ServiceFieldType.select,
                options: ['Male', 'Female', 'Undetermined'],
              ),
              ServiceFormField(key: 'dateOfDelivery', label: 'Date of Delivery', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'placeOfDelivery',
                label: 'Place of Delivery',
                type: ServiceFieldType.text,
                hint: 'Hospital/Clinic/Institution, Barangay, City/Municipality, Province',
              ),
              ServiceFormField(
                key: 'typeOfDelivery',
                label: 'Type of Delivery',
                type: ServiceFieldType.select,
                options: ['Single', 'Twin', 'Triplet', 'Quadruplet', 'Other'],
              ),
              ServiceFormField(
                key: 'multipleDeliveryOrder',
                label: 'If Multiple Delivery, Fetus Was',
                type: ServiceFieldType.select,
                options: ['First', 'Second', 'Third', 'Fourth', 'Other'],
                visibleWhenKey: 'typeOfDelivery',
                visibleWhenValueIn: ['Twin', 'Triplet', 'Quadruplet', 'Other'],
              ),
              ServiceFormField(
                key: 'methodOfDelivery',
                label: 'Method of Delivery',
                type: ServiceFieldType.text,
                hint: 'e.g. Normal spontaneous vertex; specify if others',
              ),
              ServiceFormField(
                key: 'birthOrder',
                label: 'Birth Order',
                type: ServiceFieldType.number,
                required: false,
                hint: 'Live births and fetal deaths including this delivery',
              ),
              ServiceFormField(
                key: 'weightOfFetus',
                label: 'Weight of Fetus (grams)',
                type: ServiceFieldType.number,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: "Mother's Information",
            fields: [
              ServiceFormField(key: 'motherMaidenName', label: "Mother's Maiden Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'motherCitizenship', label: "Mother's Citizenship", type: ServiceFieldType.text),
              ServiceFormField(
                key: 'motherReligion',
                label: "Mother's Religion",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'motherOccupation',
                label: "Mother's Occupation",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'motherAgeAtDelivery',
                label: "Mother's Age at the Time of Delivery",
                type: ServiceFieldType.number,
              ),
              ServiceFormField(
                key: 'childrenBornAlive',
                label: 'Total Number of Children Born Alive',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'childrenStillLiving',
                label: 'Number of Children Still Living',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'childrenBornAliveNowDead',
                label: 'Number of Children Born Alive but Now Dead',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'motherResidence',
                label: "Mother's Residence",
                type: ServiceFieldType.text,
                hint: 'House No., Street, Barangay, City/Municipality, Province',
              ),
            ],
          ),
          ServiceFormStep(
            label: "Father's Information",
            description: 'Leave blank if not applicable.',
            fields: [
              ServiceFormField(
                key: 'fatherFullName',
                label: "Father's Name",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'fatherCitizenship',
                label: "Father's Citizenship",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'fatherReligion',
                label: "Father's Religion",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'fatherOccupation',
                label: "Father's Occupation",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'fatherAgeAtDelivery',
                label: "Father's Age at the Time of Delivery",
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'parentsMarriageDate',
                label: 'Date of Marriage of Parents',
                type: ServiceFieldType.date,
                required: false,
              ),
              ServiceFormField(
                key: 'parentsMarriagePlace',
                label: 'Place of Marriage of Parents',
                type: ServiceFieldType.text,
                required: false,
                hint: 'City/Municipality, Province, Country',
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Supporting Information',
            fields: [
              ServiceFormField(
                key: 'fetusDiedWhen',
                label: 'Fetus Died',
                type: ServiceFieldType.select,
                options: ['Before Labor', 'During Labor/Delivery', 'Unknown'],
              ),
              ServiceFormField(
                key: 'lengthOfPregnancy',
                label: 'Length of Pregnancy (completed weeks)',
                type: ServiceFieldType.number,
                hint: 'Gestational age — not the mother\'s or father\'s age',
              ),
              ServiceFormField(
                key: 'fetusAttendedStatus',
                label: 'Was the Delivery Attended',
                type: ServiceFieldType.select,
                options: ['Attended', 'Not Attended'],
              ),
              ServiceFormField(
                key: 'attendedByName',
                label: 'Attended By',
                type: ServiceFieldType.text,
                hint: 'Physician, Nurse, Midwife, Hilot/Traditional Birth Attendant, etc.',
                visibleWhenKey: 'fetusAttendedStatus',
                visibleWhenValueIn: ['Attended'],
              ),
              ServiceFormField(
                key: 'causeOfFetalDeath',
                label: 'Cause of Fetal Death',
                type: ServiceFieldType.textarea,
                hint: 'As known to you — describe in your own words',
              ),
              ServiceFormField(
                key: 'reasonForDelay',
                label: 'Reason for the Delay in Registering This Fetal Death',
                type: ServiceFieldType.textarea,
              ),
              ServiceFormField(
                key: 'corpseDisposal',
                label: 'Corpse Disposal',
                type: ServiceFieldType.select,
                options: ['Burial', 'Cremation', 'Other'],
                required: false,
              ),
              ServiceFormField(
                key: 'placeOfBurialOrCremation',
                label: 'Place of Burial/Cremation',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'dateOfBurialOrCremation',
                label: 'Date of Burial/Cremation',
                type: ServiceFieldType.date,
                required: false,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_barangay_cert_late_birth',
      name: 'Barangay Certification for Late Registration of Birth',
      office: 'Barangay Hall',
      fee: '₱50.00',
      days: '1-2 working days',
      requirements: ['One (1) valid government-issued ID', 'Baptismal Certificate or School Record, if available'],
      process: ['Submit Request', 'Barangay Verification', 'Approval', 'Release'],
      icon: 'file-text',
      // Sourced: BRGY.CERTIFICATION LATE REGISTRATION.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: "Person's Details",
            fields: [
              ServiceFormField(key: 'personFullName', label: 'Full Name', type: ServiceFieldType.text),
              ServiceFormField(key: 'fatherName', label: "Father's Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'motherMaidenName', label: "Mother's Maiden Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(key: 'citizenship', label: 'Citizenship', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(key: 'occupation', label: 'Occupation', type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'spouseName',
                label: "Spouse's Name (if married)",
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
        ],
      ),
      // Web Admin's own record for Perlita (DR-2026-2341): "Supporting
      // certification for a family member's late birth registration" — NOT
      // her own birth (her own is already registered — she has an existing
      // valid ID/Resident Profile). personFullName/motherMaidenName/
      // citizenship are deliberately left blank rather than naming a
      // specific relative Web Admin never establishes. Note this form's own
      // dateOfBirth/placeOfBirth/sex/civilStatus/occupation/fatherName
      // fields describe THAT family member, not Perlita — but the wizard's
      // generic Master-Profile prefill (including the Father/Mother block,
      // which matches on the 'fatherName' key alone) has no way to tell a
      // "this is about someone else" field apart from an ordinary one
      // sharing the same key name, so those will still show her own/her
      // father's values here; see this pass's own report.
      demoPurpose: "Supporting certification for a family member's late birth registration.",
    ),
    CatalogItem(
      key: 'dokyu_barangay_cert_death',
      name: 'Barangay Certification for Registration of Death',
      office: 'Barangay Hall',
      fee: '₱50.00',
      days: '1-2 working days',
      requirements: ['One (1) valid government-issued ID of claimant', 'Proof of relationship to the deceased'],
      process: ['Submit Request', 'Barangay Verification', 'Approval', 'Release'],
      icon: 'file-text',
      // Sourced: BRGY.CERTIFICATION REGISTRATION OF DEATH.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: "Deceased's Details",
            fields: [
              ServiceFormField(key: 'deceasedFullName', label: 'Full Name', type: ServiceFieldType.text),
              ServiceFormField(key: 'fatherName', label: "Father's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'motherMaidenName',
                label: "Mother's Maiden Name",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(key: 'dateOfDeath', label: 'Date of Death', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfDeath', label: 'Place of Death', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(key: 'religion', label: 'Religion', type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'citizenship', label: 'Citizenship', type: ServiceFieldType.text),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
            ],
          ),
        ],
      ),
      // Web Admin's own record for Perlita (DR-2026-2342): "Barangay-level
      // supporting certification for a deceased grandparent's death
      // registration" — the same already-established grandparent scenario
      // as Delayed Registration of Death above. No specific grandparent is
      // named there, so the Deceased's Details fields stay blank rather
      // than inventing one.
      demoPurpose: "Barangay-level supporting certification for a deceased grandparent's death registration.",
    ),
    CatalogItem(
      key: 'dokyu_pet_registration',
      name: 'Pet Registration',
      office: 'Municipal Agriculture Office',
      fee: '₱50.00',
      days: 'Same day',
      requirements: ['Proof of rabies vaccination, if applicable', 'One (1) valid government-issued ID of owner'],
      process: ['Submit Request', 'Records Verification', 'Approval', 'Release'],
      icon: 'paw-print',
      // Sourced: PET REGISTRATION FORM.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Pet Information',
            fields: [
              ServiceFormField(key: 'petName', label: "Pet's Name", type: ServiceFieldType.text),
              ServiceFormField(
                key: 'species',
                label: 'Species',
                type: ServiceFieldType.select,
                options: ['Dog', 'Cat', 'Other'],
              ),
              ServiceFormField(key: 'breed', label: 'Breed', type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'colorMarkings', label: 'Color / Markings', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'gender',
                label: 'Gender',
                type: ServiceFieldType.select,
                options: ['Male', 'Female'],
              ),
              ServiceFormField(
                key: 'dobOrApproxAge',
                label: 'Date of Birth / Approximate Age',
                type: ServiceFieldType.text,
              ),
              ServiceFormField(
                key: 'microchipNumber',
                label: 'Microchip Number',
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Health Information',
            fields: [
              ServiceFormField(
                key: 'lastRabiesVaccinationDate',
                label: 'Last Rabies Vaccination Date',
                type: ServiceFieldType.date,
                required: false,
              ),
              ServiceFormField(
                key: 'otherVaccinations',
                label: 'Other Vaccinations',
                type: ServiceFieldType.textarea,
                required: false,
              ),
              ServiceFormField(
                key: 'spayedNeutered',
                label: 'Spayed / Neutered',
                type: ServiceFieldType.select,
                options: ['Yes', 'No', 'Unknown'],
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Owner & Emergency Contact',
            fields: [
              ServiceFormField(key: 'ownerAddress', label: "Owner's Address", type: ServiceFieldType.text),
              ServiceFormField(
                key: 'emergencyContactName',
                label: 'Emergency Contact Name',
                type: ServiceFieldType.text,
              ),
              ServiceFormField(
                key: 'emergencyContactNumber',
                label: 'Emergency Contact Number',
                type: ServiceFieldType.text,
              ),
              ServiceFormField(
                key: 'additionalInfo',
                label: 'Additional Information',
                type: ServiceFieldType.textarea,
                required: false,
              ),
            ],
          ),
        ],
      ),
      demoDefaults: {
        'petName': 'Bantay',
        'species': 'Dog',
        'breed': 'Aspin (Asong Pinoy)',
        'colorMarkings': 'Brown with white chest patch',
        'gender': 'Male',
        'dobOrApproxAge': 'Approximately 2 years old',
        'spayedNeutered': 'No',
        'ownerAddress': 'Purok 2, Barangay Bagumbayan, Teresa, Rizal',
        // emergencyContactName/Number are deliberately NOT set here — this
        // form's own field keys exactly match ResidentProfile's own
        // Emergency Contact facts, so ServiceRequestWizardScreen's generic
        // Master-Profile prefill block fills them from the same real,
        // editable Rogelio Escano / 0919 000 9012 record used everywhere
        // else, instead of this catalog item inventing its own separate
        // (and previously stale — "Lourdes Perlita" used the pre-correction
        // surname bug) emergency contact just for a pet form.
      },
      // Web Admin's own record for Perlita (DR-2026-2343).
      demoPurpose: 'Registration of household pet dog for the municipal pet registry.',
    ),
    CatalogItem(
      key: 'dokyu_locational_clearance',
      name: 'Locational Clearance',
      office: 'Municipal Planning & Development Office (MPDO)',
      fee: '₱500.00 and up (based on project)',
      days: '5-7 working days',
      requirements: [
        'Lot Title (TCT/OCT) or Tax Declaration',
        'Barangay Clearance',
        'Vicinity / Location Map',
        'Site Development Plan (for new construction)',
      ],
      process: ['Submit Application', 'Site Evaluation', 'Assessment & Payment', 'Release'],
      icon: 'map-pin',
      // Sourced: Placeholders/Dokyu/CPDO-Application-for-Locational-
      // Clearance.pdf — no official Teresa, Rizal Locational Clearance form
      // was found, so this Placeholder is used (see audit doc). Adapted:
      // office renamed from the source's City CPDO to the municipal-level
      // equivalent, MPDO; no other City-specific details carried over.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Applicant & Representative',
            fields: [
              ServiceFormField(
                key: 'applicantType',
                label: 'Applicant Type',
                type: ServiceFieldType.select,
                options: ['Individual', 'Corporation', 'Partnership', 'Other'],
              ),
              ServiceFormField(
                key: 'authorizedRepName',
                label: "Authorized Representative's Name",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'authorizedRepAddress',
                label: "Authorized Representative's Address",
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Project Details',
            fields: [
              ServiceFormField(
                key: 'natureOfApplication',
                label: 'Nature of Application',
                type: ServiceFieldType.select,
                options: ['New Development', 'Improvement / Renovation', 'Change of Use', 'Other'],
              ),
              ServiceFormField(key: 'projectTitle', label: 'Project Title', type: ServiceFieldType.text),
              ServiceFormField(key: 'projectLocation', label: 'Project Location', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'floorArea',
                label: 'Floor Area (sqm)',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'buildingHeight',
                label: 'Building Height (m)',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'numberOfStoreys',
                label: 'Number of Storeys',
                type: ServiceFieldType.number,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Lot Information',
            fields: [
              ServiceFormField(key: 'lotArea', label: 'Lot Area (sqm)', type: ServiceFieldType.number),
              ServiceFormField(key: 'titleNumber', label: 'TCT / OCT No.', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'rightOverLand',
                label: 'Right Over Land',
                type: ServiceFieldType.select,
                options: ['Owner', 'Lessee', 'Other'],
              ),
              ServiceFormField(
                key: 'projectTenure',
                label: 'Project Tenure',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'zoningClassification',
                label: 'Land Use / Zoning Classification',
                type: ServiceFieldType.multiselect,
                options: [
                  'Residential',
                  'Commercial',
                  'Industrial',
                  'Institutional',
                  'Agricultural',
                  'Open Space',
                  'Forestry',
                  'Other',
                ],
              ),
            ],
          ),
        ],
      ),
      // Web Admin's own record for Perlita (DR-2026-2344): "Locational
      // clearance for a proposed structure" — a new structure, not a
      // renovation of an existing one (natureOfApplication/projectTitle
      // updated to match; previously said "Improvement / Renovation").
      demoDefaults: {
        'applicantType': 'Individual',
        'natureOfApplication': 'New Development',
        'projectTitle': 'Proposed Residential Structure - Quiambao Residence',
        'projectLocation': 'Purok 2, Barangay Bagumbayan, Teresa, Rizal',
        'floorArea': '45',
        'lotArea': '120',
        'titleNumber': 'OCT-2019-00456',
        'rightOverLand': 'Owner',
        'zoningClassification': <String>{'Residential'},
      },
      demoPurpose: 'Locational clearance for a proposed structure.',
    ),
  ];

  static const assistanceTypes = <CatalogItem>[
    CatalogItem(
      key: 'tulong_medical',
      name: 'Medical Assistance (AICS)',
      office: 'Municipal Social Welfare and Development Office',
      fee: 'Free',
      days: '3-5 working days',
      amount: '₱1,000 – ₱150,000 per case',
      requirements: [
        'One (1) valid government-issued ID',
        "Medical Abstract or Doctor's prescription",
        'Hospital bill or Statement of Account',
        'Barangay Certificate of Indigency',
      ],
      process: [
        'Submit Request',
        'Municipal Social Welfare and Development Office Assessment',
        'Approval',
        'Cash / Guarantee Letter Release',
      ],
      icon: 'stethoscope',
      // Web Admin's own record for Perlita (AR-2026-0230) — about her own
      // treatment, not her mother's (the previous wording named her mother
      // instead, which Web Admin's record doesn't establish).
      demoPurpose: 'Financial assistance for dental treatment expenses.',
      demoRejectionReason:
          'The Medical Abstract you submitted has already expired. Please secure an updated Medical '
          'Abstract or Statement of Account from the hospital and resubmit.',
    ),
    CatalogItem(
      key: 'tulong_burial',
      name: 'Burial Assistance (AICS)',
      office: 'Municipal Social Welfare and Development Office',
      fee: 'Free',
      days: '2-3 working days',
      amount: 'Up to ₱5,000',
      requirements: [
        'Death Certificate',
        'Valid ID of claimant',
        'Proof of relationship to the deceased',
        'Barangay Certificate of Indigency',
      ],
      process: ['Submit Request', 'Verify Death Certificate', 'Approval', 'Release'],
      icon: 'flower',
      // Web Admin's own record for Perlita (AR-2026-0231): "Burial
      // assistance for a deceased grandparent" — an already-established
      // Web Admin scenario (not fabricated by this pass — see this pass's
      // own report on why a deceased relative is otherwise never invented
      // outright). No specific grandparent is named there.
      demoPurpose: 'Burial assistance for a deceased grandparent.',
    ),
    CatalogItem(
      key: 'tulong_educational',
      name: 'Educational Assistance',
      office: 'Office of the Municipal Mayor',
      fee: 'Free',
      days: '10-15 working days',
      amount: 'Tuition + allowance per semester',
      // Aligned exactly to the Web Admin's own Educational Assistance
      // requirement list (Perlita Master Profile alignment pass) — three
      // requirements, each with its own upload area (see
      // ServiceRequestWizardScreen's _usesRequirementUploaders). 'Valid
      // Government-Issued ID' and 'Barangay Certificate of Indigency' use
      // wording already recognized/shared elsewhere in the catalog (see
      // utils/requirement_document_type.dart's documentTypeFor), so a
      // document uploaded once here can be offered for reuse on other
      // services that ask for the same document, and vice versa.
      requirements: [
        'Certificate of Enrollment',
        'Valid Government-Issued ID',
        'Barangay Certificate of Indigency',
      ],
      process: ['Submit Requirements', 'Scholarship Committee Review', 'Approval', 'Disbursement'],
      icon: 'graduation-cap',
      // Field shape adapted from Placeholders/Tulong/2F5.Application-for-
      // Scholarship.pdf — that source form is actually an NCIP (Indigenous
      // Peoples) scholarship application, so its IP/ICC-specific fields
      // (ethnolinguistic group, ancestral domain, etc.) were excluded;
      // only the general applicant/school/family shape was kept. See
      // audit doc.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Student Information',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(key: 'placeOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married'],
              ),
              ServiceFormField(key: 'schoolName', label: 'School Name', type: ServiceFieldType.text),
              ServiceFormField(key: 'yearOrGradeLevel', label: 'Year / Grade Level', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'degreeProgramOrCourse',
                label: 'Degree Program / Course',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'lastSchoolAverageGrade',
                label: 'Last School Year Average Grade',
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Family Background',
            fields: [
              ServiceFormField(key: 'fatherName', label: "Father's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'fatherOccupation',
                label: "Father's Occupation",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(key: 'motherName', label: "Mother's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'motherOccupation',
                label: "Mother's Occupation",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'parentsMonthlyIncome',
                label: "Parents' Monthly Income (₱)",
                type: ServiceFieldType.number,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Additional Information',
            fields: [
              ServiceFormField(
                key: 'communityInvolvement',
                label: 'Community / School Involvement',
                type: ServiceFieldType.textarea,
                required: false,
              ),
              ServiceFormField(
                key: 'postGraduationPlans',
                label: 'Plans After Graduation',
                type: ServiceFieldType.textarea,
                required: false,
              ),
            ],
          ),
        ],
      ),
      // Web Admin's own record for Perlita (AR-2026-0227): "Scholarship
      // program application."
      demoPurpose: 'Scholarship program application.',
      demoRejectionReason:
          'Your Certificate of Enrollment does not match the current academic term. Please secure an '
          'updated Certificate of Enrollment for the present school year and resubmit.',
    ),
    CatalogItem(
      key: 'tulong_financial',
      name: 'Financial Assistance (AICS)',
      office: 'Municipal Social Welfare and Development Office',
      fee: 'Free',
      days: '3-5 working days',
      amount: 'Based on social worker assessment',
      requirements: [
        'One (1) valid government-issued ID',
        'Barangay Certificate of Indigency',
        'Brief interview / social case study with the Municipal Social Welfare and Development Office',
      ],
      process: ['Submit Request', 'Social Case Study', 'Approval', 'Release'],
      icon: 'wallet',
      // Web Admin's own record for Perlita (AR-2026-0228): "Livelihood
      // capital support."
      demoPurpose: 'Livelihood capital support.',
      demoRejectionReason:
          'The social case study found an active source of household income that was not disclosed in '
          'your request. Please coordinate with the Municipal Social Welfare and Development Office to '
          'clarify your household situation.',
    ),
    CatalogItem(
      key: 'tulong_food',
      name: 'Food / Relief Assistance',
      office: 'Municipal Disaster Risk Reduction and Management Office',
      fee: 'Free',
      days: '1-2 working days',
      amount: 'Relief goods package',
      requirements: ['Barangay Certification', 'One (1) valid government-issued ID'],
      process: ['Submit Request', 'Barangay Verification', 'Approval', 'Distribution'],
      icon: 'package',
      // Web Admin's own record for Perlita (AR-2026-0229): "Relief
      // assistance following recent heavy rains affecting the household."
      demoPurpose: 'Relief assistance following recent heavy rains affecting the household.',
      demoRejectionReason:
          'Your household has already received a relief goods package for the current distribution cycle. '
          'Please wait for the next scheduled distribution.',
    ),
    CatalogItem(
      key: 'tulong_pension',
      name: 'Social Pension (Indigent Senior Citizen)',
      office: 'Office for Senior Citizens Affairs',
      fee: '₱100.00',
      days: '5-7 working days',
      amount: '₱1,000/month (₱3,000 per quarter)',
      requirements: [
        'Senior Citizen ID',
        'Affidavit of no pension, income, or family support',
        'Barangay Certification',
      ],
      process: [
        'Submit Requirements',
        'Office for Senior Citizens Affairs / DSWD Verification',
        'Enrollment',
        'Quarterly Release',
      ],
      icon: 'users',
      // Web Admin's own record for Perlita (AR-2026-0232): "Social pension
      // benefit application." — an already-established Web Admin scenario;
      // no fabricated senior-only sub-detail is added anywhere else on
      // this form (see this pass's own report).
      demoPurpose: 'Social pension benefit application.',
    ),
    CatalogItem(
      key: 'tulong_solo_parent',
      name: 'Solo Parent Cash Assistance',
      office: 'Municipal Social Welfare and Development Office',
      fee: 'Free',
      days: '3-5 working days',
      amount: 'Cash grant + goods, per assessment',
      requirements: ['Solo Parent ID', 'PSA Birth Certificate(s) of children', 'Barangay Certification'],
      process: [
        'Submit Requirements',
        'Municipal Social Welfare and Development Office Assessment',
        'Approval',
        'Release',
      ],
      icon: 'heart-handshake',
      // Sourced: MSWD - SOLO Parent Application Form.xlsx, DSWD Annex B
      // 2023 (official) — the richest single source found in the audit.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Identifying Information',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(key: 'placeOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'educationalAttainment',
                label: 'Educational Attainment',
                type: ServiceFieldType.select,
                options: ['None', 'Elementary', 'High School', 'Vocational', 'College', 'Post Graduate'],
              ),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated', 'Annulled'],
              ),
              ServiceFormField(key: 'occupation', label: 'Occupation', type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'monthlyIncome',
                label: 'Monthly Income (₱)',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'employmentStatus',
                label: 'Employment Status',
                type: ServiceFieldType.select,
                options: ['Employed', 'Self-Employed', 'Unemployed'],
              ),
              ServiceFormField(
                key: 'isPantawidBeneficiary',
                label: '4Ps (Pantawid) Beneficiary',
                type: ServiceFieldType.checkbox,
                required: false,
              ),
              ServiceFormField(
                key: 'isIndigenousPerson',
                label: 'Indigenous Person / IP Member',
                type: ServiceFieldType.checkbox,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Family Composition',
            description: 'List your children / dependents.',
            fields: [
              ServiceFormField(
                key: 'familyComposition',
                label: 'Children / Dependents (name, age, relationship)',
                type: ServiceFieldType.textarea,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Classification',
            description: 'Select the circumstance that best describes your situation as a solo parent.',
            fields: [
              ServiceFormField(
                key: 'soloParentClassification',
                label: 'Circumstance of Being a Solo Parent',
                type: ServiceFieldType.select,
                options: [
                  'Birth from rape / exploitation',
                  'Spouse of OFW abroad',
                  'Widow / widower',
                  'Unmarried parent who chose to keep the child',
                  'Spouse of a person detained or imprisoned',
                  'Legal guardian / adoptive / foster parent',
                  'Spouse with permanent incapacity',
                  'Relative caring for a child within the 4th degree of consanguinity',
                  'Legal or de facto separation',
                  'Pregnant woman who will raise the child alone',
                  'Annulment / nullity of marriage',
                  'Abandonment by spouse for at least 1 year',
                ],
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Needs & Emergency Contact',
            fields: [
              ServiceFormField(
                key: 'needsOrProblems',
                label: 'Needs / Problems You Would Like Assistance With',
                type: ServiceFieldType.textarea,
                required: false,
              ),
              ServiceFormField(
                key: 'emergencyContactName',
                label: 'Emergency Contact Name',
                type: ServiceFieldType.text,
              ),
              ServiceFormField(
                key: 'emergencyContactNumber',
                label: 'Emergency Contact Number',
                type: ServiceFieldType.text,
              ),
            ],
          ),
        ],
      ),
      // Everything else here (familyComposition, soloParentClassification,
      // employmentStatus, monthlyIncome, needsOrProblems) genuinely
      // requires being a solo parent, which Perlita is not (Single, no
      // dependents) — deliberately left unfilled rather than fabricated;
      // see this pass's own report. isPantawidBeneficiary is the one
      // service-specific field here that's a real, true fact already on
      // her Resident Master Profile (4Ps Beneficiary), so it's filled;
      // emergencyContactName/Number are covered by the wizard's own
      // generic Master-Profile prefill, not here. 'educationalAttainment'
      // — this field's own option list has no Senior High tier (see the
      // matching note on dokyu_senior_citizen_id); 'High School' is the
      // closest valid approximation. 'employmentStatus' is a REQUIRED
      // select whose own option list has no 'Student' entry (unlike PWD
      // Registration's own employmentStatus field, which does) — without a
      // value here the wizard's required-field validation blocks Continue
      // outright, an "appears fine in code but is actually stuck in the UI"
      // bug this audit specifically targets. 'Unemployed' is the honest,
      // non-fabricated fit (she is not Employed or Self-Employed).
      // 'familyComposition' (Children / Dependents) is also REQUIRED —
      // 'None' is the truthful, non-fabricated answer (she genuinely has
      // no children/dependents), not a fabricated name; same class of
      // required-field-blocks-Continue bug as employmentStatus above.
      demoDefaults: {
        'isPantawidBeneficiary': true,
        'educationalAttainment': 'High School',
        'employmentStatus': 'Unemployed',
        'familyComposition': 'None',
      },
      // Web Admin's own record for Perlita (AR-2026-0233): "Solo parent
      // cash assistance application." — a generic purpose; Web Admin
      // never names a specific solo-parent circumstance for her either.
      demoPurpose: 'Solo parent cash assistance application.',
    ),
    CatalogItem(
      key: 'tulong_pwd_registration',
      name: 'PWD Registration (PRPWD)',
      office: 'Persons with Disability Affairs Office',
      fee: 'Free',
      days: '5-7 working days',
      requirements: [
        'Medical Certificate or School/Employer Assessment confirming disability',
        '1x1 ID photo',
        'Barangay Certification',
      ],
      process: [
        'Submit Requirements',
        'Persons with Disability Affairs Office Assessment',
        'Approval',
        'ID Release',
      ],
      icon: 'accessibility',
      // Sourced: MSWD - PRPWD Form 2.pdf, DOH Philippine Registry for
      // Persons with Disability v3.0 (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Personal Information',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'religion', label: 'Religion', type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(key: 'bloodType', label: 'Blood Type', type: ServiceFieldType.text, required: false),
            ],
          ),
          ServiceFormStep(
            label: 'Disability Information',
            fields: [
              ServiceFormField(
                key: 'disabilityType',
                label: 'Type of Disability',
                type: ServiceFieldType.multiselect,
                options: [
                  'Deaf / Hard of Hearing',
                  'Intellectual Disability',
                  'Learning Disability',
                  'Mental Disability',
                  'Orthopedic Disability',
                  'Physical Disability (Non-Orthopedic)',
                  'Psychosocial Disability',
                  'Speech and Language Impairment',
                  'Visual Disability',
                ],
              ),
              ServiceFormField(
                key: 'causeOfDisability',
                label: 'Cause of Disability',
                type: ServiceFieldType.multiselect,
                options: [
                  'Acquired',
                  'Cancer',
                  'Chronic Illness',
                  'Congenital / Inborn',
                  'Injury',
                  'Rare Disease',
                  'Autism Spectrum Disorder',
                ],
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Education & Employment',
            fields: [
              ServiceFormField(
                key: 'educationalAttainment',
                label: 'Educational Attainment',
                type: ServiceFieldType.select,
                options: ['None', 'Elementary', 'High School', 'Vocational', 'College', 'Post Graduate'],
              ),
              ServiceFormField(
                key: 'employmentStatus',
                label: 'Employment Status',
                type: ServiceFieldType.select,
                options: ['Employed', 'Unemployed', 'Self-Employed', 'Student', 'Not Applicable'],
              ),
              ServiceFormField(key: 'occupation', label: 'Occupation', type: ServiceFieldType.text, required: false),
            ],
          ),
          ServiceFormStep(
            label: 'Family Background',
            description: 'Fill in whichever is applicable.',
            fields: [
              ServiceFormField(key: 'fatherName', label: "Father's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'motherName', label: "Mother's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'guardianName',
                label: "Guardian's Name",
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
        ],
      ),
      // Disability Information (disabilityType, causeOfDisability) is
      // deliberately left unfilled — inventing a disability for Perlita is
      // exactly the kind of fabricated identity attribute this pass must
      // never create (see this pass's own report); PWD Registration is
      // logically inapplicable to her as a full demo scenario, even though
      // the ordinary fields below still legitimately prefill.
      // fatherName/motherName are covered by the wizard's own generic
      // Father/Mother prefill, not here. 'educationalAttainment' — this
      // field's own option list has no Senior High tier (see the matching
      // note on dokyu_senior_citizen_id); 'employmentStatus' genuinely
      // includes 'Student', a real fact about her.
      demoDefaults: {'educationalAttainment': 'High School', 'employmentStatus': 'Student'},
      // Web Admin's own record for Perlita (AR-2026-0234): "PWD ID / PRPWD
      // registration application." — generic; no specific disability is
      // named there either, consistent with the note above.
      demoPurpose: 'PWD ID / PRPWD registration application.',
    ),
    CatalogItem(
      key: 'tulong_tupad',
      name: 'TUPAD Emergency Employment',
      office: 'Municipal Public Employment Service Office',
      fee: 'Free',
      days: '5-10 working days',
      amount: 'Minimum wage x days engaged',
      requirements: [
        'Valid government-issued ID',
        'Barangay Certification of Residency',
        'Certificate of Indigency, if applicable',
      ],
      process: [
        'Submit Profile',
        'Municipal Public Employment Service Office Screening',
        'Approval',
        'Deployment & Payout',
      ],
      icon: 'briefcase',
      // Sourced: MPESO - DOLE TUPAD PROFILE FORM.pdf, TSSD-EFIS03-010
      // (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Worker Classification',
            fields: [
              ServiceFormField(
                key: 'typeOfWorker',
                label: 'Type of Worker',
                type: ServiceFieldType.select,
                options: [
                  'Underemployed',
                  'Laid-off due to natural calamity',
                  'Laid-off due to economic crisis',
                  'Laid-off due to armed conflict',
                  'Self-employed with lost livelihood (seasonality)',
                ],
              ),
              ServiceFormField(
                key: 'specificBeneficiaryType',
                label: 'Specific Type of Beneficiary',
                type: ServiceFieldType.select,
                options: [
                  'Crop Grower / Farmer',
                  'Homebased Worker',
                  'Transport Driver',
                  'Vendor / Self-Employed',
                  'Livestock / Poultry Raiser',
                  'Fisherfolk',
                  'Laborer',
                  'PWD',
                  'Other',
                ],
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Personal & Household Information',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(key: 'spouseName', label: "Spouse's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'monthlyIncome', label: 'Monthly Income (₱)', type: ServiceFieldType.number),
              ServiceFormField(key: 'numberOfDependents', label: 'Number of Dependents', type: ServiceFieldType.number),
              ServiceFormField(
                key: 'currentOrPreviousEmployer',
                label: 'Current / Previous Employer',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'highestEducationalAttainment',
                label: 'Highest Educational Attainment',
                type: ServiceFieldType.select,
                options: ['None', 'Elementary', 'High School', 'Vocational', 'College', 'Post Graduate'],
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Skills Training',
            fields: [
              ServiceFormField(
                key: 'intentionToAvailSkillsTraining',
                label: 'I intend to avail of skills training after this project',
                type: ServiceFieldType.checkbox,
                required: false,
              ),
            ],
          ),
        ],
      ),
      demoDefaults: {
        'typeOfWorker': 'Underemployed',
        'specificBeneficiaryType': 'Vendor / Self-Employed',
        // spouseName deliberately left unset — Perlita's Civil Status is
        // Single (see the Perlita Master Profile Web Admin sync), so a
        // spouse's name here would contradict a fact this same field's own
        // profile already establishes. This field is optional and only
        // logically applies to a married applicant.
        'monthlyIncome': '9718',
        'numberOfDependents': '0',
        // 'highestEducationalAttainment', not 'educationalAttainment' — a
        // differently-named field, so it needs its own explicit value
        // rather than relying on the wizard's generic Master-Profile
        // prefill (which only matches the exact key 'educationalAttainment').
        // 'High School', not 'Senior High School' — this field's own
        // option list predates the K-12 Senior High tier and has no such
        // option at all (the wizard's own select-field prefill guard would
        // otherwise silently drop an unmatched value, but picking the
        // closest valid option here keeps the field genuinely prefilled
        // rather than left blank); "High School" is still accurate for a
        // Senior High School graduate.
        'highestEducationalAttainment': 'High School',
        'intentionToAvailSkillsTraining': true,
      },
      // Web Admin's own record for Perlita (AR-2026-0235): "Application for
      // short-term emergency employment during school break."
      demoPurpose: 'Application for short-term emergency employment during school break.',
    ),
    CatalogItem(
      key: 'tulong_tesda_registration',
      name: 'TESDA Skills Training Registration',
      office: 'Municipal Public Employment Service Office',
      fee: 'Free',
      days: '3-5 working days',
      requirements: ['Valid government-issued ID or Birth Certificate', '2x2 ID photo'],
      process: [
        'Submit Profile',
        'Municipal Public Employment Service Office / TESDA Screening',
        'Enrollment',
        'Training Start',
      ],
      icon: 'graduation-cap',
      // Sourced: MPESO - TESDA-DPA Form 1 Registration Form (MIS 03-01).pdf
      // (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Personal Information',
            fields: [
              ServiceFormField(key: 'email', label: 'Email / Facebook', type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'nationality', label: 'Nationality', type: ServiceFieldType.text),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(
                key: 'employmentStatusBeforeTraining',
                label: 'Employment Status Before Training',
                type: ServiceFieldType.select,
                options: ['Employed', 'Unemployed', 'Self-Employed'],
              ),
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'educationalAttainmentBeforeTraining',
                label: 'Educational Attainment Before Training',
                type: ServiceFieldType.select,
                options: ['Elementary', 'High School', 'Vocational', 'College', 'Post Graduate'],
              ),
              ServiceFormField(
                key: 'parentGuardianName',
                label: "Parent / Guardian's Name",
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Learner Classification',
            fields: [
              ServiceFormField(
                key: 'learnerClassification',
                label: 'Learner Classification',
                type: ServiceFieldType.multiselect,
                options: [
                  '4Ps Beneficiary',
                  'Agrarian Reform Beneficiary',
                  'Balik Probinsya',
                  'Displaced Worker',
                  'Farmer / Fisherman',
                  'Indigenous People / Cultural Community',
                  'Industry Worker',
                  'OFW / OFW Dependent',
                  'Out-of-School Youth',
                  'Rebel Returnee',
                  'Repatriated OFW',
                  'Student',
                  'TESDA Alumni',
                  'Uniformed Personnel',
                  'Victim of Natural Disaster',
                  'Other',
                ],
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Training Preference',
            fields: [
              ServiceFormField(
                key: 'courseOrQualification',
                label: 'Course / Qualification',
                type: ServiceFieldType.text,
              ),
              ServiceFormField(
                key: 'scholarshipPackage',
                label: 'Scholarship Package',
                type: ServiceFieldType.select,
                options: ['TWSP', 'PESFA', 'STEP', 'Other / None'],
              ),
            ],
          ),
        ],
      ),
      demoDefaults: {
        'nationality': 'Filipino',
        'employmentStatusBeforeTraining': 'Unemployed',
        // 'educationalAttainmentBeforeTraining', not 'educationalAttainment'
        // — needs its own explicit value; the wizard's generic prefill
        // only matches the exact key 'educationalAttainment'. 'High
        // School', not 'Senior High School' — this field's own option list
        // has no Senior High tier at all; see the matching note on
        // tulong_tupad's highestEducationalAttainment.
        'educationalAttainmentBeforeTraining': 'High School',
        // Both true facts on Perlita's own Resident Master Profile (Student;
        // 4Ps Beneficiary — see the Perlita Master Profile Web Admin sync),
        // never fabricated.
        'learnerClassification': <String>{'Student', '4Ps Beneficiary'},
        'courseOrQualification': 'Bookkeeping NC III',
        'scholarshipPackage': 'TWSP',
      },
      // Web Admin's own record for Perlita (AR-2026-0236): "Registration
      // for Bookkeeping NC III skills training program."
      demoPurpose: 'Registration for Bookkeeping NC III skills training program.',
    ),
    CatalogItem(
      key: 'tulong_erpat_registration',
      name: "ERPAT Program Registration (Fathers' Empowerment)",
      office: 'Municipal Social Welfare and Development Office',
      fee: 'Free',
      days: '3-5 working days',
      requirements: ['Valid government-issued ID', 'Barangay Certification'],
      process: [
        'Submit Registration',
        'Municipal Social Welfare and Development Office Review',
        'Enrollment',
        'Program Orientation',
      ],
      icon: 'users',
      // Sourced: MSWD - ERPAT FORMS.docx — Registration Form portion only
      // (official); the file's meeting-minutes portions are internal
      // staff records and excluded, see audit doc.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Personal Information',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(key: 'occupation', label: 'Occupation', type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'religion', label: 'Religion', type: ServiceFieldType.text, required: false),
            ],
          ),
          ServiceFormStep(
            label: 'Family & Background',
            fields: [
              ServiceFormField(
                key: 'familyComposition',
                label: 'Household Members (name, age, relationship)',
                type: ServiceFieldType.textarea,
              ),
              ServiceFormField(
                key: 'educationalAttainment',
                label: 'Educational Attainment',
                type: ServiceFieldType.select,
                options: ['None', 'Elementary', 'High School', 'Vocational', 'College', 'Post Graduate'],
              ),
              ServiceFormField(
                key: 'specialSkillsHobbies',
                label: 'Special Abilities / Skills / Hobbies',
                type: ServiceFieldType.textarea,
                required: false,
              ),
              ServiceFormField(
                key: 'communityInvolvement',
                label: 'Community Involvement',
                type: ServiceFieldType.textarea,
                required: false,
              ),
            ],
          ),
        ],
      ),
      // 'familyComposition' and 'educationalAttainment' are both REQUIRED
      // fields the generic Master-Profile mechanisms don't reach (the
      // former has no generic source at all; the latter's option list has
      // no Senior High tier, so the master-eligible guard safely skips it)
      // — left blank, both would silently block Continue past this step, a
      // real "appears fine in code but is actually stuck in the UI" bug
      // this audit specifically targets. Household Members lists the seeded synthetic,
      // already-established household (Father, Mother, herself) — a true
      // fact, not a fabricated one; 'High School' is the same closest
      // valid, non-crashing educational-attainment approximation used
      // elsewhere in this pass.
      demoDefaults: {
        'familyComposition': 'Anselmo Quiambao (Father), Lourdes Quiambao (Mother), Perlita Quiambao (Self)',
        'educationalAttainment': 'High School',
      },
      // Web Admin's own record for Perlita (AR-2026-0237): "ERPAT program
      // registration." — generic; Web Admin never reframes her sex or
      // household role to fit the fathers'-program framing, consistent
      // with this pass never doing so either.
      demoPurpose: 'ERPAT program registration.',
    ),
  ];

  /// Incident types a citizen can report — mirrors the Web Admin's Sakuna >
  /// Incidents module intent (config/teresa_rizal_rbac.php's 'sakuna_incidents'
  /// submodule), scaled down to what a citizen-facing report form needs.
  static const incidentTypes = <CatalogItem>[
    CatalogItem(
      key: 'incident_flood',
      name: 'Flooding',
      office: 'MDRRMO',
      fee: 'Free',
      days: 'Immediate — 24 hrs',
      requirements: ['Location / landmark', 'Photo of the affected area if safe to take'],
      process: ['Submit Report', 'MDRRMO Validation', 'Dispatch / Response', 'Close'],
      icon: 'waves',
    ),
    CatalogItem(
      key: 'incident_fire',
      name: 'Fire',
      office: 'BFP / MDRRMO',
      fee: 'Free',
      days: 'Immediate',
      requirements: ['Location / landmark', 'Photo if safe to take'],
      process: ['Submit Report', 'Dispatch', 'Response', 'Close'],
      icon: 'flame',
    ),
    CatalogItem(
      key: 'incident_landslide',
      name: 'Landslide',
      office: 'MDRRMO',
      fee: 'Free',
      days: 'Immediate — 24 hrs',
      requirements: ['Location / landmark', 'Photo of the affected area if safe to take'],
      process: ['Submit Report', 'MDRRMO Validation', 'Dispatch / Response', 'Close'],
      icon: 'mountain',
    ),
    CatalogItem(
      key: 'incident_medical',
      name: 'Medical Emergency',
      office: 'Municipal Health Office / MDRRMO',
      fee: 'Free',
      days: 'Immediate',
      requirements: ['Location / landmark', 'Nature of emergency'],
      process: ['Submit Report', 'Dispatch', 'Response', 'Close'],
      icon: 'siren',
    ),
    CatalogItem(
      key: 'incident_road',
      name: 'Road Accident',
      office: 'MDRRMO / PNP',
      fee: 'Free',
      days: 'Immediate',
      requirements: ['Location / landmark', 'Photo if safe to take'],
      process: ['Submit Report', 'Dispatch', 'Response', 'Close'],
      icon: 'car-crash',
    ),
    CatalogItem(
      key: 'incident_other',
      name: 'Other Concern',
      office: 'MDRRMO',
      fee: 'Free',
      days: '1-2 working days',
      requirements: ['Description of the concern', 'Location / landmark'],
      process: ['Submit Report', 'Validation', 'Response', 'Close'],
      icon: 'flag',
    ),
  ];

  /// Evacuation centers the citizen can read. The UI orders them by the
  /// signed-in profile barangay, then by name. There is no GPS and no
  /// distance. `currentOccupancy` is deliberately left unset everywhere:
  /// there is no live capacity feed, and the emergency spec explicitly
  /// forbids inventing one — the detail screen shows "Capacity
  /// information unavailable" instead.
  static const evacuationCenters = <EvacuationCenter>[
    EvacuationCenter(
      name: 'Poblacion Covered Court',
      barangay: 'Poblacion',
      totalCapacity: 300,
      services: ['Emergency Shelter', 'Medical Aid Station', 'Relief Goods Distribution'],
      amenities: ['Restrooms', 'Drinking Water', 'Electricity', 'Covered Sleeping Area'],
      contactNumber: '(056) 333-1090',
    ),
    EvacuationCenter(
      name: 'Dalig Elementary School',
      barangay: 'Dalig',
      totalCapacity: 180,
      services: ['Emergency Shelter', 'Feeding Program'],
      amenities: ['Restrooms', 'Drinking Water', 'Classrooms for Families'],
      contactNumber: '(056) 333-1056',
    ),
    EvacuationCenter(
      name: 'San Roque Barangay Hall',
      barangay: 'San Roque',
      totalCapacity: 120,
      services: ['Emergency Shelter'],
      amenities: ['Restrooms', 'Drinking Water'],
      contactNumber: '(056) 333-1021',
    ),
  ];

  static const emergencyHotlines = [
    ('MDRRMO Teresa, Rizal', '(056) 333-1090'),
    ('Municipal Health Office', '(056) 333-1056'),
    ('Bureau of Fire Protection', '(056) 333-1077'),
    ('PNP Teresa, Rizal', '(056) 333-1000'),
  ];

  static final directoryOffices = [
    ('Office of the Municipal Mayor', 'Hon. Ricardo M. Espallardo', '(056) 333-1021'),
    ('Municipal Social Welfare & Development Office', 'Ms. Lourdes P. Villareal', '(056) 333-1044'),
    ("Municipal Treasurer's Office", 'Mr. Bienvenido T. Salazar', '(056) 333-1032'),
    ('Municipal Health Office', 'Dr. Leilani F. Domingo', '(056) 333-1056'),
    ('Office of the Municipal Civil Registrar', 'Narec N. Conag', '(056) 333-1067'),
    ('ICT Office', 'Engr. Paolo J. Reyes', '(056) 333-1099'),
  ];

  /// Section 8 of the Resident Profiling spec — a static "we found a
  /// similar family already on record" simulation, keyed by barangay. No
  /// real matching happens; this is what ResidentProfile's Family
  /// Information step checks against before showing the "Request to Join
  /// Family" banner.
  static const existingFamilyMatches = <String, ExistingFamilyMatch>{
    'Labangtaytay': ExistingFamilyMatch(familyName: 'Sarmiento Family', barangay: 'Labangtaytay'),
    'Agoho': ExistingFamilyMatch(familyName: 'Quiambao Family', barangay: 'Agoho'),
  };

  /// Event listings stay. Their posters named another municipality, so
  /// [imagePath] is empty until Teresa, Rizal art exists. The Events list
  /// paints a dashed 16:9 slot in that gap.
  static final events = [
    EventItem(
      title: 'Basketball Match Schedule — Bagumbayan vs Dalig, Dulumbayan vs Poblacion',
      date: 'Aug 3, 2026',
      time: '6:00 PM & 8:00 PM',
      venue: 'Teresa Municipal Covered Court',
      category: 'Sports',
    ),
    EventItem(
      title: 'Mega Shoe Caravan',
      date: 'Aug 7–8, 2026',
      time: '7:00 AM – 2:00 PM',
      venue: 'Teresa, Rizal Covered Court',
      category: 'Promo',
    ),
    EventItem(
      title: 'Basketball Quarter Final — May-Iba vs Prinza, San Gabriel vs San Roque',
      date: 'Aug 12, 2026',
      time: '6:00 PM & 8:00 PM',
      venue: 'Teresa Municipal Covered Court',
      category: 'Sports',
    ),
    EventItem(
      title: 'Basketball Quarter Final — Calumpang vs Bagumbayan, Dalig vs San Roque',
      date: 'Aug 13, 2026',
      time: '6:00 PM & 8:00 PM',
      venue: 'Teresa Municipal Covered Court',
      category: 'Sports',
    ),
    EventItem(
      title: 'Pa Jollibee ug Sorbetes ni Mayor JJ!',
      date: 'Aug 21, 2026',
      time: '2:00 PM',
      venue: 'Teresa Municipal Covered Court',
      category: 'Community',
      isFree: true,
    ),
    EventItem(
      title: 'Blood donation drive — Brgy. Bagumbayan',
      date: 'Aug 2, 2026',
      time: '8:00 AM – 12:00 PM',
      venue: 'Bagumbayan Barangay Hall, Teresa, Rizal',
      category: 'Community',
      upcoming: false,
      isFree: true,
    ),
    // Pack C sample. Appended so the Upcoming hub's first fold (Next up +
    // the existing cards) stays put. Poster art is not bundled.
    EventItem(
      id: 'evt-health-caravan',
      title: 'Health Caravan',
      date: 'Sun, Oct 5, 2026',
      time: '8:00 AM – 12:00 PM',
      venue: 'Municipal Hall, Teresa, Rizal',
      summary:
          'Free medical & dental check-up for Teresa, Rizal residents. Walk-ins welcome while supplies last.',
      whereNote: 'Poblacion · text address only — no map tiles',
      agenda: const [
        'Registration & vital signs',
        'General medical & dental check-up',
        'Health education & free BP check',
      ],
      upcoming: true,
      isFree: true,
    ),
    EventItem(
      id: 'evt-health-caravan-past',
      title: 'Health Caravan',
      date: 'Sun, Aug 10, 2026',
      time: '8:00 AM – 12:00 PM',
      venue: 'Municipal Hall, Teresa, Rizal',
      summary:
          'Free medical & dental check-up for Teresa, Rizal residents. Walk-ins welcome while supplies last.',
      endedDetail:
          'Held Aug 10, 2026 at Municipal Hall. RSVP and calendar add are unavailable for past events in this preview.',
      agenda: const [
        'Registration & vital signs',
        'General medical check-up',
        'Dental screening',
      ],
      upcoming: false,
      isFree: true,
    ),
  ];

  static final announcements = [
    // Lead card for the Balita social stills. The photo is a generated van
    // (no people, no real plate). The mayor is not named.
    Announcement(
      id: 'bal-lgu-ambulance',
      official: 'Teresa, Rizal LGU',
      author: 'Teresa, Rizal LGU',
      barangay: null,
      title: 'New LGU Teresa ambulance for residents',
      kind: 'Abiso',
      body: 'Joint project of the Municipal Mayor with community partners.',
      time: 'Sep 22',
      media: const PostMedia(
        path: 'assets/images/balita/lgu_ambulance.png',
        type: PostMediaType.image,
        isAsset: true,
      ),
      likes: 129,
      liked: true,
      shares: 6,
      viewCount: 240,
      commentTotal: 24,
      comments: [
        PostComment(
          author: 'Juan R.',
          body: 'Salamat po, Mayor. Useful for emergencies.',
          time: '2h',
        ),
        PostComment(
          author: 'Ana L.',
          body: 'Good news for Barangay Dalig.',
          time: '5h',
        ),
        PostComment(
          author: 'Kim S.',
          body: 'Please post the ambulance request schedule.',
          time: '1d',
        ),
      ],
    ),
    // Teresa, Rizal places only. The old certificate photo named barangays
    // that are not in this municipality, so it is not shown.
    Announcement(
      id: 'bal-mangrove-award',
      official: 'Teresa, Rizal LGU',
      author: 'Teresa, Rizal LGU',
      barangay: null,
      title: 'Bagumbayan at Dalig River Cleanup',
      kind: 'Abiso',
      body:
          'Inaanyayahan ng LGU Teresa, Rizal ang mga taga-Bagumbayan, Dalig, at Dulumbayan sa Sabado, 7AM, sa Municipal Plaza. '
          'Magdala ng tubig at guwantes. Maraming salamat sa pag-aalaga ng ating ilog dito sa Teresa, Rizal! 🌿',
      time: '2 weeks ago',
      // Lead photo stays a dashed 16:9 slot until a Teresa-only photo
      // exists. The previous file was a municipal hall facade that is not
      // Teresa, Rizal.
      media: const PostMedia(path: balitaPhotoSlotPath, type: PostMediaType.image, isAsset: false),
      likes: 89,
      shares: 21,
      viewCount: 410,
      comments: const [],
    ),
    Announcement(
      id: 'bal-1',
      official: 'Teresa, Rizal LGU',
      author: 'Teresa, Rizal LGU',
      barangay: null,
      title: 'Pagdiriwang sa Municipal Plaza',
      kind: 'Programa',
      body:
          'Sumali sa buong-munisipyong pagdiriwang ngayong Agosto! Street dancing, trade fair, at gabi-gabing cultural program sa Municipal Plaza. Maligayang pagdating sa lahat! 🎉',
      time: 'Posted yesterday',
      // No aerial still. That file includes a hall facade that is not a
      // Teresa, Rizal photo. Text-only until Teresa art exists.
      likes: 214,
      shares: 18,
      viewCount: 320,
      comments: [
        PostComment(author: 'Nicanor Sarmiento', body: 'Sama-sama tayo dito, Teresa, Rizal! 🎉', time: '20 hrs ago'),
        PostComment(author: 'Perlita Quiambao', body: 'Anong oras magsisimula yung trade fair po?', time: '15 hrs ago'),
      ],
    ),
    Announcement(
      id: 'bal-2',
      official: '',
      author: 'Elmer Bantillo',
      barangay: 'Bagumbayan',
      title: 'Blood donation drive sa Bagumbayan',
      kind: 'Programa',
      body:
          'Successful po ang blood donation drive natin ngayong araw dito sa Brgy. Bagumbayan! Umabot ng 40+ na donors. Maraming salamat sa lahat ng dumalo at sa Philippine Red Cross! 🩸🙏',
      time: '3 hrs ago',
      likes: 47,
      shares: 4,
      viewCount: 165,
      comments: [
        PostComment(author: 'Teresa, Rizal LGU', body: 'Salamat sa inyong serbisyo, Brgy. Bagumbayan! 👏', time: '2 hrs ago'),
      ],
    ),
    Announcement(
      id: 'bal-3',
      official: 'Teresa, Rizal LGU',
      author: 'Teresa, Rizal LGU',
      barangay: null,
      title: 'Libreng anti-rabies vaccination',
      kind: 'Abiso',
      body:
          'Libreng anti-rabies vaccination para sa mga alagang aso at pusa sa Poblacion Covered Court ngayong Linggo, 8AM-4PM. Dalhin ang inyong alagang hayop!',
      time: '2 days ago',
      likes: 132,
      shares: 9,
      viewCount: 290,
      comments: const [],
    ),
    Announcement(
      id: 'bal-4',
      official: 'Teresa, Rizal LGU',
      author: 'MDRRMO Teresa, Rizal',
      barangay: null,
      title: 'Disaster preparedness orientation',
      kind: 'Abiso',
      body:
          'Paalala: Disaster preparedness orientation sa lahat ng barangay captains bukas, 9AM sa Municipal Hall Conference Room. Mandatory ang attendance bilang parte ng Typhoon Season Readiness Program.',
      time: '4 days ago',
      likes: 58,
      shares: 12,
      viewCount: 210,
      comments: [
        PostComment(
          author: 'Perlita Quiambao',
          body: 'Noted po, sasabihin ko sa Brgy. Captain namin.',
          time: '3 days ago',
        ),
      ],
    ),
    // Pack C sample. Appended so the Balita hub's first fold is unchanged.
    // The photograph is the detail hero
    // (`assets/images/balita/lgu-ambulance.jpg`), not this hub card.
    Announcement(
      id: 'bal-ambulance',
      official: 'Municipality of Teresa',
      author: 'Municipality of Teresa',
      barangay: null,
      title: 'New LGU Teresa ambulance for residents',
      kind: 'Abiso',
      body:
          'The Municipality of Teresa, Rizal unveiled a new ambulance unit to strengthen emergency response for barangays. The unit supports medical transport for residents who need timely care.\n\n'
          'Mayor Rodel N. Dela Cruz thanked community partners. Local preview sample — not a live dispatch feed.',
      time: 'Sep 22, 2026',
      likes: 129,
      liked: true,
      shares: 0,
      viewCount: 0,
      commentTotal: 24,
      comments: [
        PostComment(
          author: 'Juan R.',
          body: 'Salamat po, Mayor. Useful for emergencies.',
          time: '2h',
        ),
        PostComment(
          author: 'Ana L.',
          body: 'Good news for Barangay Dalig.',
          time: '5h',
        ),
      ],
    ),
  ];

  /// One sample resident per barangay is available in the real config —
  /// this mobile demo carries a smaller representative set for the "log in
  /// as this resident" quick-demo login, mirroring the Web Admin's own
  /// frontend-only session-simulation pattern (no real password checking).
  static final demoAccounts = [
    CitizenAccount(
      id: 'ESP-RES-2024-9001',
      firstName: 'Nicanor',
      lastName: 'Sarmiento',
      email: 'nicanor.sarmiento@example.com',
      mobile: '0918 000 9001',
      barangay: 'Labangtaytay',
      purok: 'Purok 2',
      address: 'Purok 2, Barangay Labangtaytay, Teresa, Rizal',
      birthdate: 'June 8, 1990',
      sex: 'Male',
      civilStatus: 'Married',
      occupation: 'Fisherman',
      profileCompleteness: 78,
      // Demo account for the "registered but not yet verified" state — see
      // Section 7 of the nav-and-access spec. Registration is complete;
      // LGU verification is still pending.
      status: 'Pending Review',
    ),
    // SCENARIO: the fully verified citizen. Status 'Approved', so
    // AccessLevel.verified — the only demo account that reaches Dokyu and
    // Tulong. Exists to exercise the unrestricted path end to end: request
    // submission, the Digital ID wallet, a complete resident profile, and a
    // single-member household with a seeded Father and Mother in Family
    // Information (see ResidentProfileService's master-profile alignment).
    //
    // This identity is SYNTHETIC and must stay that way. It is not sourced
    // from any constituent record, roster or dataset, and its ids sit in a
    // 9xxx block chosen to be self-evidently invented. Until 2026-08-29 this
    // account was a real resident's actual Constituents record — name,
    // birthdate, address, household and family ids all copied from it — in a
    // public repository. See docs/FE02_SYNTHETIC_IDENTITIES.md.
    //
    // test/no_real_identities_test.dart fails if a retired real name or
    // record id ever reappears anywhere under lib/, test/ or assets/.
    CitizenAccount(
      id: 'ESP-RES-2024-9002',
      firstName: 'Perlita',
      lastName: 'Quiambao',
      email: 'perlita.quiambao@example.com',
      mobile: '0919 000 9002',
      barangay: 'Bagumbayan',
      purok: 'Purok 2',
      address: 'Purok 2, Barangay Bagumbayan, Teresa, Rizal',
      birthdate: 'February 4, 2001',
      sex: 'Female',
      civilStatus: 'Single',
      occupation: 'Student',
      profileCompleteness: 90,
      // Demo account for the "fully verified resident" state — full
      // access to verified-only features (Dokyu/Tulong).
      status: 'Approved',
    ),
  ];

  /// Demo-only "One Person, One Account" duplicate simulation (Phase 6) —
  /// a second registration using the real Perlita Quiambao's identity.
  /// Deliberately kept OUT of [demoAccounts] rather than appended to it:
  /// several call sites (this file's own callers, several tests) use
  /// `demoAccounts.last` to mean "the verified demo account" — appending
  /// here would silently redirect every one of those to this account
  /// instead. The Sign In screen wires this up as its own explicitly
  /// labeled button, never through the generic demo-account list.
  static final duplicateVerifiedDemoAccount = CitizenAccount(
    id: 'ESP-RES-2024-9002-DUP',
    firstName: 'Perlita',
    lastName: 'Quiambao',
    email: 'perlita.quiambao.dup@example.com',
    // Same Perlita-derived resident-fact fields as the real Perlita account
    // above — required so the two look like a genuine identity match; only
    // the id/email suffix, lower profileCompleteness, and Pending status
    // distinguish this as the duplicate registration.
    mobile: '0919 000 9002',
    barangay: 'Bagumbayan',
    purok: 'Purok 2',
    address: 'Purok 2, Barangay Bagumbayan, Teresa, Rizal',
    birthdate: 'February 4, 2001',
    sex: 'Female',
    civilStatus: 'Single',
    occupation: 'Student',
    profileCompleteness: 35,
    // Never becomes 'Approved' in this simulation — see
    // screens/notifications/duplicate_account_details_screen.dart.
    // Verification stays blocked regardless of how the duplicate-alert
    // is resolved.
    status: 'Pending Review',
  );

  /// Perlita's one seeded government ID document — the asset placed at
  /// assets/images/PERLITA DEMO ID.png, read by Profile > Personal
  /// Information's Submitted Government ID section (see
  /// utils/government_id.dart) so there is exactly one record, never two
  /// unrelated copies. A PHLPost Postal ID, per the asset itself — a demo
  /// watermark ("DEMO ID ONLY — NOT A VALID GOVERNMENT IDENTIFICATION") is
  /// printed directly on the card image.
  ///
  /// The card's own printed name reads "Perlita Quiambao" — a leftover
  /// from before this project's demo identity was corrected to Perlita
  /// Quiambao's real Web Admin record. The printed address (Purok 2,
  /// Barangay Bagumbayan) still matches exactly, but the printed date of birth
  /// (September 3, 1988) is now STALE — the Master Profile alignment
  /// passes have since corrected Perlita's actual birthdate to March 15,
  /// 2001 (the synthetic verified-demo profile), and per this project's
  /// rule against generating new ID images, this asset was intentionally
  /// left untouched. This is a known, reported printed-vs-profile mismatch
  /// (see this correction's own report), not an oversight; only a person
  /// can supply a replacement image with the corrected name/birthdate.
  static const verifiedDemoGovernmentId = GovernmentIdRecord(
    accountId: 'ESP-RES-2024-9002',
    idType: 'Postal ID (PHLPost)',
    assetPath: 'assets/images/PERLITA DEMO ID.png',
    idNumber: 'PRN 100141234567 P',
    issuingOffice: 'Teresa, Rizal',
  );

  /// Perlita Quiambao's Digital ID wallet — seeded demonstration data only,
  /// for the VERIFIED Perlita account (ESP-RES-2024-9002) exclusively. Never
  /// shown to Nicanor, Anacleto, or any other seeded account, and never
  /// inferred/derived for a real resident. A different concept entirely
  /// from [verifiedDemoGovernmentId] above — see DigitalCredential's own doc
  /// comment. Order matters: the Digital ID screen opens on the first
  /// entry (Barangay Resident ID), per this feature's spec.
  ///
  /// No `validUntil` is set for either — neither asset prints an expiry
  /// date, so none is invented here (see DigitalCredential.validUntil's own
  /// doc comment).
  ///
  /// Both card images also print "NOV 29, 1988" as Date of Birth (and
  /// "Barangay Libertad" as address, a separate, pre-existing mismatch from
  /// before this alignment pass) — now stale against the corrected Master
  /// Profile birthdate (February 4, 2001). Neither [DigitalCredential]
  /// itself nor this screen's own info panel has a structured DOB field
  /// (see that class's fields), so nothing in the app's own UI text
  /// contradicts the corrected profile — only the baked-in card artwork
  /// does. Per this project's rule against generating new ID images, both
  /// assets are left untouched; this is a known, reported mismatch (see
  /// this alignment pass's own report), not an oversight.
  static const verifiedDemoDigitalCredentials = <DigitalCredential>[
    DigitalCredential(
      id: 'perlita-barangay-resident-id',
      type: 'barangay_resident_id',
      displayName: 'Barangay Resident ID',
      holderName: 'Perlita Quiambao',
      frontAsset: 'assets/images/BarangayID_Front.png',
      backAsset: 'assets/images/BarangayID_Back.png',
      issuer: 'Municipality of Teresa, Rizal',
    ),
    DigitalCredential(
      id: 'perlita-pwd-id',
      type: 'pwd_id',
      displayName: 'PWD ID',
      holderName: 'Perlita Quiambao',
      frontAsset: 'assets/images/PWD_Front.png',
      backAsset: 'assets/images/PWD_Back.png',
      issuer: 'Municipal Social Welfare and Development Office',
    ),
  ];

  /// Nicanor's one seeded government ID document — the asset placed at
  /// assets/images/NICANOR ID DEMO.png, a purpose-built "Teresa, Rizal Resident
  /// ID" card (not a real Philippine ID type, unlike Perlita's Postal ID).
  /// Every field printed on it — name, resident ID ESP-RES-2024-9001,
  /// birthdate, address, sex, barangay/purok, civil status, occupation,
  /// and "PENDING REVIEW" account status — matches his CitizenAccount
  /// record exactly.
  static const pendingDemoGovernmentId = GovernmentIdRecord(
    accountId: 'ESP-RES-2024-9001',
    idType: 'Teresa, Rizal Resident ID',
    assetPath: 'assets/images/NICANOR ID DEMO.png',
    idNumber: 'ESP-RES-2024-9001',
    issuingOffice: 'Teresa, Rizal',
  );

  /// Anacleto's one seeded government ID document, shared by both his
  /// duplicate registrations (see unverifiedDuplicateAccountA/B — same
  /// resident, same submitted ID) — the asset placed at assets/images/
  /// ANACLETO ID DEMO.png (note the asset's own filename spells his name
  /// with an "h"; the card image itself correctly prints "Anacleto
  /// Dimaculangan", matching the account data). Every other printed field —
  /// birthdate, sex, civil status, address, occupation, mobile number, and
  /// "PENDING REVIEW" status — matches the account records exactly, except
  /// the printed Resident ID Number itself: the card reads
  /// "ESP-RES-2024-9013", a leftover from before this asset was paired
  /// with these specific seeded accounts (ESP-RES-2026-9003/-2102). Per
  /// this project's rule against generating new ID images, the existing
  /// asset is used as-is.
  static const duplicateDemoGovernmentId = GovernmentIdRecord(
    accountId: 'ESP-RES-2026-9003',
    idType: 'Teresa, Rizal Resident ID',
    assetPath: 'assets/images/ANACLETO ID DEMO.png',
    idNumber: 'ESP-RES-2024-9013',
    issuingOffice: 'Teresa, Rizal',
  );

  /// A second, independent duplicate-account demo (frontend simulation
  /// only) — unlike [duplicateVerifiedDemoAccount] (an existing Verified
  /// resident's identity gets duplicated), here NEITHER registration has
  /// reached Verified yet: the same person's identity was registered
  /// twice while still Pending Review both times. Both accounts stay
  /// Unverified and Dokyu/Tulong-restricted regardless of which one the
  /// citizen later chooses to keep — see
  /// screens/notifications/unverified_duplicate_resolution_screen.dart.
  /// Kept entirely separate from the Perlita scenario's own accounts/ids/
  /// notification keys so the two demos never interfere with each other.
  static final unverifiedDuplicateAccountA = CitizenAccount(
    id: 'ESP-RES-2026-9003',
    firstName: 'Anacleto',
    lastName: 'Dimaculangan',
    email: 'anacleto.dimaculangan@example.com',
    mobile: '0918 000 9003',
    barangay: 'Libertad',
    purok: 'Purok 3',
    address: 'Purok 3, Barangay Libertad, Teresa, Rizal',
    birthdate: 'October 27, 1992',
    sex: 'Male',
    civilStatus: 'Single',
    occupation: 'Tricycle Driver',
    profileCompleteness: 48,
    status: 'Pending Review',
  );
  static const unverifiedDuplicateAccountACreatedAt = 'July 3, 2026, 9:14 AM';

  static final unverifiedDuplicateAccountB = CitizenAccount(
    id: 'ESP-RES-2026-9004',
    firstName: 'Anacleto',
    lastName: 'Dimaculangan',
    // A second registration plausibly uses a slightly different email
    // than the first attempt (the resident forgot they'd already signed
    // up), while sharing the same phone/identity details — this is what
    // makes the two look like a genuine match rather than two unrelated
    // people who happen to share a name.
    email: 'a.dimaculangan92@example.com',
    mobile: '0918 000 9003',
    barangay: 'Libertad',
    purok: 'Purok 3',
    address: 'Purok 3, Barangay Libertad, Teresa, Rizal',
    birthdate: 'October 27, 1992',
    sex: 'Male',
    civilStatus: 'Single',
    occupation: 'Tricycle Driver',
    profileCompleteness: 40,
    status: 'Pending Review',
  );
  static const unverifiedDuplicateAccountBCreatedAt = 'July 19, 2026, 2:47 PM';
}
