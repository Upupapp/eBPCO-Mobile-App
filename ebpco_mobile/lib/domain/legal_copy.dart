import 'lgu_contact.dart';

/// Single-sourced Terms & Conditions / Privacy Policy copy — ported
/// verbatim from `ebpco-user-portal/src/app/core/domain/legal-copy.ts` so
/// the three surfaces (both web portals, this app) never drift apart.
/// Never invent an LGU fact to fill a gap here: retention period, the Data
/// Protection Officer's name, and the list of recipient offices are the
/// Municipality's to state, and are said to be "not yet determined" where
/// they are, rather than guessed.
const String termsConditionsText =
    'By using eBPCO, you agree to provide accurate information for every permit application and to comply with all '
    'applicable national and local regulations, including PD 1096 (National Building Code) and RA 9514 (Fire Code of '
    'the Philippines).';

const String privacyPolicyText =
    'Your account, applications, documents, payments and businesses are genuinely created, transmitted and stored by '
    'the Municipality of Castilla.';

class LegalSection {
  final String heading;
  final List<String> paragraphs;
  const LegalSection(this.heading, this.paragraphs);
}

/// The Terms & Conditions a citizen agrees to on every application, the citizen
/// portal's `TERMS_SECTIONS` verbatim (QA finding TC-36, 2026-10-03: they were
/// one sentence). Each term describes what eBPCO and the office actually do,
/// and none invents an LGU fact: no fee, deadline or processing time appears
/// here that the Municipality has not published.
final List<LegalSection> termsSections = [
  LegalSection('Using eBPCO', [
    "eBPCO is the Municipality of Castilla's online service for applying for building and related permits, following "
        'an application through each office, paying its fees and collecting the permit. These terms apply whenever '
        'you use it, on the citizen portal or on this app.',
    termsConditionsText,
  ]),
  LegalSection('Your account', [
    'Your account is yours alone. Keep your password private: you are responsible for everything done with your '
        'account. If you believe someone else has used it, change your password and tell the Municipality.',
  ]),
  LegalSection('What you submit', [
    'Everything you enter and every document you attach must be true, complete and yours to submit. A false '
        'statement or a falsified document in an application to a public office may be a criminal offense under '
        'Philippine law, and the Municipality may reject the application, or revoke a permit issued on it.',
    'Forms that must be signed, sealed or notarized, such as the Unified Application Form and the ancillary permit '
        'forms, are signed on paper, then scanned and uploaded. The office may ask to see the originals before it '
        'releases your permit.',
  ]),
  LegalSection('How your application is handled', [
    'An application is checked against the list of requirements in force on the day it was filed. Each office '
        'reviews the documents it is responsible for. An office may return the application to you for revision with '
        'its remarks; you then replace what it asks for and send the application back.',
    "The decision to approve or reject an application is the office's. eBPCO records each step, shows it on your "
        "application's timeline, and notifies you.",
  ]),
  LegalSection('Fees and payment', [
    'Fees are assessed by the office and stated on your Order of Payment, with the date they are due. A payment '
        "counts only once the Municipal Treasurer's Office has verified it and recorded an Official Receipt. A "
        'payment the office cannot match to a receipt may be rejected, and you will be told why so that you can pay '
        'again.',
  ]),
  LegalSection('Your permit', [
    'A permit is valid only as issued: for the work, the location and the period stated on it, under the conditions '
        'printed on it. Under the National Building Code (PD 1096), a building permit becomes void if the work it '
        'covers is not started within one year of its issue.',
    "Anyone can check that a permit number is on record on the public verification page. That page shows the "
        "permit's type, the business it was issued for, its dates and whether it has been released, and none of "
        'your personal details.',
  ]),
  LegalSection('Withdrawing an application', [
    'You may withdraw an application while it is a draft, while it waits to be received or evaluated, or while it '
        'is returned to you for revision, as long as no fees have been assessed. A withdrawn application cannot be '
        'reopened, but you may file a new one.',
  ]),
  LegalSection('Your data', [
    'How eBPCO collects, uses and keeps your personal data is set out in the Privacy Notice, under the Data Privacy '
        'Act of 2012 (RA 10173).',
  ]),
];

final List<LegalSection> privacyPolicySections = [
  LegalSection('What eBPCO does with your data today', [
    privacyPolicyText,
    'A document you attach is stored in full, not recorded by name only, and is retained for as long as your '
        'application or the resulting permit requires it. A permit that has genuinely been issued can be viewed on '
        'this app and, once released, carries its real permit number and conditions.',
    "Anyone with a permit's number can confirm it is on record on the public, no-login verification page, which "
        "checks the Municipality's own records. It shows the permit's type, the business it was issued for, its dates "
        'and whether it has been released, never your personal details.',
  ]),
  LegalSection('Who will control your data once eBPCO goes live', [
    'The personal information controller is the Local Government Unit of Castilla, Sorsogon. The Municipality '
        'states on its own permit forms that "all information we collect through this form shall be kept '
        'confidential by the Local Government Unit of Castilla and shall be used solely for legal purposes as '
        'mandated by the Data Privacy Act and other relevant laws."',
    'You can reach the ${municipalEngineer.name} at ${municipalEngineer.mobile} or ${municipalEngineer.email}, '
        'or in person at $municipalHallAddress.',
  ]),
  LegalSection('What eBPCO will collect', [
    'To create an account: your first, middle and last name, date of birth, sex, civil status, nationality, email '
        'address, mobile number and full address including barangay, city, province and postal code.',
    'To process a permit application: details of the project or establishment, and the documents each permit '
        'requires — which may include certified copies of land titles (OCT/TCT), deeds, survey plans, design plans, '
        'cost estimates, professional licences and a valid government ID.',
    'Your account password is required to sign in and is never shown to anyone at the Municipality.',
  ]),
  LegalSection('Why it is collected', [
    'Solely to receive, evaluate, assess, approve and release the permits you apply for, and to contact you about '
        "those applications. Your data is not used for any other purpose, and it is never shared with another "
        "citizen's account.",
  ]),
  LegalSection('Your rights under the Data Privacy Act of 2012 (RA 10173)', [
    'As a data subject you have the right to be informed, to object, to access your data, to correct it, to have it '
        'erased or blocked, to damages for a violation, and to data portability.',
    'You may exercise any of these rights by contacting the Municipality using the details above. If you believe '
        'your rights have been violated, you may complain to the National Privacy Commission.',
  ]),
  LegalSection('Not yet determined', [
    'Three things this notice cannot yet tell you, because the Municipality has not published them and eBPCO will '
        'not invent them: how long your data will be retained, who the Municipality\'s Data Protection Officer is, '
        'and exactly which offices your application will be shared with during evaluation.',
    "This section will be replaced with the Municipality's own answers once they are published. Your data is being "
        'collected and retained in the meantime under the general basis stated above (performance of a public task, '
        'PD 1096 permit issuance), not withheld until these specifics arrive.',
  ]),
];
