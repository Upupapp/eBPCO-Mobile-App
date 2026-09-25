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

final List<LegalSection> privacyPolicySections = [
  LegalSection('What eBPCO does with your data today', [
    privacyPolicyText,
    'A document you attach is stored in full, not recorded by name only, and is retained for as long as your '
        'application or the resulting permit requires it. A permit that has genuinely been issued can be viewed on '
        'this app and, once released, carries its real permit number and conditions.',
    "One part remains unconnected: looking up a permit by number from the public, no-login verification page does "
        "not yet check this Municipality's real records.",
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
