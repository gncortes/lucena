import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/home_layout.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/use_cases/home_suggestion.dart';
import '../../../routing/routes.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/home_cubit.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/staggered_entrance.dart';
import 'home_path_ui.dart';
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
                    // Todos os modos, mesmo os fora do destaque.
                    IconButton(
                      key: HomeKeys.allModesButton,
                      icon: const Icon(Icons.apps_rounded),
                      tooltip: l10n.allModesTitle,
                      onPressed: () => context.go(Routes.allModes),
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
                            if (state.unlockedBlind) ...[
                              const SizedBox(height: 12),
                              const _UnlockedCard(),
                            ],
                            if (state.layoutNotice) ...[
                              const SizedBox(height: 12),
                              _LayoutNotice(onCustomize: _customize),
                            ],
                            if (state.continuePath != null) ...[
                              const SizedBox(height: 12),
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
    // Os cartões entram um depois do outro.
    Widget card(HomePath path, int index) => StaggeredEntrance(
      index: index,
      child: PathCard(
        key: path.homeKey,
        icon: path.icon,
        title: path.title(l10n),
        body: path.body(l10n, state.level),
        onTap: () => context.go(path.route),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 12, 0, 0),
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
                icon: const Icon(Icons.tune, size: 18),
                label: Text(l10n.homeCustomize),
                onPressed: _customize,
              ),
            ],
          ),
        ),
        for (final (index, path) in layout.shown.indexed) ...[
          if (index > 0) const SizedBox(height: 8),
          card(path, index),
        ],
        if (layout.hidden.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Theme(
              // Sem as linhas do ExpansionTile.
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: HomeKeys.otherModes,
                tilePadding: const EdgeInsetsDirectional.only(start: 4, end: 8),
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  l10n.homeOtherModes,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                children: [
                  for (final (index, path) in layout.hidden.indexed) ...[
                    if (index > 0) const SizedBox(height: 8),
                    card(path, index),
                  ],
                ],
              ),
            ),
          ),
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

  // A configuração da tela inicial; ao voltar, a tela relê o layout.
  Future<void> _customize() async {
    final cubit = context.read<HomeCubit>();
    if (cubit.state.layoutNotice) unawaited(cubit.dismissLayoutNotice());
    await context.push(Routes.homeLayout);
    if (mounted) await cubit.load(Localizations.localeOf(context).languageCode);
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
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Card(
        key: HomeKeys.unlockedCard,
        margin: EdgeInsets.zero,
        color: colors.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.record_voice_over,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.homeUnlockedBlindTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
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
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Text(
                  l10n.homeUnlockedBlindBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
      margin: EdgeInsets.zero,
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 4, 8),
        child: Row(
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              color: colors.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
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
