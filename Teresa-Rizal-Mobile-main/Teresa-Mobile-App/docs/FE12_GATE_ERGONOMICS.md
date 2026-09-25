# FE 12 — Gate ergonomics

**Status:** complete, with the command's central premise **corrected by measurement**
**Date:** 2026-08-29
**Lane:** Windows. The macOS figures are quoted from the 2026-08-29 sweep, not re-measured here.

---

## The premise does not hold, and it matters

FE 12 says: *"The three slowest files dominate: `request_milestone_simulation_test.dart`,
`auth_navigation_regression_test.dart` and `duplicate_account_simulation_test.dart` each ran for
many minutes alone"*, and mandates *"attack the top three before anything else."*

Measured with `flutter test --reporter=json` and per-suite timings summed from
`testStart`/`testDone` events:

| | |
|---|---|
| Summed test time | **542.2 s** across 54 files |
| Wall clock | **~36–50 s** (Flutter shards across parallel `flutter_tester` processes) |
| Slowest file | `balita_image_viewer_test.dart`, **25.6 s** |
| Top 3 files combined | **74.9 s — 14 %** of summed time |
| Per test | 1.16 s (the command's figure was 4.4 s) |

**There is no hotspot.** The top twelve files sit in a 19–26 s band. Attacking the top three
would remove at most 14 % of summed time and, because the suite already runs in parallel, close
to nothing off the wall clock. `auth_navigation_regression_test.dart` — one of the three named —
is 23.9 s, i.e. ordinary.

Two of the three named files no longer exist under those names in the current tree, which is
itself a sign the profile was taken against an earlier shape.

So the mandate's first instruction was followed to the letter — profile first — and the profile
said not to do the second one. Optimising the named three would have been effort spent for a
result nobody would feel.

### Where the 33 minutes actually goes

Summed test time is 542 s on both lanes' worth of work, but the macOS lane's **wall clock** is
33 minutes — roughly 4× the summed time rather than a fraction of it. That is not a slow test
problem; it is a concurrency or machine problem. The Windows lane finishes the same 466 tests in
under a minute.

Worth the macOS lane checking before anyone rewrites a test: `flutter test --concurrency=N`,
what else is running, and whether Rosetta or a file-watcher is in the path. **The suite is not
the thing that is slow — one machine is.** That is a cheaper thing to fix than 466 tests.

---

## The fast tier

`tool/fast_test.dart`, run with:

```sh
dart run tool/fast_test.dart
```

**Measured: 22 tests, 2.6 s.** The target was under two minutes.

A Dart script, not a shell script, because two machines work this repository and it must behave
identically on both with no shell dependency.

**Selection is discovered, not listed.** A file joins the tier if it contains no `testWidgets(`.
Hand-listing the members would rot the moment someone adds a pure-logic test and forgets to
register it — the same failure as an allowlist that quietly stops covering what it names. This
also means FE 12's item 5 ("add the reachability check and the parity test to the fast tier")
needed no action: both are pure-logic files, so they joined automatically the moment they
existed.

It refuses to report success over an empty selection — `Executed 0 of 0` reads as a pass and is
not one — and it prints, every run, that it is **not** the gate.

### Being straight about what it covers

22 of 466 tests, 4.7 %. The tier is thin **by construction**: most of this codebase's model and
service behaviour is asserted through widget tests, so there is little pure-logic surface to
put in it. Growing it means writing model/service tests that do not pump widgets — worth doing,
but that is new coverage, not a re-tiering, and inventing it here would have been scope creep.

What it does cover is the structural gates: status parity, reachability, asset declarations,
and the resident-profile service maths. Those are the checks most likely to catch a mistake
early, and now they cost 2.6 s.

---

## CI: NO — and this is a recorded decision, not an omission

FE 12 mandates "Introduce CI" while noting the owner's standing position is no billed CI and
that the approach must be agreed first.

**Decision: do not add CI.** The owner's standing position across these repositories is
explicit — no GitHub Actions, no billed CI anywhere. This command's own guardrail says not to
introduce billed CI without agreement, and no agreement exists. Adding a workflow file here
would start billing on a public repository the moment anyone pushed.

The consequence is stated plainly rather than glossed: **the local gate is the only gate, and
nothing prevents an unrun one from reaching `main`.** That is a real weakness. The mitigations
actually available without CI:

1. The fast tier above, cheap enough to run constantly.
2. The structural checks now live *inside* `flutter test` rather than in `tool/` scripts nobody
   remembers — which is why `reachability_test.dart` and `status_parity_test.dart` are tests.
3. The sweep→test→merge→test→push protocol both lanes already follow.

If the owner ever wants a gate that is not opt-in, a local `pre-push` hook running the fast tier
is the zero-cost option. Not added unilaterally: a hook that blocks a push is a workflow change
for both lanes.

---

## Orphaned `flutter_tester` processes

The sweep found four `flutter_tester` processes on the macOS lane, two days old at 0 % CPU, plus
two `flutter` tool processes aged 1 d 6 h.

Measured on the Windows lane: **zero.** The only `dart` processes present were four minutes old,
from the profiling run that had just finished.

That difference is probably not coincidence. Orphans come from interrupted runs, and a 33-minute
gate gets interrupted in a way a 40-second one does not. The orphans look like a **symptom of
the gate cost, not an independent problem** — another reason to chase the macOS wall-clock gap
rather than the tests.

Cleanup, per lane:

```sh
pkill -f flutter_tester                                    # macOS / Linux
Get-Process flutter_tester -ErrorAction SilentlyContinue | Stop-Process   # Windows
```

---

## Acceptance

| Criterion | Result |
|---|---|
| A fast tier under two minutes covering models, services and utils | ✅ **2.6 s**, 22 tests — thin by construction, and said so |
| Full suite time reduced, with the per-file profile recorded before and after | ⚠️ **Profile recorded; no reduction attempted.** The profile showed a flat distribution with no hotspot, so the mandated optimisation would have bought ~0 wall clock. Chasing the macOS 4× wall-clock gap is the recommendation instead |
| Suite total still 450 or higher — never reduced by deletion | ✅ **466** |
| A CI decision recorded, and implemented if agreed | ✅ recorded: **no CI**, per the owner's standing position; consequence stated |

The second criterion is marked partially met rather than rounded up. Reporting a reduction here
would have meant either doing pointless work or claiming credit for the difference between two
machines.

---

## Guardrails observed

- **No test was deleted to make the suite faster.** The total went 450 → 466 across this pass.
- Nothing was marked skipped to hit a time target.
- The fast-tier script refuses to pass on an empty selection.
- No billed CI was introduced.

## Follow-ups

1. **macOS lane: find the 4× wall-clock gap** — `--concurrency`, machine load, Rosetta. Far
   cheaper than optimising 466 tests, and it dissolves the orphaned-process problem too.
2. Grow the fast tier by writing model/service tests that do not pump widgets — new coverage,
   deliberately not attempted here.
3. Offer a `pre-push` hook running the fast tier, if the owner wants a non-optional gate.
