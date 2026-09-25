import 'package:flutter/material.dart';
import '../../../theme/g6_tokens.dart';
import 'package:provider/provider.dart';

import '../../../models/access_level.dart';
import '../../../services/citizen_session_service.dart';
import '../../../theme/soft_widget.dart';
import 'g6_chrome.dart';
import 'g6_sample.dart';
import 'household_info_screen.dart';
import 'member_screens.dart';

/// Family & household. Sample Reyes household for a verified account.
/// Unverified and guest see the empty household (head only).
class G6HouseholdScreen extends StatefulWidget {
  /// Null follows the signed-in account. Tests and shots pass this directly.
  final bool? populated;

  const G6HouseholdScreen({super.key, this.populated});

  @override
  State<G6HouseholdScreen> createState() => _G6HouseholdScreenState();
}

class _G6HouseholdScreenState extends State<G6HouseholdScreen> {
  late List<G6Member> _members;

  @override
  void initState() {
    super.initState();
    _members = _wantsMembers(context) ? G6Sample.freshMembers() : <G6Member>[];
  }

  bool _wantsMembers(BuildContext context) {
    if (widget.populated != null) return widget.populated!;
    try {
      final session = Provider.of<CitizenSessionService>(
        context,
        listen: false,
      );
      return session.accessLevel == AccessLevel.verified;
    } catch (_) {
      return true;
    }
  }

  int get _count => 1 + _members.length;

  Future<void> _add() async {
    final created = await Navigator.of(context).push<G6Member>(
      MaterialPageRoute(builder: (_) => const G6AddMemberScreen()),
    );
    if (created != null && mounted) setState(() => _members.add(created));
  }

  Future<void> _open(G6Member member) async {
    final removed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => G6MemberDetailScreen(member: member)),
    );
    if (removed == true && mounted) {
      setState(() => _members.removeWhere((m) => m.id == member.id));
    }
  }

  void _info() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => G6HouseholdInfoScreen(people: _count)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final empty = _members.isEmpty;
    return G6Shell(
      title: 'Family & household',
      footer: empty
          ? null
          : G6Footer(
              child: G6Button(
                buttonKey: const ValueKey('g6-add-member-cta'),
                label: 'Add member',
                icon: Icons.add_rounded,
                onPressed: _add,
              ),
            ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 4, 16, empty ? 28 : 110),
        children: [
          const Text(
            'Resident profile · Pamilya at sambahayan',
            style: SoftType.eyebrow,
          ),
          const SizedBox(height: 8),
          _HouseholdCard(members: _count),
          if (empty) ...[
            const SizedBox(height: 26),
            const _EmptyMembers(),
            const SizedBox(height: 18),
            G6Button(
              buttonKey: const ValueKey('g6-add-member-cta'),
              label: 'Add member',
              icon: Icons.add_rounded,
              onPressed: _add,
            ),
            const SizedBox(height: 8),
            G6Button(
              label: 'Household information',
              kind: G6ButtonKind.outline,
              icon: Icons.home_outlined,
              onPressed: _info,
            ),
            const G6Honesty(
              lead: 'Stays on this device.',
              rest:
                  'Members you add are frontend simulation only. Nothing is sent to the civil registry or CBMS.',
            ),
          ] else ...[
            const SizedBox(height: 10),
            _InfoLink(onTap: _info),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Members · ${_members.length}',
                  style: SoftType.cellValue.copyWith(fontSize: G6Type.px14),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _add,
                  child: const Text('+ Add', style: SoftType.sectionLink),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: SoftColors.white,
                borderRadius: BorderRadius.circular(SoftRadius.lg),
                border: Border.all(color: SoftColors.lineSoft),
                boxShadow: SoftShadows.cardSm,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _members.length; i++)
                    _MemberRow(
                      member: _members[i],
                      divider: i > 0,
                      onTap: () => _open(_members[i]),
                    ),
                ],
              ),
            ),
            const G6Honesty(
              lead: 'Sample household.',
              rest:
                  'Frontend simulation, not linked to the civil registry or CBMS.',
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _HouseholdCard extends StatelessWidget {
  final int members;
  const _HouseholdCard({required this.members});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        gradient: SoftColors.featureGradient,
        boxShadow: SoftShadows.feature,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Household · Sambahayan',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: G6Type.px11,
                  color: G6Palette.white82,
                ),
              ),
              const Spacer(),
              Container(
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: G6Palette.white18,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Sample',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: G6Type.px10,
                    fontWeight: FontWeight.w500,
                    color: SoftColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            G6Sample.householdName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: G6Type.px17,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.4,
              color: SoftColors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('Barangay', G6Sample.barangay),
              _stat('Members', '$members'),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: G6Palette.white18),
          const SizedBox(height: 12),
          const Row(
            children: [
              G6Initials(initials: G6Sample.headInitials, onBlue: true),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      G6Sample.headName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: G6Type.px14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                        color: SoftColors.white,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Head of household · you',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: G6Type.px11,
                        color: G6Palette.white80,
                      ),
                    ),
                  ],
                ),
              ),
              G6VerifyChip(verify: G6Verify.verified, onBlue: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: G6Type.px10,
              color: G6Palette.white78,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: G6Type.px13,
              fontWeight: FontWeight.w500,
              color: SoftColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLink extends StatelessWidget {
  final VoidCallback onTap;
  const _InfoLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.lg),
            border: Border.all(color: SoftColors.lineSoft),
            boxShadow: SoftShadows.cardSm,
          ),
          child: const Row(
            children: [
              _MiniIcon(icon: Icons.home_outlined),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Household information', style: SoftType.name),
                    SizedBox(height: 2),
                    Text(
                      'Residence · utilities · complete',
                      style: SoftType.cellLabel,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: SoftColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  const _MiniIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SoftColors.blueSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 16, color: SoftColors.blue),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final G6Member member;
  final bool divider;
  final VoidCallback onTap;
  const _MemberRow({
    required this.member,
    required this.divider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: divider
              ? const Border(top: BorderSide(color: SoftColors.line))
              : null,
        ),
        child: Row(
          children: [
            G6Initials(initials: member.initials, tone: member.tone),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: SoftType.name),
                  const SizedBox(height: 2),
                  Text(
                    '${member.relationship} · ${member.age} yrs',
                    style: SoftType.cellLabel.copyWith(fontSize: G6Type.px12),
                  ),
                ],
              ),
            ),
            G6VerifyChip(verify: member.verify),
            const Icon(
              Icons.chevron_right_rounded,
              color: SoftColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: SoftColors.blueSoft,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Icon(
              Icons.people_outline_rounded,
              color: SoftColors.blue,
              size: 30,
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'No family members yet',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: G6Type.px18,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.4,
            color: SoftColors.ink,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Add the people who live with you in Dalig: spouse, children, parents. Members pre-fill requests you file for them.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: G6Type.px13,
            height: 1.45,
            color: SoftColors.muted,
          ),
        ),
      ],
    );
  }
}
