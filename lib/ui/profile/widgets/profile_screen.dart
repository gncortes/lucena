import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/ambiente.dart';

import 'package:intl/intl.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/lichess/lichess_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/level_source.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/use_cases/now.dart';
import '../../../routing/routes.dart';
import '../../alerts/view_models/alerts_cubit.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/profile_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/account_avatar.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../goal/widgets/goal_sheet.dart';
import '../../goal/widgets/goal_ui.dart';
import '../../region/widgets/region_sheet.dart';
import '../../pilares_sale/widgets/pilares_course_card.dart';
import '../view_models/current_rating_cubit.dart';
import '../view_models/profile_account_cubit.dart';
import '../view_models/profile_cubit.dart';
import 'account_delete_sheet.dart';
import 'lichess_sheet.dart';
import 'profile_rows.dart';

/// O Perfil (quadros `PropV1PerfilSemConta` e `PropV1PerfilConta`): só o
/// que é da pessoa, a mesma tela com e sem conta (muda a linha do cabeçalho,
/// o cartão de cima e as ações da conta). Um grupo com país, região, idioma,
/// objetivo, nível e Lichess; outro com as notificações.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    return ValueListenableBuilder(
      valueListenable: cubit.failure,
      builder: (context, failure, _) {
        if (failure != null) {
          return LoadErrorScreen(
            kind: LoadErrorKind.fromFailure(failure),
            onAction: cubit.load,
            onBack: () =>
                context.canPop() ? context.pop() : context.go(Routes.home),
          );
        }
        return _build(context);
      },
    );
  }

  Widget _build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => ProfileAccountCubit(
          accounts: context.read<AccountRepository>(),
          sync: context.read<SyncScheduler>(),
          lichess: context.read<LichessRepository>(),
          profile: context.read<ProfileRepository>(),
          analytics: context.analytics,
        )..load(),
      ),
      BlocProvider(
        create: (context) =>
            CurrentRatingCubit(context.read<RatingRepository>())..load(),
      ),
    ],
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
    final rating = context.read<CurrentRatingCubit>();
    await context.push(Routes.levelFrom('profile'));
    await profile.load();
    await account.load();
    await rating.load();
  }

  Future<void> _delete(BuildContext context) async {
    final uid = context.read<ProfileAccountCubit>().state.account?.uid;
    if (uid == null) return;
    await showAccountDeleteSheet(context, uid: uid, from: 'profile');
  }

  void _notice(BuildContext context, ProfileAccountState state) {
    // Com uma folha por cima (Lichess), o aviso aparece nela.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    showLucenaSnackBar(context, switch (state.notice) {
      ProfileNotice.failed => context.l10n.conPerfilFailed,
      ProfileNotice.lichessOffline || null => context.l10n.lichessRefreshFailed,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = context.watch<ProfileCubit>().state;
    final state = context.watch<ProfileAccountCubit>().state;
    final rating = context.watch<CurrentRatingCubit>().state;
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
            const PilaresCourseCard(),
            const SizedBox(height: AppSpacing.lg),
            if (account == null)
              const _LocalCard()
            else if (state.blocked)
              const _BlockedCard()
            else
              _SyncCard(syncedAt: state.syncedAt, phase: state.syncPhase),
            const SizedBox(height: AppSpacing.lg),
            ProfileRowGroup(
              children: [
                ProfileRow(
                  key: ProfileKeys.rowCountry,
                  icon: CanvasSymbols.public,
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
                  icon: CanvasSymbols.locationOn,
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
                ProfileRow(
                  key: ProfileKeys.rowLanguage,
                  icon: CanvasSymbols.language,
                  title: l10n.settingsLanguage,
                  value: profileLanguageName(context),
                  onTap: () => context.push(Routes.settingsLanguage),
                ),
                // Grava na hora: a folha tem o próprio "Salvar".
                ProfileRow(
                  key: ProfileKeys.rowGoal,
                  icon: CanvasSymbols.flag,
                  title: l10n.profileGoal,
                  value: profile?.goal?.title(l10n) ?? l10n.profileGoalNone,
                  onTap: () => _pickGoal(context, profile),
                ),
                ProfileRow(
                  key: ProfileKeys.rowLevel,
                  icon: CanvasSymbols.showChart,
                  title: l10n.profileLevel,
                  value: profile == null ? '' : _level(l10n, profile, rating),
                  onTap: () => _openLevel(context),
                ),
                ProfileRow(
                  key: ProfileKeys.rowLichess,
                  icon: CanvasSymbols.link,
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
            const SizedBox(height: AppSpacing.lg),
            const _NoticesGroup(),
            if (account != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _AccountActions(
                busy: state.busy,
                onSignOut: context.read<ProfileAccountCubit>().signOut,
                onDelete: () => _delete(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _level(
    AppLocalizations l10n,
    UserProfile profile,
    int? rating,
  ) {
    final source = profile.levelSource;
    final shown = rating ?? profile.rating;
    if (source == null) return '$shown';
    return l10n.profileLevelValue(shown, switch (source) {
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
              icon: const Icon(CanvasSymbols.edit),
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
  const _SyncCard({required this.syncedAt, required this.phase});

  final DateTime? syncedAt;
  final ProfileSyncPhase phase;

  String _when(BuildContext context) {
    final l10n = context.l10n;
    if (phase == ProfileSyncPhase.saving) return l10n.profileSyncing;
    if (phase == ProfileSyncPhase.saved) return l10n.profileSyncedNow;
    final at = syncedAt?.toLocal();
    if (at == null) return l10n.profileSyncedNever;
    final locale = Localizations.localeOf(context).toString();
    final now = context.read<Now>()().toLocal();
    final today =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return l10n.profileSyncedAt(
      today
          ? l10n.profileSyncedToday(DateFormat.Hm(locale).format(at))
          : l10n.conPerfilSyncedOn(DateFormat.Md(locale).format(at)),
    );
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
            _SyncIcon(phase: phase),
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
                  Text(
                    _when(context),
                    key: ProfileKeys.syncStatus,
                    style: muted,
                  ),
                ],
              ),
            ),
          ],
        ),
        // O aviso só aparece com a rede de fato fora.
        if (phase == ProfileSyncPhase.offline) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.profileSyncOffline, style: muted),
        ],
      ],
    );
  }
}

/// Conta suspensa pelo admin: o cartão da sincronização vira o aviso, porque
/// a nuvem recusa as gravações e o progresso fica no celular (H-R5-43).
class _BlockedCard extends StatelessWidget {
  const _BlockedCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _Card(
      key: ProfileKeys.accountBlocked,
      children: [
        Row(
          children: [
            Icon(Icons.cloud_off, color: colors.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileBlockedTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.profileBlockedText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sincronia enquanto salva; nuvem pronta quando termina, com um pop curto
/// (1 → 1,08 → 1) ao passar de "salvando" para "salvo". Sem pop com
/// "remover animações".
class _SyncIcon extends StatefulWidget {
  const _SyncIcon({required this.phase});

  final ProfileSyncPhase phase;

  @override
  State<_SyncIcon> createState() => _SyncIconState();
}

class _SyncIconState extends State<_SyncIcon>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, value: 1);
  late final _scale = TweenSequence(
    [
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
    ],
  ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.revealCurve));

  @override
  void didUpdateWidget(_SyncIcon old) {
    super.didUpdateWidget(old);
    if (old.phase == ProfileSyncPhase.saving &&
        widget.phase == ProfileSyncPhase.saved &&
        !AppMotion.reduced(context)) {
      _controller.duration = AppMotion.panel;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saving = widget.phase == ProfileSyncPhase.saving;
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        saving ? Icons.sync : Icons.cloud_done,
        key: ProfileKeys.syncIcon,
        size: AppIconSize.standard,
        color: AppColors.record,
      ),
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
      border: Border.all(color: AppColors.cardOutline),
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

/// "Notificações": quantos avisos estão ligados; abre a tela dos avisos.
class _NoticesGroup extends StatelessWidget {
  const _NoticesGroup();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AlertsCubit>().state;
    return ProfileRowGroup(
      children: [
        ProfileRow(
          key: ProfileKeys.rowNotices,
          icon: CanvasSymbols.notifications,
          title: l10n.alertsTitle,
          value: state.permitted
              ? l10n.alertsCount(state.enabled, state.total)
              : l10n.alertsBlockedSummary,
          onTap: () => context.push(Routes.alerts),
        ),
      ],
    );
  }
}

/// "Sair da conta", "Excluir a conta" (vermelho) e a nota da página web.
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
          icon: const Icon(CanvasSymbols.logout),
          label: Text(l10n.profileSignOut),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          key: ProfileKeys.delete,
          style: TextButton.styleFrom(foregroundColor: error),
          onPressed: busy ? null : onDelete,
          icon: const Icon(CanvasSymbols.delete),
          label: Text(l10n.profileDeleteAccount),
        ),
        Text(
          l10n.profileDeleteWeb(
            '${Ambiente.atual().siteHost}/pt/excluir-conta',
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
