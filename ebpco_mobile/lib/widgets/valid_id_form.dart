import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/account_verification.dart';
import '../domain/profile_photo.dart';
import '../domain/upload_file.dart';
import '../theme/app_typography.dart';
import '../theme/soft_widget.dart';
import 'soft_action_sheet.dart';
import 'soft_chrome.dart';

/// What the Valid ID form holds. Sign-up's Valid ID step and Profile >
/// Account verification both use it; whoever creates it disposes it.
class ValidIdDraft {
  String? idType;
  final TextEditingController idNumber = TextEditingController();
  PreparedPhoto? front;
  PreparedPhoto? back;

  /// What is still missing, worded for the citizen, or null when it can be sent.
  String? get problem => validIdProblem(idType: idType, idNumber: idNumber.text, hasFront: front != null);

  void dispose() => idNumber.dispose();
}

enum _IdPhotoAction { camera, gallery, remove }

/// ID type, ID number, and a photo of each side of the ID (the back only
/// when it carries details). Photos are taken or chosen like the profile
/// photo, then made upright and stripped of their metadata before upload.
class ValidIdForm extends StatefulWidget {
  final ValidIdDraft draft;

  /// Called after every change, so the owner can rebuild and clear its error.
  final VoidCallback onChanged;
  final bool enabled;

  const ValidIdForm({super.key, required this.draft, required this.onChanged, this.enabled = true});

  @override
  State<ValidIdForm> createState() => _ValidIdFormState();
}

class _ValidIdFormState extends State<ValidIdForm> {
  bool _preparingFront = false;
  bool _preparingBack = false;
  String? _photoError;

  ValidIdDraft get _draft => widget.draft;

  void _setPhoto({required bool front, required PreparedPhoto? photo}) {
    if (front) {
      _draft.front = photo;
    } else {
      _draft.back = photo;
    }
  }

  void _setPreparing({required bool front, required bool value}) {
    if (front) {
      _preparingFront = value;
    } else {
      _preparingBack = value;
    }
  }

  Future<void> _pick({required bool front}) async {
    final current = front ? _draft.front : _draft.back;
    final action = await showSoftActionSheet<_IdPhotoAction>(
      context,
      title: front ? 'Front of the ID' : 'Back of the ID',
      subtitle: 'All four corners in the photo, no glare, and the text easy to read.',
      actions: [
        const SoftSheetAction(value: _IdPhotoAction.camera, icon: Icons.photo_camera_outlined, title: 'Take a photo'),
        const SoftSheetAction(value: _IdPhotoAction.gallery, icon: Icons.photo_library_outlined, title: 'Choose from gallery'),
        if (current != null)
          const SoftSheetAction(value: _IdPhotoAction.remove, icon: Icons.delete_outline_rounded, title: 'Remove photo', destructive: true),
      ],
    );
    if (action == null || !mounted) return;

    if (action == _IdPhotoAction.remove) {
      setState(() {
        _setPhoto(front: front, photo: null);
        _photoError = null;
      });
      widget.onChanged();
      return;
    }

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: action == _IdPhotoAction.camera ? ImageSource.camera : ImageSource.gallery,
        // Keeps decoding quick; the photo is scaled down further below.
        maxWidth: 2400,
        maxHeight: 2400,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _photoError =
            action == _IdPhotoAction.camera ? 'The camera could not be opened.' : 'Your photos could not be opened.');
      }
      return;
    }
    if (picked == null || !mounted) return;

    setState(() {
      _setPreparing(front: front, value: true);
      _photoError = null;
    });
    try {
      final prepared = await compute(prepareIdPhoto, await picked.readAsBytes());
      if (!mounted) return;
      if (prepared == null) {
        setState(() => _photoError = 'That file is not a photo that can be used. Choose a JPEG or PNG image.');
        return;
      }
      if (prepared.bytes.length > maxIdPhotoBytes) {
        setState(() => _photoError =
            'That photo is ${describeSize(prepared.bytes.length)}, and the limit is 8 MB. '
            'Take it again at a lower resolution.');
        return;
      }
      setState(() => _setPhoto(front: front, photo: prepared));
      widget.onChanged();
    } catch (_) {
      if (mounted) setState(() => _photoError = 'That photo could not be read from your phone. Please try again.');
    } finally {
      if (mounted) setState(() => _setPreparing(front: front, value: false));
    }
  }

  Widget _photo({required bool front}) {
    final photo = front ? _draft.front : _draft.back;
    final preparing = front ? _preparingFront : _preparingBack;
    if (preparing) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: SoftColors.chipWash, borderRadius: BorderRadius.circular(SoftRadius.md)),
        child: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }
    if (photo == null) {
      return SoftPillButton(
        label: front ? 'Add photo of the front' : 'Add photo of the back',
        kind: SoftPillKind.outline,
        icon: Icons.add_a_photo_outlined,
        onPressed: widget.enabled ? () => _pick(front: front) : null,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(SoftRadius.md),
          child: Image.memory(
            photo.bytes,
            height: 150,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            semanticLabel: front ? 'Photo of the front of the ID' : 'Photo of the back of the ID',
          ),
        ),
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, size: 18, color: SoftColors.verifiedInk),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Photo added', style: SoftType.cellLabel.copyWith(color: SoftColors.verifiedInk)),
            ),
            TextButton(
              onPressed: widget.enabled ? () => _pick(front: front) : null,
              child: Text('Change', style: SoftType.sectionLink.copyWith(fontSize: 14)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SoftFieldLabel('ID Type *'),
        DropdownButtonFormField<String>(
          initialValue: _draft.idType,
          hint: const Text('Select'),
          isExpanded: true,
          borderRadius: BorderRadius.circular(SoftRadius.md),
          menuMaxHeight: 360,
          items: acceptedIdTypes
              .map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: widget.enabled
              ? (v) {
                  setState(() => _draft.idType = v);
                  widget.onChanged();
                }
              : null,
        ),
        const SizedBox(height: 16),
        const SoftFieldLabel('ID Number *'),
        TextField(
          controller: _draft.idNumber,
          enabled: widget.enabled,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          maxLength: 40,
          style: SoftType.field,
          onChanged: (_) => widget.onChanged(),
          decoration: const InputDecoration(hintText: 'As printed on the ID', counterText: ''),
        ),
        const SizedBox(height: 16),
        const SoftFieldLabel('Photo of the front *'),
        _photo(front: true),
        const SizedBox(height: 16),
        const SoftFieldLabel('Photo of the back (optional)'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Add it when the back has your address or other details.', style: SoftType.cellLabel),
        ),
        _photo(front: false),
        const SizedBox(height: 10),
        Text(
          'A clear photo (JPEG or PNG, up to 8 MB): all four corners showing, no glare, '
          'and the text easy to read.',
          style: SoftType.cellLabel,
        ),
        if (_photoError != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(_photoError!, style: AppTypography.error)),
      ],
    );
  }
}
