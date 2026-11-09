import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/view_models/coach.dart';
import '../../../domain/models/coach/coach.dart';
import '../../../domain/use_cases/now.dart';
import '../../../routing/routes.dart';
import '../../core/keys/coach_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/abas_fade_through.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/motion/lista_em_ordem.dart';
import '../../core/theme/app_chip.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/icon_navigation_bar.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/section_title.dart';
import '../view_models/link_account_cubit.dart';
import '../view_models/coach_cubit.dart';
import 'game_row.dart';
import 'coach_texts.dart';

/// As abas do Treinador, na ordem da barra.
/// [wire] é o valor de `?aba=` no link (contrato publicado).
enum CoachTab {
  today('hoje'),
  games('partidas'),
  yourGame('seuJogo');

  const CoachTab(this.wire);

  final String wire;

  static CoachTab parse(String? value) =>
      values.where((a) => a.wire == value).firstOrNull ?? today;
}

/// A casca do Treinador de partidas (T87): Hoje, Partidas e Seu jogo. Sem
/// conta ligada, mostra o "Onde você joga?".
class CoachScreen extends StatefulWidget {
  const CoachScreen({
    this.tab = CoachTab.today,
    this.yourGame,
    this.openLast = false,
    super.key,
  });

  final CoachTab tab;

  /// A aba Seu jogo vem da outra frente (`lib/ui/coach_your_game/`); sem
  /// ela, o aviso de "em breve".
  final WidgetBuilder? yourGame;

  /// Atalho da Home (A10): ao carregar, abre a última partida por cima da
  /// lista se ainda falta analisar ou fazer exercício nela.
  final bool openLast;

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  late var _tab = widget.tab;
  late var _openLast = widget.openLast;

  /// Uma vez só, com a lista carregada e o plano: a última partida nova, na
  /// espera ou com exercício pendente abre por cima; feita, fica no Hoje.
  void _maybeOpenLast(CoachState state) {
    if (!_openLast || state.loading) return;
    _openLast = false;
    final last = state.last;
    if (!state.grant || last == null) return;
    final done = last.ready && _next(last) == null;
    if (!done) _open(context, last);
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<CoachCubit, CoachState>(
      listenWhen: (_, _) => _openLast,
      listener: (context, state) => _maybeOpenLast(state),
      builder: (context, state) {
        if (_openLast && !state.loading) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => mounted ? _maybeOpenLast(state) : null,
          );
        }
        if (state.loading) {
          return LoadSkeletonScreen(title: l.treinadorTitle);
        }
        if (state.failed && state.games.isEmpty) {
          return LoadErrorScreen(
            kind: LoadErrorKind.offline,
            onAction: context.read<CoachCubit>().retry,
            onBack: _back,
          );
        }
        final noAccount = state.noAccount;
        return Scaffold(
          key: CoachKeys.screen,
          appBar: LucenaAppBar(
            leading: BackButton(key: CoachKeys.back, onPressed: _back),
            title: Text(l.treinadorTitle),
          ),
          body: noAccount
              ? _LinkAccount(grant: state.grant)
              // H-ANI-05: a troca de aba em fade through, como nas abas de
              // baixo do resto do app; a barra fica parada.
              : AbasFadeThrough(
                  child: KeyedSubtree(
                    key: ValueKey(_tab),
                    child: switch (_tab) {
                      CoachTab.today => EntradaDaTela(
                        id: 'TreinadorHoje',
                        child: _Today(state: state),
                      ),
                      CoachTab.games => EntradaDaTela(
                        id: 'TreinadorPartidas',
                        child: _Games(state: state),
                      ),
                      CoachTab.yourGame => KeyedSubtree(
                        key: CoachKeys.yourGame,
                        child:
                            widget.yourGame?.call(context) ??
                            Center(
                              child: EmptyState(
                                icon: Icons.insights,
                                message: l.treinadorSeuJogoEmBreve,
                              ),
                            ),
                      ),
                    },
                  ),
                ),
          bottomNavigationBar: IconNavigationBar(
            selectedIndex: _tab.index,
            onDestinationSelected: (i) =>
                setState(() => _tab = CoachTab.values[i]),
            tabs: [
              (
                key: CoachKeys.tabToday,
                label: l.treinadorTabHoje,
                icon: Icons.task_alt,
              ),
              (
                key: CoachKeys.tabGames,
                label: l.treinadorTabPartidas,
                icon: Icons.format_list_bulleted,
              ),
              (
                key: CoachKeys.tabYourGame,
                label: l.treinadorTabSeuJogo,
                icon: Icons.insights,
              ),
            ],
          ),
        );
      },
    );
  }
}

