/// A citizen-facing evacuation center entry — the mobile-side detail view
/// backing Sakuna's "Evacuation Centers" list. The app has no GPS, so a
/// center is never stored or shown with a distance. Lists put centers in
/// the signed-in profile barangay first, then order the rest by name.
/// `currentOccupancy` is left null by default and only rendered when
/// actually set — per the emergency spec, this app must never invent a
/// fake "X of Y occupied" number, so the detail screen shows "Capacity
/// information unavailable" whenever it is null instead of fabricating a
/// status.
class EvacuationCenter {
  final String name;
  final String barangay;
  final int totalCapacity;
  final List<String> services;
  final List<String> amenities;
  final String? contactNumber;
  final int? currentOccupancy;

  const EvacuationCenter({
    required this.name,
    required this.barangay,
    required this.totalCapacity,
    this.services = const [],
    this.amenities = const [],
    this.contactNumber,
    this.currentOccupancy,
  });

  bool get hasLiveCapacityData => currentOccupancy != null;

  /// True when this center's barangay is the signed-in profile barangay.
  static bool barangayMatchesProfile(String barangay, String? profileBarangay) {
    final home = profileBarangay?.trim();
    return home != null && home.isNotEmpty && barangay == home;
  }

  /// Profile barangay first, then name A to Z. A missing profile sorts by name only.
  static int compareByProfileBarangay(
    EvacuationCenter a,
    EvacuationCenter b,
    String? profileBarangay,
  ) {
    final aHome = barangayMatchesProfile(a.barangay, profileBarangay);
    final bHome = barangayMatchesProfile(b.barangay, profileBarangay);
    if (aHome != bHome) return aHome ? -1 : 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
