import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/app_bar_progress.dart';

import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/placement.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/placement_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_button_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/one_line.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/placement_cubit.dart';
import 'placement_prompt.dart';
import 'placement_result_view.dart';

/// O teste de nível (T52): a abertura com o Viktor, as 20 perguntas (sem
/// dizer se acertou) e o resultado. [onDone] recebe o fim: o tour segue, as
/// outras entradas voltam.
class PlacementScreen extends StatelessWidget {
  const PlacementScreen({this.onDone, this.onChooseByHand, super.key});

  /// O jogador terminou e usou o resultado.
  final VoidCallback? onDone;

  /// O jogador prefere escolher a faixa na mão (só no tour).
  final VoidCallback? onChooseByHand;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<PlacementCubit>().state;
    return Scaffold(
      key: PlacementKeys.screen,
      // O resultado tem o próprio cabeçalho, que recolhe ao rolar.
      appBar: state.view == PlacementView.result
          ? null
          : LucenaAppBar(
              title: state.view == PlacementView.question
                  ? Text(
                      l10n.placementQuestionOf(state.number),
                      key: PlacementKeys.counter,
                    )
                  : Text(l10n.placementTitle),
              // Quanto do questionário já foi: uma barra contínua na base
              // da barra do app, que anda a cada resposta.
              bottom: state.view == PlacementView.question
                  ? AppBarProgress(
                      key: PlacementKeys.progress,
                      value: (state.number - 1) / 20,
                    )
                  : null,
            ),
      body: SafeArea(
        top: state.view != PlacementView.result,
        child: AnimatedSwitcher(
          duration: AppMotion.of(context).component,
          switchInCurve: AppMotion.enter,
          switchOutCurve: AppMotion.exit,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: switch (state.view) {
            PlacementView.loading => const SkeletonList(),
            PlacementView.intro => _Intro(
              key: const ValueKey('intro'),
              state: state,
              onChooseByHand: onChooseByHand,
            ),
            PlacementView.question => _Question(
              key: ValueKey('q${state.number}'),
              state: state,
              usefulHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.viewPaddingOf(context).vertical,
            ),
            PlacementView.result => PlacementResultView(
              key: const ValueKey('result'),
              state: state,
              onDone: onDone,
              onChooseByHand: onChooseByHand,
            ),
          },
        ),
      ),
    );
  }
}

/// A abertura: o Viktor explica, três selos e "Começar" (ou continuar).
class _Intro extends StatelessWidget {
  const _Intro({required this.state, this.onChooseByHand, super.key});

