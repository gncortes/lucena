import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/onboarding.dart';
import '../../../domain/use_cases/featured_rules.dart';
import '../../../routing/routes.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/staggered_entrance.dart';
import '../../featured/widgets/featured_card.dart';
import '../../streak/widgets/streak_lost_sheet.dart';
import '../view_models/home_cubit.dart';
import 'hero_card.dart';
import 'mode_tile.dart';
import 'player_card.dart';

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

  // O nome do app, o rating e a engrenagem ficam fixos no alto; embaixo
  // rolam o cartão azul, os finais em destaque e os atalhos (T83).
  Widget _content(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _Entrance(
              animation: _title,
              child: SizedBox(
                height: _topBar,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.lg,
                    end: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.appTitle,
                          key: HomeKeys.title,
                          maxLines: 1,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 26,
                            height: 32 / 26,
                            fontWeight: AppWeight.heavy,
                          ),
                        ),
                      ),
                      BlocBuilder<HomeCubit, HomeState>(
                        builder: (context, state) => state.ready
                            ? PlayerCard(state: state)
                            : const SizedBox.shrink(),
                      ),
                      IconButton(
                        key: HomeKeys.settingsButton,
                        icon: const Icon(
                          CanvasSymbols.settings,
                          size: AppIconSize.standard,
                        ),
                        tooltip: l10n.settingsTitle,
                        onPressed: () => context.go(Routes.settings),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  if (!state.ready) return const SizedBox.shrink();
                  return ListView(
                    padding: scrollPadding(
                      context,
                      left: AppSpacing.lg,
                      top: AppSpacing.sm,
                      right: AppSpacing.lg,
                    ),
                    children: [
                      _Entrance(
                        animation: _actions,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (state.unlockedBlind) ...[
                              const _UnlockedCard(),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                            if (state.hero != null) ...[
                              HeroCard(state: state),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                            if (state.showsFeatured &&
                                state.featured != null) ...[
                              _featured(context, state.featured!),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                            _shortcuts(context, state),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A altura da barra de cima (canvas `PropV2UxHome`).
  static const _topBar = 64.0;

  // "Finais em destaque": o título, "Ver mais" (a lista) e o destaque.
  Widget _featured(BuildContext context, FeaturedItem item) {
    final l10n = context.l10n;
    return Column(
      key: FeaturedKeys.homeSection,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        HomeSectionHeader(
          title: l10n.featuredTitle,
          titleKey: HomeKeys.featuredTitle,
          seeMoreKey: FeaturedKeys.homeSeeAll,
          onSeeMore: () => context.go(Routes.featured),
        ),
        FeaturedCard(
          key: FeaturedKeys.homeCard,
          item: item,
          compact: true,
          // Por cima da tela inicial: voltar cai nela, não na lista.
          onTap: () => context.push(Routes.featuredEndgame(item.id)),
        ),
      ],
    );
  }

  // "Atalhos": todos os caminhos marcados numa grade 2×N, todos da mesma
  // altura; "Ver mais" abre Todos os modos.
  Widget _shortcuts(BuildContext context, HomeState state) {
    final shortcuts = state.shortcuts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        HomeSectionHeader(
          title: context.l10n.homeShortcutsTitle,
          titleKey: HomeKeys.shortcutsTitle,
          seeMoreKey: HomeKeys.shortcutsSeeMore,
          onSeeMore: () => context.go(Routes.allModes),
        ),
        for (var row = 0; row < shortcuts.length; row += 2)
          Row(
            spacing: AppSpacing.md,
            children: [
              for (var column = row; column < row + 2; column++)
                Expanded(
                  child: column < shortcuts.length
                      ? StaggeredEntrance(
                          index: column,
                          child: ModeTile(shortcut: shortcuts[column]),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
      ],
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
