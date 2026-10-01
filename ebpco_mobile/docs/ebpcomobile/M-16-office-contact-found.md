# The office's contact details were in the repository the whole time

*Found 31 August 2026 in `eBPCO-Mobile-App`. Front-end mobile only.*

---

## What happened

Yesterday this app was found printing an invented support address, a Metro
Manila phone number for a Sorsogon municipality, and an office address in
Quezon City — as the channel for exercising rights under RA 10173. They were
replaced with a sentence saying the office had published no direct line or
email, and M-16 was reported as blocked on the LGU.

**That sentence was a statement about what had been looked at, not about what
existed.**

`assets/permits/Building-Permit-and-Occupancy-Checklist.pdf` has been bundled
with this app since before any of that work. It is the Municipality of
Castilla's own documentary checklist, under its seal, headed *Office of the
Municipal Engineer*. Its footer reads:

> \*For updates and inquiries, please call MEO at 09054818572 (cellphone) or
> send an email at meocastilla@gmail.com within 3 working days.

Read at high magnification to be certain of every digit, because misreading a
phone number would be its own fabrication.

## What the app says now

`OfficeContact` carries the number, the address, the office's own *within 3
working days* reply pledge — and, beside them on the Help & Support screen,
**where they came from**. An applicant deciding whether to trust a phone number
is owed its provenance, and this app has been wrong about contact details once
already.

The office is now named as both: **Office of the Building Official — Office of
the Municipal Engineer**. The OBO is the statutory role under PD 1096; in
Castilla it sits with the Municipal Engineer's office, which is what the
checklist and the Excavation permit form are both headed. An applicant is
looking for a door.

## What is still genuinely unpublished

**A named Data Protection Officer.** The checklist gives the office; RA 10173
rights are a different channel and the LGU has not named an officer for it. The
Privacy Policy now gives the office's real details *and* says plainly that no
Data Protection Officer has been published, and to ask for one. That half of
M-16 stays open.

## The gate changed, and the change is the point

`office_contact_test` forbade the *shape* of an email address or a phone number
in any applicant-facing string. That was right when every such string was
invented. It is wrong now.

The rule is now: **a screen may not hold its own contact literal.** Real
details live in `OfficeContact`, which carries the document they came from; a
screen literal carries nothing. The shape check still runs — over `lib/features`
— so an invented number added to a screen still fails, and the fabrications
this replaced are still asserted gone by name.

Two more tests were added: that the details match the checklist exactly, and
that the checklist is still bundled — because if the file goes, the citation
becomes a claim nobody can check.

## The lesson worth keeping

Three tasks in a row this week were filed as blocked on an external party and
turned out to be answerable here: the bundle identifier's domain (settled by
`dig`), the permit forms (settled by `qlmanage`), and now the office's contact
details (settled by reading a file the app already ships).

**Before recording something as blocked on someone else, check what is already
in the repository.** All three had been filed by someone — me — who had not
looked.