  final PlacementViewState state;
  final VoidCallback? onChooseByHand;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final cubit = context.read<PlacementCubit>();
    final viktor = state.viktor;
    final chips = [
      (Icons.format_list_numbered_rounded, l10n.placementChipQuestions),
      (Icons.schedule_rounded, l10n.placementChipMinutes),
      (Icons.timer_off_outlined, l10n.placementChipNoClock),
    ];
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: scrollPadding(
              context,
              // Canvas `PropV2TesteAbertura`: margem de 16, como o rodapé.
              left: AppSpacing.lg,
              top: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (viktor != null)
                  TeacherSpeech(
                    speechContext: SpeechContext.teaching,
                    teacher: viktor,
                    text: l10n.placementIntroSpeech,
                    emotion: Emotion.happy,
                    avatarSize: 56,
                    speaks: true,
                  ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    // CompChip informativo: cheio, sem contorno.
                    for (final (icon, label) in chips)
                      Chip(
                        avatar: Icon(icon, size: 18, color: colors.onSurface),
                        label: Text(label),
                        labelStyle: TextStyle(color: colors.onSurface),
                        backgroundColor: colors.surfaceContainer,
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Fixo no rodapé (Gabriel, 14/10/2026; canvas PropV2TesteAbertura): o
        // principal cheio na largura toda e a saída em texto logo abaixo.
        ColoredBox(
          key: PlacementKeys.footer,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.xs,
              children: [
                // Na retomada (canvas 0744f9e): onde o teste parou, centrado
                // acima do botão (4 de margem, mais o vão da coluna).
                if (state.resuming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      l10n.placementStoppedAt(
                        state.number,
                        PlacementState.questionCount,
                      ),
                      key: PlacementKeys.stoppedAt,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                FilledButton(
                  key: state.resuming
                      ? PlacementKeys.resume
                      : PlacementKeys.start,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(kButtonHeight),
                    textStyle: AppButtonText.footer(context),
                  ),
                  onPressed: cubit.start,
                  child: Text(
                    state.resuming ? l10n.placementResume : l10n.placementStart,
                  ),
                ),
                if (state.resuming)
                  TextButton(
                    key: PlacementKeys.restart,
                    style: _footerText,
                    onPressed: cubit.restart,
                    child: Text(l10n.placementRestart),
                  )
                else if (onChooseByHand != null)
                  TextButton(
                    key: PlacementKeys.chooseByHand,
                    style: _footerText,
                    onPressed: onChooseByHand,
                    child: Text(l10n.placementChooseByHand),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A saída em texto do rodapé da abertura: 40 de altura, largura toda.
final _footerText = TextButton.styleFrom(
  minimumSize: const Size.fromHeight(40),
);

/// Uma pergunta: enunciado no alto, tabuleiro centralizado na área entre
/// as barras do sistema e respostas no rodapé.
class _Question extends StatelessWidget {
  const _Question({required this.state, required this.usefulHeight, super.key});

  final PlacementViewState state;
  final double usefulHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<PlacementCubit>();
    final item = state.item;
    if (item == null) return const SizedBox.shrink();
    final prompt = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Text(
        placementPrompt(l10n, item),
        key: PlacementKeys.prompt,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        // A altura vem de fora do SafeArea, que remove o padding das barras
        // nos descendentes. O centro inclui o AppBar e as respostas.
        return CenteredBoardLayout(
          // Em retrato compacto aceita casas de 20 dp; em paisagem a
          // rolagem preserva um tabuleiro de 240 dp.
          minBoardSide: box.maxWidth.clamp(0, 480) / 2,
          centerY: box.maxHeight - usefulHeight / 2,
          gap: AppSpacing.md,
          reserveTop: _promptReserve,
          topAlignment: Alignment.topCenter,
          top: prompt,
          board: LayoutBuilder(
            builder: (context, box) => _Board(state: state, size: box.maxWidth),
          ),
          footer: Padding(
            key: PlacementKeys.answers,
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: _Answers(state: state, cubit: cubit),
          ),
        );
      },
    );
  }

  /// O espaço guardado para a pergunta: duas linhas.
  static const _promptReserve = 48.0;
}

class _Answers extends StatelessWidget {
  const _Answers({required this.state, required this.cubit});

  final PlacementViewState state;
  final PlacementCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = state.item!;
    final dontKnow = TextButton(
      key: PlacementKeys.dontKnow,
      onPressed: () => cubit.answer(PlacementOutcome.dontKnow),
      child: Text(l10n.placementDontKnow),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.type == PlacementItemType.choice)
            // As opções em grade, duas por linha; a que sobra sozinha ocupa
            // a linha inteira.
            for (var row = 0; row < item.options.length; row += 2) ...[
              if (row > 0) const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (final (index, option)
                      in item.options.skip(row).take(2).indexed) ...[
                    if (index > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _Option(option: option, cubit: cubit),
                    ),
                  ],
                ],
              ),
            ],
          if (item.type == PlacementItemType.squares)
            FilledButton(
              key: PlacementKeys.confirm,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kButtonHeight),
              ),
              onPressed: state.selected.isEmpty ? null : cubit.confirmSquares,
              child: Text(l10n.placementConfirm),
            ),
          const SizedBox(height: AppSpacing.xs),
          dontKnow,
        ],
      ),
    );
  }
}

/// Uma opção da pergunta de escolha: um cartão com borda, o texto no meio.
class _Option extends StatelessWidget {
  const _Option({required this.option, required this.cubit});

  final String option;
  final PlacementCubit cubit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return OutlinedButton(
      key: PlacementKeys.option(option),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(kButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        backgroundColor: colors.surfaceContainerLow,
        foregroundColor: colors.onSurface,
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.medium),
        ),
        textStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () => cubit.choose(option),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OptionBadge(option: option),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: OneLine(placementOption(context.l10n, option))),
        ],
      ),
    );
  }
}

