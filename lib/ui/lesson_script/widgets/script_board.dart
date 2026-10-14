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
/// a [LessonScriptState.transition] pede (lance, lances rápidos, corte com
/// esmaecer, volta) e só desenha setas e marcas quando a peça já chegou.
class ScriptBoard extends StatefulWidget {
  const ScriptBoard({
    required this.state,
    required this.size,
    required this.settings,
    required this.onMove,
    this.showMarks = true,
    super.key,
  });

  /// O tempo de cada lance rápido (`seq`) e do esmaecer do corte.
  static const seqStep = AppMotion.component;
  static const fade = AppMotion.state;

  /// O giro do tabuleiro quando o aluno troca de lado.
  static const flip = AppMotion.screen;

  /// O tempo até as setas aparecerem depois de um lance (o lance mais 120 ms de respiro; protótipo, 420 ms).
  static final shapesDelay = Duration(
    microseconds: AppMotion.component.inMicroseconds + 120000,
  );

  final LessonScriptState state;
  final double size;
  final BoardSettings settings;
  final ValueChanged<String> onMove;

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
  double _opacity = 1;
  Side _orientation = Side.white;

  /// Meia volta enquanto o tabuleiro gira; no fim, a orientação troca e o
  /// giro volta a zero sem animar (as peças ficam de pé).
  double _turns = 0;
  bool _spinning = false;

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
    final live = interactive && position != null && movable != null;
    return GameData(
      fen: fen,
      playerSide: !live
          ? PlayerSide.none
          : movable == Side.white
          ? PlayerSide.white
          : PlayerSide.black,
      sideToMove: position?.turn ?? Side.white,
      validMoves: live ? GameRules.legalMoves(position) : const {},
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
    if (flipping) unawaited(_flip(s.orientation));
    if (s.transition.id != old.state.transition.id || s.fen != old.state.fen) {
      unawaited(_apply(s, flipping: flipping));
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
    for (final uci in ucis) {
      final move = Move.parse(uci);
      if (position == null || move == null || !position.isLegal(move)) break;
      position = position.play(move);
      out.add(position.fen);
    }
    return out;
  }

  bool _alive(int run) => mounted && run == _run;

  Future<void> _flip(Side side) async {
    if (AppMotion.reduced(context)) {
      setState(() => _orientation = side);
      return;
    }
    setState(() {
      _spinning = true;
      _turns = 0.5;
    });
    await _wait(ScriptBoard.flip);
    if (!mounted || widget.state.orientation != side) return;
    setState(() {
      _spinning = false;
      _turns = 0;
      _orientation = side;
    });
  }

  Future<void> _wait(Duration duration) => Future<void>.delayed(duration);

  Future<void> _apply(LessonScriptState s, {bool flipping = false}) async {
    final run = ++_run;
    final t = s.transition;
    final from = t.fromFen;
    // A troca de lado é a meia-volta à vista (E7d, E12d2): a posição nova
    // entra de uma vez e gira, sem esmaecer (Gabriel, 14/10/2026).
    if (flipping && t.kind == TransitionKind.jump) {
      final start = t.ucis.isEmpty ? s.fen : (from ?? s.fen);
      setState(() {
        _busy = true;
        _shapes = false;
        _opacity = 1;
      });
      _controller.updatePosition(
        _data(start, interactive: false),
        animate: false,
        resetPremove: true,
      );
      if (t.ucis.isEmpty) {
        await _finish(run, s, ScriptBoard.flip);
      } else {
        await _wait(ScriptBoard.flip);
        if (!_alive(run)) return;
        await _play(run, s, start, t.ucis, fade: true);
      }
      return;
    }
    switch (t.kind) {
      case TransitionKind.none:
        _busy = false;
        _controller.updatePosition(
          _data(s.fen, last: s.lastMove),
          animate: false,
          resetPremove: true,
        );
        setState(() {
          _shapes = true;
          _opacity = 1;
        });
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
        setState(() {
          _busy = true;
          _shapes = false;
          _opacity = 0;
        });
        await _wait(ScriptBoard.fade);
        if (!_alive(run)) return;
        final start = t.ucis.isEmpty ? s.fen : (from ?? s.fen);
        _controller.updatePosition(
          _data(start, interactive: false),
          animate: false,
          resetPremove: true,
        );
        setState(() => _opacity = 1);
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
    if (!_shapes || !widget.showMarks) return const {};
    return {
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedRotation(
      turns: _turns,
      duration: _spinning ? ScriptBoard.flip : Duration.zero,
      curve: AppMotion.move,
      child: _faded(colors),
    );
  }

  Widget _faded(ColorScheme colors) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: ScriptBoard.fade,
      // O tabuleiro não espelha em idiomas da direita para a esquerda.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Chessboard(
          key: LessonScriptKeys.board,
          size: widget.size,
          controller: _controller,
          settings: widget.settings.chessground,
          orientation: _orientation,
          shapes: _shapeSet(colors),
          onMove: (move, {viaDragAndDrop}) => widget.onMove(move.uci),
        ),
      ),
    );
  }
}
