import 'package:flutter/material.dart';

import '../domain/permit_forms.dart';
import '../screens/permits/blank_form_screen.dart';
import '../theme/soft_widget.dart';

/// On a document card that IS a form to sign on paper: the blank form, named,
/// one tap from opening it to download, print or share. A tinted row of its
/// own, with room above and below, so it reads as part of the requirement and
/// not as one more button crowded under its title.
class BlankFormLink extends StatelessWidget {
  final PermitForm form;
  const BlankFormLink({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SoftColors.primaryWash,
      borderRadius: BorderRadius.circular(SoftRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.sm),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BlankFormScreen(form: form))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 22, color: SoftColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Blank form to print and sign', style: SoftType.tileSub.copyWith(fontSize: 12.5)),
                    const SizedBox(height: 2),
                    Text(form.title, style: SoftType.tileTitle.copyWith(fontSize: 14.5, color: SoftColors.primaryDeep)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: SoftColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
