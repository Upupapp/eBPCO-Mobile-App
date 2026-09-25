# FE 05 — Accessibility

**Status: PARTIAL — and deliberately reported as partial.** The automatable half is done and
enforced. The half that needs a screen reader on a real handset is not, and cannot be faked from
this lane.
**Date:** 2026-08-29
**Gate:** `flutter analyze` clean · `flutter test` **516 passed** (was 466)

---

## Why this one is not "complete"

FE 05's headline acceptance is *"every icon-only control and status chip announces something
meaningful under VoiceOver and TalkBack"*. That is a **device measurement**. This lane has an
Android emulator and no iOS toolchain, and the command's own guardrail says a static count is
not accessibility coverage.

So this deliverable does the parts that can be measured exactly — contrast, overflow at 200 %,
whether a control has an accessible name at all — and hands the screen-reader walk to FE 03 with
the groundwork laid. Claiming otherwise would be the exact failure the standing rules warn
about.

---

## Two real 200 % defects, found and fixed

The existing overflow suites stopped at 1.3× (one went to 1.6×). Extending them to **2.0×**
immediately found two layouts that break for a citizen who has set large text — the population
this app is built for, with dedicated OSCA and PDAO flows.

### 1. `_FamilyChip` — 82 px of overflow

`HouseholdInformationScreen`, at 280 pt / 200 %: **82 px** over. Also 42 px at 320 pt and 1.8 px
at 360 pt; clean at 412 pt.

Located by walking `RenderFlex` children and comparing their summed width against the row's
(190.0 vs 271.8 — exactly the 81.8 px reported). The cause was a trailing `Text('Your family')`
with no `Flexible`, so it could neither shrink nor wrap.

Fixed by making it `Flexible`. **Not** by shrinking the font — that would defeat the setting the
citizen chose, and the guardrail says so explicitly.

### 2. `OnboardingStepIndicator` — 35 px of overflow

`RegisterScreen` step 1, at 280 pt / 200 %. Same shape: an unconstrained leading
`Text('Step 1 of 4')`. Now `Flexible` with ellipsis, keeping priority over the step label beside
it, which ellipsizes first.

This one sits on the **registration** screen — the first thing a new citizen sees.

### Coverage now permanent

| Suite | Scales before | Scales now |
|---|---|---|
| `resident_profile_overflow_test.dart` | 1.0, 1.3 | 1.0, 1.3, **2.0** |
| `home_screen_overflow_test.dart` | 1.0, 1.3, 1.6 | 1.0, 1.3, 1.6, **2.0** |
| `nav_access_overflow_test.dart` | 1.0, 1.3 | 1.0, 1.3, **2.0** |

152 overflow assertions across four device widths down to 280 pt. Suite total 466 → 516.

---

## The text-scale cap is gone, and the measurement says it should be

`teresa_rizal_nav_item.dart:55` clamped the system text scale to `1.3` — the only place in the app
that touched text scaling, and it *limited* it.

FE 05 says remove it unless there is a measured reason to keep it. Measured, with the clamp
removed, at 280/320/360/412 pt:

| Scale | `Home` | `Profile` | Ellipsized? |
|---|---|---|---|
| 1.0× | 40.8 × 12.0 | 71.4 × 12.0 | no |
| 1.3× | 53.4 × 15.0 | 72.0 × 15.0 | **`Profile` already yes** |
| 2.0× | 72.0 × 23.0 | 72.0 × 23.0 | yes |

Three findings, and together they settle it:

1. **No overflow at any width at any scale up to 2.0×.** The fixed-height bar absorbs it.
2. The label nearly doubles in height, 12 pt → 23 pt — which is the entire point.
3. **`Profile` already ellipsized at 1.3× *with* the clamp.** So the clamp never bought
   legibility; it only rendered the same truncated word smaller.

Removed, with all of that written at the call site as the mandate requires. Ellipsis is visual
only — the semantics tree still carries the full label, so a screen reader is unaffected, and
the icon above carries the identity regardless.

---

## Contrast: two failures, both inherited, both raised not patched

