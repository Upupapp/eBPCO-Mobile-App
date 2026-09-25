/// The one canonical path to the Teresa, Rizal municipal seal — every screen
/// that shows the seal (Splash, the three Welcome/onboarding pages, Sign
/// In, and the Dokyu/Tulong office- and service-card fallbacks) imports
/// this constant rather than hardcoding the asset string itself, so a
/// future asset move only needs to change one place instead of silently
/// breaking it everywhere it appears (exactly what happened before this
/// file existed — several screens hardcoded `assets/images/teresa-rizal-seal.png`,
/// which pointed nowhere once the actual file turned out to live under
/// `assets/images/Logo/`).
const String teresaRizalSealAsset = 'assets/images/Logo/teresa-rizal-seal.png';
