import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../domain/models/user_profile.dart';
import '../../../routing/routes.dart';
import '../../core/keys/account_keys.dart';
import '../../core/keys/profile_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/account_avatar.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/nickname_field.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../profile/widgets/profile_rows.dart';
import '../view_models/account_cubit.dart';

/// "Seus dados" (canvas `PropV1PerfilDados`): avatar, nome, país e idioma.
/// Vem depois de criar a conta e do lápis do Perfil. Salvar grava no
/// aparelho e, com conta, sobe sem esperar a rede.
class AccountDataScreen extends StatelessWidget {
  const AccountDataScreen({required this.from, super.key});

  final String from;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AccountCubit(
      context.read<AccountRepository>(),
      sync: context.read<SyncScheduler>(),
    ),
    child: _DataView(from: from),
  );
}

class _DataView extends StatefulWidget {
  const _DataView({required this.from});

  final String from;

  @override
  State<_DataView> createState() => _DataViewState();
}

class _DataViewState extends State<_DataView> {
  final _nickname = TextEditingController();
  int _color = 0;
  bool _photo = false;
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
    _color = profile.avatarColor;
    _photo = profile.googlePhoto && account?.photoUrl != null;
  }

  Future<void> _save() async {
    final router = GoRouter.of(context);
    final account = context.read<AccountCubit>();
    await context.read<ProfileCubit>().saveData(
      nickname: _nickname.text,
      avatarColor: _color,
      googlePhoto: _photo,
    );
    account.publishProfile(_nickname.text);
    router.go(Routes.afterAccount(widget.from));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final photoUrl = context.read<AccountRepository>().current?.photoUrl;
    final country = context.select(
      (ProfileCubit cubit) => cubit.state?.country,
    );
    return BlocListener<ProfileCubit, UserProfile?>(
      listener: (context, profile) => setState(() => _fill(profile)),
      child: Scaffold(
        key: AccountKeys.dataScreen,
        appBar: LucenaAppBar(title: Text(l10n.accountDataTitle)),
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          children: [
            Text(l10n.accountAvatar, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ValueListenableBuilder(
              valueListenable: _nickname,
              builder: (context, value, _) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < avatarPalette.length; i++)
                    _AvatarChoice(
                      key: AccountKeys.avatar(i),
                      label: l10n.accountAvatarColor(i + 1),
                      selected: !_photo && _color == i,
                      onTap: () => setState(() {
                        _color = i;
                        _photo = false;
                      }),
                      child: AccountAvatar(
                        name: value.text.isEmpty
                            ? l10n.profileNicknameDefault
                            : value.text,
                        color: i,
                        size: 42,
                      ),
                    ),
                  if (photoUrl != null)
                    _AvatarChoice(
                      key: AccountKeys.avatarGoogle,
                      label: l10n.accountAvatarGoogle,
                      selected: _photo,
                      onTap: () => setState(() => _photo = true),
                      child: AccountAvatar(
                        name: value.text,
                        photoUrl: photoUrl,
                        size: 42,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.accountAvatarNote, style: muted),
            const SizedBox(height: AppSpacing.lg),
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
                  value: country == null
                      ? l10n.profileCountryNone
                      : l10n.accountCountryFromPhone(
                          profileCountryName(l10n, country),
                        ),
                ),
                ProfileRow(
                  key: ProfileKeys.rowLanguage,
                  icon: Icons.language,
                  title: l10n.profileLanguage,
                  value: profileLanguageName(context),
                  onTap: () => context.push(Routes.settingsLanguage),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.accountDataNote, style: muted),
          ],
        ),
        bottomNavigationBar: ActionsFooter(
          children: [
            FilledButton(
              key: AccountKeys.dataSave,
              onPressed: _save,
              child: Text(l10n.accountSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma opção de avatar: o anel azul marca a escolhida.
class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
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
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: AppShape.hairline + 1,
              color: selected ? colors.primary : Colors.transparent,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
