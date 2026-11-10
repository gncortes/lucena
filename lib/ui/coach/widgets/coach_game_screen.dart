import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/coach/coach.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/coach/coach_rules.dart';
import '../../../routing/routes.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/keys/coach_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/entrada_em_cascata.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/motion/transicao_eixo_x.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_progress.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../survey/view_models/viktor_thanks_cubit.dart';
import '../view_models/trivia_cubit.dart';
import '../view_models/coach_game_cubit.dart';
import 'game_row.dart';
import 'coach_screen.dart';

/// Uma partida do Treinador: o início, a espera da análise, o erro e o
/// resumo, conforme o status que o servidor gravou.
class CoachGameScreen extends StatelessWidget {
  const CoachGameScreen({super.key});

  static void back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.coach());

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<CoachGameCubit, CoachGameState>(
      listenWhen: (a, b) => a.request != b.request,
      listener: (context, state) {
        final cubit = context.read<CoachGameCubit>();
        switch (state.request) {
          case AnalysisRequest.quota:
            cubit.requestSeen();
            unawaited(context.push(Routes.pilaresSale));
          case AnalysisRequest.refused || AnalysisRequest.failed:
            showLucenaSnackBar(
              context,
              state.request == AnalysisRequest.refused
                  ? l.treinadorRecusado
                  : l.treinadorPedidoFalhou,
            );
            cubit.requestSeen();
          case AnalysisRequest.none || AnalysisRequest.sending:
            break;
        }
      },
      builder: (context, state) {
        final cubit = context.read<CoachGameCubit>();
        final sending = state.request == AnalysisRequest.sending;
        if (state.loading) {
          return LoadSkeletonScreen(title: l.treinadorAnaliseTitulo);
        }
        if (state.failed) {
          return LoadErrorScreen(
            kind: LoadErrorKind.offline,
            onAction: cubit.retry,
            onBack: () => back(context),
          );
        }
        final game = state.game;
        if (game == null) {
          return LoadErrorScreen(
            kind: LoadErrorKind.notFound,
            onAction: () => context.go(Routes.coach()),
            onBack: () => back(context),
          );
        }
        final (title, body) = switch (game.status) {
          GameStatus.queued || GameStatus.analyzing => (
            l.treinadorAnaliseTitulo,
            _Loading(
              game: game,
              start: state.analysisStart,
              expected: _expected(state),
            ),
          ),
          // A10 G2: com plano, a partida nova já pede a análise ao abrir.
          GameStatus.newGame when state.autoAnalysis => (
            l.treinadorAnaliseTitulo,
            _Loading(
              game: game,
              start: state.analysisStart,
              expected: _expected(state),
            ),
          ),
          GameStatus.error => (
            l.treinadorAnaliseTitulo,
            _Error(game: game, sending: sending),
          ),
          GameStatus.ready when _summary(game) => (
            l.treinadorResumoContra(game.opponent.name),
            _Summary(game: game, state: state),
          ),
          _ => (l.treinadorAnaliseTitulo, _Start(game: game, state: state)),
        };
        return Scaffold(
          key: CoachKeys.screen,
          appBar: LucenaAppBar(
            leading: BackButton(
              key: CoachKeys.back,
              onPressed: () => back(context),
            ),
            // O nome do adversário quebra a linha, sem reticências.
            title: Text(
              title,
              maxLines: 2,
              softWrap: true,
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
            ),
          ),
          // Início → preparando → pronta: passos em sequência (H-ANI-03).
          body: SafeArea(
            top: false,
            child: TransicaoEixoX(
              child: KeyedSubtree(
                key: ValueKey(_step(game, state)),
                child: body,
              ),
            ),
          ),
        );
      },
    );
  }

  /// O passo da tela: a troca entre passos desliza no eixo X.
  static String _step(CoachGame p, CoachGameState s) => switch (p.status) {
    GameStatus.queued || GameStatus.analyzing => 'carregando',
    GameStatus.newGame when s.autoAnalysis => 'carregando',
    GameStatus.ready when _summary(p) => 'resumo',
    final s => s.name,
  };

  static int _expected(CoachGameState s) =>
      s.expectedExercises ?? CoachConfig.standard.exercisesPerGame;

  /// Pronta e sem exercício a fazer: vai direto ao resumo.
  static bool _summary(CoachGame p) =>
      p.exercises.isEmpty ||
      (p.progress ?? GameProgress.empty).isComplete(p.exercises.length);
}

