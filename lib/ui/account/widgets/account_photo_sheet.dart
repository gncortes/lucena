import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/photo/photo_repository.dart';
import '../../../domain/models/avatar_photo.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/account_avatar.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../view_models/account_photo_cubit.dart';

/// "Foto do perfil" (canvas `V1ContaFoto`, §2.12): tirar foto, escolher da
/// galeria, a do Google, ou a inicial numa das cores; e remover a foto.
/// Tirar e escolher só aparecem com conta.
Future<void> showAccountPhotoSheet(
  BuildContext context, {
  required String name,
}) {
  final cubit = context.read<AccountPhotoCubit>();
  return showLucenaSheet<void>(
    context,
    sheetKey: AccountKeys.photoSheet,
    builder: (sheet) => BlocProvider.value(
      value: cubit,
      child: _PhotoSheet(name: name),
    ),
  );
}

class _PhotoSheet extends StatelessWidget {
  const _PhotoSheet({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cubit = context.read<AccountPhotoCubit>();
    final state = context.watch<AccountPhotoCubit>().state;
    final google = cubit.googleUrl;
    void close() => Navigator.of(context).pop();
    void pick(PhotoSource source) {
      close();
      cubit.pick(source);
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountPhotoTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (cubit.canUpload) ...[
              _Option(
                key: AccountKeys.photoCamera,
                icon: Icons.photo_camera,
                text: l10n.accountPhotoCamera,
                onTap: () => pick(PhotoSource.camera),
              ),
              _Option(
                key: AccountKeys.photoGallery,
                icon: Icons.photo_library,
                text: l10n.accountPhotoGallery,
                onTap: () => pick(PhotoSource.gallery),
              ),
            ],
            if (google != null)
              _Option(
                key: AccountKeys.photoGoogle,
                icon: Icons.account_circle,
                text: l10n.accountAvatarGoogle,
                selected: state.photo == AvatarPhoto.google,
                onTap: () {
                  cubit.useGoogle();
                  close();
                },
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.accountPhotoInitial,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < avatarPalette.length; i++)
                  _Initial(
                    key: AccountKeys.avatar(i),
                    label: l10n.accountAvatarColor(i + 1),
                    selected:
                        state.photo == AvatarPhoto.none && state.color == i,
                    onTap: () {
                      cubit.useInitial(i);
                      close();
                    },
                    child: AccountAvatar(
                      name: name.isEmpty ? l10n.profileNicknameDefault : name,
                      color: i,
                      size: 42,
                    ),
                  ),
              ],
            ),
            if (state.photo != AvatarPhoto.none) ...[
              const SizedBox(height: AppSpacing.md),
              _Option(
                key: AccountKeys.photoRemove,
                icon: Icons.delete_outline,
                text: l10n.accountPhotoRemove,
                color: AppColors.errorColor,
                onTap: () {
                  cubit.remove();
                  close();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Uma linha da folha: ícone e texto, 56 de altura.
class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.text,
    required this.onTap,
    this.selected = false,
    this.color,
    super.key,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      minTileHeight: 56,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.medium),
      ),
      leading: Icon(
        icon,
        size: AppIconSize.standard,
        color: color ?? colors.primary,
      ),
      title: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      trailing: selected ? Icon(Icons.check, color: colors.primary) : null,
      selected: selected,
      onTap: onTap,
    );
  }
}

/// Uma inicial colorida: o anel azul marca a escolhida.
class _Initial extends StatelessWidget {
  const _Initial({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 3,
              color: selected ? colors.primary : AppColors.clear,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
