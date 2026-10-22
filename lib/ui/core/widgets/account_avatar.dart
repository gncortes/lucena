import 'package:flutter/material.dart';

import '../../../domain/models/user_profile.dart';
import '../theme/app_colors.dart';

/// As cores do avatar, na ordem do `UserProfile.avatarColor`.
const avatarPalette = AppColors.avatars;

/// O avatar do jogador: a inicial do [name] na cor [color] ou, com
/// [photoUrl], a foto da conta do Google.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({
    required this.name,
    this.color = 0,
    this.photoUrl,
    this.size = 56,
    super.key,
  }) : assert(avatarPalette.length == UserProfile.avatarColors);

  final String name;
  final int color;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = avatarPalette[color.clamp(0, avatarPalette.length - 1)];
    final photo = photoUrl;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? ''
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: colors.background,
        foregroundImage: photo == null ? null : NetworkImage(photo),
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
