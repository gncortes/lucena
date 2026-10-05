import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/home_cubit.dart';
import '../../core/widgets/scroll_padding.dart';
import 'path_card.dart';
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _Entrance(
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
                            const SizedBox(height: 12),
                            WhereCard(state: state),
                            _shortcuts(context, theme),
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

  // Os caminhos do app, na ordem de quem está aprendendo: as aulas, depois a
  // Jornada para praticar, o speedrun e os finais avulsos. Cada um diz o que
  // se faz nele. Depois, as ferramentas. Os números do jogador ficam nos
  // detalhes do rating.
  Widget _shortcuts(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    final paths = [
      (
        key: HomeKeys.schoolButton,
        icon: Icons.school_outlined,
        title: l10n.homeLearn,
        body: l10n.homeLearnBody,
        route: Routes.school,
      ),
      (
        key: HomeKeys.journeyButton,
        icon: Icons.flag_rounded,
        title: l10n.homeJourney,
        body: l10n.homeJourneyBody,
        route: Routes.journey,
      ),
      (
        key: HomeKeys.speedrunButton,
        icon: Icons.timer_outlined,
        title: l10n.homeSpeedrun,
        body: l10n.homeSpeedrunBody,
        route: Routes.speedruns,
      ),
      (
        key: HomeKeys.catalogButton,
        icon: Icons.grid_view_rounded,
        title: l10n.homeTrain,
        body: l10n.homeTrainBody,
        route: Routes.catalog,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(theme, l10n.homePathsTitle, key: HomeKeys.pathsTitle),
        for (final (index, path) in paths.indexed) ...[
          if (index > 0) const SizedBox(height: 8),
          PathCard(
            key: path.key,
            icon: path.icon,
            title: path.title,
            body: path.body,
            onTap: () => context.go(path.route),
          ),
        ],
        _sectionTitle(theme, l10n.homeTools),
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

  Widget _sectionTitle(ThemeData theme, String text, {Key? key}) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 20, 4, 8),
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
