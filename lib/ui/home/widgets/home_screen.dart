import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/home_layout.dart';
import '../../../domain/models/onboarding.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/use_cases/home_suggestion.dart';
import '../../../routing/routes.dart';
import '../../free_board/widgets/saved_game_sheet.dart';
import '../../core/keys/home_keys.dart';
import '../../daily/widgets/daily_home_card.dart';
import '../../featured/widgets/featured_home_section.dart';
import '../../streak/widgets/streak_lost_sheet.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../view_models/home_cubit.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/staggered_entrance.dart';
import 'home_path_ui.dart';
import 'path_card.dart';
import 'player_card.dart';
import 'goal_card.dart';
import 'where_card.dart';
import '../../core/theme/app_motion.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.entrance,
  );

  // Entrada em sequência: o nome do app primeiro, depois o painel.
  late final _title = _stage(0, 0.6);
  late final _actions = _stage(0.3, 1);

  CurvedAnimation _stage(double begin, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: AppMotion.enter),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Quem pediu menos movimento ao sistema vê a tela pronta, sem animação.
    if (AppMotion.of(context).disabled) {
      _entrance.value = 1;
    } else if (_entrance.isDismissed) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _actions.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<HomeCubit, HomeState>(
      // Primeira abertura: o tour antes de tudo (ou a tela em que a pessoa
      // parou). Com outra tela por cima (o desafio de um link), o tour
      // espera: "Conhecer o app" volta aqui.
      listenWhen: (previous, current) =>
          current.ready && current.tourPending && !previous.tourPending,
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent ?? true) {
          context.go(switch (state.stage) {
            OnboardingStage.tour => Routes.tour,
            OnboardingStage.goal => Routes.goal,
            OnboardingStage.level => Routes.level,
          });
        }
      },
      child: BlocListener<HomeCubit, HomeState>(
        // A sequência que acabou: o aviso sai uma vez, com o final de hoje.
        listenWhen: (previous, current) =>
            current.streak.lost > 0 && previous.streak.lost == 0,
        listener: (context, state) {
          final cubit = context.read<HomeCubit>();
          var played = false;
          unawaited(
            showStreakLostSheet(
              context,
              streak: state.streak,
              onPlay: () {
                played = true;
                unawaited(context.push(Routes.daily));
              },
            ).then((_) => cubit.lostAnswered(state.streak, played: played)),
          );
          unawaited(cubit.lostShown());
        },
        child: _scaffold(context, theme),
      ),
    );
  }

  Widget _scaffold(BuildContext context, ThemeData theme) {
    return Scaffold(
      key: HomeKeys.screen,
      body: SafeArea(child: _content(context, theme)),
    );
  }

  // O nome do app e os botões ficam fixos no alto; embaixo rola o painel do
  // jogador: o rating, o "Continuar" e os caminhos.
  Widget _content(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: _Entrance(
                animation: _title,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: AppSpacing.xs,
                        ),
                        child: Text(
                          l10n.appTitle,
                          key: HomeKeys.title,
                          style: context.bigNumber?.copyWith(letterSpacing: 1),
                        ),
                      ),
                    ),
                    // Todos os modos, mesmo os fora do destaque.
                    IconButton(
                      key: HomeKeys.allModesButton,
                      icon: const Icon(Icons.apps_rounded),
                      tooltip: l10n.allModesTitle,
                      onPressed: () => context.go(Routes.allModes),
                    ),
                    IconButton(
                      key: HomeKeys.achievementsButton,
                      icon: const Icon(Icons.military_tech_outlined),
                      tooltip: l10n.homeAchievements,
                      onPressed: () => context.go(Routes.achievements),
                    ),
                    IconButton(
                      key: HomeKeys.settingsButton,
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: l10n.settingsTitle,
                      onPressed: () => context.go(Routes.settings),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: scrollPadding(context, left: 16, top: 8, right: 16),
                children: [
                  BlocBuilder<HomeCubit, HomeState>(
                    builder: (context, state) {
                      if (!state.ready) return const SizedBox.shrink();
                      return _Entrance(
                        animation: _actions,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PlayerCard(state: state),
                            if (state.unlockedBlind) ...[
                              const SizedBox(height: AppSpacing.md),
                              const _UnlockedCard(),
                            ],
                            if (state.layoutNotice) ...[
                              const SizedBox(height: AppSpacing.md),
                              _LayoutNotice(onCustomize: _customize),
                            ],
                            if (state.goalPath != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              GoalCard(state: state),
                            ],
                            if (state.resumePath != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              ResumeCard(state: state),
                            ],
                            if (state.continuePath != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              WhereCard(state: state),
                            ],
                            _shortcuts(context, theme, state),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Os caminhos em destaque, na ordem que o jogador escolheu (ou a sugerida
  // para o nível dele), cada um dizendo o que se faz nele. Os outros ficam
  // recolhidos em "Outros modos": nada fica inacessível. Depois, as
  // ferramentas.
  Widget _shortcuts(BuildContext context, ThemeData theme, HomeState state) {
    final l10n = context.l10n;
    final layout = state.layout ?? HomeSuggestion.of(RatingLevel.casual);
    final daily = state.daily == null
        ? null
        : DailyHomeCard(daily: state.daily!, streak: state.streak.current);
    // Os cartões entram um depois do outro.
    Widget card(HomePath path, int index) => StaggeredEntrance(
      index: index,
      child: PathCard(
        key: path.homeKey,
        icon: path.icon,
        title: path.title(l10n),
        body: path.body(l10n, state.level, tested: state.placementDone),
        onTap: () => context.go(path.route),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!state.showsFeatured)
          const SizedBox.shrink()
        else if (state.featured != null)
          FeaturedHomeSection(item: state.featured!, daily: daily)
        else if (daily != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: daily,
          ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.xs,
            AppSpacing.md,
            0,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homePathsTitle,
                  key: HomeKeys.pathsTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton.icon(
                key: HomeKeys.customizeButton,
                icon: const Icon(Icons.tune, size: AppIconSize.button),
                label: Text(l10n.homeCustomize),
                onPressed: _customize,
              ),
            ],
          ),
        ),
        // O caminho do objetivo já é o cartão grande.
        for (final (index, path) in state.shownPaths.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          card(path, index),
        ],
        if (layout.hidden.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Theme(
              // Sem as linhas do ExpansionTile.
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: HomeKeys.otherModes,
                tilePadding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xs,
                  end: AppSpacing.sm,
                ),
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  l10n.homeOtherModes,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                children: [
                  for (final (index, path) in layout.hidden.indexed) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.sm),
                    card(path, index),
                  ],
                ],
              ),
            ),
          ),
        _sectionTitle(theme, l10n.homeTools),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              key: HomeKeys.customPositionButton,
              icon: const Icon(Icons.edit_outlined, size: AppIconSize.button),
              label: Text(l10n.customPositionTitle),
              onPressed: () => context.go(Routes.customPosition),
            ),
            OutlinedButton.icon(
              key: HomeKeys.freeBoardButton,
              icon: const Icon(
                Icons.grid_on_outlined,
                size: AppIconSize.button,
              ),
              label: Text(l10n.freeBoardTitle),
              onPressed: () => openFreeBoard(context),
            ),
          ],
        ),
      ],
    );
  }

  // A configuração da tela inicial; ao voltar, a tela relê o layout.
  Future<void> _customize() async {
    final cubit = context.read<HomeCubit>();
    if (cubit.state.layoutNotice) unawaited(cubit.dismissLayoutNotice());
    await context.push(Routes.homeLayout);
    if (mounted) await cubit.load(Localizations.localeOf(context).languageCode);
  }

  Widget _sectionTitle(ThemeData theme, String text, {Key? key}) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        key: key,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// O modo novo destravado na Jornada (às cegas): entra crescendo, uma vez.
