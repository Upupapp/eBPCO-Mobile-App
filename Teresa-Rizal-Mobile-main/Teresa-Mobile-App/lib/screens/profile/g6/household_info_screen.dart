import 'package:flutter/material.dart';
import '../../../theme/g6_tokens.dart';

import '../../../services/mock_catalog.dart';
import '../../../theme/soft_widget.dart';
import '../../../widgets/app_dialogs.dart';
import 'g6_chrome.dart';
import 'g6_sample.dart';

const _residences = ['Owned', 'Renting', 'With relatives'];
const _utilityNames = ['Electricity', 'Water', 'Internet', 'LPG'];

/// Household information. Saved on this device only.
class G6HouseholdInfoScreen extends StatefulWidget {
  final int people;
  const G6HouseholdInfoScreen({super.key, this.people = 5});

  @override
  State<G6HouseholdInfoScreen> createState() => _G6HouseholdInfoScreenState();
}

class _G6HouseholdInfoScreenState extends State<G6HouseholdInfoScreen> {
  String _residence = 'Owned';
  String _barangay = G6Sample.barangay;
  final _purok = TextEditingController(text: G6Sample.purok);
  final _selected = <String>{'Electricity', 'Water', 'Internet'};

  @override
  void dispose() {
    _purok.dispose();
    super.dispose();
  }

  Future<void> _pickBarangay() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: SoftColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final name in MockCatalog.barangays)
                ListTile(
                  title: Text(name, style: SoftType.name),
                  trailing: name == _barangay
                      ? const Icon(Icons.check_rounded, color: SoftColors.blue)
                      : null,
                  onTap: () => Navigator.of(context).pop(name),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) setState(() => _barangay = picked);
  }

  @override
  Widget build(BuildContext context) {
    return G6Shell(
      title: 'Household info',
      footer: G6Footer(
        child: G6Button(
          label: 'Save section',
          onPressed: () {
            AppDialogs.toast(context, 'Saved on this device.');
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          const Text('Resident profile · Sambahayan', style: SoftType.eyebrow),
          const SizedBox(height: 4),
          const Text('Household information', style: SoftType.h1),
          const SizedBox(height: 6),
          const Text(
            'Where your household lives and basic utilities. Pre-fills Tulong requests.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: G6Type.px13,
              height: 1.45,
              color: SoftColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          const _Label('Residence'),
          Row(
            children: [
              for (final name in _residences) ...[
                if (name != _residences.first) const SizedBox(width: 8),
                Expanded(
                  child: _Tile(
                    label: name,
                    icon: switch (name) {
                      'Owned' => Icons.home_outlined,
                      'Renting' => Icons.key_outlined,
                      _ => Icons.people_outline_rounded,
                    },
                    selected: _residence == name,
                    onTap: () => setState(() => _residence = name),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const _Label('Purok / street'),
          _FieldBox(child: Text(_purok.text, style: SoftType.cellValue)),
          const SizedBox(height: 12),
          const _Label('Barangay'),
          GestureDetector(
            onTap: _pickBarangay,
            child: _FieldBox(
              child: Row(
                children: [
                  Expanded(child: Text(_barangay, style: SoftType.cellValue)),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: SoftColors.muted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Bagumbayan · Calumpang · Dalig · Dulumbayan · May-Iba · Poblacion · Prinza · San Gabriel · San Roque',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: G6Type.px11,
                height: 1.4,
                color: SoftColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: G6Type.px12,
                fontWeight: FontWeight.w500,
                color: SoftColors.ink,
              ),
              children: [
                TextSpan(text: 'Utilities '),
                TextSpan(
                  text: '· select all that apply',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: SoftColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _utilityNames.length; i += 2) ...[
            Row(
              children: [
                Expanded(child: _utility(_utilityNames[i])),
                const SizedBox(width: 8),
                Expanded(
                  child: i + 1 < _utilityNames.length
                      ? _utility(_utilityNames[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: SoftColors.blueWash,
              borderRadius: BorderRadius.circular(SoftRadius.md),
              border: Border.all(color: SoftColors.line),
            ),
            child: Row(
              children: [
                const Text('Household size', style: SoftType.cellLabel),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${widget.people} people', style: SoftType.cellValue),
                    const Text(
                      'From your Family list',
                      style: SoftType.cellLabel,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const G6Honesty(
            lead: 'Local preview.',
            rest: 'Saved on this device only, no CBMS or barangay census sync.',
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _utility(String name) {
    final on = _selected.contains(name);
    return _Tile(
      label: name,
      row: true,
      selected: on,
      icon: switch (name) {
        'Electricity' => Icons.bolt_rounded,
        'Water' => Icons.water_drop_outlined,
        'Internet' => Icons.wifi_rounded,
        _ => Icons.local_fire_department_outlined,
      },
      onTap: () => setState(() {
        if (on) {
          _selected.remove(name);
        } else {
          _selected.add(name);
        }
      }),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: G6Type.px12,
          fontWeight: FontWeight.w500,
          color: SoftColors.ink,
        ),
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final Widget child;
  const _FieldBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SoftColors.line),
      ),
      child: child,
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool row;
  final VoidCallback onTap;

  const _Tile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.row = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SoftColors.blueWash : SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.md),
        onTap: onTap,
        child: Container(
          height: row ? 46 : 58,
          padding: EdgeInsets.symmetric(horizontal: row ? 12 : 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.md),
            border: Border.all(
              color: selected ? SoftColors.blue : SoftColors.line,
              width: 1.5,
            ),
            boxShadow: selected ? null : SoftShadows.cardSm,
          ),
          child: row
              ? Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: selected ? SoftColors.blue : SoftColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: G6Type.px12,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? SoftColors.blueDeep
                              : SoftColors.ink,
                        ),
                      ),
                    ),
                  ],
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: selected ? SoftColors.blue : SoftColors.muted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: G6Type.px12,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? SoftColors.blueDeep
                                : SoftColors.ink,
                          ),
                        ),
                      ],
                    ),
                    if (selected)
                      const Positioned(
                        top: 4,
                        right: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: SoftColors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: SoftColors.white,
                            ),
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
