import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/dependencies.dart';
import '../../../data/repositories/account/account_repository.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/user_profile.dart';
import '../../../routing/routes.dart';
import '../../alerts/view_models/alerts_cubit.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/account_avatar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/section_title.dart';
import '../../goal/widgets/goal_ui.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../profile/widgets/profile_rows.dart';
import 'open_link_dialog.dart';

/// As Configurações (canvas `PropV1ConfigB`): a pessoa no alto, que abre o
/// Perfil, e o que é do app em seções; a versão no fim.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.version = ''});

  /// A versão do app, no rodapé, para quem relata um problema. Vazia: não
  /// aparece.
  final String version;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      key: SettingsKeys.screen,
      appBar: LucenaAppBar(
        title: Text(l10n.settingsTitle, key: SettingsKeys.title),
      ),
      body: ListView(
        padding: scrollPadding(
          context,
          left: AppSpacing.screen,
          top: AppSpacing.sm,
          right: AppSpacing.screen,
        ),
        children: [
          const _PersonRow(),
          SectionTitle(l10n.settingsSectionApp, inset: AppSpacing.xs),
          ProfileRowGroup(
            children: [
              _Group(
                tileKey: SettingsKeys.appearanceTile,
                icon: Icons.palette_outlined,
                title: l10n.settingsAppearance,
                hint: l10n.settingsAppearanceHint,
                route: Routes.settingsAppearance,
              ),
              _Group(
                tileKey: SettingsKeys.gameTile,
                icon: Icons.sports_esports_outlined,
                title: l10n.settingsGame,
                hint: l10n.settingsGameHint,
                route: Routes.settingsGame,
              ),
              _Group(
                tileKey: SettingsKeys.soundTile,
                icon: Icons.volume_up_outlined,
                title: l10n.settingsSoundGroup,
                hint: l10n.settingsSoundGroupHint,
                route: Routes.settingsSound,
              ),
              const _AlertsGroup(),
            ],
          ),
          SectionTitle(l10n.settingsSectionHelp, inset: AppSpacing.xs),
          ProfileRowGroup(
            children: [
              _Group(
                tileKey: SettingsKeys.aboutTile,
                icon: Icons.info_outline,
                title: l10n.settingsAbout,
                hint: l10n.settingsAboutHint,
                route: Routes.settingsAbout,
              ),
              // Só em build de desenvolvimento e de teste.
              if (showsDevTools)
                ProfileRow(
                  key: SettingsKeys.maiaDebugTile,
                  icon: Icons.bug_report_outlined,
                  title: l10n.maiaDebugTitle,
                  onTap: () => context.go(Routes.settingsMaia),
                ),
              if (showsDevTools)
                ProfileRow(
                  key: SettingsKeys.openLinkTile,
                  icon: Icons.link,
                  title: l10n.devOpenLinkTitle,
                  onTap: () => showOpenLinkDialog(context),
                ),
            ],
          ),
          if (version.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Text(
                l10n.homeVersion(version),
                key: SettingsKeys.version,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A pessoa no alto: avatar, nome e "Sem conta · objetivo · rating". Abre o
/// Perfil.
class _PersonRow extends StatelessWidget {
  const _PersonRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profile = context.select((ProfileCubit cubit) => cubit.state);
    final accounts = context.read<AccountRepository>();
    return StreamBuilder<Account?>(
      stream: accounts.changes,
      initialData: accounts.current,
      builder: (context, snapshot) {
        final account = snapshot.data;
        final nickname = profile?.nickname ?? '';
        final name = nickname.isNotEmpty
            ? nickname
            : account?.name ?? l10n.profileNicknameDefault;
        return Material(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppShape.large),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: SettingsKeys.profileTile,
            onTap: () => context.go(Routes.settingsProfile),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  AccountAvatar(
                    name: name,
                    color: profile?.avatarColor ?? 0,
                    photoUrl: profile?.googlePhoto == true
                        ? account?.photoUrl
                        : null,
                    size: 48,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          key: SettingsKeys.profileName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          profile == null
                              ? ''
                              : _summary(l10n, profile, account),
                          key: SettingsKeys.profileValue,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// "Sem conta · Aprender finais · 1712" (com conta, o e-mail no lugar).
  static String _summary(
    AppLocalizations l10n,
    UserProfile profile,
    Account? account,
  ) => [
    account == null ? l10n.profileNoAccount : account.email ?? account.name,
    ?profile.goal?.title(l10n),
    '${profile.rating}',
  ].nonNulls.where((part) => part.isNotEmpty).join(' · ');
}

/// Um grupo das Configurações: abre a tela dele.
class _Group extends StatelessWidget {
  const _Group({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.hint,
    required this.route,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String hint;
  final String route;

  @override
  Widget build(BuildContext context) => ProfileRow(
    key: tileKey,
    icon: icon,
    title: title,
    value: hint,
    onTap: () => context.go(route),
  );
}

/// Avisos, com quantas chaves estão ligadas.
class _AlertsGroup extends StatelessWidget {
  const _AlertsGroup();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AlertsCubit>().state;
    return _Group(
      tileKey: SettingsKeys.alertsTile,
      icon: Icons.notifications_outlined,
      title: l10n.alertsTitle,
      hint: l10n.alertsCount(state.enabled, state.total),
      route: Routes.alerts,
    );
  }
}
