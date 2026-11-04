import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/account/avatar_repository.dart';
import '../../../data/repositories/photo/photo_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../domain/models/avatar_photo.dart';
import '../../../domain/models/user_profile.dart';
import '../../../routing/routes.dart';
import '../../core/keys/account_keys.dart';
import '../../core/keys/profile_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/account_avatar.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/widgets/nickname_field.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../profile/widgets/profile_rows.dart';
import '../../region/widgets/region_sheet.dart';
import '../view_models/account_cubit.dart';
import '../view_models/account_photo_cubit.dart';
import 'account_flow.dart';
import 'account_photo_sheet.dart';

/// "Seu perfil" (canvas `V1ContaPerfil`, §2.12): a foto, o nome, o país e o
/// estado e cidade. Vem depois de entrar numa conta nova e do lápis do
/// Perfil. Com [welcome] (acabou de entrar), avisa que o progresso deste
/// celular já está na conta. Salvar grava no aparelho e, com conta, sobe
/// sem esperar a rede (a foto nova sobe antes).
class AccountDataScreen extends StatelessWidget {
  const AccountDataScreen({
    required this.from,
    this.welcome = false,
    super.key,
  });

  final String from;
  final bool welcome;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => AccountCubit(
          context.read<AccountRepository>(),
          sync: context.read<SyncScheduler>(),
        ),
      ),
      BlocProvider(
        create: (context) => AccountPhotoCubit(
          accounts: context.read<AccountRepository>(),
          photos: context.read<PhotoRepository>(),
          avatars: context.read<AvatarRepository>(),
        ),
      ),
    ],
    child: _DataView(from: from, welcome: welcome),
  );
}

class _DataView extends StatefulWidget {
  const _DataView({required this.from, required this.welcome});

  final String from;
  final bool welcome;

  @override
  State<_DataView> createState() => _DataViewState();
}

