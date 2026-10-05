import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../board/board_settings_ui.dart';

/// A miniatura de uma posição (FEN), vista pelo lado que joga (ou pelo
/// [orientation] pedido), com as cores e as peças escolhidas pelo jogador.
class PositionBoard extends StatelessWidget {
  const PositionBoard({
    required this.fen,
    required this.size,
    this.orientation,
    this.coordinates = false,
    this.radius = 6,
    this.heroTag,
    this.boardKey,
    super.key,
  });

  /// Com a marca, o tabuleiro voa (e cresce) até o de mesma marca na tela
  /// seguinte.
  final Object? heroTag;

  /// A chave do tabuleiro em si (o `StaticChessboard`), para os testes lerem
  /// a orientação. Fica fora do voo.
  final Key? boardKey;

  final String fen;
  final double size;

  /// O lado de baixo. Sem ele, o lado que joga na posição.
  final Side? orientation;
  final bool coordinates;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final board = _board(context, size, radius);
    final tag = heroTag;
    if (tag == null) return board;
    return Hero(
      tag: tag,
      flightShuttleBuilder: (context, animation, direction, from, to) {
        final fromBoard = from.widget as Hero;
        final toBoard = to.widget as Hero;
        final start = (fromBoard.child as _BoardFrame).radius;
        final finish = (toBoard.child as _BoardFrame).radius;
        // O voo já vem numa curva suave (acelera e freia).
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            // Os cantos vão do tamanho de partida ao de chegada, e uma sombra
            // leve aparece no meio do voo.
            final radius = start + (finish - start) * t;
            final lift = math.sin(math.pi * t) * 12;
            return LayoutBuilder(
              builder: (context, box) => PhysicalModel(
                color: Colors.transparent,
                elevation: lift,
                borderRadius: BorderRadius.circular(radius),
                child: _board(context, box.maxWidth, radius, flying: true),
              ),
            );
          },
        );
      },
      child: board,
    );
  }

  Widget _board(
    BuildContext context,
    double size,
    double radius, {
    bool flying = false,
  }) {
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final turn = fen.split(' ')[1] == 'b' ? Side.black : Side.white;
    final child = Directionality(
      textDirection: TextDirection.ltr,
      child: StaticChessboard(
        key: flying ? null : boardKey,
        size: size,
        orientation: orientation ?? turn,
        fen: fen,
        settings: StaticChessboardSettings(
          colorScheme: board.colors.scheme,
          pieceAssets: board.pieces.assets,
          // As coordenadas só depois do pouso.
          enableCoordinates: !flying && coordinates && board.coordinates,
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          animationDuration: Duration.zero,
        ),
      ),
    );
    return _BoardFrame(radius: radius, child: child);
  }
}

/// Guarda o raio dos cantos do tabuleiro, para o voo interpolar entre o de
/// partida e o de chegada.
class _BoardFrame extends StatelessWidget {
  const _BoardFrame({required this.radius, required this.child});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
