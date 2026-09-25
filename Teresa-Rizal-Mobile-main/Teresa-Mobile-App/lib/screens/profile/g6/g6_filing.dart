/// Who the next Dokyu request is being started for.
///
/// [ServiceRequest] records the signed-in applicant only. It has no field
/// for the household member a request was filed for, and this prototype
/// does not add one. The member screen sets [memberName] before opening
/// the existing Dokyu picker; the request wizard copies it into the
/// applicant name field, then the member screen clears it when that
/// picker route pops.
class G6FilingContext {
  G6FilingContext._();

  static String? memberName;
}
