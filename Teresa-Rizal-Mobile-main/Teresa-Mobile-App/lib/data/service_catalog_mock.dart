/// Placeholder catalog values for Pack G / H / I / J.
///
/// Fees, times, requirement counts, windows, eligibility, office hours and
/// the paternity rule are sample data. Widgets read them from here.
/// The Municipality confirms real values before any citizen release.
library;

enum DokyuSection { barangay, civil, business, ids }

enum ProgramWindow { open, closed, opensSoon }

enum TulongSection { aics, programs, livelihood }

class DokyuService {
  final String id;
  final String title;
  final String expansion;
  final String fee;
  final String time;
  final int requirements;
  final DokyuSection section;
  final String legacyKey;
  final String blurb;
  final List<String> requirementLines;
  final String claim;
  final List<String> steps;
  final bool delayedBirth;

  const DokyuService({
    required this.id,
    required this.title,
    this.expansion = '',
    required this.fee,
    required this.time,
    required this.requirements,
    required this.section,
    required this.legacyKey,
    required this.blurb,
    this.requirementLines = const [],
    this.claim = '',
    this.steps = const [],
    this.delayedBirth = false,
  });

  /// Catalog tile: "Delayed Birth · Registration".
  String get display => expansion.isEmpty ? title : '$title · $expansion';

  /// App bar: the same name as one proper noun, "Delayed Birth Registration".
  String get appBarTitle => expansion.isEmpty ? title : '$title $expansion';
}

class TulongProgram {
  final String id;
  final String name;
  final String blurb;
  final String eligibility;
  final String eligibilityDetail;
  final ProgramWindow window;
  final TulongSection section;
  final String sectionLabel;
  final int minAge;
  final String windowLine;
  final String amountTitle;
  final String amountHelper;
  final String claimTitle;
  final String claimSub;
  final List<String> requirements;
  final bool educationalLanding;
  final String closedTip;
  final String soonDate;

  const TulongProgram({
    required this.id,
    required this.name,
    required this.blurb,
    required this.eligibility,
    this.eligibilityDetail = 'Sample eligibility',
    required this.window,
    required this.section,
    required this.sectionLabel,
    this.minAge = 0,
    this.windowLine = '',
    this.amountTitle = 'Set after MSWDO assessment',
    this.amountHelper = 'No fixed amount shown in the app',
    this.claimTitle = 'Municipal Hall',
    this.claimSub = 'Poblacion, Teresa, Rizal · text only',
    this.requirements = const [],
    this.educationalLanding = false,
    this.closedTip = '',
    this.soonDate = '',
  });

  bool get canStart => window == ProgramWindow.open;
}

class SakunaKind {
  final String id;
  final String label;
  final String blurb;
  final String legacyKey;

  const SakunaKind({
    required this.id,
    required this.label,
    required this.blurb,
    required this.legacyKey,
  });
}

class WizardStepInfo {
  final int number;
  final String label;
  final bool conditional;
  const WizardStepInfo(this.number, this.label, {this.conditional = false});
}

class RequirementSpec {
  final String id;
  final String title;
  final String detail;
  final String fromHakbang;
  final bool conditional;
  const RequirementSpec({
    required this.id,
    required this.title,
    this.detail = '',
    this.fromHakbang = '',
    this.conditional = false,
  });
}

class ServiceCatalogMock {
  ServiceCatalogMock._();

