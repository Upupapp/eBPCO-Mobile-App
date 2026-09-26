/// Where the eBPCO API lives.
///
/// Set at BUILD time via `--dart-define=EBPCO_API_BASE_URL=...`, mirroring
/// the web portals' own `config.js`-before-bundle pattern as closely as a
/// compiled mobile binary can — a mobile build cannot swap this at runtime
/// the way a web deploy can, so this is resolved once, at build time,
/// rather than read from device storage. The default below points at the
/// same Linode host the two web portals are already live on
/// (`apps/ebpco-api/deploy/push-source.sh` in eBPCOBackend), so `flutter
/// run` with no extra flags talks to the real, current backend rather than
/// nothing — unlike the web portals, a guessed-vs-unconfigured distinction
/// buys nothing here: there is no "unconfigured" build a citizen could ever
/// install, only a build pointed at the wrong environment, which a
/// `--dart-define` override for staging/prod flavors solves directly.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'EBPCO_API_BASE_URL',
    defaultValue: 'https://139-162-51-165.sslip.io',
  );

  /// The citizen web portal — the server's own `USER_PORTAL_BASE_URL`. A
  /// permit's QR code points at its public `/verify/<permit number>` page,
  /// the same address the portal's printed permit encodes.
  static const String userPortalBaseUrl = String.fromEnvironment(
    'EBPCO_USER_PORTAL_BASE_URL',
    defaultValue: 'https://fastidious-chimera-7a7a18.netlify.app',
  );
}
