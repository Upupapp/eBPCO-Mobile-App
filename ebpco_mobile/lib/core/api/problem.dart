/// RFC 9457 `application/problem+json` — what every eBPCO API error
/// response is, ported field-for-field from the web portals' own
/// `core/api/problem.ts` so the same server response produces the same
/// citizen-facing message on both surfaces.
class FieldError {
  final String pointer;
  final String message;
  const FieldError({required this.pointer, required this.message});

  factory FieldError.fromJson(Map<String, dynamic> json) => FieldError(
        pointer: json['pointer'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );
}

class Problem {
  final String? type;
  final String? title;
  final int? status;
  final String? detail;
  final String? instance;
  final List<FieldError> fieldErrors;

  const Problem({this.type, this.title, this.status, this.detail, this.instance, this.fieldErrors = const []});

  factory Problem.fromJson(Map<String, dynamic> json) {
    final rawErrors = (json['errors'] ?? json['fieldErrors']) as List<dynamic>?;
    return Problem(
      type: json['type'] as String?,
      title: json['title'] as String?,
      status: json['status'] as int?,
      detail: json['detail'] as String?,
      instance: json['instance'] as String?,
      fieldErrors: rawErrors?.map((e) => FieldError.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
    );
  }
}

class ApiError implements Exception {
  final int status;
  final Problem? problem;

  /// True when the body was not a problem document — a bare 413, a proxy
  /// page, an empty body, or no connection at all (status 0).
  final bool bare;

  const ApiError(this.status, this.problem, this.bare);

  /// What to put in front of a citizen. Never the status code alone.
  /// `title` is checked before the generic catch-all: a 401 for a wrong
  /// password carries no `detail` but DOES carry a real, written-for-a-reader
  /// `title` — see the web client's own `citizenMessage` for why this order
  /// matters (found live wiring the real login flow).
  String get citizenMessage {
    final detail = problem?.detail;
    if (detail != null && detail.isNotEmpty) return detail;
    if (status == 413) return 'That file is too large to upload. Try a file under about 750 KB.';
    if (status == 404) return 'We could not find that. It may not exist, or it may not be on your account.';
    if (status == 0) return "We could not reach the Municipality's system. Check your connection and try again.";
    final title = problem?.title;
    if (title != null && title.isNotEmpty) return title;
    return "Something went wrong at the Municipality's system. Please try again.";
  }

  @override
  String toString() => 'ApiError($status, ${problem?.detail ?? problem?.title})';
}

ApiError problemFrom(dynamic body, int status) {
  final looksLikeProblem = body is Map<String, dynamic> &&
      (body.containsKey('detail') || body.containsKey('title') || body.containsKey('type'));
  if (!looksLikeProblem) return ApiError(status, null, true);
  return ApiError(status, Problem.fromJson(body), false);
}
