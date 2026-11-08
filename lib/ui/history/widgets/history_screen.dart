import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/widgets/load_error.dart';

import '../../../domain/models/history_filter.dart';
import '../../core/keys/history_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/container_navigation.dart';
import '../view_models/history_cubit.dart';
import 'history_games_tab.dart';
import 'rating_card.dart';
import 'history_speedruns_tab.dart';
import '../../core/motion/shimmer_conteudo.dart';

/// O Histórico: Partidas, Clássico e Maratona. A aba escolhida fica gravada
/// (toque ou arraste).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({this.gameDestinationBuilder, super.key});

  /// O destino dos detalhes de uma partida (o da rota canônica).
  final Widget Function(BuildContext, int)? gameDestinationBuilder;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: HistoryTab.values.length,
    vsync: this,
  )..addListener(_changed);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Toque ou arraste: grava a aba nova.
  void _changed() {
    final cubit = context.read<HistoryCubit>();
    if (!cubit.state.loaded) return;
    final tab = HistoryTab.values[_controller.index];
    if (tab != cubit.state.tab) cubit.selectTab(tab);
    setState(() {});
  }

  // A primeira leitura traz a aba gravada.
  void _restore(HistoryState state) {
    if (_controller.index != state.tab.index) {
      _controller.index = state.tab.index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<HistoryCubit>().state;
    if (state.failed) {
      return LoadErrorScreen(
        kind: LoadErrorKind.generic,
        onAction: () async {
          final cubit = context.read<HistoryCubit>();
          await cubit.load();
          if (mounted) _restore(cubit.state);
        },
        onBack: () => context.canPop()
            ? context.pop()
            : context.go(Routes.settingsProfile),
      );
    }
    return BlocListener<HistoryCubit, HistoryState>(
      listenWhen: (before, after) =>
          (!before.loaded && after.loaded) || before.tab != after.tab,
      listener: (context, state) => _restore(state),
      child: Scaffold(
        key: HistoryKeys.screen,
        appBar: LucenaAppBar(
          leading: ContainerNavigation.canClose(context)
              ? BackButton(onPressed: () => ContainerNavigation.close(context))
              : null,
          title: Text(l10n.historyTitle),
          actions: [if (_hasFilter(state)) _filterIcon(context, state)],
        ),
        body: ShimmerConteudo(
          carregando: !state.loaded,
          esqueleto: const HistoryLoading(),
          child: !state.loaded
              ? const SizedBox.shrink()
              : NestedScrollView(
                  // O rating sai ao rolar; o título e as abas ficam presos.
                  headerSliverBuilder: (context, _) => [
                    if (state.history.isNotEmpty)
                      SliverToBoxAdapter(
                        child: HistoryRatingCard(state: state),
                      ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabsHeader(
                        background: Theme.of(context).scaffoldBackgroundColor,
                        child: _HistoryTabs(controller: _controller),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _controller,
                    children: [
                      HistoryGamesTab(
                        gameDestinationBuilder: widget.gameDestinationBuilder,
                      ),
                      const HistorySpeedrunsTab(marathon: false),
                      const HistorySpeedrunsTab(marathon: true),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // Só há o que filtrar na aba que já tem partidas ou speedruns.
  bool _hasFilter(HistoryState state) {
    if (!state.loaded) return false;
    return switch (_controller.index) {
      0 => state.history.isNotEmpty,
      1 => state.classic.isNotEmpty,
      _ => state.marathons.isNotEmpty,
    };
  }

  // O filtro da aba aberta; o ponto avisa que há um filtro valendo.
  Widget _filterIcon(BuildContext context, HistoryState state) {
    final active = switch (_controller.index) {
      0 => !state.gamesFilter.isEmpty,
      1 => !state.classicFilter.isEmpty,
      _ => !state.marathonFilter.isEmpty,
    };
    return IconButton(
      key: HistoryKeys.filterIcon,
      tooltip: context.l10n.historyFiltersAll,
      onPressed: () => switch (_controller.index) {
        0 => const HistoryGamesTab().openFilter(context),
        1 => const HistorySpeedrunsTab(marathon: false).openFilter(context),
        _ => const HistorySpeedrunsTab(marathon: true).openFilter(context),
      },
      icon: Badge(
        isLabelVisible: active,
        smallSize: 8,
        child: const Icon(Icons.tune),
      ),
    );
  }
}

// O cabeçalho fixo das abas: 48 de toque e 1 do traço de baixo.
class _TabsHeader extends SliverPersistentHeaderDelegate {
  const _TabsHeader({required this.child, required this.background});

  final Widget child;
  final Color background;

  static const _height = 49.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: background,
    child: SizedBox.expand(child: child),
  );

  @override
  bool shouldRebuild(_TabsHeader old) =>
      old.child != child || old.background != background;
}

/// As três abas iguais, com o ícone na linha do texto (cheio na escolhida) e
/// o indicador de 3 dp, com 20% de recuo de cada lado.
class _HistoryTabs extends StatelessWidget {
  const _HistoryTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tabs = [
      (
        Icons.sports_esports,
        Icons.sports_esports_outlined,
        l10n.historyTabGames,
      ),
      (Icons.timer, Icons.timer_outlined, l10n.historyTabClassic),
      (Icons.all_inclusive, Icons.all_inclusive, l10n.historyTabMarathon),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              for (final (index, (filled, outlined, label)) in tabs.indexed)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final selected = controller.index == index;
                      final color = selected
                          ? colors.primary
                          : colors.onSurfaceVariant;
                      return Semantics(
                        button: true,
                        selected: selected,
                        child: InkWell(
                          key: HistoryKeys.tab(index),
                          onTap: () => controller.animateTo(index),
                          child: ConstrainedBox(
                            // 48 dp de altura, mais com fonte grande.
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.sm,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ExcludeSemantics(
                                      child: Icon(
                                        selected ? filled : outlined,
                                        size: AppIconSize.button,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    // Sem corte com a fonte grande: o rótulo
                                    // encolhe para caber (contrato §9).
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          label,
                                          maxLines: 1,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(color: color),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          // O indicador acompanha o arraste.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: controller.animation!,
                builder: (context, _) => CustomPaint(
                  painter: _IndicatorPainter(
                    position: controller.animation!.value,
                    color: colors.primary,
                    count: tabs.length,
                    rtl: Directionality.of(context) == TextDirection.rtl,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorPainter extends CustomPainter {
  _IndicatorPainter({
    required this.position,
    required this.color,
    required this.count,
    required this.rtl,
  });

  final double position;
  final Color color;
  final int count;
  final bool rtl;

  // Altura 3, raio 3 no topo e 20% de recuo de cada lado (artboard).
  static const _height = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width / count;
    final x = rtl ? size.width - (position + 1) * width : position * width;
    final rect = Rect.fromLTWH(
      x + width * 0.2,
      size.height - _height,
      width * 0.6,
      _height,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(_height),
        topRight: const Radius.circular(_height),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_IndicatorPainter old) =>
      old.position != position || old.color != color || old.rtl != rtl;
}
