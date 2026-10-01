# ADR 0001 (mobile) — Tokens live in the keychain, and sign-out means sign-out

**Status:** Accepted
**Date:** 19 August 2026
**Closes:** M-01 (client half), M-22, gap G5.
**Taken out of index order, deliberately:** TAB 11 before TAB 10.

## Why this came before wiring the live layer

The Master Command sequences TAB 10 (live repositories) before TAB 11. That
order is wrong here and the Master Command itself says why: *"fixing token
storage after real tokens are issued means every issued token was, for a period,
stored insecurely."*

TAB 03 now issues real tokens. So this had to land first. The read point
returned null in every shipped build, which means nothing has ever been exposed
— and that is exactly the window worth not wasting.

## What was wrong

`LocalStorageService.sessionToken()` read from SharedPreferences: an unencrypted
XML file on Android and an unencrypted plist on iOS. Readable on a rooted or
jailbroken device, and historically swept into automatic cloud backup. A session
token there is a session anyone holding the backup can resume.

## What replaces it

**The platform keychain**, through `flutter_secure_storage`. On iOS,
`first_unlock_this_device` rather than `first_unlock`: the plain variant is
included in encrypted iCloud backups and restores onto a *different* device,
carrying an applicant's session with it. `synchronizable: false` for the same
reason. On Android the plugin's own Keystore-backed ciphers — the
`encryptedSharedPreferences` option is deprecated as of v10 because Google
deprecated the Jetpack Security library behind it.

The old key is purged on startup. It almost certainly holds nothing, but "almost
certainly" is not a reason to leave it.

## Three things that are load-bearing

**Single-flight refresh.** An applicant opening the app after a while has a home
screen firing several requests at once, all of which 401 together. Without a
guard each one refreshes — and because refresh tokens rotate and a replay
revokes the whole family (TAB 03), the second refresh to land signs them out and
looks, from the server, like a stolen token. Ten concurrent 401s now produce one
refresh call.

**Certificate pinning with a backup pin and a kill switch.** Without pinning, a
device with an attacker-installed root reads every token and every identity
document, and the platform trust store does not help because the attacker's root
is *in* it. The backup pin is the next certificate's, so a renewal needs no app
update. The kill switch exists because if both pins are wrong, every install is
bricked until the stores approve an update — days. It is a **build-time** flag,
never remote: a remotely disableable pin can be disabled by whoever is doing the
intercepting.

**Sign-out clears documents, not just tokens.** On a shared or handed-on device —
common here, not exotic — a sign-out that only forgets the token leaves the next
person looking at somebody's title deed. The preference sweep is an **allow-list**:
a key added later is cleared by default, because the thing that would otherwise
be forgotten is somebody's data. Onboarding state and language survive, since
wiping them makes every sign-out feel like a factory reset without protecting
anyone.

## What is NOT verified here

- **A real TLS handshake against a pinned certificate.** The pin arithmetic,
  backup pin, kill switch and misconfiguration guard are all tested against
  synthetic certificates; a live handshake needs a server. Acceptance criteria 4
  and 5 are therefore **partially met**, and rehearsing a rotation against
  staging is blocking for TAB 21.
- **Keychain behaviour on a device.** `flutter_secure_storage` has no
  implementation in the Flutter test environment, so the store's contract is
  verified through the in-memory implementation and the *absence* of writes to
  SharedPreferences. A device test belongs with M-18.
- **`FLAG_SECURE` and app-switcher redaction** are not implemented. They need
  platform channel work and a decision about which screens; recorded rather than
  half-done.
- **PBKDF2 retirement.** `CredentialVerifier` still backs the mock sign-in. It
  stops being an authentication mechanism when TAB 10 wires the live layer, and
  should be deleted or repurposed as a local unlock then — with M-17.