/// "Análise da partida": o cartão da partida, o "Como funciona" e, presos no
/// pé, o botão de analisar (nova) ou de começar os exercícios (pronta) e a
/// volta à lista (canvas `DInicioNova` e `DInicio`).
class _Start extends StatelessWidget {
  const _Start({required this.game, required this.state});

  final CoachGame game;
  final CoachGameState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<CoachGameCubit>();
    final ready = game.ready;
    final doneCount = game.progress?.doneCount ?? 0;
    final total = game.exercises.length;
    final expected = total > 0
        ? total
        : state.expectedExercises ?? CoachConfig.standard.exercisesPerGame;
    // H-ANI-16, como nas telas de abertura do app: a partida, o "Como
    // funciona" e os botões entram em cascata na primeira vez.
    return EntradaDaTela(
      id: 'TreinadorPartidaInicio-${game.id}',
      child: EntradaEmCascata(
        itens: [
          ItemDaCascata.texto(
            LucenaCard(
              key: CoachKeys.gameCard,
              padding: EdgeInsets.zero,
              child: GameRow(
                game: game,
                currentTime: context.read<Now>()(),
                grant: state.grant,
                showSummary: true,
                showArrow: false,
              ),
            ),
          ),
          ItemDaCascata.texto(
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: _HowItWorks(total: total, expected: expected),
            ),
          ),
          ItemDaCascata.botao(
            _BottomActions(
              children: [
                if (!ready)
                  BusyButton(
                    buttonKey: CoachKeys.begin,
                    label: l.treinadorPartidaComecarAnalise,
                    busy: state.request == AnalysisRequest.sending,
                    onPressed: () => cubit.analyze(),
                  )
                else
                  BusyButton(
                    buttonKey: CoachKeys.begin,
                    label: doneCount > 0
                        ? l.treinadorContinuar(doneCount, total)
                        : l.treinadorComecar,
                    onPressed: () =>
                        unawaited(context.push(Routes.coachExercises(game.id))),
                  ),
                BusyButton(
                  buttonKey: CoachKeys.seeGames,
                  style: BusyButtonStyle.outlined,
                  label: l.treinadorPartidaVerMinhas,
                  onPressed: () =>
                      context.go(Routes.coach(tab: CoachTab.games.wire)),
                ),
              ],
            ),
          ),
        ],
        montar: (items) => Column(
          children: [
            Expanded(
              child: ListView(
                key: CoachKeys.start,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.sm,
                  AppSpacing.screen,
                  AppSpacing.screen,
                ),
                children: items.sublist(0, items.length - 1),
              ),
            ),
            items.last,
          ],
        ),
      ),
    );
  }
}

/// "Como funciona": os três passos do que vem depois da análise. Aparece no
/// início e na espera (A10 G3), para a espera já ensinar o que vem.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.total, required this.expected});

  final int total;
  final int expected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LucenaCard(
      key: CoachKeys.howItWorks,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.treinadorComoFunciona, style: context.cardTitle),
          const SizedBox(height: AppSpacing.lg),
          _Step(
            icon: Icons.extension_outlined,
            title: total > 0
                ? l.treinadorPartidaPasso1Titulo(total)
                : l.treinadorPartidaPasso1TituloAte(expected),
            text: l.treinadorPartidaPasso1Texto,
          ),
          const SizedBox(height: AppSpacing.lg),
          _Step(
            icon: Icons.visibility_outlined,
            title: l.treinadorPartidaPasso2Titulo,
            text: l.treinadorPartidaPasso2Texto,
          ),
          const SizedBox(height: AppSpacing.lg),
          _Step(
            icon: Icons.analytics_outlined,
            title: l.treinadorPartidaPasso3Titulo,
            text: l.treinadorPartidaPasso3Texto,
          ),
        ],
      ),
    );
  }
}

/// Os botões presos no pé da tela, um sobre o outro (canvas: 12 dp entre eles).
class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.screen,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            c,
          ],
        ],
      ),
    );
  }
}

/// Um item do "Como funciona": o ícone num círculo de 40 dp, o título e o
/// texto (canvas `d_inicio`, `passo`).
class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.text});

  /// O círculo do ícone no canvas.
  static const _circle = 40.0;

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _circle,
          height: _circle,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: AppIconSize.notice,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.cardTitle),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A espera da análise (canvas `DCarregandoMeio`): frase (que se reveza) e
