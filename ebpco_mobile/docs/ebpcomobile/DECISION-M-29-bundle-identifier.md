# M-29 — the bundle identifier. One decision, then a mechanical change.

> **APPLIED, 31 August 2026 — half of it.** The owner approved
> `ph.gov.castillasorsogon.ebpco`. **iOS and macOS carry it now**: six
> `PRODUCT_BUNDLE_IDENTIFIER` entries in the Xcode project (three of them the
> test target) and one line in `macos/Runner/Configs/AppInfo.xcconfig`.
>
> **Android and Linux still carry `com.ebpco.ebpco_user_app`, and they are not
> this lane's to change.** The Windows agent owns Android releases, and the
> change there is a file move rather than an edit: `MainActivity.kt` lives at
> `android/app/src/main/kotlin/com/ebpco/ebpco_user_app/`, a directory path
> derived from the identifier.
>
> **For the Windows lane, the whole change is:**
>
> 1. `android/app/build.gradle.kts` — `namespace` and `applicationId` both to
>    `ph.gov.castillasorsogon.ebpco`.
> 2. Move `android/app/src/main/kotlin/com/ebpco/ebpco_user_app/MainActivity.kt`
>    to `android/app/src/main/kotlin/ph/gov/castillasorsogon/ebpco/` and change
>    its `package` line to match.
> 3. `linux/CMakeLists.txt` — `APPLICATION_ID` to the same.
> 4. Delete the split expectation in
>    `test/architecture/bundle_identifier_test.dart` and set `_android` to
>    `_apple`. That test fails until you do, and says so.
>
> Nothing has been published under either identifier, so this is still free.
> It stops being free at the first store submission.

---

*Measured 29 August 2026. Front-end lane; the Android half is the Windows
lane's and is described, not changed.*

---

## Where it stands

**The two stores already disagree**, which is a defect on its own:

| Target | Identifier |
|---|---|
| iOS | `com.ebpco.ebpcoUserApp` |
| Android | `com.ebpco.ebpco_user_app` |

They are separate namespaces, so nothing *breaks* today — but they are meant to
name one product, and two spellings will be quoted at Apple and Google as though
they were deliberate. Settling M-29 is the moment to reconcile them.

`com.ebpco` is a placeholder. Reverse-DNS convention expects a domain the
publisher controls, and this app is published by the Municipality of Castilla.

## Everywhere it is written

Twelve files, across six platform targets and the documentation:

| Owner | Files |
|---|---|
| **This lane (iOS)** | `ios/Runner.xcodeproj/project.pbxproj` — 3 `Runner` + 3 `RunnerTests` entries |
| **Windows lane (Android)** | `android/app/build.gradle.kts` (`namespace`, `applicationId`) and `android/app/src/main/kotlin/com/ebpco/ebpco_user_app/MainActivity.kt` — **whose directory path is derived from the identifier**, so their change moves a folder |
| Neither, in practice | `macos/`, `linux/`, `windows/` — Flutter desktop scaffolding this product does not ship. Worth aligning for tidiness, not worth blocking on |
| Documentation | `LANES.md`, `release/ios/README.md`, `release/ios/NOTES.md`, `docs/MANUAL-TASKS.md`, the production master command |

## Why it cannot wait, and cannot be undone

- **It is permanent after publication.** Neither store lets an app change its
  identifier; a new one is a new listing, losing reviews, ratings and installed
  base.
- **It blocks every remaining iOS step.** Registering a provisioning profile
  binds the identifier to the team — which is exactly why no archive has been
  attempted (see `release/ios/NOTES.md`). Registering the placeholder would
  consume a slot on `2K2SF7NRQP` for a name nobody chose.

## What I recommend

**A single identifier, in reverse-DNS on a domain the LGU controls, identical
on both stores.** Shape, not a specific string:

```
ph.gov.<lgu-domain>.ebpco
```

