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

const String castillaCity = 'Castilla';
const String castillaProvince = 'Sorsogon';
