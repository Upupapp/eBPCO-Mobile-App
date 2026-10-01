# The API host has to satisfy App Transport Security

Measured 31 August 2026. Prompted by B-1: before a base URL is chosen, it is
worth knowing what the app will and will not talk to.

## Why this is not just "use HTTPS"

`Info.plist` declares **no ATS exceptions**, deliberately. So iOS enforces
Apple's full requirement set, and it enforces it **at runtime** — a build
pointed at a non-compliant host compiles, uploads, passes review, installs, and
then fails in a citizen's hands with a network error nobody can explain.

Four things must all hold:

* **TLS 1.2 or later.** TLS 1.0 and 1.1 are refused.
* **A certificate that validates against the system trust store.** Self-signed
  and expired both fail — this is the one a hand-rolled VPS deployment usually
  trips over.
* **Forward secrecy** — an ECDHE or DHE key exchange.
* **An accepted cipher** — the AES-GCM or ChaCha20-Poly1305 families.

HTTPS alone satisfies none of these by itself.

## What the LGU's existing hosts do today

```
$ ./tool/check-ats.sh castillasorsogon.gov.ph
  certificate            valid
  protocol               TLSv1.2
  forward secrecy        ECDHE-RSA-AES128-GCM-SHA256
  cipher family          accepted by ATS
  PASSES

$ ./tool/check-ats.sh castilla-ebpco.online
  certificate            valid
  protocol               TLSv1.2
  forward secrecy        ECDHE-ECDSA-CHACHA20-POLY1305
  cipher family          accepted by ATS
  PASSES
```

**Both pass.** The municipality's own domain and the eBPCO website already meet
every requirement, as does the admin portal on Netlify. So an API served from
the same domain, or through the same providers, will be fine — and the answer
to "will it be HTTPS?" is very likely yes, for reasons stronger than intent.

## Where the risk actually is

Not the domain. **A deployment outside it.** The realistic failure is an API
stood up on a bare instance with a self-signed certificate, or behind a
load balancer terminating TLS 1.0 for compatibility with something older. Both
serve `https://` and both are refused by the app.

So the check to run is not "is it HTTPS" but `./tool/check-ats.sh <host>`,
against the real API host, **before** a release is built pointing at it.

## Do not answer a failure with an exception

`NSAllowsArbitraryLoads`, or a per-domain exception, would make the app connect
to a host Apple considers unsafe — and it weakens the guarantee for every other
connection the app makes, on a client carrying citizens' identity documents,
land titles and TINs. It also invites a review question that has to be answered
with a justification.

**Fix the host.** The LGU's existing infrastructure already shows it can be
done, because it already is.

## The two checks, together

```
./tool/check-ats.sh api.example.gov.ph     # can the app reach it at all
flutter test test/core/config/live_mode_define_test.dart \
  --dart-define=EBPCO_API_BASE_URL=https://api.example.gov.ph
```

The second is in `tool/verify.sh` and refuses a cleartext URL. The first is the
one that needs running once, by hand, the day a host exists.
