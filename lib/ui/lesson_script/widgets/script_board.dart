import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/lesson_script.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/lesson_script_keys.dart';
import '../../core/theme/app_motion.dart';
import '../view_models/lesson_script_state.dart';
import 'board_coordinates.dart';

/// As cores das setas e das marcas do professor (protótipo T70: verde
/// `0xcc15781b` como as marcas de `lesson_screen.dart`, azul = primária a 75%
/// e vermelho = erro `0xccc62828` como em `exercise_screen.dart`).
abstract final class ScriptShapes {
  static const green = Color(0xcc15781b);
  static const red = Color(0xccc62828);

  static Color arrow(ColorScheme colors, String code) => switch (code) {
    'r' => red,
    'b' => colors.primary.withValues(alpha: 0.75),
    _ => green,
  };
}

/// O tabuleiro da lição roteirizada: mostra a posição do estado, anima o que
/// a [LessonScriptState.transition] pede (lance, lances rápidos, posição nova
/// em crossfade, volta) e só desenha setas e marcas quando a peça já chegou.
///
/// Posição nova que não vem de lance (exemplo, parte, demonstração, troca de
/// lado, voltar ao início) é sempre [TransitionKind.jump] ou uma troca de
/// orientação: o tabuleiro de antes se dissolve direto no novo, sem vão vazio
/// nem giro (Gabriel, 14/10/2026). Lance da mesma linha desliza a peça.
class ScriptBoard extends StatefulWidget {
  const ScriptBoard({
    required this.state,
    required this.size,
    required this.settings,
    required this.onMove,
    this.onSquare,
    this.showMarks = true,
    super.key,
  });

  /// O tempo de cada lance rápido (`seq`) e do crossfade da posição nova.
  static const seqStep = AppMotion.component;
  static const fade = AppMotion.component;

  /// O tempo até as setas aparecerem depois de um lance (o lance mais 120 ms de respiro; protótipo, 420 ms).
  static final shapesDelay = Duration(
    microseconds: AppMotion.component.inMicroseconds + 120000,
  );

  final LessonScriptState state;
  final double size;
  final BoardSettings settings;
  final ValueChanged<String> onMove;

  /// Toque numa casa (qualquer uma, até vazia) na prática do tipo toque.
  final ValueChanged<String>? onSquare;

  /// A preferência do botão ao lado do som: sem ela, nem setas nem círculos.
  final bool showMarks;

  @override
  State<ScriptBoard> createState() => _ScriptBoardState();
}

class _ScriptBoardState extends State<ScriptBoard> {
  late final ChessboardController _controller;
  int _run = 0;
  bool _busy = false;
  bool _shapes = true;
  Side _orientation = Side.white;

  /// As marcas desenhadas no último quadro (o crossfade as leva junto).
  Set<Shape> _drawn = const {};

  /// O tabuleiro de antes, por cima do novo, enquanto se dissolve.
  StaticChessboard? _ghost;
  int _ghostId = 0;

  @override
  void initState() {
    super.initState();
    _orientation = widget.state.orientation;
    _controller = ChessboardController(game: _data(widget.state.fen));
  }

  @override
  void dispose() {
    _run++;
    _controller.dispose();
    super.dispose();
  }

  GameData _data(String fen, {bool interactive = true, String? last}) {
    final position = GameRules.fromFen(fen);
    final movable = widget.state.movable;
    // Os destinos vêm do estado: nas posições sem rei (curso de iniciante) o
    // FEN não vira posição de xadrez e as regras não dão os lances.
    final dests =
        widget.state.dests ??
        (position == null ? null : GameRules.legalMoves(position));
    final live = interactive && dests != null && movable != null;
    return GameData(
      fen: fen,
      playerSide: !live
          ? PlayerSide.none
          : movable == Side.white
          ? PlayerSide.white
          : PlayerSide.black,
      sideToMove:
          position?.turn ?? (fen.contains(' b') ? Side.black : Side.white),
      validMoves: live ? dests : const {},
      lastMove: last == null ? null : Move.parse(last),
      kingSquareInCheck: position == null
          ? null
          : GameRules.checkedKing(position),
    );
  }

