/// Where a saved Draft reopens (2026-10-01): at the first step the citizen
/// has not finished, or at Review & Submit once every step is done — so
/// Continue takes them back to where they stopped instead of to the first
/// page of an application they already filled in. Every field stays
/// editable through Back. The portal decides the same way (`draft-resume.ts`).
///
/// [applicantDone]: a business is chosen (and not known to be inactive), and
/// a Renewal or Amendment names its permit. [detailsDone]: the project
/// address and scope of work are filled in. [documentsDone]: every required
/// document is attached.
int resumeStep({required bool applicantDone, required bool detailsDone, required bool documentsDone}) {
  if (!applicantDone) return 1;
  if (!detailsDone) return 2;
  if (!documentsDone) return 3;
  return 4;
}
