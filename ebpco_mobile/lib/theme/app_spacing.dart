/// Spacing scale matching Tailwind's default 4px-based scale, which both
/// eBPCO web portals use throughout. Structural, not a color token — kept
/// identical to the design reference's own scale (Teresa-Rizal-Mobile),
/// per the owner's "design/look only" instruction.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}

/// Border radius scale matching the web portals' own `--radius-sm/md/lg`
/// tokens (0.4rem/0.5rem/0.85rem) and component classes: buttons/inputs
/// read as `md`, cards/sheets/modals as `lg`, badges/avatars as `full`.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
  static const double full = 999;
}
