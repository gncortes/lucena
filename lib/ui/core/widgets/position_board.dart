import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../board/board_settings_ui.dart';

/// A miniatura de uma posição (FEN), vista pelo lado que joga, com as cores
/// e as peças escolhidas pelo jogador.
class PositionBoard extends StatelessWidget {
  const PositionBoard({
    required this.fen,
    required this.size,
    this.coordinates = false,
    this.radius = 6,
    super.key,
  });

  final String fen;
  final double size;
  final bool coordinates;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final turn = fen.split(' ')[1] == 'b' ? Side.black : Side.white;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: StaticChessboard(
        size: size,
        orientation: turn,
        fen: fen,
        settings: StaticChessboardSettings(
          colorScheme: board.colors.scheme,
          pieceAssets: board.pieces.assets,
          enableCoordinates: coordinates && board.coordinates,
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          animationDuration: Duration.zero,
        ),
      ),
    );
  }
}