Status chips render 12 px regular = "normal text" under WCAG 2.1, so the threshold is **4.5:1**.
Computed for all 18 `AppStatus` values (`test/status_contrast_test.dart`):

| Status | Ratio | |
|---|---|---|
| 16 statuses | 4.79:1 – 8.92:1 | pass |
| **`Cancelled`** | **4.34:1** | fail (marginal) |
| **`Archived`** | **2.34:1** | fail — roughly half the requirement |

Both are grey-on-grey pairs (`slate-500` and `slate-400` on `slate-100`) that come **straight
from the shared web palette**. Both surfaces deliberately de-emphasise these two statuses — but
WCAG grants no exemption for text that is *meant* to recede, and "Archived" is still something a
citizen has to be able to read.

**Not re-coloured here.** The guardrail is explicit: the palette is a verified 1:1 port, so
patching it on mobile breaks parity and leaves the web platform failing anyway. They are
recorded in `_knownSharedPaletteFailures` with their measured ratios and **raised as a
cross-surface finding**. A companion test fails if either is ever fixed upstream, so the
escalation cannot go stale.

The test also refuses any *new* sub-AA colour: a newly introduced colour that fails is a
mobile-side mistake, not a shared-palette problem, and the map is not a place to hide one.

---

## Accessible names on icon-only controls

Ten `IconButton`s; **three** had a tooltip. In Flutter the tooltip *is* the semantic label, so
the other seven announced only "button".

All ten now have one: *Remove family member*, *Remove this family from the household*, *Remove
member*, *Remove*, *Remove attachment*, *Back* ×2, plus the three that already had them.

`test/accessibility_labels_test.dart` keeps it that way, and was **watched failing** — stripping
one tooltip produced `lib/screens/support/report_problem_screen.dart:209`. It refuses to pass if
it finds fewer than 10 call sites, so a broken pattern cannot make it green over an empty scan.

**Its limits, stated rather than glossed:** it is a source-level check. It proves every icon
button *has* a name, not that the name is a *good* one, and it cannot see icon-only controls
built from `GestureDetector` or `InkWell`. Only a device walk settles those.

---

## Acceptance

| Criterion | Result |
|---|---|
| Every icon-only control and status chip announces meaningfully under VoiceOver/TalkBack | ⚠️ **Not verified.** All 10 icon buttons now have names and it is enforced; the screen-reader walk needs a device (FE 03) |
| App usable end to end at 200 % on both platforms, with screenshots | ⚠️ **Partial.** 152 automated assertions at 2.0 % across 4 widths, two real defects fixed — but no manual walk, no screenshots, Android only |
| Contrast results recorded for the full status palette, failures raised not re-coloured | ✅ all 18 computed, 2 failures raised as cross-surface findings |
| The text-scale cap is removed, or justified in writing | ✅ **removed**, with the measurement written at the call site |

Two of four are marked partial. Both are partial for the same reason — they need a screen reader
on real hardware — and rounding them up would be the "static count as accessibility coverage"
mistake the command warns against.

## Guardrails observed

- No `semanticLabel` was sprayed mechanically; only genuinely icon-only controls were named.
- No 200 % overflow was fixed by shrinking a font. Both fixes are layout changes.
- No palette token was re-coloured to pass contrast.
- No static grep is counted as accessibility coverage — this file says where each check stops.

## Follow-ups

1. **VoiceOver + TalkBack walk, screen by screen** (with FE 03). The remaining half.
2. **Touch targets** — the 48×48 minimum was not audited. It needs rendered geometry per
   control, and is best done in the same device pass.
3. **Decorative images need `ExcludeSemantics`** — not started. A screen reader that reads
   decoration aloud is worse than one that stays quiet.
4. `semanticLabel` on meaningful images is still **0**. The demo ID card images in particular
   convey real information.
5. **Raise `Cancelled` / `Archived` contrast with the web platform team.**
6. FE 06 first, then re-check: 433 hardcoded `fontSize` values are 433 places a text-scale bug
   can still hide, and only the screens under test are currently proven at 2.0×.