class _UnlockedCard extends StatelessWidget {
  const _UnlockedCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cubit = context.read<HomeCubit>();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: AppMotion.of(context).celebrate,
      curve: AppMotion.bounce,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Card(
        key: HomeKeys.unlockedCard,
        color: colors.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.record_voice_over,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.homeUnlockedBlindTitle,
                      style: context.cardTitle?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    key: HomeKeys.unlockedClose,
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    onPressed: cubit.dismissUnlocked,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                child: Text(
                  l10n.homeUnlockedBlindBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                key: HomeKeys.unlockedAction,
                icon: const Icon(Icons.grid_view_rounded),
                label: Text(l10n.homeUnlockedBlindAction),
                onPressed: () {
                  unawaited(cubit.dismissUnlocked());
                  context.go(Routes.catalog);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O aviso único para quem já usava o app: agora dá para escolher os
/// caminhos da tela inicial.
class _LayoutNotice extends StatelessWidget {
  const _LayoutNotice({required this.onCustomize});

  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      key: HomeKeys.layoutNotice,
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              color: colors.onTertiaryContainer,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                l10n.homeLayoutNotice,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onTertiaryContainer,
                ),
              ),
            ),
            TextButton(
              key: HomeKeys.layoutNoticeCustomize,
              onPressed: onCustomize,
              child: Text(l10n.homeCustomize),
            ),
            IconButton(
              key: HomeKeys.layoutNoticeClose,
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: context.read<HomeCubit>().dismissLayoutNotice,
            ),
          ],
        ),
      ),
    );
  }
}

/// Surge subindo de leve.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
