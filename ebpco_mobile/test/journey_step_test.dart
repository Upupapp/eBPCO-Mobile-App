import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/theme/app_status.dart';

/// The step tracker on an application's page (2026-10-01): five steps, and
/// every one of the 19 lifecycle statuses lands on one of them, past them, or
/// off the road entirely.
void main() {
  int? step(LifecycleStatus status) => status.journeyStep;

  test('a draft is on the first step, not past it', () {
    expect(step(LifecycleStatus.draft), 0);
  });

  test('an application returned for revision is still in review', () {
    expect(step(LifecycleStatus.revisionRequired), step(LifecycleStatus.underEvaluation));
    expect(journeySteps[step(LifecycleStatus.revisionRequired)!], 'Review');
  });

  test('each status lands on the step its name says', () {
    expect(journeySteps[step(LifecycleStatus.received)!], 'Review');
    expect(journeySteps[step(LifecycleStatus.assessed)!], 'Payment');
    expect(journeySteps[step(LifecycleStatus.paymentVerified)!], 'Payment');
    expect(journeySteps[step(LifecycleStatus.forApproval)!], 'Approval');
    expect(journeySteps[step(LifecycleStatus.readyForRelease)!], 'Release');
  });

  test('a released permit has every step done', () {
    expect(step(LifecycleStatus.released), journeySteps.length);
    expect(step(LifecycleStatus.completed), journeySteps.length);
  });

  test('a closed application draws no road at all', () {
    for (final status in [LifecycleStatus.rejected, LifecycleStatus.cancelled, LifecycleStatus.expired]) {
      expect(step(status), isNull, reason: status.label);
    }
  });

  test('the road only moves forward through the lifecycle order', () {
    var last = -1;
    for (final status in LifecycleStatus.values) {
      final at = step(status);
      if (at == null || status == LifecycleStatus.revisionRequired) continue;
      expect(at, greaterThanOrEqualTo(last), reason: status.label);
      last = at;
    }
  });
}
