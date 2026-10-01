# Reference assets — kept in the repository, kept OUT of the app bundle

`assets/images/` is declared as a directory in `pubspec.yaml`, so **anything
placed there ships inside the binary**, referenced or not. That is how a
188 KB image of the **DILG seal** — the Department of the Interior and Local
Government, a national agency — was still travelling in the iOS bundle after
the app stopped using it on 31 August 2026.

It shipped as `DILG%20logo.png`, URL-encoded because of the space in its name,
which is also why a first check for the literal filename reported it absent.

Nothing referenced it, and an app should not ship an image it never draws — so
it lives here instead: still in the repository, still findable, no longer in
the binary.

**Not because the seal was improper.** The LGU is a partner with the DILG, and
the department co-issues the Joint Memorandum Circular this app's Terms cite.
An earlier version of this note called it a misattribution; that was written
without knowing the relationship and was too strong. It was the wrong mark for
the screen where the app identifies itself, which is a smaller thing.

**The rule this directory exists for:** an unreferenced file under `assets/`
is not dead weight that the build strips — it is shipped. Put anything kept
for reference outside `assets/`.

The DILG is still cited in the app, correctly, in the Terms: the
DILG–DPWH–DICT–DTI Joint Memorandum Circular that governs the unified
application forms. A citation is not a seal.