void _open(BuildContext context, CoachGame p) =>
    unawaited(context.push(Routes.coachGame(p.id)));

/// O próximo exercício pendente de uma partida pronta: o mesmo em que a tela
/// de exercícios começa (`ProgressoPartida.proximo`). Nulo se não há nenhum.
CoachExercise? _next(CoachGame p) {
  if (!p.ready) return null;
  final doneCount = (p.progress ?? GameProgress.empty).doneCount;
  return doneCount < p.exercises.length ? p.exercises[doneCount] : null;
}

/// O nome do tema do exercício (`xeque_duplo` → "Xeque duplo"). Tema sem nome
/// no app aparece com o texto do servidor sem os sublinhados.
String? coachMotifName(AppLocalizations l, String? motif) {
  if (motif == null || motif.isEmpty) return null;
  final text = motif.replaceAll('_', ' ');
  return l.treinadorHojeTema(
    motif,
    '${text[0].toUpperCase()}${text.substring(1)}',
  );
}

/// A aba Hoje: a última partida e os exercícios que faltam.
class _Today extends StatelessWidget {
  const _Today({required this.state});

  final CoachState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentTime = context.read<Now>()();
    final last = state.last;
    final toDo = [
      for (final p in state.games)
        if (_next(p) case final ex?) (p, ex),
    ];
    return ListView(
      key: CoachKeys.today,
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.lg),
      children: [
        if (!state.grant) const _NoPlan(),
        if (last == null)
          EmptyState(
            key: CoachKeys.todayEmpty,
            icon: Icons.sports_esports_outlined,
            message: l.treinadorHojeVazio(
              context.platform(state.account?.platform ?? Platform.lichess),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DecoratedBox(
              key: CoachKeys.lastGame,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppShape.large),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.xs,
                      ),
                      child: Text(
                        l.treinadorHojeUltima,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    GameRow(
                      game: last,
                      currentTime: currentTime,
                      grant: state.grant,
                      showSummary: true,
                      onTap: () => _open(context, last),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: BusyButton(
                        buttonKey: CoachKeys.seeLastGame,
                        label: l.treinadorVerPartida,
                        onPressed: () => _open(context, last),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (last != null) ...[
          SectionTitle(l.treinadorHojeParaFazer),
          if (toDo.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l.treinadorHojeEmDia,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          else
            // H-ANI-17: a lista entra em ordem na primeira vez.
            ListaEmOrdem(
              itens: [
                for (final (p, ex) in toDo)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: CourseItemTile(
                      key: CoachKeys.toDoExercise(p.id, ex.n),
                      state: CourseItemState.open,
                      title:
                          coachMotifName(l, ex.motif) ??
                          l.treinadorLance(ex.chessMove),
                      summary: l.treinadorHojeExercicio(
                        p.opponent.name,
                        ex.chessMove,
                      ),
                      difficulty: ex.stars.clamp(1, 3),
                      onTap: () =>
                          unawaited(context.push(Routes.coachExercises(p.id))),
                    ),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}

/// A aba Partidas: os filtros de ritmo e resultado e a lista.
class _Games extends StatelessWidget {
  const _Games({required this.state});

  final CoachState state;

  String _count(BuildContext context, int n) {
    final l = context.l10n;
    final filter = state.filter;
    final name = switch (filter.result) {
      null => l.treinadorListaPartidas(n),
      GameResult.win => l.treinadorListaVitorias(n),
      GameResult.loss => l.treinadorListaDerrotas(n),
      GameResult.draw => l.treinadorListaEmpates(n),
    };
    final timeControl = filter.timeControl;
    if (timeControl != null) {
      return l.treinadorListaContagemRitmo(
        n,
        name,
        context.timeControl(timeControl).toLowerCase(),
      );
    }
    return l.treinadorListaContagemSite(
      n,
      name,
      context.platform(state.account?.platform ?? Platform.lichess),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<CoachCubit>();
    final currentTime = context.read<Now>()();
    final filter = state.filter;
    final list = state.filtered;
    Widget chip(Key key, String label, bool selected, VoidCallback onTap) =>
        ChoiceChip(
          key: key,
          materialTapTargetSize: AppChip.tapTarget,
          visualDensity: AppChip.density,
          label: Text(label),
          showCheckmark: false,
          selected: selected,
          onSelected: (_) => onTap(),
        );
    return ListView(
      key: CoachKeys.games,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Canvas DPartidasFiltro: uma fileira que rola; "Todas" uma vez só.
        SingleChildScrollView(
          key: CoachKeys.filters,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              chip(
                CoachKeys.filterAll,
                l.treinadorListaTodas,
                filter.timeControl == null && filter.result == null,
                () => unawaited(
                  cubit.applyFilter(
                    filter.withTimeControl(null).withResult(null),
                  ),
                ),
              ),
              for (final r in TimeControl.values)
                chip(
                  CoachKeys.timeControlFilter(r.wire),
                  context.timeControl(r),
                  filter.timeControl == r,
                  () => unawaited(
                    cubit.applyFilter(
                      filter.withTimeControl(
                        filter.timeControl == r ? null : r,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                height: AppSpacing.lg,
                child: VerticalDivider(
                  width: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              for (final (r, name) in [
                (GameResult.win, l.treinadorFiltroVitorias),
                (GameResult.loss, l.treinadorFiltroDerrotas),
                (GameResult.draw, l.treinadorFiltroEmpates),
              ])
                chip(
                  CoachKeys.resultFilter(r.wire),
                  name,
                  filter.result == r,
                  () => unawaited(
                    cubit.applyFilter(
                      filter.withResult(filter.result == r ? null : r),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (state.games.isEmpty)
          EmptyState(
            key: CoachKeys.gamesEmpty,
            icon: Icons.sports_esports_outlined,
            message: l.treinadorHojeVazio(
              context.platform(state.account?.platform ?? Platform.lichess),
            ),
          )
        else if (list.isEmpty)
          EmptyState(
            key: CoachKeys.gamesEmpty,
            icon: Icons.filter_alt_off_outlined,
            message: l.treinadorPartidasVazio,
            actionLabel: l.treinadorLimparFiltros,
            actionKey: CoachKeys.clearFilters,
            onAction: () => unawaited(cubit.clearFilters()),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xs,
              bottom: AppSpacing.md,
            ),
            child: Text(
              _count(context, list.length),
              key: CoachKeys.gamesCount,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          LucenaCard(
            key: CoachKeys.gamesBase,
            padding: EdgeInsets.zero,
            // H-ANI-17: as partidas entram em ordem na primeira vez.
            child: ListaEmOrdem(
              itens: [
                for (final (i, p) in list.indexed)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i > 0)
                        const Divider(
                          height: 1,
                          indent: AppSpacing.md,
                          endIndent: AppSpacing.md,
                        ),
                      GameRow(
                        game: p,
                        currentTime: currentTime,
                        grant: state.grant,
                        onTap: () => _open(context, p),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A caixa de quem não tem o plano de análise (3 análises grátis por semana).
class _NoPlan extends StatelessWidget {
  const _NoPlan();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: LucenaCard(
        key: CoachKeys.noPlan,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.treinadorSemPlanoTitulo, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.treinadorSemPlanoTexto,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            BusyButton(
              buttonKey: CoachKeys.discoverPlan,
              style: BusyButtonStyle.tonal,
              label: l.treinadorConhecerPlano,
              onPressed: () => unawaited(context.push(Routes.pilaresSale)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Onde você joga?": escolhe o site e digita o usuário.
class _LinkAccount extends StatefulWidget {
  const _LinkAccount({required this.grant});

  final bool grant;

  @override
  State<_LinkAccount> createState() => _LinkAccountViewState();
}

class _LinkAccountViewState extends State<_LinkAccount> {
  Platform? _platform;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final platform = _platform;
    // Canvas DLigarConta: 32 dp dos lados.
    const padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xxl,
      vertical: AppSpacing.xl,
    );
    // Canvas DLigarConta: o bloco centrado na altura, com rolagem se não couber.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        key: CoachKeys.linkAccount,
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: box.maxHeight - padding.vertical,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.link,
                  size: AppIconSize.illustration,
                  color: colors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.treinadorLigarTituloConta,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.treinadorLigarTextoConta,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (platform == null) ...[
                  BusyButton(
                    buttonKey: CoachKeys.linkLichess,
                    label: l.treinadorLigarBotao(
                      context.platform(Platform.lichess),
                    ),
                    onPressed: () =>
                        setState(() => _platform = Platform.lichess),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BusyButton(
                    buttonKey: CoachKeys.linkChesscom,
                    style: BusyButtonStyle.outlined,
                    label: l.treinadorLigarBotao(
                      context.platform(Platform.chesscom),
                    ),
                    onPressed: () =>
                        setState(() => _platform = Platform.chesscom),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l.treinadorLigarPrivacidade,
                    key: CoachKeys.linkPrivacy,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ] else
                  BlocProvider(
                    key: ValueKey(platform),
                    create: (c) =>
                        createLinkAccountCubit(c, platform: platform),
                    child: _AccountForm(
                      onSwitch: () => setState(() => _platform = null),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountForm extends StatelessWidget {
  const _AccountForm({required this.onSwitch});

  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<LinkAccountCubit>();
    return BlocBuilder<LinkAccountCubit, LinkAccountState>(
      builder: (context, state) {
        final site = context.platform(state.platform);
        final error = switch (state.failure) {
          null => null,
          LinkAccountFailure.doesNotExist => l.treinadorContaNaoExiste(site),
          LinkAccountFailure.noResponse => l.treinadorContaSemResposta,
          LinkAccountFailure.noPlan => l.treinadorContaSemPlano,
          LinkAccountFailure.noLogin => l.treinadorContaSemLogin,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: CoachKeys.username,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onChanged: cubit.typeText,
              onSubmitted: (_) => unawaited(cubit.link()),
              decoration: InputDecoration(
                labelText: l.treinadorUsuarioNo(site),
                border: const OutlineInputBorder(),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  error,
                  key: CoachKeys.accountError,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            BusyButton(
              buttonKey: CoachKeys.confirmAccount,
              label: l.treinadorLigarConta,
              busy: state.sending,
              onPressed: state.canSend ? cubit.link : null,
            ),
            if (state.failure == LinkAccountFailure.noPlan) ...[
              const SizedBox(height: AppSpacing.sm),
              BusyButton(
                buttonKey: CoachKeys.discoverPlan,
                style: BusyButtonStyle.tonal,
                label: l.treinadorConhecerPlano,
                onPressed: () => unawaited(context.push(Routes.pilaresSale)),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            BusyButton(
              buttonKey: CoachKeys.switchSite,
              style: BusyButtonStyle.text,
              label: l.treinadorTrocarSite,
              onPressed: onSwitch,
            ),
          ],
        );
      },
    );
  }
}
