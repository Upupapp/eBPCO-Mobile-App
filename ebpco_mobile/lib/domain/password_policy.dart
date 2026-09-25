/// Client-side mirror of the server's password policy — ported from the
/// citizen portal's `core/domain/password-policy.ts`, which itself mirrors
/// eBPCOBackend `identity/domain/password-policy.ts`. Same rules, same
/// order, same wording, so a rejection here reads exactly like the server's.
/// The breach screen is server-only: a password passing every check here can
/// still be refused on submit, and that error is shown as returned.
library;

const minPasswordLength = 12;

const _serviceWords = ['ebpco', 'permit', 'building', 'occupancy', 'quezon', 'philippines'];

final _uppercase = RegExp(r'\p{Lu}', unicode: true);
final _lowercase = RegExp(r'\p{Ll}', unicode: true);
final _digit = RegExp(r'\p{Nd}', unicode: true);
final _punctuation = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

class PasswordContext {
  final String? email;
  final String? firstName;
  final String? lastName;
  const PasswordContext({this.email, this.firstName, this.lastName});
}

bool _isRepetitive(String password) {
  final runes = password.runes.toList();
  return runes.isNotEmpty && runes.every((r) => r == runes.first);
}

bool _isSequential(String password) {
  final runes = password.toLowerCase().runes.toList();
  var ascending = true;
  var descending = true;
  for (var i = 1; i < runes.length; i++) {
    if (runes[i] != runes[i - 1] + 1) ascending = false;
    if (runes[i] != runes[i - 1] - 1) descending = false;
    if (!ascending && !descending) return false;
  }
  return ascending || descending;
}

bool _containsContextWords(String password, PasswordContext context) {
  final lower = password.toLowerCase();
  final candidates = [
    ..._serviceWords,
    context.firstName?.toLowerCase(),
    context.lastName?.toLowerCase(),
    context.email?.toLowerCase().split('@').first,
  ].whereType<String>().where((w) => w.length >= 4);
  return candidates.any(lower.contains);
}

class PasswordCheck {
  final String label;
  final bool passed;
  const PasswordCheck(this.label, this.passed);
}

List<PasswordCheck> passwordChecks(String password, [PasswordContext context = const PasswordContext()]) {
  final hasAny = password.isNotEmpty;
  return [
    PasswordCheck('At least $minPasswordLength characters long', password.runes.length >= minPasswordLength),
    PasswordCheck('Contains an uppercase letter', _uppercase.hasMatch(password)),
    PasswordCheck('Contains a lowercase letter', _lowercase.hasMatch(password)),
    PasswordCheck('Contains a number', _digit.hasMatch(password)),
    PasswordCheck('Contains punctuation', _punctuation.hasMatch(password)),
    PasswordCheck('Not a single character repeated', hasAny && !_isRepetitive(password)),
    PasswordCheck('Not a simple sequence (e.g. "123456789012")', hasAny && !_isSequential(password)),
    PasswordCheck('Doesn’t contain your name, email, or the service name', hasAny && !_containsContextWords(password, context)),
  ];
}

String? firstPasswordRejectionMessage(String password, [PasswordContext context = const PasswordContext()]) {
  if (password.runes.length < minPasswordLength) {
    return 'Use at least $minPasswordLength characters. A longer phrase is easier to remember and harder to guess than a short one with symbols in it.';
  }
  if (!_uppercase.hasMatch(password)) return 'Include at least one uppercase letter.';
  if (!_lowercase.hasMatch(password)) return 'Include at least one lowercase letter.';
  if (!_digit.hasMatch(password)) return 'Include at least one number.';
  if (!_punctuation.hasMatch(password)) return 'Include at least one punctuation character (e.g. ! ? . , -).';
  if (_isRepetitive(password)) return 'This is a single character repeated. Choose something with more variety.';
  if (_isSequential(password)) return 'This is a simple sequence. Choose something less predictable.';
  if (_containsContextWords(password, context)) {
    return 'This contains your own details or the name of this service, both of which are easy to guess.';
  }
  return null;
}
