import 'package:flutter/material.dart';

import '../../../theme/soft_widget.dart';
import '../../../widgets/soft_chrome.dart';
import 'pack_d_chrome.dart';

/// One Pack D frame. [upload] is the in-app requirements page the sheets
/// sit on. The other values match the comp PNG basenames.
enum PackDFrame {
  upload,
  permCamera,
  permPhotos,
  permDocuments,
  permDenied,
  attachSource,
  attachUseExisting,
  applicant,
  review,
  payment,
  rejected,
  correction,
  manual,
  cancel,
  approved,
}

extension PackDFrameName on PackDFrame {
  String get fileName => switch (this) {
    PackDFrame.upload => 'upload',
    PackDFrame.permCamera => 'perm-camera',
    PackDFrame.permPhotos => 'perm-photos',
    PackDFrame.permDocuments => 'perm-documents',
    PackDFrame.permDenied => 'perm-denied',
    PackDFrame.attachSource => 'attach-source',
    PackDFrame.attachUseExisting => 'attach-use-existing',
    PackDFrame.applicant => 'req-applicant-info',
    PackDFrame.review => 'req-review-submit',
    PackDFrame.payment => 'req-payment',
    PackDFrame.rejected => 'req-detail-rejected',
    PackDFrame.correction => 'req-detail-correction',
    PackDFrame.manual => 'req-detail-manual',
    PackDFrame.cancel => 'req-cancel-confirm',
    PackDFrame.approved => 'req-detail-approved',
  };

  String get indexLabel => switch (this) {
    PackDFrame.upload => 'Upload requirements',
    PackDFrame.permCamera => 'Allow camera',
    PackDFrame.permPhotos => 'Allow photo library',
    PackDFrame.permDocuments => 'Allow documents',
    PackDFrame.permDenied => 'Camera access off',
    PackDFrame.attachSource => 'Add attachment',
    PackDFrame.attachUseExisting => 'Use existing document',
    PackDFrame.applicant => 'Applicant info · 2/4',
    PackDFrame.review => 'Review · 3/4',
    PackDFrame.payment => 'Payment · 4/4',
    PackDFrame.rejected => 'Rejected',
    PackDFrame.correction => 'Needs correction',
    PackDFrame.manual => 'Manual verification',
    PackDFrame.cancel => 'Cancel confirm',
    PackDFrame.approved => 'Released',
  };
}

const packDShotFrames = <PackDFrame>[
  PackDFrame.permCamera,
  PackDFrame.permPhotos,
  PackDFrame.permDocuments,
  PackDFrame.permDenied,
  PackDFrame.attachSource,
  PackDFrame.attachUseExisting,
  PackDFrame.applicant,
  PackDFrame.review,
  PackDFrame.payment,
  PackDFrame.rejected,
  PackDFrame.correction,
  PackDFrame.manual,
  PackDFrame.cancel,
  PackDFrame.approved,
];

/// Screens-only Pack D frame. Callbacks stay local — nothing here opens a
/// camera pipeline, a document vault, or a payment provider.
class PackDFrameScreen extends StatelessWidget {
  final PackDFrame frame;
  final VoidCallback onBack;
  final ValueChanged<PackDFrame> onGo;
  final String sex;
  final ValueChanged<String> onSex;
  final String payMethod;
  final ValueChanged<String> onPayMethod;
  final bool settingsHandoff;
  final VoidCallback onOpenSettings;
  final VoidCallback onViewReceipt;
  final VoidCallback onCancelRequest;

  const PackDFrameScreen({
    super.key,
    required this.frame,
    required this.onBack,
    required this.onGo,
    this.sex = 'Female',
    required this.onSex,
    this.payMethod = 'GCash',
    required this.onPayMethod,
    this.settingsHandoff = false,
    required this.onOpenSettings,
    required this.onViewReceipt,
    required this.onCancelRequest,
  });