  @override
  void didUpdateWidget(ScriptBoard old) {
    super.didUpdateWidget(old);
    final s = widget.state;
    final flipping = s.orientation != old.state.orientation;
    final moved =
        s.transition.id != old.state.transition.id || s.fen != old.state.fen;
    if (flipping || (moved && s.transition.kind == TransitionKind.jump)) {
      _crossfade();
      _orientation = s.orientation;
    }
    if (moved) {
      unawaited(_apply(s));
    } else if (!_busy) {
      _controller.updatePosition(
        _data(s.fen, last: s.lastMove),
        animate: false,
        resetPremove: true,
      );
    }
  }

  /// A posição depois de [ucis] a partir de [fen]: uma por lance.
  List<String> _fens(String fen, List<String> ucis) {
    final out = <String>[];
    var position = GameRules.fromFen(fen);
    if (position == null) return _bareFens(fen, ucis);
    for (final uci in ucis) {
      final move = Move.parse(uci);
      if (position == null || move == null || !position.isLegal(move)) break;
      position = position.play(move);
      out.add(position.fen);
    }
    return out;
  }

  /// [_fens] sem rei: a peça só muda de casa no tabuleiro do FEN (o resto
  /// do FEN fica igual, como no estado da lição).
  List<String> _bareFens(String fen, List<String> ucis) {
    final out = <String>[];
    final space = fen.indexOf(' ');
    final rest = space < 0 ? '' : fen.substring(space);
    Board board;
    try {
      board = Board.parseFen(space < 0 ? fen : fen.substring(0, space));
    } on FenException {
      return out;
    }
    for (final uci in ucis) {
      final move = Move.parse(uci);
      if (move is! NormalMove) break;
      final piece = board.pieceAt(move.from);
      if (piece == null) break;
      final promoted = move.promotion == null
          ? piece
          : Piece(color: piece.color, role: move.promotion!);
      board = board.removePieceAt(move.from).setPieceAt(move.to, promoted);
      out.add('${board.fen}$rest');
    }
    return out;
  }

  bool _alive(int run) => mounted && run == _run;

  /// Põe por cima uma cópia fixa do que está na tela, que se dissolve no
  /// tabuleiro novo embaixo (sem movimento reduzido, troca seca).
  void _crossfade() {
    if (AppMotion.reduced(context)) return;
    final game = _controller.game;
    _ghostId++;
    _ghost = StaticChessboard(
      size: widget.size,
      orientation: _orientation,
      fen: game.fen,
      lastMove: game.lastMove,
      shapes: _drawn,
      settings: StaticChessboardSettings.fromBoardSettings(_boardSettings),
    );
  }

  Future<void> _wait(Duration duration) => Future<void>.delayed(duration);

  Future<void> _apply(LessonScriptState s) async {
    final run = ++_run;
    final t = s.transition;
    final from = t.fromFen;
    switch (t.kind) {
      case TransitionKind.none:
        _busy = false;
        _controller.updatePosition(
          _data(s.fen, last: s.lastMove),
          animate: false,
          resetPremove: true,
        );
        setState(() => _shapes = true);
      case TransitionKind.move || TransitionKind.back:
        _controller.updatePosition(
          _data(s.fen, interactive: false, last: s.lastMove),
          animate: true,
          resetPremove: true,
        );
        await _finish(run, s, ScriptBoard.shapesDelay);
      case TransitionKind.seq:
        await _play(run, s, from ?? s.fen, t.ucis, fade: false);
      case TransitionKind.jump:
        // A posição nova entra já embaixo da cópia que se dissolve.
        final start = t.ucis.isEmpty ? s.fen : (from ?? s.fen);
        setState(() {
          _busy = true;
          _shapes = false;
        });
        _controller.updatePosition(
          _data(start, interactive: false),
          animate: false,
          resetPremove: true,
        );
        if (t.ucis.isEmpty) {
          await _finish(run, s, ScriptBoard.fade);
        } else {
          await _wait(ScriptBoard.fade);
          if (!_alive(run)) return;
          await _play(run, s, start, t.ucis, fade: true);
        }
    }
  }

