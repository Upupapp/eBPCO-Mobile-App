# FE 06 — Design token discipline

**Status: PARTIAL, and the partial is deliberate.** The root cause is fixed, every colour that
could drift is tokenised, and the gate is in place. The bulk type migration is 46 screens of
screen-by-screen work and remains.
**Date:** 2026-08-29
**Gate:** `flutter analyze` clean · `flutter test` **544 passed**

---

## The diagnosis: the token set was too small, not the team careless

FE 06 guesses this in its own mandate — *"a 4.6:1 bypass rate usually means the token set is too
small"* — and the measurement confirms it outright.

Of **412** hardcoded `fontSize:` literals outside `lib/theme/`, the distribution is:

| Size | Uses | Token existed? |
|---|---|---|
| **12.5** | **90** | **no** |
| 12 | 71 | yes (`caption`) |
| 13 | 56 | yes (`cardTitle`) |
| **13.5** | **42** | **no** |
| 14 | 32 | yes (`body`) |
| **11.5** | **30** | **no** |
| 11 | 28 | yes (`overline`) |
| **10.5 / 14.5** | **15** | **no** |

**177 of the 412 are half-point sizes for which `AppTypography` had no value at all** — and
`12.5` alone, the single most-used size in the entire app, was among them. Nobody could have used
a token for those. They wrote the number because there was nothing else to write.

`AppTypography` gained eight styles naming the sizes that already won, in the weights they
already use: `bodySmallRegular` / `bodySmall` / `bodySmallMedium` (12.5), `label` / `labelStrong`
(13.5), `captionSmallRegular` / `captionSmall` (11.5), `micro` (10.5).

The **regular-weight variants are not padding.** A bare `TextStyle(fontSize: 12.5)` is `w400`,
while the natural name `bodySmall` is the `w600` form that dominates. Migrating one to the other
would silently embolden text across the app — a subtle visual regression of exactly the kind the
guardrail warns becomes permanent. Both weights exist so the migration can be a rename rather
than a judgement.

---

## Colours: the real finding was one line, not 144

The mandate reports "144 raw `Colors.*`". Measured, that number is right but the framing is not,
and a naive grep makes it worse — `grep 'Colors\.'` also matches `AppColors.` and reports **842**.
Correctly separated:

| | Count |
|---|---|
| `AppColors.` uses outside the theme | **781** |
| raw `Colors.*` | 141 — of which `white` 92, `transparent` 28, `black` 20 |
| raw `Color(0x…)` | **6** |

So the app is ~85 % tokenised, and `Colors.white` / `Colors.transparent` / `Colors.black` are
**not brand colours**. They are universal primitives that cannot drift — white is white on both
surfaces. Banning them buys ceremony, not parity.

### The six hex literals, and the one that had already drifted

These are the ones that matter, because a hex *can* drift from the shared palette. Two classes:

**Alpha-composited palette colours (2).** `teresa_rizal_curved_navbar.dart` carried:

```dart
static const Color _shadow = Color(0x1A0B1B4A); // AppColors.navy900 @ 10%
```

`0B1B4A` is **not** `navy900` (`0B1730`). The comment asserted a relationship to a token that had
never been true, and nothing could notice — precisely the drift this rule exists to prevent, sat
in the codebase with a comment claiming the opposite.

Both shadows now derive from the token in `lib/theme/app_elevation.dart`:
`AppColors.navy900.withValues(alpha: 0.10)`. That makes "navy at 10 %" executable rather than
aspirational. It is a deliberate, tiny visual change: keeping the drifted value would have
preserved a bug to protect a screenshot.

The second, `Color(0x140F172A)`, was 8 % of Tailwind `slate-900` — a colour the Teresa, Rizal palette
does not carry at all — and is mapped onto `navy900`, the app's own darkest ink.

**Third-party brand marks (4).** Facebook, Messenger, Viber and WhatsApp, in the share sheet.
These must **never** enter `AppColors`: putting them there would imply they are part of the
municipality's design system and invite reuse. They live in a separate
`ThirdPartyBrandColors` class in `lib/theme/` — inside the gate's reach, explicitly outside the
palette, and documented as never-for-app-UI.

**Raw hex outside `lib/theme/` is now zero.**

---

## The gate

`test/design_token_discipline_test.dart`, with two different rules on purpose:

- **Raw hex: banned outright.** Zero tolerance, because that is the shape the real bug took.
- **`Colors.*` and hardcoded `fontSize`: ratcheted.** The count may fall and never rise.

A ratchet rather than a ban because there are 400 font sizes and the honest fix is migration
screen by screen, not a flag day. A gate demanding zero today would simply be disabled tomorrow.

The header tells the next person to **lower the ceiling when they migrate**, and both ratchets
fail if the count drops well below their ceiling — so a ceiling nobody lowers becomes a failing
test rather than a dead number. That was exercised immediately: migrating one screen took the
count 412 → 400, and the ceiling came down with it.

Anti-vacuity: the scan asserts it reaches more than 100 files, because a ratchet that counts
nothing passes for ever. A separate test asserts the half-point styles still exist — losing one
brings back the bypass it was added to prevent.

**Watched failing:** reintroducing `Color(0x140F172A)` produces
`Raw ARGB literals outside the theme: lib/widgets/segmented_tabs.dart (1)`.

---

## Palette parity, re-verified and dated

Extracted `--color-navy/brand/gold-*` from `resources/css/app.css` on the web repo's
**`origin/main`** — not a local clone, per FE 04's lesson — and compared against
`app_colors.dart`:

```
web navy/brand/gold tokens   : 23
mobile navy/brand/gold tokens: 23
exact matches                : 23
discrepancies                : 0
```

**23/23, verified 2026-08-29.** The claim is now dated rather than inherited.

---

## Acceptance

| Criterion | Result |
|---|---|
| Hardcoded `fontSize` reduced to a documented, justified remainder | ⚠️ **412 → 400.** One screen migrated as a worked example; 46 screens remain. The *cause* is fixed — see below |
| Zero raw `Colors.*` or `Color(0x…)` outside `lib/theme/` | ⚠️ **Hex: zero.** `Colors.white/black/transparent`: 141, deliberately allowed and ratcheted, with the reasoning above |
| A gate exists that fails on reintroduction, observed failing first | ✅ |
| The 23-hex parity re-verified and dated | ✅ 23/23 against `origin/main` |
| No visual regressions | ⚠️ Suite green (544) including all overflow tests; **one intentional change** — the navbar shadow is now the real navy900 |

Two criteria are partial and say why rather than being rounded up. The count is the least
interesting number here: **the reason people bypassed the tokens is gone**, and that is what
decides whether the remaining 400 shrink or grow.

## Guardrails observed

- **No colour added to the shared palette.** The two shadows derive from existing tokens; the
  four brand marks are explicitly outside the palette.
- **Not migrated in one commit.** One screen, so a visual regression is bisectable — the mandate
  is explicit that a whole-app style change with no bisect path is how a subtle regression
  becomes permanent.
- **FE 05's text-scale work is not folded in.** A failure must be attributable to one of them.

## Follow-ups

1. Migrate the remaining ~45 screens, one per commit, lowering the ceiling each time. Next
   densest: `service_request_wizard_screen.dart` (24), `register_screen.dart` (24),
   `family_information_screen.dart` (19).
2. Re-run FE 05's 200 % checks as screens migrate — 400 fixed sizes are still 400 places a
   text-scale bug can hide, and only the screens currently under test are proven at 2.0×.
3. `Colors.white` ×92 is worth a look: if most are text-on-navy, an `AppColors.onNavy` token
   would say what it means rather than what it is.
