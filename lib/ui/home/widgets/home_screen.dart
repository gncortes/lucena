import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/home_cubit.dart';
import '../../core/widgets/scroll_padding.dart';
import 'player_card.dart';
import 'where_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // Entrada em sequência: o nome do app primeiro, depois o painel.
  late final _title = _stage(0, 0.6);
  late final _actions = _stage(0.3, 1);

  CurvedAnimation _stage(double begin, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Quem pediu menos movimento ao sistema vê a tela pronta, sem animação.
    if (MediaQuery.disableAnimationsOf(context)) {
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
      // Primeira abertura: o tour antes de tudo.
      listenWhen: (previous, current) =>
          current.ready && current.tourPending && !previous.tourPending,
      listener: (context, state) => context.go(Routes.tour),
      child: _scaffold(context, theme),
    );
  }

  Widget _scaffold(BuildContext context, ThemeData theme) {
    return Scaffold(
      key: HomeKeys.screen,
      body: SafeArea(child: _content(context, theme)),
    );
  }

  // O painel do jogador: o topo compacto, o rating, o "Continuar", os números
  // do progresso e os atalhos.
  Widget _content(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: scrollPadding(context, left: 16, top: 8, right: 16),
          children: [
            // No alto, só o nome do app e os botões.
            _Entrance(
              animation: _title,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 4),
                      child: Text(
                        l10n.appTitle,
                        key: HomeKeys.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: HomeKeys.achievementsButton,
                    icon: const Icon(Icons.emoji_events_outlined),
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
            const SizedBox(height: 12),
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                if (!state.ready) return const SizedBox.shrink();
                return _Entrance(
                  animation: _actions,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PlayerCard(state: state),
                      const SizedBox(height: 12),
                      WhereCard(state: state),
                      const SizedBox(height: 12),
                      StatsRow(state: state),
                      const SizedBox(height: 16),
                      _shortcuts(context, theme, state),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // A Jornada em destaque, os modos de jogo em grade e as ferramentas, mais
  // discretas.
  Widget _shortcuts(BuildContext context, ThemeData theme, HomeState state) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: HomeKeys.journeyButton,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            textStyle: theme.textTheme.titleMedium,
          ),
          icon: const Icon(Icons.flag_rounded),
          label: Text(l10n.homeJourney),
          onPressed: () => context.go(Routes.journey),
        ),
        const SizedBox(height: 12),
        // Os três atalhos com a mesma altura.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Tile(
                  key: HomeKeys.catalogButton,
                  icon: Icons.grid_view_rounded,
                  label: l10n.homeTrain,
                  onTap: () => context.go(Routes.catalog),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  key: HomeKeys.speedrunButton,
                  icon: Icons.timer_outlined,
                  label: l10n.homeSpeedrun,
                  onTap: () => context.go(Routes.speedruns),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  key: HomeKeys.schoolButton,
                  icon: Icons.school_outlined,
                  label: l10n.homeSchool,
                  onTap: () => context.go(Routes.school),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 20, 4, 4),
          child: Text(
            l10n.homeTools,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: HomeKeys.customPositionButton,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(l10n.customPositionTitle),
              onPressed: () => context.go(Routes.customPosition),
            ),
            OutlinedButton.icon(
              key: HomeKeys.freeBoardButton,
              icon: const Icon(Icons.grid_on_outlined, size: 18),
              label: Text(l10n.freeBoardTitle),
              onPressed: () => context.go(Routes.freeBoard),
            ),
          ],
        ),
      ],
    );
  }
}

/// Um atalho quadrado da grade: ícone em cima, nome embaixo.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colors.onSecondaryContainer),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
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