/// porcentagem, a
/// barra, o Viktor com a curiosidade e, no pé, a nota e "Me avise". Na fila
/// do grátis a barra corre sem número, porque a análise ainda não começou.
class _Loading extends StatefulWidget {
  const _Loading({
    required this.game,
    required this.start,
    required this.expected,
  });

  final CoachGame game;
  final DateTime? start;
  final int expected;

  @override
  State<_Loading> createState() => _LoadingState();
}

class _LoadingState extends State<_Loading> {
  Timer? _timer;

  /// Segundos com a espera na tela: as frases se revezam por aqui, e não pelo
  /// início da análise, que pode não ter chegado do servidor.
  int _seconds = 0;

  bool get _queued => widget.game.status == GameStatus.queued;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_queued) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Quanto tempo cada frase da espera fica na tela.
  static const _perPhrase = Duration(seconds: 4);

  /// A frase da espera: na fila, a da fila; analisando, frases curtas que
  /// se revezam e tranquilizam, sem narrar o passo da análise (o servidor
  /// não conta em que passo está). "Quase lá" só entra perto do fim.
  String _phrase(int p) {
    final l = context.l10n;
    if (_queued) return l.treinadorFilaFrase;
    final phrases = [
      l.treinadorEsperaPreparando,
      l.treinadorEsperaSeparando,
      l.treinadorEsperaMontando,
      if (p >= 80) l.treinadorEsperaQuaseLa,
    ];
    final past = _seconds ~/ _perPhrase.inSeconds;
    return phrases[past % phrases.length];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final currentTime = context.read<Now>()();
    final p = WaitPercentage.of(widget.start, currentTime);
    return Column(
      key: CoachKeys.loading,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.screen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _phrase(p),
                        key: CoachKeys.loadingPhrase,
                        style: context.cardTitle,
                      ),
                    ),
                    if (!_queued) ...[
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        l.treinadorPorcentagem(p),
                        key: CoachKeys.loadingPercentage,
                        style: context.cardTitle?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AnimatedProgress(
                  key: CoachKeys.loadingBar,
                  value: _queued ? null : p / 100,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _queued
                      ? l.treinadorFilaSubtitulo
                      : l.treinadorEsperaSubtitulo,
                  key: _queued
                      ? CoachKeys.loadingQueue
                      : CoachKeys.loadingSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: AppSpacing.xl),
                // A10 G3: enquanto espera, a curiosidade e o que vem depois
                // entram em cascata (H-ANI-16).
                EntradaEmCascata(
                  itens: [
                    const ItemDaCascata.texto(_Trivia()),
                    ItemDaCascata.texto(
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: _HowItWorks(total: 0, expected: widget.expected),
                      ),
                    ),
                  ],
                  montar: (items) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: items,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.screen,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.treinadorEsperaNota,
                key: CoachKeys.loadingNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.md),
              BusyButton(
                buttonKey: CoachKeys.notifyMe,
                style: BusyButtonStyle.outlined,
                label: l.treinadorMeAvise,
                onPressed: () {
                  unawaited(context.read<CoachGameCubit>().notifyMe());
                  CoachGameScreen.back(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Você sabia?": a curiosidade dita pelo Viktor no balão das lições, os
/// pontos de paginação e "Outra curiosidade".
class _Trivia extends StatelessWidget {
  const _Trivia();

  /// Quantos pontos o canvas mostra (6 curiosidades); com o catálogo maior, o
  /// ponto ativo anda em círculo entre eles.
  static const _points = 6;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return BlocBuilder<TriviaCubit, TriviaState>(
      builder: (context, c) {
        final current = c.current;
        if (current == null) return const SizedBox.shrink();
        final points = math.min(c.all.length, _points);
        return Column(
          key: CoachKeys.trivia,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: InfoChip(
                label: l.treinadorVoceSabia,
                icon: Icons.auto_stories_outlined,
                background: theme.colorScheme.primaryContainer,
                foreground: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            BlocBuilder<ViktorThanksCubit, Character?>(
              builder: (context, viktor) => viktor == null
                  ? Text(current.text, style: theme.textTheme.bodyLarge)
                  : TeacherSpeech(
                      speechContext: SpeechContext.teaching,
                      teacher: viktor,
                      text: current.text,
                    ),
            ),
            if (points > 1) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      key: CoachKeys.triviaDots,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (var i = 0; i < points; i++)
                          _Point(active: i == c.index % points),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  BusyButton(
                    buttonKey: CoachKeys.anotherTrivia,
                    style: BusyButtonStyle.outlined,
                    label: l.treinadorOutraCuriosidade,
                    onPressed: context.read<TriviaCubit>().another,
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Um ponto da paginação: o ativo é a pílula de 20 dp (canvas `lc-brota`).
class _Point extends StatelessWidget {
  const _Point({required this.active});

  /// O ponto (8 dp, [AppSpacing.sm]) e a pílula do ativo (20 dp).
  static const _side = AppSpacing.sm;
  static const _active = AppSpacing.lg + AppSpacing.xs;

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AppMotion.of(context).state,
      width: active ? _active : _side,
      height: _side,
      decoration: BoxDecoration(
        color: active ? colors.primary : colors.outlineVariant,
        borderRadius: BorderRadius.circular(AppShape.full),
      ),
    );
  }
}

/// A análise falhou no servidor.
class _Error extends StatelessWidget {
  const _Error({required this.game, required this.sending});

  final CoachGame game;

  /// O pedido de "Tentar de novo" está a caminho.
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<CoachGameCubit>();
    final canRedo = game.canRedo;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(
              key: CoachKeys.error,
              icon: Icons.error_outline,
              title: l.treinadorErroTitulo,
              message: canRedo ? l.treinadorErroTexto : l.treinadorErroVariante,
            ),
            // O botão fica fora do `EmptyState`, que não tem estado de envio.
            BusyButton(
              buttonKey: canRedo ? CoachKeys.errorRetry : CoachKeys.errorBack,
              style: BusyButtonStyle.tonal,
              label: canRedo ? l.loadErrorRetry : l.treinadorVerPartidas,
              busy: canRedo ? sending : null,
              onPressed: canRedo
                  ? () => cubit.analyze()
                  : () => context.go(Routes.coach(tab: CoachTab.games.wire)),
            ),
          ],
        ),
      ),
    );
  }
}

/// O resumo da partida (canvas `DPartida`): o cartão da partida, os números,
/// as fases, as posições-chave e, presos no pé, os dois caminhos.
class _Summary extends StatelessWidget {
  const _Summary({required this.game, required this.state});

  final CoachGame game;
  final CoachGameState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final progress = game.progress ?? GameProgress.empty;
    final total = game.exercises.length;
    final phases = [
      (l.treinadorFaseAbertura, game.phases.opening),
      (l.treinadorFaseMeio, game.phases.middlegame),
      (l.treinadorFaseFinal, game.phases.ending),
    ].where((f) => f.$2 != null).toList();
    final worst = phases.length > 1
        ? phases.map((f) => f.$2!).reduce(math.min)
        : null;
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: CoachKeys.summary,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.screen,
            ),
            children: [
              LucenaCard(
                key: CoachKeys.summaryGameCard,
                padding: EdgeInsets.zero,
                child: GameRow(
                  game: game,
                  currentTime: context.read<Now>()(),
                  grant: state.grant,
                  showStatus: false,
                  showArrow: false,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Number(
                      key: CoachKeys.summaryAccuracy,
                      label: l.treinadorResumoSuaPrecisao,
                      value: game.accuracy == null
                          ? l.treinadorResumoSemValor
                          : l.treinadorPrecisaoValor(game.accuracy!.round()),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _Number(
                      key: CoachKeys.summaryExercises,
                      label: l.treinadorExercicios,
                      value: total == 0
                          ? l.treinadorResumoSemValor
                          : l.treinadorResumoAcertosDeTotal(
                              progress.corrects,
                              total,
                            ),
                      note: total == 0 ? null : l.treinadorResumoExerciciosNota,
                    ),
                  ],
                ),
              ),
              if (game.summary case final summary?) ...[
                const SizedBox(height: AppSpacing.md),
                Text(summary, style: Theme.of(context).textTheme.bodyLarge),
              ],
              if (phases.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _PhasesCard(phases: phases, worst: worst),
              ],
              if (game.exercises.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _PositionsCard(game: game, progress: progress),
              ],
            ],
          ),
        ),
        _BottomActions(
          children: [
            if (game.exercises.isNotEmpty)
              BusyButton(
                buttonKey: CoachKeys.redo,
                label: l.treinadorRefazer,
                onPressed: () => unawaited(
                  context.push(Routes.coachExercises(game.id, redo: true)),
                ),
              ),
            BusyButton(
              buttonKey: CoachKeys.analysisSummary,
              style: game.exercises.isNotEmpty
                  ? BusyButtonStyle.outlined
                  : BusyButtonStyle.filled,
              label: l.treinadorVerAnalise,
              onPressed: () =>
                  unawaited(context.push(Routes.coachAnalysis(game.id))),
            ),
          ],
        ),
      ],
    );
  }
}

