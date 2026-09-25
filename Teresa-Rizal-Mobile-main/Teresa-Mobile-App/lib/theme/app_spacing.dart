/// Spacing scale matching Tailwind's default 4px-based scale, which the
/// Web Admin uses throughout (p-4, gap-2.5, px-4.5, etc).
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

/// Border radius scale matching the Web Admin's component classes:
/// buttons/inputs use `rounded-xl` (12px), cards use `rounded-2xl` (16px),
/// badges/avatars use `rounded-full`.
class AppRadius {
  AppRadius._();

  static const double sm = 8; // rounded-lg
  static const double md = 12; // rounded-xl — buttons, inputs
  static const double lg = 16; // rounded-2xl — cards, sheets, modals
  static const double full = 999; // rounded-full — badges, avatars, chips
}
