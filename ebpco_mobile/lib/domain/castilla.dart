/// All 34 barangays of Castilla, Sorsogon — ported verbatim from
/// `eBPCOBackend/src/modules/businesses/castilla-barangays.ts`, the
/// backend's own canonical list every address (business AND personal) is
/// validated against. City/Province are pinned constants, not free text,
/// matching the citizen portal's own registration form and the owner
/// decision recorded in that file: a citizen's own address is Castilla-only
/// too, same as a business's.
const List<String> castillaBarangays = [
  'Amomonting', 'Bagalayag', 'Bagong Sirang', 'Bonga', 'Buenavista', 'Burabod', 'Caburacan',
  'Canjela', 'Cogon', 'Cumadcad', 'Dangcalan', 'Dinapa', 'La Union', 'Libtong', 'Loreto',
  'Macalaya', 'Maracabac', 'Mayon', 'Maypangi', 'Milagrosa', 'Miluya', 'Monte Carmelo', 'Oras',
  'Pandan', 'Poblacion', 'Quirapi', 'Saclayan', 'Salvacion', 'San Isidro', 'San Rafael',
  'San Roque', 'San Vicente', 'Sogoy', 'Tomalaytay',
];

/// The portal's `NATIONALITIES` (core/domain/ph-reference-data.ts), verbatim.
/// 'Other' reveals a free-text field, same as the portal.
const List<String> nationalities = [
  'American', 'Australian', 'Bangladeshi', 'British', 'Bruneian', 'Burmese', 'Cambodian', 'Canadian',
  'Chinese', 'Emirati', 'Filipino', 'French', 'German', 'Indian', 'Indonesian', 'Italian', 'Japanese',
  'Jordanian', 'Kuwaiti', 'Lao', 'Malaysian', 'Mongolian', 'Nepalese', 'New Zealander', 'Pakistani',
  'Qatari', 'Russian', 'Saudi Arabian', 'Singaporean', 'South Korean', 'Spanish', 'Sri Lankan',
  'Taiwanese', 'Thai', 'Timorese', 'Vietnamese', 'Other',
];

const String castillaCity = 'Castilla';
const String castillaProvince = 'Sorsogon';
