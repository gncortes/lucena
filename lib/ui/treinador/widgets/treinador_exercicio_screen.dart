import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../core/widgets/training_canvas_layout.dart';
import '../../endgames/widgets/grade_widgets.dart';
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
                      label: l.treinadorEstrelas(ex.estrelas),
                      excludeSemantics: true,
                      child: Row(
                        key: TreinadorKeys.exercicioEstrelas,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < ex.estrelas.clamp(1, 3); i++)
                            const Icon(
                              Icons.star_rounded,
                              size: AppIconSize.large,
                            ),
                        ],
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
                          boardBuilder: (size) => _tabuleiro(context, s, size),
                          notation: const SizedBox(height: 40),
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
  ) {
    final board = _board;
    final ex = s.exercicio!;
    if (board == null) return SizedBox.square(dimension: size);
    final boardSettings = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
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

/// A pontuação: a medalha, os certos, os pontos e a fala do Viktor.
class _Fim extends StatelessWidget {
  const _Fim({
    required this.state,
    required this.viktor,
    required this.onFechar,
  });

  final TreinadorExercicioState state;
  final Character viktor;
  final VoidCallback onFechar;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = state.progresso;
    final nota = TreinadorRegras.nota(p.acertos, state.total);
    final titulo = switch (nota) {
      ExerciseGrade.perfect => l.treinadorFimPerfeito,
      ExerciseGrade.good || ExerciseGrade.excellent => l.treinadorFimBom,
      ExerciseGrade.passed => l.treinadorFimAprovado,
      ExerciseGrade.below => l.treinadorFimAbaixo,
    };
    final fala = switch (nota) {
      ExerciseGrade.perfect => l.treinadorFimVikPerfeito,
      ExerciseGrade.good ||
      ExerciseGrade.excellent ||
      ExerciseGrade.passed => l.treinadorFimVikBom,
      ExerciseGrade.below => l.treinadorFimVikAbaixo,
    };
    final id = state.partida?.id ?? '';
    return Scaffold(
      key: TreinadorKeys.fim,
      appBar: LucenaAppBar(
        leading: BackButton(key: TreinadorKeys.back, onPressed: onFechar),
        title: Text(l.treinadorResumoTitulo),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: GradeMedal(key: TreinadorKeys.fimNota, grade: nota),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l.treinadorFimCertos(p.acertos, state.total)} · '
              '${l.treinadorFimPontos(p.pontos)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TeacherSpeech(
              speechContext: SpeechContext.teaching,
              teacher: viktor,
              text: fala,
            ),
            const SizedBox(height: AppSpacing.xl),
            BusyButton(
              buttonKey: TreinadorKeys.fimAnalise,
              label: l.treinadorVerAnalise,
              onPressed: () =>
                  unawaited(context.push(Routes.treinadorAnalise(id))),
            ),
            const SizedBox(height: AppSpacing.sm),
            BusyButton(
              buttonKey: TreinadorKeys.fimSeuJogo,
              style: BusyButtonStyle.outlined,
              label: l.treinadorOndeErra,
              onPressed: () =>
                  context.go(Routes.treinador(aba: AbaTreinador.seuJogo.name)),
            ),
            const SizedBox(height: AppSpacing.sm),
            BusyButton(
              buttonKey: TreinadorKeys.fimFechar,
              style: BusyButtonStyle.text,
              label: l.licaoAdClose,
              onPressed: onFechar,
            ),
          ],
        ),
      ),
    );
  }
}
