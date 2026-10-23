import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/account.dart';
import '../../../domain/models/avatar_photo.dart';
import '../../../domain/models/user_profile.dart';

/// As cores do avatar, na ordem do `UserProfile.avatarColor`.
const avatarPalette = AppColors.avatars;

/// O endereço da foto do avatar: a do Google ou a enviada, só com conta.
String? avatarPhotoUrl(UserProfile? profile, Account? account) {
  if (account == null) return null;
  return switch (profile?.photo) {
    AvatarPhoto.google => account.photoUrl,
    AvatarPhoto.upload => profile?.photoUrl,
    _ => null,
  };
}

/// O avatar do jogador: a inicial do [name] na cor [color] ou a foto, de
/// [photoUrl] ou ainda não enviada ([photoBytes]).
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({
    required this.name,
    this.color = 0,
    this.photoUrl,
    this.photoBytes,
    this.size = 56,
    super.key,
  }) : assert(avatarPalette.length == UserProfile.avatarColors);

  final String name;
  final int color;
  final String? photoUrl;
  final Uint8List? photoBytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = avatarPalette[color.clamp(0, avatarPalette.length - 1)];
    final url = photoUrl;
    final bytes = photoBytes;
    final ImageProvider? image = bytes != null
        ? MemoryImage(bytes)
        : url == null
        ? null
        : NetworkImage(url);
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? ''
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: colors.background,
        foregroundImage: image,
        // Sem rede ou foto apagada, fica a inicial.
        onForegroundImageError: image == null ? null : (_, _) {},
        child: Text(
          initial,
          style: TextStyle(
            color: colors.foreground,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
