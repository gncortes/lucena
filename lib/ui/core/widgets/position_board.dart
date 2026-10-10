import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../board/board_settings_ui.dart';
import '../theme/app_motion.dart';

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
    this.lastMove,
    this.boardKey,
    super.key,
  });

  /// O lance em destaque.
  final Move? lastMove;

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
        // As duas pontas do voo, na ordem das telas: a de baixo (de onde o
        // tabuleiro sai ao abrir a tela nova) e a de cima. A animação é a da
        // tela de cima: vai de 0 a 1 ao abrir e volta de 1 a 0 ao fechar.
        final push = direction == HeroFlightDirection.push;
        final below = BoardHeroFrame.of(push ? from : to);
        final above = BoardHeroFrame.of(push ? to : from);
        final mine = _side;
        final belowSide = below?.orientation ?? mine;
        final aboveSide = above?.orientation ?? mine;
        // A outra ponta pode ser um tabuleiro de jogar (sem moldura): cantos
        // retos.
        final belowRadius = below?.radius ?? 0;
        final aboveRadius = above?.radius ?? 0;
        // O voo já vem numa curva suave (acelera e freia).
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            // Os cantos vão do tamanho de uma ponta ao da outra, e uma sombra
            // leve aparece no meio do voo.
            final radius = belowRadius + (aboveRadius - belowRadius) * t;
            final lift = math.sin(math.pi * t) * 12;
            // Se as pontas olham de lados diferentes (o editor é sempre das
            // brancas), o tabuleiro vira no ar como uma carta: de lado, no
            // meio do voo, troca a orientação. Nada salta nem pisca.
            final flip = belowSide == aboveSide
                ? null
                : AppMotion.move.transform(t);
            final side = flip == null || flip < 0.5 ? belowSide : aboveSide;
            return LayoutBuilder(
              builder: (context, box) {
                final flying = PhysicalModel(
                  color: Colors.transparent,
                  elevation: lift,
                  borderRadius: BorderRadius.circular(radius),
                  child: _board(
                    context,
                    box.maxWidth,
                    radius,
                    flying: true,
                    side: side,
                  ),
                );
                if (flip == null) return flying;
                final angle = math.pi * (flip < 0.5 ? flip : flip - 1);
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, _perspective)
                    ..rotateX(angle),
                  child: flying,
                );
              },
            );
          },
        );
      },
      child: board,
    );
  }

  /// A profundidade da virada no ar.
  static const _perspective = 0.0015;

  /// O lado de baixo deste tabuleiro.
  Side get _side =>
      orientation ?? (fen.split(' ')[1] == 'b' ? Side.black : Side.white);

  Widget _board(
    BuildContext context,
    double size,
    double radius, {
    bool flying = false,
    Side? side,
  }) {
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final child = Directionality(
      textDirection: TextDirection.ltr,
      child: StaticChessboard(
        key: flying ? null : boardKey,
        size: size,
        orientation: side ?? _side,
        fen: fen,
        lastMove: lastMove,
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
    return BoardHeroFrame(radius: radius, orientation: _side, child: child);
  }
}

/// O filho do Hero de um tabuleiro: guarda o raio dos cantos e o lado de
/// baixo, para o voo interpolar os cantos e virar o tabuleiro quando as
/// pontas olham de lados diferentes. Também serve a tabuleiros que não são
/// [PositionBoard], como o do editor de posição.
class BoardHeroFrame extends StatelessWidget {
  const BoardHeroFrame({
    required this.radius,
    required this.orientation,
    required this.child,
    super.key,
  });

  final double radius;
  final Side orientation;
  final Widget child;

  /// A moldura da ponta [hero] do voo, se o filho do Hero for uma.
  static BoardHeroFrame? of(BuildContext hero) {
    final child = (hero.widget as Hero).child;
    return child is BoardHeroFrame ? child : null;
  }

  @override
  Widget build(BuildContext context) => child;
}
