# ADR 0002 (mobile) — Queued is not Submitted

**Status:** Accepted
**Date:** 19 August 2026
**Closes:** M-20, gap G10.

## The constraint everything else serves

A queued submission is shown as **"Queued"**, never "Submitted".

An applicant who believes a filing reached the LGU when it is sitting on their
phone will not resend it. They will find out at the counter, possibly after a
deadline they thought they had met — and from their side the system lied to
them. Every other decision here follows from refusing to do that.

`applicantStatus` has no path from a waiting state to the word "Submitted", and
a test iterates every state to prove it.

## Why the queue exists at all

A permit application is fifteen or more screens and a stack of photographed
documents. Losing one to a dropped connection is not a minor inconvenience: it
sends the applicant back to the counter, which is the thing this system exists
to avoid. Mobile connectivity in the target environment cannot be assumed.

## The decisions inside it

**The idempotency key is created once, at enqueue, and reused on every retry.**
This is what makes a submission interrupted *after the server committed but
before the response arrived* safe: the replay carries the same key and the
server returns the original result. Regenerating it per attempt would turn one
bad connection into two building permits.

**Ordering has two rules.** A submission cannot go before the uploads it
references, or the server rejects it for naming documents that do not exist.
And within one application items go in the order the applicant did them, while
across applications they do not queue behind each other — one stuck filing must
not hold up an unrelated one.

**Transient versus permanent is `ApiFailure`'s judgement, not a second one.**
Retrying a validation error forever burns battery and data and never succeeds;
giving up on a dropped connection loses work that would have gone through a
minute later. An *unexpected* error is treated as transient, because being wrong
that way costs a retry and being wrong the other way discards a filing over a
bug.

**Backoff carries jitter.** Not decoration: without it every device that lost
the same cell tower retries at the same instant, and the LGU's server meets a
thundering herd exactly as it comes back up.

**A permanent failure is never discarded.** It stays in the queue with the
server's own explanation — which knows the specifics, where a generic message
does not — and reads as "Needs your attention". Silently dropping an applicant's
work is worse than any error message.

**Retrying stops eventually**, not because the failure stopped being transient
but because an item retrying invisibly forever is indistinguishable from one
that was lost.

## Where the data lives

Queue **metadata** — names, addresses, business details, document ids — is in
the platform keychain, for the same reason tokens are (ADR 0001). Document
**bytes** stay in the app's private directory, which both platforms encrypt at
rest, and the queue references them by path: putting megabytes of scanned plans
into a keychain designed for secrets is the wrong tool and would fail on size.

## What is NOT verified here

- **A real force-quit and device restart.** The durability test constructs a new
  queue over the same store, which is the closest a unit test gets. A device
  test belongs with M-18.
- **Encryption at rest, observed.** `flutter_secure_storage` has no
  implementation in the Flutter test environment, so the secure store is
  exercised through the in-memory one. Same limitation as ADR 0001.
- **Connectivity-triggered flush.** The engine flushes when asked; nothing yet
  watches for a connection returning. That needs `connectivity_plus` and a
  decision about background execution, which is a platform question rather than
  a logic one — and polling would defeat the battery reasoning above.
- **Nothing is wired into the submission path yet.** The queue and engine are
  complete and tested; making the wizards enqueue instead of calling the API
  directly is the next step, and it is deliberately separate so this can be
  reviewed on its own.