### Correction, 30 August 2026 — there IS a candidate domain

This note said no `.gov.ph` domain for Castilla was recorded anywhere in the
repository, and that a chosen one would therefore be invented. **That was
wrong.** The check behind it looked at the documents and the platform files and
not at `lib`.

`lib/core/contract/requirements_catalog.dart` records
**`castillasorsogon.gov.ph`** as the *"Municipality of Castilla, Sorsogon —
official Citizen's Charter / OBO documentary checklist"*.

It carries `verificationStatus: PENDING_CASTILLA_VERIFICATION` and a note that
the site was *"not accessible to automated research as of 2026-08-20"*.

### Second correction, 31 August 2026 — the domain is verified

The "recorded but unverified" framing conflated two different questions. Only
one of them is still open.

**Does the domain exist and belong to a government entity? Yes — measured by
DNS, not asserted:**

```
$ dig +short castillasorsogon.gov.ph A
104.18.34.142
172.64.153.114

$ dig +short castillasorsogon.gov.ph NS
ns3.dns.gov.ph.  ns4.dns.gov.ph.  ns5.dns.gov.ph.  newscott.gov.ph.

$ dig +short castillasorsogon.gov.ph SOA
ns3.dns.gov.ph. dns.dict.gov.ph. 2022072147 …
```

The zone is live and **delegated to the Philippine government's own
nameservers**, with the SOA responsible party at `dns.dict.gov.ph` — the
Department of Information and Communications Technology, which administers the
`.gov.ph` namespace. **A `.gov.ph` zone is issued only to a Philippine
government entity**, and the label is `castillasorsogon`.

**What is still not machine-verifiable:** the page itself. It sits behind a
Cloudflare challenge and returns `403` to an automated fetch, which is exactly
what the catalogue entry recorded on 20 August. That is a fact about the site's
bot protection, not about the domain.

**And that distinction is the point.** A reverse-DNS bundle identifier is a
claim about a *domain*, not about the wording on a page. The domain is real,
governmental, and Castilla's. `PENDING_CASTILLA_VERIFICATION` stays exactly
where it is — it describes whether the **Citizen's Charter content** in that
catalogue came from Castilla, which is M-08, and is untouched by any of this.

### So the recommendation is no longer conditional

```
ph.gov.castillasorsogon.ebpco
```

Avoid the two current spellings' suffix: `UserApp` and `user_app` both name an
internal build target rather than the product an applicant installs. Avoid the
underscore, which Apple discourages.

**The one thing still outstanding is the decision, not the evidence.** The
owner deferred it on 30 August pending the LGU's answer, and it has not been
applied. What would make it wrong is not the domain — it is if the LGU intends
to publish under some other identity, which no measurement can tell me.

The fallback remains: if the LGU prefers `com.ebpco`, that is defensible for a
pilot, but it must then be spelled **identically** everywhere, which today it
is not.

Avoid: `_` in the iOS identifier (Apple discourages it), and the
`UserApp`/`user_app` suffix, which describes an internal build target rather
than the product an applicant installs.

## What happens once you decide

**My half is three lines** — six `PRODUCT_BUNDLE_IDENTIFIER` entries in one
Xcode project file, of which three are the test target. No code references it;
nothing in `lib/` reads it.

**The Windows lane's half is larger**: two Gradle values plus a package
directory move for `MainActivity.kt`.

### It is a four-target split, not a two-target one

Measured 30 August: **macOS carries the iOS spelling and Linux carries the
Android one.** Two camps, four files, one product. macOS and Linux are not
shipped, and they are still two more places the wrong spelling is written down
and can be copied from.

`test/architecture/bundle_identifier_test.dart` now pins all four and asserts
the split *as it stands*, so it cannot be closed by halves: change one side and
the test fails; change both to the same value and it fails too, and says to
delete itself.

Say the identifier and I will apply the iOS half, update the four documents, and
leave the Android half stated for that lane.