/// O sinal de cada resposta: o da notação para xeque (+), mate (#) e
/// afogamento (=), a cor do lado que ganha, o aperto de mão do empate.
class _OptionBadge extends StatelessWidget {
  const _OptionBadge({required this.option});

  final String option;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = switch (option) {
      'check' => '+',
      'mate' => '#',
      'stalemate' => '=',
      'none' => '–',
      _ => null,
    };
    final icon = switch (option) {
      'yes' => Icons.thumb_up_alt_outlined,
      'no' => Icons.thumb_down_alt_outlined,
      'draw' => Icons.handshake_outlined,
      _ => null,
    };
    final side = switch (option) {
      'whiteWins' => AppColors.chessWhiteColor,
      'blackWins' => AppColors.chessBlackColor,
      _ => null,
    };
    // Só o sinal, sem fundo; o lado que ganha é uma bolinha da cor dele.
    if (side != null) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: side,
          border: Border.all(color: colors.outline),
        ),
      );
    }
    if (icon != null) return Icon(icon, size: 20, color: colors.primary);
    return Text(
      text ?? '',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: colors.primary,
      ),
    );
  }
}

/// O tabuleiro da pergunta: de jogar (lance), de tocar (casas) ou só de ver
/// (escolha).
class _Board extends StatefulWidget {
  const _Board({required this.state, required this.size});

  final PlacementViewState state;
  final double size;

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> {
  ChessboardController? _controller;
  String? _shown;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  GameData _game(PlacementViewState state) {
    final fen = state.fen ?? state.item!.fen;
    final position = GameRules.fromFen(fen);
    return GameData(
      fen: fen,
      playerSide: position == null
          ? PlayerSide.none
          : position.turn == Side.white
          ? PlayerSide.white
          : PlayerSide.black,
      sideToMove: position?.turn ?? Side.white,
      validMoves: position == null ? const {} : GameRules.legalMoves(position),
      lastMove: state.lastMove ?? _lastMoveOf(state.item!),
      kingSquareInCheck: position == null
          ? null
          : GameRules.checkedKing(position),
    );
  }

  static Move? _lastMoveOf(PlacementItem item) {
    final uci = item.lastMove;
    return uci == null ? null : Move.parse(uci);
  }

  // O lado de baixo: quem joga na posição da pergunta.
  Side _orientation(PlacementItem item) =>
      item.fen.split(' ').elementAtOrNull(1) == 'b' ? Side.black : Side.white;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final item = state.item!;
    final cubit = context.read<PlacementCubit>();
    final colors = Theme.of(context).colorScheme;
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final orientation = _orientation(item);
    // O tabuleiro não espelha em idiomas da direita para a esquerda.
    final Widget child;
    if (item.type == PlacementItemType.move) {
      final game = _game(state);
      final controller = _controller ??= ChessboardController(game: game);
      // Depois do lance (e da resposta), a posição nova.
      if (_shown != null && _shown != game.fen) {
        controller.updatePosition(game, resetPremove: true);
      }
      _shown = game.fen;
      child = Chessboard(
        key: PlacementKeys.board,
        size: widget.size,
        controller: controller,
        settings: board.chessground,
        orientation: orientation,
        onMove: (move, {viaDragAndDrop}) => cubit.play(move),
      );
    } else {
      child = StaticChessboard(
        key: PlacementKeys.board,
        size: widget.size,
        orientation: orientation,
        fen: item.fen,
        lastMove: _lastMoveOf(item),
        settings: StaticChessboardSettings(
          colorScheme: board.colors.scheme,
          pieceAssets: board.pieces.assets,
          // "Toque na casa a1": sem as letras e os números da borda, que
          // dariam a resposta.
          enableCoordinates:
              board.coordinates && item.prompt != 'placementTapSquare',
          borderRadius: const BorderRadius.all(Radius.circular(AppShape.small)),
        ),
        // As casas marcadas, num círculo da cor do tema.
        shapes: {
          for (final name in state.selected) ?_circle(name, colors.primary),
        },
        onTouchedSquare: item.type == PlacementItemType.squares
            ? (square) => cubit.toggleSquare(square.name)
            : null,
      );
    }
    return Directionality(textDirection: TextDirection.ltr, child: child);
  }

  static Shape? _circle(String name, Color color) {
    final square = Square.parse(name);
    return square == null ? null : Circle(color: color, orig: square);
  }
}