  static const clock = '2026-09-24';

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
  ];

  static const profileBarangay = 'Dalig';

  static const sheetHonesty =
      'Frontend preview. Catalog content is sample until the Municipality confirms it.';
  static const sheetSubline =
      'Browse any service. Requests need a verified account.';
  static const dokyuHonesty =
      'Sample fees, times and requirements. Frontend preview, not the official Citizen\'s Charter.';
  static const dokyuSearchTip =
      'Search matches service names and what each one is for. Not sure which one? Late Birth brgy cert is the barangay step before Delayed Birth registration.';
  static const dokyuSearchTipShort =
      'Not sure which one? Late Birth brgy cert is the barangay step before Delayed Birth registration.';
  static const noResultsHonesty =
      'Local search. Searches this device\'s sample catalog only.';
  static const tulongHonesty =
      'Sample windows and eligibility summaries. Not an official MSWDO call for applications.';
  static const sakunaHonesty =
      'Sample report channel. No live MDRRMO dispatch. Only 911 is callable; MDRRMO stays disabled until the Municipality confirms the number.';
  static const detailHonesty =
      'Frontend preview. Fee, time and hours are samples, not the official Citizen\'s Charter.';
  static const tulongDetailFooter =
      'Sample program · no funds are released in this preview.';
  static const guestGateHonesty =
      'Frontend simulation — Guest / account gates are local preview state. No live LGU account backend.';
  static const unverifiedGateHonesty =
      'Frontend simulation — verification is local preview state, no civil registry check. Emergency reports and 911 stay available.';
  static const fieldsHonesty =
      'Token specimen. Sample values only; nothing is submitted.';
  static const wizardIntroHonesty =
      'Sample flow. Steps and requirements are a preview. Confirm with the Municipal Civil Registrar before filing. Not a live civil registry submission.';
  static const wizardSavedLine = 'Answers are saved on this device as you go.';
  static const parentsRule =
      'Sample rule. Confirm with the Municipal Civil Registrar.';
  static const paternityNote =
      'Adds a requirement in Hakbang 4: Affidavit of Acknowledgment / Admission of Paternity';
  static const attendantNote =
      'Adds a requirement in Hakbang 4: Certification from the birth attendant. Sample rule; confirm with the Municipal Civil Registrar.';
  static const h1Honesty =
      'Sample flow. Confirm name and date rules with the Municipal Civil Registrar. Answers stay on this device.';
  static const h4Progress = '3 of 6 files · Sample list';
  static const h4Honesty =
      'Sample requirement list. The Municipal Civil Registrar confirms what\'s needed. Files stay on this device.';
  static const removeFinePrint =
      'Sample rule. The Municipal Civil Registrar confirms requirements.';
  static const closedHelper =
      'Applications are closed right now · sample window';
  static const closedWindow =
      'Applications closed. Next window not announced yet';
  static const remindHelper =
      'Local preview: the reminder is saved on this device only. No push notification is sent.';
  static const mayNotFitIntro =
      'We checked one sample eligibility line against your profile before you start. Nothing was sent.';
  static const mayNotFitFooter =
      'Sample rule checked on this device. MSWDO makes the final decision.';
  static const emergencyNumber = '911';
  static const mdrrmoName = 'MDRRMO Teresa';
  static const mdrrmoNumber = '[TO BE PROVIDED]';
  static const evacHonesty =
      'Status and capacity are sample values. Confirm with MDRRMO during real events.';
  static const stripHeadline = 'Life in danger? Call 911.';
  static const stripMdrrmo = 'MDRRMO hotline [TO BE PROVIDED]';
  static const formStripSub = 'This form is a report, not a dispatch.';
  static const guestStripHeadline = 'In danger now? Call 911.';
  static const guestStripSub = 'No account needed.';
  static const reportFormHonesty =
      'Sample report channel. Not a live dispatch. MDRRMO does not receive reports in this preview; MDRRMO hotline is [TO BE PROVIDED].';
  static const locationTyped = 'Location is typed, not GPS.';
  static const sentTitle = 'Report saved on this device';
  static const sentBody =
      'Your flooding report is stored in this preview. It was not sent to anyone.';
  static const sentStatus = 'Saved · not dispatched';
  static const sentReference = 'SAMPLE-INC-0007';
  static const sentDanger =
      'Sample report channel, not a live dispatch. No responder has been notified. If anyone is in danger, call 911 now.';
  static const guestReportTitle = 'Sign in to send a report';
  static const guestReportBody =
      'Incident reports need a signed-in account. Unverified accounts can report; you don\'t need to finish verification.';
  static const guestReportHonesty =
      'Frontend simulation — account gates are local preview state. Reports go to a sample channel, not a live dispatch.';
  static const closedBrowseTip =
      'While it\'s closed watch Balita and Advisories for the next window.';
  static const affidavitFileName = 'affidavit-acknowledgment.pdf';
  static const affidavitFileSize = '1.1 MB';
  static const attendantFileName = 'attendant-cert.pdf';
  static const attendantFileSize = '0.8 MB';

  static const wizardSteps = [
    WizardStepInfo(1, 'Registrant'),
    WizardStepInfo(2, 'Parents', conditional: true),
    WizardStepInfo(3, 'Birth details', conditional: true),
    WizardStepInfo(4, 'Requirements'),
    WizardStepInfo(5, 'Applicant Info'),
    WizardStepInfo(6, 'Review & Submit'),
    WizardStepInfo(7, 'Payment'),
  ];

  static const baseRequirements = [
    RequirementSpec(
      id: 'psa',
      title: 'PSA negative certification of birth',
      detail: 'psa-negative-cert.pdf · 0.8 MB',
    ),
    RequirementSpec(
      id: 'records',
      title: 'Two records of name, date and place of birth',
      detail: 'Baptismal, school or medical · baptismal-cert.jpg · 1 of 2',
    ),
    RequirementSpec(
      id: 'valid-id',
      title: 'Your valid ID',
      detail: 'philsys-front.jpg · applicant in Hakbang 5',
    ),
  ];

  static const affidavitRequirement = RequirementSpec(
    id: 'affidavit',
    title: 'Affidavit of Acknowledgment / Admission of Paternity',
    detail: 'Signed by the father',
    fromHakbang: 'From Hakbang 2 · father acknowledges',
    conditional: true,
  );

  static const attendantRequirement = RequirementSpec(
    id: 'attendant',
    title: 'Certification from the birth attendant',
    detail: 'From the midwife who attended',
    fromHakbang: 'From Hakbang 3 · born at home',
    conditional: true,
  );

  static const dokyu = <DokyuService>[
    DokyuService(
      id: 'brgy-clearance',
      title: 'Barangay Clearance',
      fee: '₱50',
      time: 'Same day',
      requirements: 2,
      section: DokyuSection.barangay,
      legacyKey: 'dokyu_barangay_clearance',
      blurb:
          'Certifies you are a resident of good standing in your barangay. Often asked for work, loans and permits.',
      requirementLines: [
        'Valid ID',
        'Proof of residency · utility bill or cedula',
      ],
      claim:
          'Barangay Hall · Dalig / Your barangay · Mon–Fri 8 AM–5 PM · sample hours',
      steps: ['Requirements', 'Applicant', 'Review', 'Payment'],
    ),
    DokyuService(
      id: 'residency',
      title: 'Residency',
      expansion: 'Certificate',
      fee: '₱50',
      time: 'Same day',
      requirements: 2,
      section: DokyuSection.barangay,
      legacyKey: 'dokyu_residency',
      blurb: 'Proof that you live in the barangay.',
    ),
    DokyuService(
      id: 'indigency',
      title: 'Indigency',
      expansion: 'Certificate',
      fee: 'Free',
      time: 'Same day',
      requirements: 2,
      section: DokyuSection.barangay,
      legacyKey: 'dokyu_indigency',
      blurb: 'Used when a program asks for proof of indigency.',
    ),
    DokyuService(
      id: 'brgy-business',
      title: 'Brgy Business Clearance',
      fee: '₱300',
      time: '1–2 days',
      requirements: 3,
      section: DokyuSection.barangay,
      legacyKey: 'dokyu_barangay_business_clearance',
      blurb: 'Barangay clearance for a business.',
    ),
    DokyuService(
      id: 'brgy-cert',
      title: 'Brgy Certification',
      fee: '₱50',
      time: 'Same day',
      requirements: 1,
      section: DokyuSection.barangay,
      legacyKey: 'dokyu_barangay_certification',
      blurb: 'A general barangay certification.',
    ),
    DokyuService(
      id: 'job-seeker',
      title: 'First Time Job Seeker',
      expansion: 'Certification',
      fee: 'Free',
      time: 'Same day',
      requirements: 2,
      section: DokyuSection.barangay,
      legacyKey: 'dokyu_first_time_jobseeker',
      blurb: 'Certification for a first-time job seeker.',
    ),
    DokyuService(
      id: 'live-birth',
      title: 'Live Birth copy',
      expansion: 'Certified copy',
      fee: '₱100',
      time: '1–2 days',
      requirements: 1,
      section: DokyuSection.civil,
      legacyKey: 'mcro_live_birth',
      blurb: 'Certified copy of a live birth record.',
    ),
    DokyuService(
      id: 'marriage-license',
      title: 'Marriage License',
      fee: '₱300',
      time: '10+ days',
      requirements: 6,
      section: DokyuSection.civil,
      legacyKey: 'dokyu_marriage_license',
      blurb: 'License to marry, issued by the civil registrar.',
    ),
    DokyuService(
      id: 'marriage-copy',
      title: 'Marriage Certificate copy',
      fee: '₱100',
      time: '1–2 days',
      requirements: 1,
      section: DokyuSection.civil,
      legacyKey: 'dokyu_marriage_certificate_copy',
      blurb: 'Certified copy of a marriage certificate.',
    ),
    DokyuService(
      id: 'delayed-birth',
      title: 'Delayed Birth',
      expansion: 'Registration',
      fee: '₱150',
      time: '10+ days',
      requirements: 6,
      section: DokyuSection.civil,
      legacyKey: 'dokyu_delayed_birth_registration',
      blurb: 'Register a birth more than 30 days after the child was born.',
      delayedBirth: true,
    ),
    DokyuService(
      id: 'delayed-death',
      title: 'Delayed Death',
      expansion: 'Registration',
      fee: '₱150',
      time: '10+ days',
      requirements: 4,
      section: DokyuSection.civil,
      legacyKey: 'dokyu_delayed_death_registration',
      blurb: 'Register a death after the usual filing window.',
    ),
    DokyuService(
      id: 'fetal',
      title: 'Fetal Death',
      expansion: 'Registration',
      fee: '₱100',
      time: '1–3 days',
      requirements: 3,
      section: DokyuSection.civil,
      legacyKey: 'dokyu_fetal_death',
      blurb: 'Registration of a fetal death.',
    ),
    DokyuService(
      id: 'late-birth-brgy',
      title: 'Late Birth brgy cert',
      fee: '₱50',
      time: 'Same day',
      requirements: 2,
      section: DokyuSection.civil,
      legacyKey: 'dokyu_barangay_cert_late_birth',
      blurb: 'Barangay certificate used before delayed birth registration.',
    ),
    DokyuService(
      id: 'death-brgy',
      title: 'Death registration brgy cert',
      fee: '₱50',
      time: 'Same day',
      requirements: 2,
      section: DokyuSection.civil,
      legacyKey: 'dokyu_barangay_cert_death',
      blurb: 'Barangay certificate used with a death registration.',
    ),
    DokyuService(
      id: 'cedula',
      title: 'Cedula',
      expansion: 'Community tax certificate',
      fee: 'From ₱5',
      time: 'Same day',
      requirements: 1,
      section: DokyuSection.business,
      legacyKey: 'dokyu_cedula',
      blurb: 'Community tax certificate.',
    ),
    DokyuService(
      id: 'business-permit',
      title: 'Business Permit (New)',
      fee: 'Assessed',
      time: '3–5 days',
      requirements: 7,
      section: DokyuSection.business,
      legacyKey: 'dokyu_business_new',
      blurb: 'New business permit.',
    ),
    DokyuService(
      id: 'rpt',
      title: 'RPT Clearance',
      expansion: 'Real property tax',
      fee: '₱100',
      time: '1 day',
      requirements: 2,
      section: DokyuSection.business,
      legacyKey: 'dokyu_rpt',
      blurb: 'Real property tax clearance.',
    ),
    DokyuService(
      id: 'locational',
      title: 'Locational Clearance',
      fee: 'Assessed',
      time: '3–5 days',
      requirements: 4,
      section: DokyuSection.business,
      legacyKey: 'dokyu_locational_clearance',
      blurb: 'Clearance for the location of a project.',
    ),
    DokyuService(
      id: 'senior-id',
      title: 'Senior Citizen ID',
      fee: 'Free',
      time: '3–5 days',
      requirements: 3,
      section: DokyuSection.ids,
      legacyKey: 'dokyu_senior_citizen_id',
      blurb: 'Identification card for a senior citizen.',
    ),
    DokyuService(
      id: 'pet',
      title: 'Pet Registration',
      fee: '₱50',
      time: 'Same day',
      requirements: 2,
      section: DokyuSection.ids,
      legacyKey: 'dokyu_pet_registration',
      blurb: 'Register a pet with the municipality.',
    ),
  ];

  static const tulong = <TulongProgram>[
    TulongProgram(
      id: 'medical-aics',
      name: 'Medical AICS',
      blurb: 'Help with hospital bills, medicine or lab costs. Assessed and released through MSWDO.',
      eligibility: 'Hospital bill, medicine or lab costs for low-income residents.',
      eligibilityDetail: 'Low-income residents of Teresa, Rizal',
      window: ProgramWindow.open,
      section: TulongSection.aics,
      sectionLabel: 'AICS',
      windowLine: '3–5 working days after assessment',
      requirements: [
        'Valid ID',
        'Medical certificate or clinical abstract',
        'Hospital bill or prescription',
        'Certificate of Indigency (Dokyu)',
      ],
    ),
    TulongProgram(
      id: 'burial-aics',
      name: 'Burial AICS',
      blurb: 'Funeral costs for a family member who passed away.',
      eligibility: 'Funeral costs for a family member who passed away.',
      window: ProgramWindow.open,
      section: TulongSection.aics,
      sectionLabel: 'AICS',
    ),
    TulongProgram(
      id: 'educational-aics',
      name: 'Educational AICS',
      blurb: 'Enrolled students with school costs they can\'t cover.',
      eligibility: 'Enrolled students with school costs they can\'t cover.',
      window: ProgramWindow.open,
      section: TulongSection.aics,
      sectionLabel: 'AICS',
      educationalLanding: true,
    ),
    TulongProgram(
      id: 'financial-aics',
      name: 'Financial AICS',
      blurb: 'One-time help after a crisis such as fire or job loss.',
      eligibility: 'One-time help after a crisis such as fire or job loss.',
      window: ProgramWindow.open,
      section: TulongSection.aics,
      sectionLabel: 'AICS',
    ),
    TulongProgram(
      id: 'food-aics',
      name: 'Food AICS',
      blurb: 'Food packs for families affected by a calamity.',
      eligibility: 'Food packs for families affected by a calamity.',
      window: ProgramWindow.closed,
      section: TulongSection.aics,
      sectionLabel: 'AICS',
      windowLine: closedWindow,
    ),
    TulongProgram(
      id: 'social-pension',
      name: 'Social Pension',
      blurb: 'Indigent senior citizens 60+ with no regular pension.',
      eligibility: 'Indigent senior citizens 60+ with no regular pension.',
      eligibilityDetail: 'Residents 60 and older',
      window: ProgramWindow.open,
      section: TulongSection.programs,
      sectionLabel: 'Programs & IDs',
      minAge: 60,
      requirements: ['Valid ID', 'Birth certificate', 'Barangay certificate'],
    ),
    TulongProgram(
      id: 'solo-parent',
      name: 'Solo Parent',
      blurb: 'Solo parents raising a child on their own · Solo Parent ID.',
      eligibility: 'Solo parents raising a child on their own · Solo Parent ID.',
      window: ProgramWindow.open,
      section: TulongSection.programs,
      sectionLabel: 'Programs & IDs',
    ),
    TulongProgram(
      id: 'pwd',
      name: 'PWD Registration',
      blurb: 'Persons with disability · PWD ID and benefits.',
      eligibility: 'Persons with disability · PWD ID and benefits.',
      window: ProgramWindow.open,
      section: TulongSection.programs,
      sectionLabel: 'Programs & IDs',
    ),
    TulongProgram(
      id: 'tupad',
      name: 'TUPAD',
      blurb: 'Short-term emergency work for displaced or underemployed workers.',
      eligibility: 'Displaced or underemployed workers 18+',
      window: ProgramWindow.closed,
      section: TulongSection.livelihood,
      sectionLabel: 'Livelihood',
      windowLine: closedWindow,
      amountTitle: 'Set by the program',
      amountHelper: 'No amount shown in the app',
      requirements: [
        'Valid ID',
        'Barangay Certification (Dokyu)',
        'Proof of displacement or low income',
      ],
      closedTip: closedBrowseTip,
    ),
    TulongProgram(
      id: 'tesda',
      name: 'TESDA',
      blurb: 'Skills training and scholarships for youth and adults 18 and older.',
      eligibility: 'Residents 18 and older',
      eligibilityDetail: 'Out of school or looking for work · Sample eligibility',
      window: ProgramWindow.opensSoon,
      section: TulongSection.livelihood,
      sectionLabel: 'Livelihood',
      minAge: 18,
      windowLine: 'Opens 15 Oct 2026. Requirements may change before then.',
      soonDate: '15 Oct 2026',
      requirements: [
        'Valid ID',
        'PSA birth certificate',
        'Barangay Residency certificate (Dokyu)',
      ],
    ),
  ];

  static const sakuna = <SakunaKind>[
    SakunaKind(
      id: 'flood',
      label: 'Flooding',
      blurb: 'Rising water, flooded road or home',
      legacyKey: 'incident_flood',
    ),
    SakunaKind(
      id: 'fire',
      label: 'Fire',
      blurb: 'House, grass or vehicle fire',
      legacyKey: 'incident_fire',
    ),
    SakunaKind(
      id: 'landslide',
      label: 'Landslide',
      blurb: 'Soil or rock movement, cracks on slopes',
      legacyKey: 'incident_landslide',
    ),
    SakunaKind(
      id: 'medical',
      label: 'Medical emergency',
      blurb: 'Someone is sick or injured',
      legacyKey: 'incident_medical',
    ),
    SakunaKind(
      id: 'road',
      label: 'Road accident',
      blurb: 'Collision or vehicle incident',
      legacyKey: 'incident_road',
    ),
    SakunaKind(
      id: 'other',
      label: 'Other concern',
      blurb: 'Anything else that needs MDRRMO',
      legacyKey: 'incident_other',
    ),
  ];

  static const relatedWhenEmpty = ['business-permit', 'locational'];

  static String sectionTitle(DokyuSection section) => switch (section) {
        DokyuSection.barangay => 'Barangay certificates',
        DokyuSection.civil => 'Civil registry',
        DokyuSection.business => 'Business, tax & property',
        DokyuSection.ids => 'IDs & registrations',
      };

  static int sectionCount(DokyuSection section) =>
      dokyu.where((item) => item.section == section).length;

  static List<DokyuService> search(String query) {
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return dokyu;
    return dokyu.where((item) {
      final hay = '${item.title} ${item.expansion}'.toLowerCase();
      return tokens.every(hay.contains);
    }).toList();
  }

  static TulongProgram byId(String id) =>
      tulong.firstWhere((item) => item.id == id);

  static DokyuService dokyuById(String id) =>
      dokyu.firstWhere((item) => item.id == id);

  static SakunaKind sakunaById(String id) =>
      sakuna.firstWhere((item) => item.id == id);
}
