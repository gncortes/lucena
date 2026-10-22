import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/lichess/lichess_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/purchase/purchase_repository.dart';
import '../../../data/repositories/store/store_listing_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/level_source.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/use_cases/now.dart';
import '../../../routing/routes.dart';
import '../../core/keys/profile_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/account_avatar.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/widgets/section_title.dart';
import '../../goal/widgets/goal_sheet.dart';
import '../../goal/widgets/goal_ui.dart';
import '../../privacy/widgets/remove_ads_sheet.dart';
import '../../region/widgets/region_sheet.dart';
import '../view_models/profile_account_cubit.dart';
import '../view_models/profile_cubit.dart';
import 'account_delete_dialog.dart';
import 'lichess_sheet.dart';
import 'profile_rows.dart';

/// O Perfil (canvas `PropV1ConfigBPerfil`): só o que é da pessoa, a mesma
/// tela com e sem conta (muda a linha do cabeçalho e o cartão de cima), com
/// as seções Seu xadrez e Região. O idioma fica em Aparência.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ProfileAccountCubit(
      accounts: context.read<AccountRepository>(),
      sync: context.read<SyncScheduler>(),
      lichess: context.read<LichessRepository>(),
      profile: context.read<ProfileRepository>(),
    )..load(),
    child: const _ProfileView(),
  );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  Future<void> _pickGoal(BuildContext context, UserProfile? profile) async {
    final cubit = context.read<ProfileCubit>();
    final goal = await showGoalSheet(context, selected: profile?.goal);
    if (goal != null) await cubit.setGoal(goal);
  }

  // "Seu nível" grava o rating na hora; o Lichess pode ter sido conectado.
  Future<void> _openLevel(BuildContext context) async {
    final profile = context.read<ProfileCubit>();
    final account = context.read<ProfileAccountCubit>();
    await context.push(Routes.levelFrom('profile'));
    await profile.load();
    await account.load();
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<ProfileAccountCubit>();
    if (await showAccountDeleteDialog(context)) await cubit.deleteAccount();
  }

  // Com e-mail, o Firebase pediu um login recente: a pessoa entra de novo e
  // a conta é apagada em seguida.
  Future<void> _reauthAndDelete(BuildContext context, Account account) async {
    final cubit = context.read<ProfileAccountCubit>();
    final ok = await context.push<bool>(
      Routes.accountEmailFrom('profile', reauth: true),
    );
    if (ok == true) await cubit.deleteAfterSignIn(account.uid);
  }

  void _notice(BuildContext context, ProfileAccountState state) {
    final l10n = context.l10n;
    final account = state.account;
    final notice = state.notice;
    if (notice == ProfileNotice.deleteRelogin && account != null) {
      _reauthAndDelete(context, account);
      return;
    }
    showLucenaSnackBar(context, switch (notice) {
      ProfileNotice.deleteOffline => l10n.accountDeleteOffline,
      ProfileNotice.deleteRelogin => l10n.accountDeleteRelogin,
      ProfileNotice.deleteFailed => l10n.accountDeleteFailed,
      ProfileNotice.deleted => l10n.accountDeleted,
      ProfileNotice.lichessOffline || null => l10n.lichessRefreshFailed,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = context.watch<ProfileCubit>().state;
    final state = context.watch<ProfileAccountCubit>().state;
    final account = state.account;
    final lichess = state.lichess;
    final lichessUser = lichess?.user ?? profile?.lichessUser;
    return BlocListener<ProfileAccountCubit, ProfileAccountState>(
      listenWhen: (before, now) =>
          now.notice != null && before.noticeCount != now.noticeCount,
      listener: _notice,
      child: Scaffold(
        key: ProfileKeys.screen,
        appBar: LucenaAppBar(title: Text(l10n.profileTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            _Header(profile: profile, account: account),
            const SizedBox(height: AppSpacing.lg),
            if (account == null)
              const _LocalCard()
            else
              _SyncCard(syncedAt: state.syncedAt),
            SectionTitle(l10n.profileSectionChess, inset: AppSpacing.xs),
            ProfileRowGroup(
              children: [
                // Grava na hora: a folha tem o próprio "Salvar".
                ProfileRow(
                  key: ProfileKeys.rowGoal,
                  icon: Icons.flag,
                  title: l10n.profileGoal,
                  value: profile?.goal?.title(l10n) ?? l10n.profileGoalNone,
                  onTap: () => _pickGoal(context, profile),
                ),
                ProfileRow(
                  key: ProfileKeys.rowLevel,
                  icon: Icons.show_chart,
                  title: l10n.profileLevel,
                  value: profile == null ? '' : _level(l10n, profile),
                  onTap: () => _openLevel(context),
                ),
                ProfileRow(
                  key: ProfileKeys.rowLichess,
                  icon: Icons.link,
                  title: l10n.profileLichess,
                  value: lichessUser ?? l10n.profileLichessNone,
                  onTap: lichess == null
                      ? () => _openLevel(context)
                      : () => showLichessSheet(
                          context,
                          context.read<ProfileAccountCubit>(),
                        ),
                ),
              ],
            ),
            SectionTitle(l10n.profileSectionRegion, inset: AppSpacing.xs),
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
            const SizedBox(height: AppSpacing.lg),
            // O rating de finais fica no histórico, com os detalhes.
            OutlinedButton.icon(
              key: ProfileKeys.ratingCard,
              onPressed: () => context.push(Routes.rating),
              icon: const Icon(Icons.show_chart_rounded),
              label: Text(l10n.ratingHistory),
            ),
            if (account != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _AccountActions(
                busy: state.busy,
                onSignOut: context.read<ProfileAccountCubit>().signOut,
                onDelete: () => _delete(context),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SupportGroups(onDelete: () => _delete(context)),
          ],
        ),
      ),
    );
  }

  static String _level(AppLocalizations l10n, UserProfile profile) {
    final source = profile.levelSource;
    if (source == null) return '${profile.rating}';
    return l10n.profileLevelValue(profile.rating, switch (source) {
      LevelSource.test => l10n.profileLevelSourceTest,
      LevelSource.lichess => l10n.profileLevelSourceLichess,
      LevelSource.chesscom => l10n.profileLevelSourceChessCom,
      LevelSource.manual => l10n.profileLevelSourceManual,
      LevelSource.zero => l10n.profileLevelSourceZero,
    });
  }
}

/// Avatar, nome e a linha da conta; o lápis abre "Seus dados".
class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.account});

  final UserProfile? profile;
  final Account? account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final account = this.account;
    final nickname = profile?.nickname ?? '';
    final name = nickname.isNotEmpty
        ? nickname
        : account?.name ?? l10n.profileNicknameDefault;
    final email = account?.email;
    final line = account == null
        ? l10n.profileNoAccount
        : l10n.profileAccountLine(
            email ?? '',
            account.provider == AccountProvider.google
                ? l10n.profileProviderGoogle
                : l10n.profileProviderEmail,
          );
    void edit() => context.push(Routes.accountDataFrom('profile'));
    return InkWell(
      key: ProfileKeys.header,
      borderRadius: BorderRadius.circular(AppShape.large),
      onTap: edit,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            AccountAvatar(
              name: name,
              color: profile?.avatarColor ?? 0,
              photoUrl: avatarPhotoUrl(profile, account),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    key: ProfileKeys.headerName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    line,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: ProfileKeys.editData,
              tooltip: l10n.profileEditData,
              onPressed: edit,
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sem conta: "Seu progresso está só neste celular".
class _LocalCard extends StatelessWidget {
  const _LocalCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _Card(
      key: ProfileKeys.localCard,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppShape.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(Icons.cloud_sync, color: colors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileLocalOnlyTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.profileLocalOnlyText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          key: ProfileKeys.createAccount,
          onPressed: () => context.push(Routes.accountEnterFrom('profile')),
          child: Text(l10n.profileCreateOrSignIn),
        ),
      ],
    );
  }
}

/// Com conta: "Tudo guardado na conta" e a última sincronização.
class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.syncedAt});

  final DateTime? syncedAt;

  String _when(BuildContext context) {
    final l10n = context.l10n;
    final at = syncedAt?.toLocal();
    if (at == null) return l10n.profileSyncedNever;
    final locale = Localizations.localeOf(context).toString();
    final now = context.read<Now>()().toLocal();
    final today =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return today
        ? l10n.profileSyncedToday(DateFormat.Hm(locale).format(at))
        : DateFormat.Md(locale).format(at);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return _Card(
      key: ProfileKeys.syncCard,
      children: [
        Row(
          children: [
            const Icon(
              Icons.cloud_done,
              size: AppIconSize.standard,
              color: AppColors.record,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileSyncedTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(l10n.profileSyncedAt(_when(context)), style: muted),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.profileSyncOffline, style: muted),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppShape.large),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.insideCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

/// "Sair da conta", "Apagar a conta" (vermelho) e a nota da página web.
class _AccountActions extends StatelessWidget {
  const _AccountActions({
    required this.busy,
    required this.onSignOut,
    required this.onDelete,
  });

  final bool busy;
  final VoidCallback onSignOut;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: ProfileKeys.signOut,
          onPressed: busy ? null : onSignOut,
          icon: const Icon(Icons.logout),
          label: Text(l10n.profileSignOut),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          key: ProfileKeys.delete,
          style: TextButton.styleFrom(foregroundColor: error),
          onPressed: busy ? null : onDelete,
          icon: const Icon(Icons.delete),
          label: Text(l10n.profileDeleteAccount),
        ),
        Text(
          l10n.profileDeleteWeb,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Os grupos do fim (E1.25): "Remover anúncios", que some sem preço da Play
/// e vira "Sem anúncios" depois da compra; Privacidade, feedback e avaliar.
class _SupportGroups extends StatelessWidget {
  const _SupportGroups({required this.onDelete});

  /// "Apagar minha conta e meus dados" da Privacidade.
  final VoidCallback onDelete;

  Future<void> _privacy(BuildContext context) async {
    final delete = await context.push<bool>(Routes.privacy);
    if (delete == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final purchases = context.read<PurchaseRepository>();
    return StreamBuilder<PurchaseState>(
      stream: purchases.changes,
      initialData: purchases.state,
      builder: (context, snapshot) {
        final purchase = snapshot.data ?? purchases.state;
        final price = purchase.price;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (purchase.adFree || price != null) ...[
              ProfileRowGroup(
                children: [
                  ProfileRow(
                    key: ProfileKeys.rowRemoveAds,
                    icon: Icons.hide_source,
                    title: l10n.profileRemoveAds,
                    value: purchase.adFree || price == null
                        ? l10n.profileRemoveAdsDone
                        : l10n.profileRemoveAdsValue(price),
                    onTap: purchase.adFree
                        ? null
                        : () => showRemoveAdsSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            ProfileRowGroup(
              children: [
                ProfileRow(
                  key: ProfileKeys.rowPrivacy,
                  icon: Icons.privacy_tip,
                  title: l10n.profilePrivacy,
                  value: l10n.profilePrivacyValue,
                  onTap: () => _privacy(context),
                ),
                ProfileRow(
                  key: ProfileKeys.rowFeedback,
                  icon: Icons.feedback,
                  title: l10n.profileFeedback,
                  value: l10n.profileFeedbackValue,
                  onTap: () => context.push(Routes.feedback),
                ),
                ProfileRow(
                  key: ProfileKeys.rowRate,
                  icon: Icons.storefront,
                  title: l10n.profileRate,
                  value: l10n.profileRateValue,
                  onTap: context.read<StoreListingRepository>().open,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