  void _go(PackDFrame next) => onGo(next);

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey('pack-d-${frame.fileName}'),
      child: switch (frame) {
        PackDFrame.upload => _uploadPage(
          sheet: false,
          lede: true,
          residency: true,
        ),
        PackDFrame.permCamera => _permission(
          icon: Icons.photo_camera_outlined,
          title: 'Allow camera access?',
          body:
              'Teresa, Rizal uses the camera so you can photograph a valid ID or requirement. Photos stay on this device in the preview build.',
          lead: 'Frontend simulation.',
          rest: 'Permission UI is local chrome — no live LGU camera pipeline.',
          allow: 'Allow camera',
          allowTo: PackDFrame.attachUseExisting,
          lede: true,
          residency: true,
        ),
        PackDFrame.permPhotos => _permission(
          icon: Icons.image_outlined,
          title: 'Allow photo library access?',
          body:
              'Choose an existing photo of your ID or supporting document from your gallery. Selection is simulated for this preview.',
          lead: 'On-device only.',
          rest:
              'Gallery picks are not uploaded to a live LGU server in this frontend simulation.',
          allow: 'Allow photos',
          allowTo: PackDFrame.attachUseExisting,
          residency: true,
        ),
        PackDFrame.permDocuments => _permission(
          icon: Icons.description_outlined,
          title: 'Allow document access?',
          body:
              'Attach a PDF or file from your device for requirements that need a scanned document. File pick is simulated locally.',
          lead: 'Preview build.',
          rest:
              'Document picker chrome only — no municipal document vault in this simulation.',
          allow: 'Allow files',
          allowTo: PackDFrame.attachUseExisting,
          residency: true,
        ),
        PackDFrame.permDenied => _denied(),
        PackDFrame.attachSource => _source(),
        PackDFrame.attachUseExisting => _existing(),
        PackDFrame.applicant => _applicant(),
        PackDFrame.review => _review(),
        PackDFrame.payment => _payment(),
        PackDFrame.rejected => _rejected(),
        PackDFrame.correction => _correction(),
        PackDFrame.manual => _manual(),
        PackDFrame.cancel => _cancel(),
        PackDFrame.approved => _approved(),
      },
    );
  }

  Widget _permission({
    required IconData icon,
    required String title,
    required String body,
    required String lead,
    required String rest,
    required String allow,
    required PackDFrame allowTo,
    bool lede = false,
    bool residency = false,
  }) {
    return PackDScrim(
      backdrop: _uploadPage(lede: lede, residency: residency),
      sheet: PackDSheet(
        child: Column(
          children: [
            const PackDHandle(),
            PackDGlyph(icon: icon),
            Text(title, textAlign: TextAlign.center, style: SoftType.pageBar),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: SoftType.eyebrow),
            PackDHonesty(lead: lead, rest: rest),
            PackDActions(
              secondary: 'Not now',
              onSecondary: () => _go(
                frame == PackDFrame.permCamera
                    ? PackDFrame.permDenied
                    : PackDFrame.attachSource,
              ),
              primary: allow,
              onPrimary: () => _go(allowTo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _denied() {
    return PackDScrim(
      backdrop: _uploadPage(),
      sheet: PackDSheet(
        child: Column(
          children: [
            const PackDHandle(),
            const PackDGlyph(icon: Icons.error_outline_rounded, danger: true),
            const Text(
              'Camera access is off',
              textAlign: TextAlign.center,
              style: SoftType.pageBar,
            ),
            const SizedBox(height: 8),
            const Text(
              'You previously denied camera permission. To photograph a requirement, open system Settings and allow Camera for Teresa, Rizal.',
              textAlign: TextAlign.center,
              style: SoftType.eyebrow,
            ),
            const PackDHonesty(
              tone: PackDHonestyTone.danger,
              lead: 'Denied path.',
              rest:
                  'Open Settings hands off to the OS settings screen — still a local preview in this build.',
            ),
            PackDActions(
              secondary: 'Cancel',
              onSecondary: () => _go(PackDFrame.attachSource),
              primary: 'Open Settings',
              onPrimary: onOpenSettings,
            ),
            SoftPillButton(
              label: 'Use Gallery or File instead',
              kind: SoftPillKind.text,
              onPressed: () => _go(PackDFrame.attachSource),
            ),
            if (settingsHandoff) ...[
              const SizedBox(height: 8),
              Text(
                'Local preview — system Settings stays closed in this build.',
                textAlign: TextAlign.center,
                style: SoftType.greetingHi.copyWith(color: SoftColors.ink),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _source() {
    return PackDScrim(
      backdrop: _uploadPage(lede: true, residency: true, choosing: true),
      sheet: PackDSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PackDHandle(),
            const Text('Add attachment', style: SoftType.pageBar),
            const SizedBox(height: 4),
            const Text(
              'Valid ID · pick a source',
              style: SoftType.eyebrow,
            ),
            const SizedBox(height: 8),
            _SourceRow(
              icon: Icons.photo_camera_outlined,
              title: 'Camera',
              subtitle: 'Take a new photo',
              onTap: () => _go(PackDFrame.permCamera),
            ),
            _SourceRow(
              icon: Icons.image_outlined,
              title: 'Gallery',
              subtitle: 'Choose from photo library',
              onTap: () => _go(PackDFrame.permPhotos),
            ),
            _SourceRow(
              icon: Icons.description_outlined,
              title: 'File',
              subtitle: 'PDF or document from device',
              onTap: () => _go(PackDFrame.permDocuments),
              last: true,
            ),
            PackDActions(
              primary: 'Cancel',
              primaryKind: SoftPillKind.outline,
              onPrimary: () => _go(PackDFrame.upload),
            ),
          ],
        ),
      ),
    );
  }

  Widget _existing() {
    return PackDScrim(
      backdrop: _uploadPage(),
      sheet: PackDSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PackDHandle(),
            const Text('Use existing document?', style: SoftType.pageBar),
            const SizedBox(height: 4),
            const Text(
              'A matching file is already in your Documents master file on this device.',
              style: SoftType.eyebrow,
            ),
            const SizedBox(height: 14),
            const _DocCard(
              name: 'PhilSys ID · front',
              meta: 'Added Sep 12 · Documents · local only',
            ),
            const PackDHonesty(
              lead: 'Master-file reuse.',
              rest:
                  'Reuses a previously uploaded local document — not a live LGU vault lookup.',
            ),
            PackDActions(
              secondary: 'Take new',
              onSecondary: () => _go(PackDFrame.permCamera),
              primary: 'Use existing',
              onPrimary: () => _go(PackDFrame.applicant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadPage({
    bool sheet = true,
    bool lede = false,
    bool residency = false,
    bool choosing = false,
  }) {
    final page = PackDShell(
      title: 'Barangay clearance',
      onBack: onBack,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const PackDProgress(fraction: 0.25, label: '1 / 4'),
          const Text(
            'Hakbang 1 · Requirements',
            style: SoftType.cellLabel,
          ),
          const SizedBox(height: 4),
          const Text('Upload requirements', style: SoftType.h1),
          if (lede) ...[
            const SizedBox(height: 6),
            const Text(
              'Files stay on this device in the frontend simulation.',
              style: SoftType.body,
            ),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: sheet ? null : () => _go(PackDFrame.attachSource),
            child: PackDUploadTile(
              title: 'Valid ID',
              hint: choosing ? 'Choose a source…' : 'Tap to add photo or PDF',
              active: choosing,
            ),
          ),
          if (residency) ...[
            const SizedBox(height: 10),
            const PackDUploadTile(
              title: 'Proof of residency',
              hint: 'Optional for some requests',
            ),
          ],
          if (!sheet)
            PackDActions(
              secondary: 'Back',
              onSecondary: onBack,
              primary: 'Continue',
              onPrimary: () => _go(PackDFrame.applicant),
              pinned: false,
            ),
        ],
      ),
    );
    return page;
  }

  Widget _wizard({
    required double fraction,
    required String step,
    required String eyebrow,
    required String title,
    required String lede,
    required List<Widget> children,
    required String primary,
    required PackDFrame backTo,
    required VoidCallback onPrimary,
  }) {
    return PackDShell(
      title: 'Barangay clearance',
      onBack: onBack,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              children: [
                PackDProgress(fraction: fraction, label: step),
                Text(eyebrow, style: SoftType.cellLabel),
                const SizedBox(height: 4),
                Text(title, style: SoftType.h1),
                const SizedBox(height: 6),
                Text(lede, style: SoftType.body),
                ...children,
              ],
            ),
          ),
          PackDActions(
            pinned: true,
            secondary: 'Back',
            onSecondary: () => _go(backTo),
            primary: primary,
            onPrimary: onPrimary,
          ),
        ],
      ),
    );
  }

  Widget _applicant() {
    return _wizard(
      fraction: 0.5,
      step: '2 / 4',
      eyebrow: 'Hakbang 2 · Applicant Info',
      title: 'Confirm applicant',
      lede:
          'Pulled from your resident profile for Teresa, Rizal. Edit only if something changed.',
      backTo: PackDFrame.upload,
      primary: 'Continue',
      onPrimary: () => _go(PackDFrame.review),
      children: [
        const PackDField(label: 'Full name', value: 'Ana Marie Santos'),
        const PackDField(label: 'Birth date', value: 'March 14, 1992'),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sex',
                style: SoftType.greetingHi.copyWith(
                  color: SoftColors.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _SexChip(
                    label: 'Male',
                    selected: sex == 'Male',
                    onTap: () => onSex('Male'),
                  ),
                  const SizedBox(width: 8),
                  _SexChip(
                    label: 'Female',
                    selected: sex == 'Female',
                    onTap: () => onSex('Female'),
                  ),
                  const SizedBox(width: 8),
                  _SexChip(
                    label: 'Prefer not',
                    selected: sex == 'Prefer not',
                    onTap: () => onSex('Prefer not'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PackDField(label: 'Mobile', value: '09XX XXX 4412'),
        const PackDField(label: 'Barangay', value: 'Dalig'),
        const PackDField(label: 'Purok / street', value: 'Purok 3 · Sitio Mabuhay'),
        const PackDHonesty(
          lead: 'Local profile.',
          rest:
              'Applicant fields are frontend simulation — not a live civil registry pull.',
        ),
      ],
    );
  }

  Widget _review() {
    return _wizard(
      fraction: 0.75,
      step: '3 / 4',
      eyebrow: 'Hakbang 3 · Review & Submit',
      title: 'Review your request',
      lede: 'Check details before submitting. You can still edit a section.',
      backTo: PackDFrame.applicant,
      primary: 'Continue to payment',
      onPrimary: () => _go(PackDFrame.payment),
      children: [
        PackDCard(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            children: [
              _SummaryRow(
                icon: Icons.person_outline_rounded,
                label: 'Applicant',
                value: 'Ana Marie Santos · Dalig',
                onEdit: () => _go(PackDFrame.applicant),
                divider: false,
              ),
              _SummaryRow(
                icon: Icons.description_outlined,
                label: 'Details',
                value: 'Employment requirement · Purok 3',
                onEdit: () => _go(PackDFrame.applicant),
              ),
              _SummaryRow(
                icon: Icons.upload_outlined,
                label: 'Requirements',
                value: 'Valid ID · Proof of residency',
                onEdit: () => _go(PackDFrame.upload),
              ),
              const _SummaryRow(
                icon: Icons.credit_card_outlined,
                label: 'Fee',
                value: '₱50.00 · pay next step',
              ),
            ],
          ),
        ),
        const PackDHonesty(
          lead: 'Submit is simulated.',
          rest:
              'No live LGU ticket is created. Reference labels stay local to this preview.',
        ),
      ],
    );
  }

  Widget _payment() {
    return _wizard(
      fraction: 1,
      step: '4 / 4',
      eyebrow: 'Hakbang 4 · Payment',
      title: 'Payment method',
      lede: 'Choose how you will settle the fee. All methods are DEMO in this preview.',
      backTo: PackDFrame.review,
      primary: 'Confirm Payment',
      onPrimary: () => _go(PackDFrame.approved),
      children: [
        const PackDCard(
          child: Column(
            children: [
              _FeeRow(label: 'Barangay clearance', value: '₱50.00'),
              _FeeRow(label: 'Convenience fee', value: '₱0.00'),
              _FeeRow(label: 'Total due', value: '₱50.00', total: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PayTile(
          icon: Icons.credit_card_outlined,
          title: 'GCash',
          subtitle: 'E-wallet · simulated',
          selected: payMethod == 'GCash',
          onTap: () => onPayMethod('GCash'),
        ),
        const SizedBox(height: 10),
        _PayTile(
          icon: Icons.credit_card_outlined,
          title: 'Maya',
          subtitle: 'E-wallet · simulated',
          selected: payMethod == 'Maya',
          onTap: () => onPayMethod('Maya'),
        ),
        const SizedBox(height: 10),
        _PayTile(
          icon: Icons.account_balance_outlined,
          title: 'Cash at window',
          subtitle: 'Pay at Municipal Hall · Teresa',
          selected: payMethod == 'Cash at window',
          onTap: () => onPayMethod('Cash at window'),
        ),
        const PackDHonesty(
          tone: PackDHonestyTone.strong,
          lead: 'Not live LGU money.',
          rest:
              'Confirm Payment is a frontend simulation. No real GCash/Maya charge and no treasury receipt is issued.',
        ),
      ],
    );
  }

  Widget _detail({required List<Widget> children}) {
    return PackDShell(
      title: 'Request',
      onBack: onBack,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: children,
      ),
    );
  }

  Widget _rejected() {
    return _detail(
      children: [
        const Text('Dokyu · TR-DKY-0918', style: SoftType.cellLabel),
        const SizedBox(height: 4),
        const Text('Barangay clearance', style: SoftType.h1),
        const SizedBox(height: 10),
        const PackDStatusPill(
          label: 'Rejected',
          background: SoftColors.dangerSoft,
          foreground: SoftColors.danger,
        ),
        PackDCard(
          color: SoftColors.dangerSoft,
          borderColor: null,
          shadow: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reason',
                style: SoftType.bannerTitle.copyWith(color: SoftColors.danger),
              ),
              SizedBox(height: 6),
              Text(
                'Valid ID photo is unclear. Please reapply with a sharper front photo of your PhilSys or government ID.',
                style: SoftType.bannerTitle.copyWith(
                  color: SoftColors.ink,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const PackDCard(
          child: Column(
            children: [
              PackDMilestone(
                title: 'Submitted',
                subtitle: 'Sep 18 · 2:10 PM',
                dot: SoftColors.verifiedInk,
                ring: SoftColors.verifiedSoft,
              ),
              PackDMilestone(
                title: 'In review',
                subtitle: 'Municipal office checked requirements',
                dot: SoftColors.verifiedInk,
                ring: SoftColors.verifiedSoft,
              ),
              PackDMilestone(
                title: 'Rejected',
                subtitle: 'Sep 22 · sample reason above',
                dot: SoftColors.danger,
                ring: SoftColors.dangerSoft,
                line: false,
              ),
            ],
          ),
        ),
        const PackDHonesty(
          lead: 'Simulated rejection.',
          rest:
              'Apply Again restarts the local wizard — no live LGU officer decision.',
        ),
        PackDActions(
          primary: 'Apply Again',
          onPrimary: () => _go(PackDFrame.applicant),
        ),
        PackDActions(
          primary: 'Back to My requests',
          primaryKind: SoftPillKind.outline,
          onPrimary: onBack,
        ),
      ],
    );
  }

  Widget _correction() {
    return _detail(
      children: [
        const Text(
          'Dokyu · TR-DKY-0920 · Opened from notification',
          style: SoftType.cellLabel,
        ),
        const SizedBox(height: 4),
        const Text('Barangay clearance', style: SoftType.h1),
        const SizedBox(height: 10),
        const PackDStatusPill(
          label: 'Needs correction',
          background: SoftColors.pendingCream,
          foreground: SoftColors.pendingInk,
        ),
        PackDCard(
          color: SoftColors.pendingCream,
          borderColor: null,
          shadow: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Action needed',
                style: SoftType.bannerTitle.copyWith(color: SoftColors.pendingInk),
              ),
              const SizedBox(height: 6),
              Text(
                'One requirement was flagged. Replace the document below, then resubmit for review.',
                style: SoftType.bannerTitle.copyWith(
                  color: SoftColors.ink,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        PackDCard(
          borderColor: SoftColors.danger.withValues(alpha: 0.35),
          borderWidth: 1.5,
          shadow: [
            BoxShadow(
              color: SoftColors.danger.withValues(alpha: 0.08),
              spreadRadius: 3,
            ),
            ...SoftShadows.cardSm,
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Valid ID',
                      style: SoftType.bannerTitle.copyWith(color: SoftColors.ink),
                    ),
                  ),
                  Container(
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: SoftColors.dangerSoft,
                      borderRadius: BorderRadius.circular(SoftRadius.pill),
                    ),
                    child: Text(
                      'Flagged',
                      style: SoftType.nav.copyWith(
                        color: SoftColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Blurry · edges cut off. Upload a clearer front photo.',
                style: SoftType.greetingHi.copyWith(height: 1.4),
              ),
              const SizedBox(height: 12),
              const _DocCard(
                name: 'philsys-front.jpg',
                meta: 'Needs replace · local file',
                danger: true,
                filled: true,
              ),
              PackDActions(
                primary: 'Replace document',
                primaryKind: SoftPillKind.outline,
                onPrimary: () => _go(PackDFrame.attachSource),
              ),
            ],
          ),
        ),
        PackDCard(
          color: SoftColors.blueSoft,
          borderColor: null,
          shadow: null,
          child: Text(
            'Proof of residency was accepted — no action needed.',
            style: SoftType.greetingHi.copyWith(height: 1.4),
          ),
        ),
        const PackDHonesty(
          lead: 'Correction path.',
          rest:
              'Flagged replace + Resubmit are local preview actions — not a live officer queue.',
        ),
        PackDActions(
          primary: 'Resubmit',
          onPrimary: () => _go(PackDFrame.manual),
        ),
      ],
    );
  }

  Widget _manual() {
    return _detail(
      children: [
        const Text('Dokyu · TR-DKY-0924', style: SoftType.cellLabel),
        const SizedBox(height: 4),
        const Text('Barangay clearance', style: SoftType.h1),
        const SizedBox(height: 10),
        const PackDStatusPill(
          label: 'Manual verification',
          background: SoftColors.pendingCream,
          foreground: SoftColors.pendingInk,
        ),
        PackDCard(
          color: SoftColors.pendingCream,
          borderColor: null,
          shadow: null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SoftColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: SoftShadows.cardSm,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: SoftColors.pendingInk,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Under manual review',
                      style: SoftType.cellValue.copyWith(color: SoftColors.pendingInk),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A municipal officer is verifying your requirements offline. There is nothing you need to do right now.',
                      style: SoftType.bannerTitle.copyWith(
                        color: SoftColors.ink,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PackDCard(
          child: Column(
            children: [
              PackDMilestone(
                title: 'Submitted',
                subtitle: 'Sep 20 · 10:14 AM',
                dot: SoftColors.verifiedInk,
                ring: SoftColors.verifiedSoft,
              ),
              PackDMilestone(
                title: 'Manual verification',
                subtitle: 'Officer review in progress · no citizen action',
                dot: SoftColors.gold,
                ring: SoftColors.pendingCream,
              ),
              PackDMilestone(
                title: 'For release',
                subtitle: 'Pending',
                dot: SoftColors.bannerDash,
              ),
              PackDMilestone(
                title: 'Released',
                subtitle: 'Pending',
                dot: SoftColors.bannerDash,
                line: false,
              ),
            ],
          ),
        ),
        const PackDHonesty(
          lead: 'No citizen action.',
          rest:
              'Wait state only — no Replace / Resubmit CTA. Officer review is simulated for preview.',
        ),
        PackDActions(
          primary: 'Back to My requests',
          primaryKind: SoftPillKind.outline,
          onPrimary: onBack,
        ),
      ],
    );
  }

  Widget _cancel() {
    return PackDScrim(
      backdrop: _detail(
        children: const [
          Text('Dokyu · TR-DKY-0924', style: SoftType.cellLabel),
          SizedBox(height: 4),
          Text('Barangay clearance', style: SoftType.h1),
          SizedBox(height: 10),
          PackDStatusPill(
            label: 'In review',
            background: SoftColors.pendingCream,
            foreground: SoftColors.pendingInk,
          ),
          PackDCard(
            child: SizedBox(height: 120),
          ),
        ],
      ),
      sheet: PackDSheet(
        child: Column(
          children: [
            const PackDHandle(),
            const PackDGlyph(icon: Icons.close_rounded, danger: true),
            const Text(
              'Cancel this request?',
              textAlign: TextAlign.center,
              style: SoftType.pageBar,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cancelling stops tracking for TR-DKY-0924. In this preview, the request is removed from local Active list only — no live LGU ticket is voided.',
              textAlign: TextAlign.center,
              style: SoftType.eyebrow,
            ),
            const PackDHonesty(
              tone: PackDHonestyTone.danger,
              lead: 'High-stakes confirm.',
              rest:
                  'Fees already simulated as paid are not refunded in this frontend demo.',
            ),
            PackDActions(
              secondary: 'Keep request',
              onSecondary: () => _go(PackDFrame.manual),
              primary: 'Cancel request',
              danger: true,
              onPrimary: onCancelRequest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _approved() {
    return _detail(
      children: [
        const Text('Dokyu · TR-DKY-0910', style: SoftType.cellLabel),
        const SizedBox(height: 4),
        const Text('Barangay clearance', style: SoftType.h1),
        const SizedBox(height: 10),
        const PackDStatusPill(
          label: 'Released',
          background: SoftColors.verifiedSoft,
          foreground: SoftColors.verifiedInk,
        ),
        PackDCard(
          color: SoftColors.verifiedSoft,
          borderColor: null,
          shadow: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready for release',
                style: SoftType.bannerTitle.copyWith(color: SoftColors.verifiedInk),
              ),
              const SizedBox(height: 6),
              Text(
                'Claim at the Barangay Desk · Municipal Hall, Poblacion, Teresa, Rizal. Bring a valid ID. Office hours sample only.',
                style: SoftType.bannerTitle.copyWith(
                  color: SoftColors.ink,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const PackDCard(
          child: Column(
            children: [
              PackDMilestone(
                title: 'Submitted',
                subtitle: 'Sep 10 · 9:02 AM',
                dot: SoftColors.verifiedInk,
                ring: SoftColors.verifiedSoft,
              ),
              PackDMilestone(
                title: 'In review',
                subtitle: 'Completed',
                dot: SoftColors.verifiedInk,
                ring: SoftColors.verifiedSoft,
              ),
              PackDMilestone(
                title: 'For release',
                subtitle: 'Sep 14',
                dot: SoftColors.verifiedInk,
                ring: SoftColors.verifiedSoft,
              ),
              PackDMilestone(
                title: 'Released',
                subtitle: 'Claim at window · sample',
                dot: SoftColors.verifiedInk,
                ring: SoftColors.verifiedSoft,
                line: false,
              ),
            ],
          ),
        ),
        const PackDCard(
          child: Column(
            children: [
              _FeeRow(label: 'Local reference', value: 'DEMO-PAY-0012'),
              _FeeRow(label: 'Paid in demo', value: '₱50.00 · Cash DEMO'),
            ],
          ),
        ),
        const PackDHonesty(
          lead: 'Preview release.',
          rest:
              'Payment record and claim instructions are simulated — not a live treasury release.',
        ),
        PackDActions(
          primary: 'View payment record',
          // TODO(PR-L): route to payment detail
          onPrimary: onViewReceipt,
        ),
        PackDActions(
          primary: 'Back to My requests',
          primaryKind: SoftPillKind.outline,
          onPrimary: onBack,
        ),
      ],
    );
  }
}

class _SourceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool last;

  const _SourceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: SoftColors.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SoftColors.blueSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: SoftColors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: SoftType.cellValue),
                  const SizedBox(height: 2),
                  Text(subtitle, style: SoftType.greetingHi),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: SoftColors.muted),
          ],
        ),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final String name;
  final String meta;
  final bool danger;
  final bool filled;

  const _DocCard({
    required this.name,
    required this.meta,
    this.danger = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: filled ? SoftColors.white : SoftColors.blueWash,
        borderRadius: BorderRadius.circular(SoftRadius.md),
        border: Border.all(color: SoftColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: danger ? SoftColors.dangerSoft : SoftColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: SoftShadows.cardSm,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 20,
              color: danger ? SoftColors.danger : SoftColors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: SoftType.bannerTitle.copyWith(color: SoftColors.ink),
                ),
                const SizedBox(height: 2),
                Text(meta, style: SoftType.cellLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SexChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SexChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SoftColors.blue : SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            border: Border.all(color: selected ? SoftColors.blue : SoftColors.line),
          ),
          child: Text(
            label,
            style: SoftType.sectionLink.copyWith(
              color: selected ? SoftColors.white : SoftColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;
  final bool divider;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: divider
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: SoftColors.line)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SoftColors.blueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: SoftColors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SoftType.cellLabel),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: SoftType.bannerTitle.copyWith(color: SoftColors.ink),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: SoftColors.blue,
                padding: const EdgeInsets.only(left: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Edit', style: SoftType.sectionLink),
            ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool total;

  const _FeeRow({required this.label, required this.value, this.total = false});

  @override
  Widget build(BuildContext context) {
    final labelStyle = total
        ? SoftType.eyebrow.copyWith(color: SoftColors.ink, fontWeight: FontWeight.w500)
        : SoftType.eyebrow;
    final valueStyle = total
        ? SoftType.section.copyWith(color: SoftColors.blue, fontWeight: FontWeight.w600)
        : SoftType.bannerTitle.copyWith(color: SoftColors.ink);
    return Container(
      padding: EdgeInsets.only(top: total ? 12 : 6, bottom: 6),
      decoration: total
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: SoftColors.line)),
            )
          : null,
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PayTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fill = selected ? SoftColors.blueWash : SoftColors.white;
    return Material(
      color: fill,
      elevation: 0,
      shadowColor: SoftColors.clear,
      surfaceTintColor: SoftColors.clear,
      borderRadius: BorderRadius.circular(SoftRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SoftRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(SoftRadius.md),
            border: Border.all(
              color: selected ? SoftColors.blue : SoftColors.line,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: SoftShadows.cardSm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SoftColors.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: SoftColors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SoftType.cellValue),
                    const SizedBox(height: 2),
                    Text(subtitle, style: SoftType.cellLabel),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SoftColors.pendingCream,
                  borderRadius: BorderRadius.circular(SoftRadius.pill),
                ),
                child: Text(
                  'DEMO',
                  style: SoftType.nav.copyWith(
                    color: SoftColors.pendingInk,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Local receipt page reached from Released. Still a preview — no treasury file.
class PackDReceiptPreview extends StatelessWidget {
  final VoidCallback onBack;

  const PackDReceiptPreview({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return PackDShell(
      title: 'Payment record (demo)',
      onBack: onBack,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: const [
          Text('Dokyu · TR-DKY-0910', style: SoftType.cellLabel),
          SizedBox(height: 4),
          Text('Barangay clearance', style: SoftType.h1),
          PackDCard(
            child: Column(
              children: [
                _FeeRow(label: 'Local reference', value: 'DEMO-PAY-0012'),
                _FeeRow(label: 'Paid in demo', value: '₱50.00 · Cash DEMO'),
                _FeeRow(label: 'Method', value: 'Cash at window · DEMO'),
              ],
            ),
          ),
          PackDHonesty(
            lead: 'Preview release.',
            rest:
                'Not an official receipt. This is a demo record saved on this device. No treasury receipt is issued.',
          ),
        ],
      ),
    );
  }
}