class _DataViewState extends State<_DataView> {
  final _nickname = TextEditingController();
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _fill(context.read<ProfileCubit>().state);
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  // A tela recebe o perfil gravado uma vez só; depois valem as edições.
  void _fill(UserProfile? profile) {
    if (_filled || profile == null) return;
    _filled = true;
    final account = context.read<AccountRepository>().current;
    _nickname.text = profile.nickname.isEmpty
        ? account?.name ?? ''
        : profile.nickname;
    context.read<AccountPhotoCubit>().load(profile);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final account = context.read<AccountCubit>();
    final profile = context.read<ProfileCubit>();
    final photo = await context.read<AccountPhotoCubit>().save();
    if (!mounted) return;
    if (photo == null) {
      // Sem rede (gap 6): o apelido fica, com a foto que já estava; avisa e
      // fica na tela para tentar a foto de novo.
      final saved = context.read<AccountPhotoCubit>().saved;
      await profile.saveData(
        nickname: _nickname.text,
        avatarColor: saved.color,
        photo: saved.photo,
        photoUrl: saved.photoUrl,
      );
      account.publishProfile(_nickname.text);
      if (mounted) showLucenaSnackBar(context, l10n.accountPhotoFailed);
      return;
    }
    await profile.saveData(
      nickname: _nickname.text,
      avatarColor: photo.color,
      photo: photo.photo,
      photoUrl: photo.photoUrl,
    );
    account.publishProfile(_nickname.text);
    finishAccount(router, widget.from);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final profile = context.watch<ProfileCubit>().state;
    final saving = context.select(
      (AccountPhotoCubit cubit) => cubit.state.saving,
    );
    void changePhoto() =>
        showAccountPhotoSheet(context, name: _nickname.text.trim());
    final edit = !widget.welcome;
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileCubit, UserProfile?>(
          listener: (context, profile) => setState(() => _fill(profile)),
        ),
        BlocListener<AccountPhotoCubit, AccountPhotoState>(
          listenWhen: (before, now) => now.pickFailed != before.pickFailed,
          listener: (context, _) =>
              showLucenaSnackBar(context, l10n.conPerfilFailed),
        ),
      ],
      child: Scaffold(
        key: AccountKeys.dataScreen,
        appBar: LucenaAppBar(title: Text(l10n.accountProfileTitle)),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: _PhotoButton(
                nickname: _nickname,
                saving: saving,
                onTap: saving ? null : changePhoto,
              ),
            ),
            if (edit)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  l10n.conPerfilPhotoHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              Center(
                child: TextButton(
                  onPressed: saving ? null : changePhoto,
                  child: Text(l10n.accountPhotoChange),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            NicknameField(
              fieldKey: AccountKeys.nickname,
              controller: _nickname,
              label: l10n.accountNickname,
              hint: l10n.profileNicknameDefault,
              helper: l10n.accountNicknameHelp,
            ),
            const SizedBox(height: AppSpacing.lg),
            ProfileRowGroup(
              children: [
                ProfileRow(
                  key: ProfileKeys.rowCountry,
                  icon: Icons.public,
                  title: l10n.profileCountry,
                  value: profileCountryValue(
                    l10n,
                    profile?.country,
                    phone: context.read<ProfileCubit>().phoneCountry,
                  ),
                  onTap: () => context.push(Routes.country),
                ),
                if (edit)
                  ProfileRow(
                    key: ProfileKeys.rowLanguage,
                    icon: Icons.language,
                    title: l10n.settingsLanguage,
                    value: profileLanguageName(context),
                    onTap: () => context.push(Routes.settingsLanguage),
                  )
                else
                  ProfileRow(
                    key: ProfileKeys.rowRegion,
                    icon: Icons.location_on,
                    title: l10n.profileRegion,
                    value:
                        regionLabel(
                          l10n,
                          country: profile?.country,
                          state: profile?.state,
                          city: profile?.city,
                        ) ??
                        l10n.profileRegionNone,
                    onTap: () => showRegionSheet(context),
                  ),
              ],
            ),
            if (widget.welcome)
              _SavedNote(
                key: AccountKeys.savedBanner,
                text: l10n.conPerfilSaved,
              )
            else if (context.read<AccountRepository>().current != null)
              _SavedNote(
                key: AccountKeys.editSavedNote,
                text: l10n.conPerfilEditSaved,
              ),
          ],
        ),
        bottomNavigationBar: ActionsFooter(
          children: [
            FilledButton(
              key: AccountKeys.dataSave,
              onPressed: saving ? null : _save,
              child: Text(edit ? l10n.profileSave : l10n.accountSaveContinue),
            ),
          ],
        ),
      ),
    );
  }
}

/// O avatar grande com o selo da câmera; tocar abre "Foto do perfil".
class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.nickname,
    required this.saving,
    required this.onTap,
  });

  final TextEditingController nickname;
  final bool saving;
  final VoidCallback? onTap;

  static const _size = 112.0;
  static const _badge = 40.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final state = context.watch<AccountPhotoCubit>().state;
    final cubit = context.read<AccountPhotoCubit>();
    final url = switch (state.photo) {
      AvatarPhoto.google => cubit.googleUrl,
      AvatarPhoto.upload => state.photoUrl,
      AvatarPhoto.none => null,
    };
    return Semantics(
      button: true,
      label: l10n.accountPhotoChange,
      child: InkWell(
        key: AccountKeys.photo,
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: _size,
          child: Stack(
            children: [
              ValueListenableBuilder(
                valueListenable: nickname,
                builder: (context, value, _) => AccountAvatar(
                  name: value.text.trim().isEmpty
                      ? l10n.profileNicknameDefault
                      : value.text,
                  color: state.color,
                  photoUrl: url,
                  photoBytes: state.bytes,
                  size: _size,
                ),
              ),
              if (saving)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
              PositionedDirectional(
                end: 0,
                bottom: 0,
                child: Container(
                  width: _badge,
                  height: _badge,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 3),
                  ),
                  child: Icon(
                    Icons.photo_camera,
                    size: AppIconSize.button,
                    color: colors.onPrimary,
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

/// O aviso com `cloud_done`: o progresso deste celular está na conta.
class _SavedNote extends StatelessWidget {
  const _SavedNote({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.goalWinBg,
          borderRadius: BorderRadius.circular(AppShape.large),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_done,
                size: AppIconSize.standard,
                color: AppColors.record,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
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