  Future<void> _play(
    int run,
    LessonScriptState s,
    String start,
    List<String> ucis, {
    required bool fade,
  }) async {
    setState(() {
      _busy = true;
      _shapes = false;
    });
    if (!fade) {
      _controller.updatePosition(
        _data(start, interactive: false),
        animate: false,
        resetPremove: true,
      );
    }
    final fens = _fens(start, ucis);
    for (final fen in fens) {
      await _wait(ScriptBoard.seqStep);
      if (!_alive(run)) return;
      _controller.updatePosition(
        _data(fen, interactive: false),
        animate: true,
        resetPremove: true,
      );
    }
    await _finish(run, s, ScriptBoard.seqStep);
  }

  /// Espera a peça chegar e põe a posição final (com toque) e as marcas.
  Future<void> _finish(int run, LessonScriptState s, Duration wait) async {
    setState(() {
      _busy = true;
      _shapes = false;
    });
    await _wait(wait);
    if (!_alive(run)) return;
    _controller.updatePosition(
      _data(s.fen, last: s.lastMove),
      animate: false,
      resetPremove: true,
    );
    setState(() {
      _busy = false;
      _shapes = true;
    });
  }

  Set<Shape> _shapeSet(ColorScheme colors) {
    final s = widget.state;
    // As casas da prática de toque: a resposta ao clique, não uma marca do
    // professor (aparecem mesmo com as marcas desligadas).
    final touch = {
      for (final square in s.touched)
        Circle(color: ScriptShapes.green, orig: Square.fromName(square)),
      if (s.touchMiss case final miss?)
        Circle(color: ScriptShapes.red, orig: Square.fromName(miss)),
    };
    if (!_shapes || !widget.showMarks) return touch;
    return {
      ...touch,
      for (final ScriptArrow arrow in s.arrows)
        Arrow(
          color: ScriptShapes.arrow(colors, arrow.color),
          orig: Square.fromName(arrow.from),
          dest: Square.fromName(arrow.to),
        ),
      for (final mark in s.marks)
        Circle(color: ScriptShapes.green, orig: Square.fromName(mark)),
    };
  }

  /// As coordenadas: a prática de toque pode escondê-las (`coordenadas`
  /// falso) ou mostrá-las enquanto o aluno procura a casa; fora dela, vale a
  /// preferência do aluno.
  ChessboardSettings get _boardSettings {
    final base = widget.settings.chessground;
    final s = widget.state;
    if (!s.coordinates) return base.copyWith(enableCoordinates: false);
    if (s.touching) return base.copyWith(enableCoordinates: true);
    return base;
  }

  @override
  Widget build(BuildContext context) {
    _drawn = _shapeSet(Theme.of(context).colorScheme);
    final ghost = _ghost;
    final settings = _boardSettings;
    // As coordenadas na casa vão por cima das marcações (canvas
    // `T71-360-propostas`, 3B); na borda, ficam com o chessground.
    final coordinates = settings.enableCoordinates && settings.border == null;
    // O tabuleiro não espelha em idiomas da direita para a esquerda.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Chessboard(
            key: LessonScriptKeys.board,
            size: widget.size,
            controller: _controller,
            settings: coordinates
                ? settings.copyWith(enableCoordinates: false)
                : settings,
            orientation: _orientation,
            shapes: _drawn,
            onMove: (move, {viaDragAndDrop}) => widget.onMove(move.uci),
            onTouchedSquare: widget.state.touching && widget.onSquare != null
                ? (square) => widget.onSquare!(square.name)
                : null,
          ),
          if (ghost != null)
            Positioned.fill(
              child: IgnorePointer(
                key: LessonScriptKeys.crossfade,
                child: TweenAnimationBuilder<double>(
                  // Cópia nova, animação nova (troca antes do fim recomeça).
                  key: ValueKey(_ghostId),
                  tween: Tween(begin: 1, end: 0),
                  duration: ScriptBoard.fade,
                  onEnd: () => setState(() => _ghost = null),
                  builder: (_, opacity, child) =>
                      Opacity(opacity: opacity, child: child),
                  child: ghost,
                ),
              ),
            ),
          if (coordinates)
            Positioned.fill(
              child: BoardCoordinates(
                key: LessonScriptKeys.coordinates,
                orientation: _orientation,
                settings: settings,
              ),
            ),
        ],
      ),
    );
  }
}
