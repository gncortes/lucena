import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/goal_preference.dart';
import '../../../domain/models/onboarding.dart';
import '../../../domain/use_cases/featured_rules.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/cartao_pressionavel.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/motion/lista_em_ordem.dart';
import '../../core/motion/shimmer_conteudo.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/load_error.dart';
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

  // O nome do app entra primeiro; o painel entra em ordem, de cima para
  // baixo (`ListaEmOrdem`, H-ANI-17).
  late final _title = _stage(0, 0.6);

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
      // A cada carga pronta: se o tour ficou esperando (outra tela por cima),
      // ele abre quando o Início volta a ser a tela de cima.
      listenWhen: (previous, current) => current.ready && current.tourPending,
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent ?? true) {
          context.go(switch (state.stage) {
            OnboardingStage.tour => Routes.tour,
            OnboardingStage.goal => Routes.goal,
          });
        }
      },
      child: BlocListener<HomeCubit, HomeState>(
        // A oferta do Pilares por cima do Início (H-INI-14), uma vez por
        // abertura, quando o Início é a tela de cima.
        listenWhen: (previous, current) =>
            current.ready && current.offerOpen && !current.tourPending,
        listener: (context, state) {
          if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
          unawaited(context.read<HomeCubit>().offerOpened());
          unawaited(context.push(D2Paths.pilaresBeforeHome));
        },
        child: BlocListener<HomeCubit, HomeState>(
          // A sequência que acabou: o aviso sai uma vez, com o final de hoje.
          // Tour e oferta primeiro: a folha só sai quando é a vez dela (uma por
          // abertura).
          listenWhen: (previous, current) =>
              current.lostSheetTurn &&
              (previous.streak.lost == 0 ||
                  previous.tourPending ||
                  previous.offerPending),
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
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) => state.failed && !state.ready
                // O Início é a raiz: o erro não tem "Voltar".
                ? KeyedSubtree(
                    key: HomeKeys.error,
                    child: LoadErrorScreen(
                      kind: LoadErrorKind.generic,
                      onAction: () => context.read<HomeCubit>().load(
                        Localizations.localeOf(context).languageCode,
                      ),
                    ),
                  )
                : _HomeScaffold(title: _title, theme: theme),
          ),
        ),
      ),
    );
  }

  // As partes da rolagem, na ordem em que entram: o cartão, o destaque, o
  // título dos atalhos e uma linha da grade por vez.
  static List<Widget> _sections(BuildContext context, HomeState state) {
    Widget gap(Widget child, double bottom) => Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: child,
    );
    return [
      if (state.hero != null)
        gap(
          // Aprender a jogar: o cartão do objetivo (a aula da Escola, ou a Jornada
          // enquanto a Escola não está no app) entra com pop (S6 do T85).
          HeroCard(state: state, pop: state.goal == GoalPreference.learn),
          AppSpacing.xl,
        ),
      if (state.showsFeatured && state.featured != null)
        gap(_FeaturedSection(item: state.featured!), AppSpacing.xl),
      ..._shortcuts(context, state),
    ];
  }

  /// O quadro do canvas da entrada do Início (H-ANI-01: uma vez por sessão).
  static const homeEntranceId = 'PropV2Home';

  /// A altura da barra de cima (canvas `PropV2UxHome`).
  static const _topBar = 64.0;

  // "Atalhos": todos os caminhos marcados numa grade 2×N, todos da mesma
  // altura; "Ver mais" abre Todos os modos. Cada linha é uma parte da lista.
  static List<Widget> _shortcuts(BuildContext context, HomeState state) {
    final shortcuts = state.shortcuts;
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: HomeSectionHeader(
          title: context.l10n.homeShortcutsTitle,
          titleKey: HomeKeys.shortcutsTitle,
          seeMoreKey: HomeKeys.shortcutsSeeMore,
          onSeeMore: () => context.go(Routes.allModes),
        ),
      ),
      for (var row = 0; row < shortcuts.length; row += 2)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              for (var column = row; column < row + 2; column++)
                Expanded(
                  child: column < shortcuts.length
                      ? ModeTile(
                          shortcut: shortcuts[column],
                          hasPlan: state.training != null,
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
    ];
  }
}

/// O esqueleto do primeiro carregamento (canvas `PropV1InicioCarregando`): o
/// cartão de cima, os títulos das duas seções, o destaque e os quatro
/// atalhos. A rolagem fica parada.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  static Widget _section() => const Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      SkeletonBlock(width: 140, height: 20, radius: 6),
      SkeletonBlock(width: 64, height: 20, radius: 6),
    ],
  );

  static Widget _tile() =>
      const Expanded(child: SkeletonBlock(height: 144, radius: AppShape.large));

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: HomeKeys.loading,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      children: [
        const SkeletonBlock(height: 148, radius: 24),
        const SizedBox(height: AppSpacing.xl),
        _section(),
        const SizedBox(height: AppSpacing.md),
        const SkeletonBlock(height: 72, radius: AppShape.large),
        const SizedBox(height: AppSpacing.xl),
        _section(),
        const SizedBox(height: AppSpacing.md),
        Row(spacing: AppSpacing.md, children: [_tile(), _tile()]),
        const SizedBox(height: AppSpacing.md),
        Row(spacing: AppSpacing.md, children: [_tile(), _tile()]),
      ],
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

// "Finais em destaque": o título, "Ver mais" (a lista) e o destaque.
class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({required this.item});

  final FeaturedItem item;

  @override
  Widget build(BuildContext context) {
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
        // H-ANI-20: o destaque afunda no toque.
        CartaoPressionavel(
          child: FeaturedCard(
            key: FeaturedKeys.homeCard,
            item: item,
            compact: true,
            // Por cima da tela inicial: voltar cai nela, não na lista.
            onTap: () => context.push(Routes.featuredEndgame(item.id)),
          ),
        ),
      ],
    );
  }
}

// O nome do app, o rating e a engrenagem ficam fixos no alto; embaixo
// rolam o cartão azul, os finais em destaque e os atalhos (T83).
class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.title, required this.theme});

  final Animation<double> title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _Entrance(
              animation: title,
              child: SizedBox(
                height: _HomeScreenState._topBar,
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
                            : const SkeletonBlock(
                                width: 96,
                                height: 32,
                                radius: AppShape.large,
                              ),
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
                // Primeira carga: o esqueleto brilha e se dissolve no
                // conteúdo (H-ANI-07).
                builder: (context, state) => ShimmerConteudo(
                  carregando: !state.ready,
                  esqueleto: const _HomeSkeleton(),
                  child: ListView(
                    padding: scrollPadding(
                      context,
                      left: AppSpacing.lg,
                      top: AppSpacing.sm,
                      right: AppSpacing.lg,
                    ),
                    children: [
                      ListaEmOrdem(
                        itens: _HomeScreenState._sections(context, state),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold({required this.title, required this.theme});

  final Animation<double> title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return EntradaDaTela(
      id: _HomeScreenState.homeEntranceId,
      child: Scaffold(
        key: HomeKeys.screen,
        body: SafeArea(
          child: _HomeContent(title: title, theme: theme),
        ),
      ),
    );
  }
}
