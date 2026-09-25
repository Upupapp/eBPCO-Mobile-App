/// The Municipality of Castilla's real contact details — ported verbatim
/// from `ebpco-user-portal/src/app/core/domain/lgu-contact.ts`, the single
/// source of truth both web portals use. Every value here is transcribed
/// from a document in that repo (named in its own comments); nothing here
/// is invented. If a value is not sourced, it does not belong here — say so
/// on screen instead.
class LguOffice {
  final String name;
  final String shortName;
  final String email;
  final String? mobile;
  final String handles;
  const LguOffice({required this.name, required this.shortName, required this.email, required this.mobile, required this.handles});
}

const municipalEngineer = LguOffice(
  name: 'Office of the Municipal Engineer',
  shortName: 'MEO',
  email: 'meocastilla@gmail.com',
  mobile: '09054818572',
  handles: 'Building permits, ancillary permits and certificates of occupancy',
);

const planningAndDevelopment = LguOffice(
  name: 'Municipal Planning and Development Office',
  shortName: 'MPDO',
  email: 'castillampdo@gmail.com',
  mobile: null,
  handles: 'Locational clearance and certificates of zoning compliance',
);

const municipalHallAddress = 'Castilla Town Hall, Cumadcad, Castilla, Sorsogon';

const inquiryTurnaround = 'Inquiries are answered within 3 working days.';

/// A bank-transfer deposit account, once the Municipality supplies one.
class BankTransferInfo {
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String branch;
  const BankTransferInfo({required this.bankName, required this.accountName, required this.accountNumber, required this.branch});
}

/// `null` means "not supplied" — ported verbatim from the web portal's own
/// `DEFAULT_BANK_INFO`. This was previously a fabricated account number on
/// that portal (a real bank, an invented number) and was set to null
/// specifically because a labelled fake account can still be copied, and a
/// partially-real one (right bank, wrong number) is the most dangerous form
/// of all. Never fill this in with a plausible value — only with what the
/// Municipality actually publishes.
const BankTransferInfo? defaultBankInfo = null;
