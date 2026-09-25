import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/catalog_gate_policy.dart';
import '../../data/service_catalog_mock.dart';
import '../../models/access_level.dart';
import '../../screens/auth/register_screen.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/soft_widget.dart';
import 'catalog_chrome.dart';

Future<void> showGuestRequestGate(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: SoftColors.clear,
    builder: (ctx) => const _GateSheet(guest: true),
  );
}

Future<void> showUnverifiedRequestGate(BuildContext context, {bool resubmit = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: SoftColors.clear,
    builder: (ctx) => _GateSheet(guest: false, resubmit: resubmit),
  );
}

/// Centered duplicate-account intercept. The session switch is Pack K.
Future<void> showDuplicateAccountDialog(
  BuildContext context, {
  VoidCallback? onGoToVerified,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _DuplicateDialog(onGoToVerified: onGoToVerified),
  );
}

/// Applies [startRequestGate]. Returns true when the request may continue.
bool openStartGate(
  BuildContext context, {
  CatalogGatePolicy? policy,
  bool emergency = false,
}) {
  CitizenSessionService? session;
  try {
    session = context.read<CitizenSessionService>();
  } catch (_) {}
  final decision = startRequestGate(
    catalogAccountKind(session?.account),
    policy ?? currentCatalogGatePolicy(),
    emergency: emergency,
  );
  switch (decision) {
    case StartRequestGate.proceed:
      return true;
    case StartRequestGate.guestSheet:
      if (emergency) {
        showSakunaGuestGate(context);
      } else {
        showGuestRequestGate(context);
      }
    case StartRequestGate.unverifiedSheet:
      showUnverifiedRequestGate(context);
    case StartRequestGate.rejectedSheet:
      showUnverifiedRequestGate(context, resubmit: true);
    case StartRequestGate.duplicateDialog:
      showDuplicateAccountDialog(
        context,
        onGoToVerified: () {
          // TODO(Pack K): switch session
        },
      );
  }
  return false;
}

Future<void> showSakunaGuestGate(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: SoftColors.clear,
    builder: (ctx) => const _SakunaGuestSheet(),
  );
}

class _GateSheet extends StatelessWidget {
  final bool guest;
  final bool resubmit;
  const _GateSheet({required this.guest, this.resubmit = false});

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Material(
        color: SoftColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(SoftRadius.xl)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SoftColors.line,
                    borderRadius: BorderRadius.circular(SoftRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                guest ? 'Sign in to start a request' : 'Finish verification to apply',
                style: SoftType.h1,
              ),
              const SizedBox(height: 8),
              if (!guest)
                const Text('Unverified · Face check next', style: CatalogType.meta),
              const SizedBox(height: 12),
              HonestyNote(
                text: guest
                    ? ServiceCatalogMock.guestGateHonesty
                    : ServiceCatalogMock.unverifiedGateHonesty,
              ),
              const SizedBox(height: 8),
              if (guest) ...[
                CatalogCta(label: 'Sign in', onPressed: () => _signIn(context)),
                const SizedBox(height: 8),
                CatalogCta(
                  label: 'Create account',
                  primary: false,
                  onPressed: () => _create(context),
                ),
              ]               else
                CatalogCta(
                  label: resubmit ? 'Resubmit verification' : 'Continue verification',
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Keep browsing', style: CatalogType.link),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signIn(BuildContext context) async {
    final session = context.read<CitizenSessionService>();
    Navigator.of(context).pop();
    await session.endGuestSession();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _create(BuildContext context) async {
    final session = context.read<CitizenSessionService>();
    Navigator.of(context).pop();
    await session.endGuestSession();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }
}

class _SakunaGuestSheet extends StatelessWidget {
  const _SakunaGuestSheet();

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Material(
        color: SoftColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(SoftRadius.xl)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SoftColors.line,
                    borderRadius: BorderRadius.circular(SoftRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Call911Strip(
                headline: ServiceCatalogMock.guestStripHeadline,
                subtitle: ServiceCatalogMock.guestStripSub,
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Text(ServiceCatalogMock.guestReportTitle, style: SoftType.h1),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 6, 4, 8),
                child: Text(ServiceCatalogMock.guestReportBody, style: CatalogType.tileSub),
              ),
              const HonestyNote(text: ServiceCatalogMock.guestReportHonesty),
              const SizedBox(height: 8),
              CatalogCta(
                label: 'Sign in',
                onPressed: () async {
                  final session = context.read<CitizenSessionService>();
                  Navigator.of(context).pop();
                  await session.endGuestSession();
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                  }
                },
              ),
              const SizedBox(height: 8),
              CatalogCta(
                label: 'Create account',
                primary: false,
                onPressed: () async {
                  final session = context.read<CitizenSessionService>();
                  Navigator.of(context).pop();
                  await session.endGuestSession();
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Keep browsing', style: CatalogType.link),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DuplicateDialog extends StatelessWidget {
  final VoidCallback? onGoToVerified;
  const _DuplicateDialog({this.onGoToVerified});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('duplicate-account-dialog'),
      backgroundColor: SoftColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SoftRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Use your verified account',
              textAlign: TextAlign.center,
              style: CatalogType.dialogTitle,
            ),
            const SizedBox(height: 8),
            const Text(
              'One person, one verified account. Policy text to confirm.',
              textAlign: TextAlign.center,
              style: CatalogType.note,
            ),
            const SizedBox(height: 16),
            CatalogCta(
              label: 'Go to my verified account',
              onPressed: () {
                Navigator.of(context).pop();
                onGoToVerified?.call();
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not now', style: CatalogType.link),
            ),
            const Text(
              'Sample switch. No password is shared between accounts.',
              textAlign: TextAlign.center,
              style: CatalogType.meta,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

bool sessionCanStart(AccessLevel level, {bool emergency = false}) {
  if (emergency) return level.index >= AccessLevel.unverified.index;
  return level.index >= AccessLevel.verified.index;
}
