# App Store readiness — where this build actually stands

Second pass, 31 August 2026, after the morning's sweep and a day of live
testing against a running server. **iOS only**, by standing rule.

**Verdict: NOT SUBMITTABLE — and the reason has changed.** This morning it was
a shared password in the binary and a missing account-deletion flow. Both are
closed. What blocks submission now is that **the app does not work**, and that
is measured rather than inferred.

---

## What is ready

Everything on the platform checklist, re-verified against a freshly built
release binary rather than against the source:

| Check | State |
|---|---|
| Bundle identifier | `ph.gov.castillasorsogon.ebpco` — no `com.example` |
| Display name / version | `E-BPCO` · `1.0.0+1` |
| Deployment target | iOS 15.0 |
| Release build | succeeds, **34 MB** |
| App icons | `Assets.car` + 1024 marketing icon, RGB, **no alpha** |
| Launch screen | `Base.lproj/LaunchScreen.storyboardc` — Castilla seal on brand red, matching the Flutter splash |
| Privacy manifest | `PrivacyInfo.xcprivacy` **shipped inside the bundle** |
| Export compliance | `ITSAppUsesNonExemptEncryption = false` |
| Credentials in the binary | **0** — `strings` on `App.framework` finds neither `password123` nor `user@ebpco.com` |
| Bundled fonts | 5 Poppins weights + `OFL.txt`; **no request to `fonts.gstatic.com`** |
| Usage strings | camera and photo library, specific, naming the app |
| ATS | no exceptions; no `http://` in `lib/` |
| **Account deletion** | **DELETE /me**, built and gated — Guideline 5.1.1(v) satisfied |

### Closed since this morning

* **The shared password.** The sign-in screen advertised `user@ebpco.com` /
  `password123`; confining the banner to debug was not enough, because
  `MockAuthRepository` shipped and accepted it. The constants now compile to
  `''` in release — measured 1 → 0 in the binary.
* **Account deletion.** Filed as a certain rejection because the contract
  declares no DELETE operation. `DELETE /me` existed all along — 202, session
  invalid afterwards.
* **The DILG seal.** 188 KB of a national agency's seal was still shipping as
  `DILG%20logo.png` after the app stopped using it, because `assets/images/`
  is a declared directory and ships what it contains. Moved to
  `docs/reference-assets/`; the bundle dropped from 35.9 MB to 34 MB.

---

## What blocks submission

### 1. The app cannot file 18 of the 19 permits it offers

Measured against a running server, filing one application of every type
through the app's own repository:

```
accepted: 1 of 19  —  Certificate of Occupancy
refused: 18        —  "The LGU does not issue a … permit."
```

This is D-10, ruled on 31 August: the office's names are canonical and the
server's `permit_types` seed carries seventeen different ones. **All eighteen
fail for the same reason**, so the seed is the whole fix.

**Why it is a submission blocker and not just a bug.** App Review Guideline
2.1 covers app completeness. An app whose primary function — filing a
building permit — fails for eighteen of nineteen cases will not pass a
reviewer who taps twice.

### 2. No production backend (B-1)

`AppConfig.assertShippable()` throws on a release build with no
`EBPCO_API_BASE_URL`, because such a build serves fabricated data and a mock
account. That guard is correct and it means **there is no submittable binary
until a production API exists**. Hosting and who operates it are E-1/E-2, and
outside this lane.

**What this lane could do about it, and has.** A live-mode release had never
been built. The switch everything depends on — `--dart-define`, read by
`AppConfig`, consulted by `RepositoryFactory` — had never been exercised end to
end, and no test could have caught a break in it: `String.fromEnvironment` is a
compile-time constant, so in a default build the live branch does not exist.
The entire suite runs against a binary where `useLiveBackend` is const false.
A define that stopped arriving would have passed 2,228 tests and shipped
fabricated data.

Now verified, and `tool/verify.sh` runs it on every pass:

* a release binary built **with** a base URL compiles the URL in (found once by
  `strings`), and still contains **no** credentials;
* `AppConfig.useLiveBackend` and `RepositoryFactory.isLive` are asserted to
  agree, in whichever mode the suite is run;
* a live build resolves every domain to its `Http` implementation;
* **a cleartext base URL fails the check.** The app declares no App Transport
  Security exceptions, so iOS refuses `http://` at runtime, not at build time —
  a release shipping one fails in a citizen's hands rather than here. If the
  LGU's eventual API is not HTTPS, that has to be known now.

So the moment a URL exists, the client side of B-1 is a build flag rather than
a discovery.

### 3. Document resubmission returns 404 (D-8)

`POST /applications/{id}/documents/{documentId}/resubmit` is called by the app,
undeclared in the contract, unimplemented on the server. A citizen whose
document is rejected cannot replace it.

---

## What is needed from App Store Connect, and is not in this repository

* **Privacy label** — answers prepared in `M-50-app-store-privacy-label.md`,
  including what "Other Data Types" is carrying: a TIN in nine places, PRC,
  PTR and CTC numbers, most of them belonging to somebody who is not the
  account holder.
* **Support URL** and **privacy policy URL** — the LGU has published neither
  a street address nor a DPO (M-11, M-16), so these need deciding.
* **Screenshots** — 6.7" and 6.5" iPhone. Cannot be produced here: synthetic
  taps are blocked on this machine, so the app cannot be driven past its
  first screen without someone holding it.
* **Review notes with credentials.** `user@ebpco.com` / `password123` belongs
  here now that it no longer appears on screen — and only if the reviewer is
  given a build pointed at a working API.
* **Age rating**, and the **export compliance** answer, which the Info.plist
  now pre-answers.

---

## The honest summary

The platform work is done. Every item a reviewer checks mechanically passes,
and the two things that would have been outright rejections this morning are
closed.

What remains is not App Store work at all. **The app cannot yet do the thing
it exists to do**, for reasons that live in a seed file and a hosting
decision. Submitting before those land would spend a review cycle to be told
something already known.
