/// Single source of truth for turning a birthdate into a completed-years
/// age — accounts for month/day, not just `currentYear - birthYear`, so
/// someone born Dec 20 isn't shown a year older until their birthday has
/// actually passed. Every place in the app that needs an age (resident
/// profiles, Dokyu/Tulong forms) derives it through this helper instead of
/// asking the citizen to type it separately from their Date of Birth.
int calculateAge(DateTime birthDate, {DateTime? asOf}) {
  final now = asOf ?? DateTime.now();
  var years = now.year - birthDate.year;
  if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
    years--;
  }
  return years < 0 ? 0 : years;
}
