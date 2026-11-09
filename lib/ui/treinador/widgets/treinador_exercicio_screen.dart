import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/treinador/treinador.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/treinador/treinador_regras.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/keys/treinador_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/retorno_do_lance.dart';
import '../../core/motion/tabuleiro_animado.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/move_highlight.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../core/widgets/training_canvas_layout.dart';
import '../../endgames/widgets/grade_widgets.dart';
import '../../lesson_script/view_models/lesson_script_state.dart';
import '../../lesson_script/widgets/script_move_list.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../survey/view_models/viktor_thanks_cubit.dart';
import '../view_models/treinador_exercicio_cubit.dart';
import 'treinador_screen.dart';

/// Os exercícios de uma partida analisada, com o Viktor, e a pontuação no
/// fim. O progresso fica salvo a cada exercício (sair no meio retoma dali).
class TreinadorExercicioScreen extends StatefulWidget {
  const TreinadorExercicioScreen({super.key});

  @override
  State<TreinadorExercicioScreen> createState() =>
      _TreinadorExercicioScreenState();
}

class _TreinadorExercicioScreenState extends State<TreinadorExercicioScreen> {
  ChessboardController? _board;

  @override
  void dispose() {
    _board?.dispose();
    super.dispose();
  }

  void _voltar() =>
      context.canPop() ? context.pop() : context.go(Routes.treinador());

  static Side _lado(ExercicioTreinador ex) =>
      GameRules.fromFen(ex.fen)?.turn ?? Side.white;

  GameData _dados(TreinadorExercicioState s) {
    final fen = s.fen!;
    final posicao = GameRules.fromFen(fen);
    final lado = _lado(s.exercicio!);
    final lance = s.ultimoLance == null ? null : Move.parse(s.ultimoLance!);
    return GameData(
      fen: fen,
      playerSide: posicao == null || s.fase != FaseExercicio.jogando
          ? PlayerSide.none
          : (lado == Side.white ? PlayerSide.white : PlayerSide.black),
      sideToMove: posicao?.turn ?? lado,
      validMoves: posicao == null ? const {} : GameRules.legalMoves(posicao),
      lastMove: lance,
      kingSquareInCheck: posicao == null
          ? null
          : GameRules.checkedKing(posicao),
    );
  }

  TreinadorExercicioState? _anterior;