/// Um número do resumo: valor grande, rótulo e nota opcional.
class _Number extends StatelessWidget {
  const _Number({
    required this.label,
    required this.value,
    this.note,
    super.key,
  });

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: LucenaCard(
        key: key,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: context.bigNumber),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: AppWeight.strong,
              ),
            ),
            if (note case final note?)
              Text(
                note,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Precisão por fase": a fase mais fraca em azul cheio e as outras em azul
/// claro (canvas `fase`, decisão de 08/11: uma cor só nas barras).
class _PhasesCard extends StatelessWidget {
  const _PhasesCard({required this.phases, required this.worst});

  final List<(String, double?)> phases;
  final double? worst;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LucenaCard(
      key: CoachKeys.summaryPhases,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.treinadorPrecisaoPorFase, style: context.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          for (final (name, value) in phases)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name, style: theme.textTheme.titleSmall),
                      ),
                      Text(
                        l.treinadorPrecisaoValor(value!.round()),
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedProgress(
                    value: (value / 100).clamp(0, 1),
                    color: worst == null || value == worst
                        ? colors.primary
                        : colors.primary.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Posições-chave": ✓/✗ do aparelho, "Lance N · tema" e o tipo do exercício.
/// Sem resultado neste aparelho (outro aparelho, reinstalação), nem ✓ nem ✗.
class _PositionsCard extends StatelessWidget {
  const _PositionsCard({required this.game, required this.progress});

  final CoachGame game;
  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LucenaCard(
      key: CoachKeys.summaryPositions,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(l.treinadorPosicoesChave, style: context.cardTitle),
          ),
          for (final (i, ex) in game.exercises.indexed) ...[
            if (i > 0) const Divider(height: 1),
            _PositionRow(game: game, ex: ex, result: _result(progress, ex.n)),
          ],
        ],
      ),
    );
  }

  /// Nulo: sem resultado gravado neste aparelho.
  static bool? _result(GameProgress p, int n) {
    for (final r in p.results) {
      if (r.n == n) return r.solved;
    }
    return null;
  }
}

