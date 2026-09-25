import 'dart:convert';
import 'package:flutter/widgets.dart';
import '../models/citizen_account.dart';
import '../models/resident_profile.dart';

/// The one place that knows both "where each demo resident's portrait
/// lives" and "which account ids show it" — every avatar call site asks
/// [demoProfileImageFor] instead of re-deriving either fact itself, so
/// there's only one spot to update if an asset ever moves, and one place
/// to extend when a new seeded resident gets a photo.
const String verifiedDemoProfilePhotoAsset = 'assets/images/Perlita Profile.png';
const String pendingDemoProfilePhotoAsset = 'assets/images/Nicanor Sarmiento.png';
const String duplicateDemoProfilePhotoAsset = 'assets/images/Anacleto Dimaculangan.png';

/// Every account id that shares a resident's single portrait — the
/// Verified Perlita account and her duplicate registration are the same
/// resident (see MockCatalog.duplicateVerifiedDemoAccount's own doc comment), and
/// likewise both Anacleto Dimaculangan duplicate registrations (see
/// MockCatalog.unverifiedDuplicateAccountA/B) are the same resident.
/// Nicanor has only the one account.
const _profilePhotoAssetByAccountId = {
  'ESP-RES-2024-9002': verifiedDemoProfilePhotoAsset,
  'ESP-RES-2024-9002-DUP': verifiedDemoProfilePhotoAsset,
  'ESP-RES-2024-9001': pendingDemoProfilePhotoAsset,
  'ESP-RES-2026-9003': duplicateDemoProfilePhotoAsset,
  'ESP-RES-2026-9004': duplicateDemoProfilePhotoAsset,
};

/// Every avatar call site shows a photo at a small size (a CircleAvatar of
/// radius 40 at most, i.e. an 80-logical-px circle) — capping decode width
/// here once, centrally, means every one of those sites gets a cheap
/// resized image automatically rather than each holding the source's own
/// full-resolution decode (these seeded portraits are ~2MB/multi-megapixel
/// photos; a real uploaded photo can be just as large). Comfortably above
/// the largest current avatar usage x a high device pixel ratio, without
/// needing every call site to know or pass its own display size.
const int _avatarDecodeWidth = 240;

/// The seeded portrait to show for [account], or null for every other
/// account (which should keep showing its initials, exactly as before).
ImageProvider? demoProfileImageFor(CitizenAccount? account) {
  if (account == null) return null;
  final asset = _profilePhotoAssetByAccountId[account.id];
  if (asset == null) return null;
  return ResizeImage.resizeIfNeeded(_avatarDecodeWidth, null, AssetImage(asset));
}

/// Every avatar call site's actual entry point: a citizen's own saved
/// profile photo (set via the camera-icon flow — see
/// ResidentProfileService.updateProfilePhoto) takes priority over the
/// seeded portrait, which itself takes priority over showing initials.
/// [personal] is that account's own `ResidentProfile.personal` (pass null
/// only when no ResidentProfileService lookup applies, e.g. a guest).
ImageProvider? profileImageFor(CitizenAccount? account, Individual? personal) {
  if (account == null) return null;
  final b64 = personal?.photoBytesBase64;
  if (b64 != null && b64.isNotEmpty) {
    try {
      return ResizeImage.resizeIfNeeded(_avatarDecodeWidth, null, MemoryImage(base64Decode(b64)));
    } catch (_) {
      // Corrupt/undecodable — fall through to the seeded portrait below
      // rather than crash the avatar.
    }
  }
  return demoProfileImageFor(account);
}
