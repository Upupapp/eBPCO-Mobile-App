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

/// One office as every screen and document names it: the full name, and the
/// short form for chips and tight cells only.
class OfficeName {
  final String name;
  final String short;
  const OfficeName(this.name, this.short);
}

/// The ONE place an office's name comes from — the portal's `OFFICES`
/// (design review, 4 Nov 2026: one permit named its issuer three ways, and
/// the pay page sent cash to a fourth). The Building Official and Zoning names
/// are the backend's issuing-office.ts, word for word, so the permit, the
/// server, the portal and the app agree. Open question for the LGU: is the
/// Office of the Municipal Engineer also the Office of the Building Official?
/// Until it says otherwise, the backend's name is used alone.
abstract final class Offices {
  static const buildingOfficial = OfficeName('Office of the Building Official (Municipal Engineering Office)', 'OBO');
  static const zoning = OfficeName('Municipal Planning and Development Office (Zoning Administrator)', 'MPDO');
  static const fireStation = OfficeName('Bureau of Fire Protection — Castilla Fire Station', 'BFP');
  static const treasurer = OfficeName("Municipal Treasurer's Office", "Treasurer's Office");
}

/// Where a citizen pays.
class PayingOffice {
  final String name;
  final String short;
  final String place;
  final String cashierLabel;
  const PayingOffice({required this.name, required this.short, required this.place, required this.cashierLabel});
}

/// Where a citizen pays (design review I2): the Municipal Treasurer's Office,
/// whose Cashier verifies the payment and issues the Official Receipt — the
/// portal's `MUNICIPAL_TREASURER`. The pay screen, the Order of Payment, the
/// Payments list and the receipt all read this, so the screen and the paper
/// the citizen brings say the same thing.
const municipalTreasurer = PayingOffice(
  name: "Municipal Treasurer's Office",
  short: "Treasurer's Office",
  place: 'Castilla Town Hall',
  cashierLabel: 'Cashier',
);

/// Where to pay in person, word for word as the portal's pay page and the
/// Order of Payment say it.
const onsitePaymentWhere = "Pay at the Municipal Treasurer's Office (Cashier), Castilla Town Hall. Bring your Order of Payment.";

/// Source: the Building Permit & Occupancy checklist (letterhead "OFFICE OF
/// THE MUNICIPAL ENGINEER"; "call MEO at 09054818572 … meocastilla@gmail.com").
/// Named as the issuing office ([Offices.buildingOfficial]), the name the
/// permit prints, so a citizen never reads the two as different offices.
const municipalEngineer = LguOffice(
  name: 'Office of the Building Official (Municipal Engineering Office)',
  shortName: 'OBO',
  email: 'meocastilla@gmail.com',
  mobile: '09054818572',
  handles: 'Building permits, ancillary permits and certificates of occupancy',
);

/// Source: the Zoning Checklist (FM-MPD-12). Named as the zoning clearance's
/// issuer ([Offices.zoning]).
const planningAndDevelopment = LguOffice(
  name: 'Municipal Planning and Development Office (Zoning Administrator)',
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