class _PositionRow extends StatelessWidget {
  const _PositionRow({
    required this.game,
    required this.ex,
    required this.result,
  });

  final CoachGame game;
  final CoachExercise ex;
  final bool? result;

  /// A altura mínima da linha no canvas.
  static const _height = 52.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (iconData, color, label) = switch (result) {
      true => (
        Icons.check_circle_outline,
        AppColors.trainingDayCorrect,
        l.treinadorResumoAcertou,
      ),
      false => (Icons.highlight_off, colors.error, l.treinadorResumoErrou),
      null => (
        Icons.radio_button_unchecked,
        colors.outline,
        l.treinadorResumoSemResultado,
      ),
    };
    final type = switch (ex.type) {
      ExerciseType.opponent => l.treinadorResumoTipoAdversario,
      ExerciseType.prophylaxis => l.treinadorResumoTipoProfilaxia,
      ExerciseType.yourBest => l.treinadorResumoTipoSeuMelhor,
      ExerciseType.decisive => l.treinadorResumoTipoDecisivo,
    };
    final white = game.color == GameColor.white;
    return InkWell(
      key: CoachKeys.keyPosition(ex.n),
      onTap: () => unawaited(
        context.push(
          Routes.coachAnalysis(
            game.id,
            ply: CoachRules.halfMove(ex.chessMove, white: white),
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _height),
        child: Row(
          children: [
            Icon(
              iconData,
              size: AppIconSize.button,
              color: color,
              semanticLabel: label,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.motif == null
                          ? l.treinadorLance(ex.chessMove)
                          : l.treinadorResumoLanceTema(
                              ex.chessMove,
                              coachMotifName(l, ex.motif)!,
                            ),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      type,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