  void _sincronizar(TreinadorExercicioState s) {
    final anterior = _anterior;
    _anterior = s;
    if (s.fen == null || s.exercicio == null) return;
    final board = _board;
    if (board == null) {
      _board = ChessboardController(game: _dados(s));
      return;
    }
    board.updatePosition(
      _dados(s),
      animate: anterior?.fen != s.fen && anterior?.indice == s.indice,
      resetPremove: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Lido no build: o boardBuilder roda no layout.
    final boardSettings = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
    return BlocConsumer<TreinadorExercicioCubit, TreinadorExercicioState>(
      listener: (_, s) => _sincronizar(s),
      builder: (context, s) {
        if (s.fase == FaseExercicio.carregando) {
          return const LoadSkeletonScreen();
        }
        if (s.fase == FaseExercicio.indisponivel) {
          return LoadErrorScreen(
            kind: LoadErrorKind.notFound,
            onAction: () => context.go(Routes.treinador()),
            onBack: _voltar,
          );
        }
        if (s.fase == FaseExercicio.offline) {
          return LoadErrorScreen(
            kind: LoadErrorKind.offline,
            onAction: context.read<TreinadorExercicioCubit>().recarregar,
            onBack: _voltar,
          );
        }
        if (_board == null && s.fen != null && s.exercicio != null) {
          _board = ChessboardController(game: _dados(s));
          _anterior = s;
        }
        return BlocBuilder<ViktorThanksCubit, Character?>(
          builder: (context, viktor) {
            if (viktor == null) return const LoadSkeletonScreen();
            if (s.fase == FaseExercicio.fim) {
              return _Fim(state: s, viktor: viktor, onFechar: _voltar);
            }
            final ex = s.exercicio!;
            return Scaffold(
              key: TreinadorKeys.exercicio,
              appBar: LucenaAppBar(
                leading: BackButton(
                  key: TreinadorKeys.back,
                  onPressed: _voltar,
                ),
                centerTitle: true,
                title: Text(l.treinadorExercicioTitulo(s.indice + 1, s.total)),
                actions: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.md,
                    ),
                    child: Semantics(
                      label: _vale(s)
                          ? l.exercisePoints(s.vale)
                          : l.exerciseNoMorePoints,
                      excludeSemantics: true,
                      // Como nos exercícios de finais (exercise_screen): neutra,
                      // na cor do texto, cheia enquanto ainda vale pontos; cada
                      // erro ou dica desce um degrau (3 → 2 → 1), e só esvazia
                      // quando não vale mais nada.
                      child: Icon(
                        _vale(s)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        key: TreinadorKeys.exercicioEstrelas,
                        size: AppIconSize.large,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              body: BoardViewport(
                usefulHeight: BoardViewport.usefulHeightOf(context),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: TrainingCanvasPage(
                          pageKey: TreinadorKeys.exercicioPagina,
                          teacher: viktor,
                          text: _fala(l, s, ex),
                          boardBuilder: (size) =>
                              _tabuleiro(context, s, size, boardSettings),
                          notation: _notacao(s, ex),
                        ),
                      ),
                      _rodape(context, s),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static bool _vale(TreinadorExercicioState s) =>
      s.vale > 0 &&
      (s.fase == FaseExercicio.jogando || s.fase == FaseExercicio.acertou);

  /// O lance tentado (com "?" no erro) ou a solução, em SAN, como no Treino,
  /// com o destaque do lance da análise de partida.
  /// Na posição do exercício; vazia enquanto o aluno ainda não jogou.
  static Widget _notacao(TreinadorExercicioState s, ExercicioTreinador ex) {
    final posicao = GameRules.fromFen(ex.fen);
    final uci = switch (s.fase) {
      FaseExercicio.acertou || FaseExercicio.errou => s.ultimoLance,
      FaseExercicio.solucao => ex.solucao,
      _ => null,
    };
    if (posicao == null || uci == null) return const SizedBox.shrink();
    final sans = GameRules.sanLine(posicao, [uci]);
    if (sans.isEmpty) return const SizedBox.shrink();
    return ScriptMoveList(
      moves: [
        ScriptMoveEntry(
          id: '0',
          san: sans.first,
          number: posicao.fullmoves,
          side: posicao.turn,
          variant: false,
          symbol: switch (s.fase) {
            FaseExercicio.errou => '?',
            FaseExercicio.solucao => '!',
            _ => null,
          },
        ),
      ],
      currentId: '0',
      onTap: (_) {},
      // O destaque do lance como na análise da partida (T87).
      highlight: MoveHighlight.outlined,
    );
  }

  static String _fala(
    AppLocalizations l,
    TreinadorExercicioState s,
    ExercicioTreinador ex,
  ) {
    String ou(String texto, String padrao) =>
        texto.trim().isEmpty ? padrao : texto;
    return switch (s.fase) {
      FaseExercicio.acertou => ou(ex.falas.acerto, l.treinadorAcertoPadrao),
      FaseExercicio.errou => ou(ex.falas.erro, l.treinadorErroPadrao),
      FaseExercicio.solucao => ou(ex.falas.solucao, l.treinadorSolucaoPadrao),
      _ => ou(ex.falas.enunciado, l.treinadorEnunciadoPadrao),
    };
  }

  Widget _rodape(BuildContext context, TreinadorExercicioState s) {
    final l = context.l10n;
    final cubit = context.read<TreinadorExercicioCubit>();
    final avancar =
        s.fase == FaseExercicio.acertou || s.fase == FaseExercicio.solucao;
    return TrainingCanvasFooter(
      // A lâmpada à esquerda, como no exercício do Treino.
      leading: s.podeDica
          ? TrainingCanvasFooter.hint(
              key: TreinadorKeys.dica,
              label: switch (s.vale) {
                0 => l.exerciseHintFree,
                1 => l.exerciseHintLast,
                _ => l.exerciseHint,
              },
              onPressed: cubit.dica,
            )
          : null,
      secondary:
          s.fase == FaseExercicio.jogando || s.fase == FaseExercicio.errou
          ? TrainingCanvasFooter.button(
              key: TreinadorKeys.verSolucao,
              label: l.trainingSeeSolution,
              onPressed: () => unawaited(cubit.verSolucao()),
            )
          : null,
      primary: s.fase == FaseExercicio.errou
          ? TrainingCanvasFooter.button(
              key: TreinadorKeys.tentarDeNovo,
              label: l.loadErrorRetry,
              primary: true,
              onPressed: cubit.tentarDeNovo,
            )
          : avancar
          ? TrainingCanvasFooter.button(
              key: TreinadorKeys.proximo,
              label: s.ultimo ? l.treinadorVerPontuacao : l.treinadorProximo,
              primary: true,
              onPressed: cubit.proximo,
            )
          : null,
    );
  }

  Widget _tabuleiro(
    BuildContext context,
    TreinadorExercicioState s,
    double size,
    BoardSettings boardSettings,
  ) {
    final board = _board;
    final ex = s.exercicio!;
    if (board == null) return SizedBox.square(dimension: size);
    final lado = _lado(ex);
    final jogado = s.ultimoLance == null ? null : Move.parse(s.ultimoLance!);
    final solucao = Move.parse(ex.solucao);
    final child = SizedBox.square(
      dimension: size,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: TabuleiroAnimado(
          controlador: board,
          orientacao: lado,
          tamanho: size,
          pecas: boardSettings.chessground.pieceAssets,
          child: Chessboard(
            key: TreinadorKeys.exercicioTabuleiro,
            size: size,
            controller: board,
            settings: TabuleiroAnimado.ajustes(
              context,
              boardSettings.chessground,
            ),
            orientation: lado,
            shapes: {
              // A dica: a peça que joga (1) e depois o lance (2).
              if (s.fase == FaseExercicio.jogando &&
                  s.dicas == 1 &&
                  solucao is NormalMove)
                Circle(
                  color: Theme.of(context).colorScheme.primary,
                  orig: solucao.from,
                ),
              if (s.fase == FaseExercicio.jogando &&
                  s.dicas >= 2 &&
                  solucao is NormalMove)
                Arrow(
                  color: Theme.of(context).colorScheme.primary,
                  orig: solucao.from,
                  dest: solucao.to,
                ),
              if (s.fase == FaseExercicio.errou && jogado is NormalMove)
                Arrow(
                  color: AppColors.errorColor.withValues(
                    alpha: AppColors.boardMarkAlpha,
                  ),
                  orig: jogado.from,
                  dest: jogado.to,
                ),
              if (s.fase == FaseExercicio.solucao && solucao is NormalMove)
                Arrow(
                  color: AppColors.successColor.withValues(
                    alpha: AppColors.boardMarkAlpha,
                  ),
                  orig: solucao.from,
                  dest: solucao.to,
                ),
            },
            onMove: (move, {viaDragAndDrop}) => unawaited(
              context.read<TreinadorExercicioCubit>().jogar(move.uci),
            ),
          ),
        ),
      ),
    );
    if (jogado is! NormalMove ||
        (s.fase != FaseExercicio.acertou && s.fase != FaseExercicio.errou)) {
      return child;
    }
    return RetornoDoLance(
      key: ValueKey('${s.indice}.${s.tentativas}.${s.fase.name}'),
      tipo: s.fase == FaseExercicio.acertou
          ? TipoDeRetorno.acerto
          : TipoDeRetorno.erro,
      casa: jogado.to,
      orientacao: lado,
      tamanho: size,
      vibrar: context.read<SettingsCubit>().state?.vibration ?? true,
      child: child,
    );
  }
}

/// A pontuação (canvas DFim): a medalha, "x de N certos", a partida, uma
/// bolinha por exercício, a fala do Viktor e os botões no pé.
class _Fim extends StatelessWidget {
  const _Fim({
    required this.state,
    required this.viktor,
    required this.onFechar,
  });

  final TreinadorExercicioState state;
  final Character viktor;
  final VoidCallback onFechar;

  /// O diâmetro da bolinha (DFim: 40 dp).
  static const _bolinha = 40.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = state.progresso;
    final partida = state.partida;
    final nota = TreinadorRegras.nota(p.acertos, state.total);
    final fala = switch (nota) {
      ExerciseGrade.perfect => l.treinadorFimVikPerfeito,
      ExerciseGrade.good ||
      ExerciseGrade.excellent ||
      ExerciseGrade.passed => l.treinadorFimVikBom,
      ExerciseGrade.below => l.treinadorFimVikAbaixo,
    };
    final id = partida?.id ?? '';
    final adversario = partida?.adversario.nome ?? '';
    final cadencia = partida?.cadencia;
    return Scaffold(
      key: TreinadorKeys.fim,
      appBar: LucenaAppBar(
        leading: IconButton(
          key: TreinadorKeys.fimFechar,
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: onFechar,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: GradeMedal(key: TreinadorKeys.fimNota, grade: nota),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l.treinadorFimCertos(p.acertos, state.total),
                    textAlign: TextAlign.center,
                    style: context.screenTitle?.copyWith(
                      fontWeight: AppWeight.heavy,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    cadencia == null || cadencia.isEmpty
                        ? l.treinadorFimSubtituloSemCadencia(adversario)
                        : l.treinadorFimSubtitulo(adversario, cadencia),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Bolinhas(state: state, diametro: _bolinha),
                  const SizedBox(height: AppSpacing.lg),
                  TeacherSpeech(
                    speechContext: SpeechContext.teaching,
                    teacher: viktor,
                    text: fala,
                  ),
                ],
              ),
            ),
            ActionsFooter(
              stacked: true,
              children: [
                BusyButton(
                  buttonKey: TreinadorKeys.fimAnalise,
                  icon: Icons.analytics_outlined,
                  label: l.treinadorVerAnalise,
                  onPressed: () =>
                      unawaited(context.push(Routes.treinadorAnalise(id))),
                ),
                BusyButton(
                  buttonKey: TreinadorKeys.fimSeuJogo,
                  icon: Icons.insights_outlined,
                  style: BusyButtonStyle.outlined,
                  label: l.treinadorOndeErra,
                  onPressed: () => context.go(
                    Routes.treinador(aba: AbaTreinador.seuJogo.name),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma bolinha por exercício: verde certo, vermelha errado (de
/// `progresso.resultados`); o que não foi feito fica só com o contorno.
class _Bolinhas extends StatelessWidget {
  const _Bolinhas({required this.state, required this.diametro});

  final TreinadorExercicioState state;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final porN = {for (final r in state.progresso.resultados) r.n: r};
    return Wrap(
      key: TreinadorKeys.fimBolinhas,
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (i, ex) in state.exercicios.indexed)
          _Bolinha(
            key: TreinadorKeys.fimBolinha(i + 1),
            numero: i + 1,
            diametro: diametro,
            certo: porN[ex.n]?.acertou,
            semantica: switch (porN[ex.n]?.acertou) {
              true => l.treinadorFimBolinhaCerta(i + 1),
              false => l.treinadorFimBolinhaErrada(i + 1),
              // Sem resultado neste celular: "Exercício n de N" e o valor.
              null => l.treinadorExercicioTitulo(i + 1, state.total),
            },
            valorSemantico: porN[ex.n] == null
                ? l.treinadorResumoSemResultado
                : null,
            texto: theme.textTheme.titleMedium,
          ),
      ],
    );
  }
}

class _Bolinha extends StatelessWidget {
  const _Bolinha({
    required this.numero,
    required this.diametro,
    required this.certo,
    required this.semantica,
    required this.texto,
    this.valorSemantico,
    super.key,
  });

  final int numero;
  final double diametro;

  /// Nulo: ainda sem resultado.
  final bool? certo;
  final String semantica;
  final String? valorSemantico;
  final TextStyle? texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cor = switch (certo) {
      true => AppColors.trainingDayCorrect,
      false => AppColors.trainingDayWrong,
      null => null,
    };
    return Semantics(
      label: semantica,
      value: valorSemantico,
      excludeSemantics: true,
      child: Container(
        width: diametro,
        height: diametro,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cor,
          // Sem resultado: só o contorno, com o número na cor do texto.
          border: cor == null ? Border.all(color: colors.outline) : null,
          shape: BoxShape.circle,
        ),
        child: Text(
          NumberFormat.decimalPattern(
            Localizations.localeOf(context).toString(),
          ).format(numero),
          style: texto?.copyWith(
            color: cor == null ? colors.onSurface : AppColors.chessWhiteColor,
          ),
        ),
      ),
    );
  }
}
