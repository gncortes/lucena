import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/models/board_settings.dart';
import '../../../../domain/models/star_challenge.dart';
import '../../../school/widgets/star_shape.dart';
import '../../../settings/view_models/settings_cubit.dart';
import '../../board/board_settings_ui.dart';
import '../../keys/training_keys.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';

/// Completed challenge levels, rather than historical best points.
class PieceStarsRow extends StatelessWidget {
  const PieceStarsRow({required this.piece, required this.completed, super.key})
    : assert(completed >= 0 && completed <= 3);

  final ChallengePiece piece;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final label = switch (piece) {
      ChallengePiece.rook => t.pieceRook,
      ChallengePiece.bishop => t.pieceBishop,
      ChallengePiece.knight => t.pieceKnight,
      ChallengePiece.queen => t.pieceQueen,
      ChallengePiece.king => t.pieceKing,
      ChallengePiece.pawn => t.piecePawn,
    };
    final board = context
        .select(
          (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
        )
        .chessground;
    return Semantics(
      key: TrainingKeys.pieceStars(piece.name),
      label: label,
      value: t.trainingCount(3, completed),
      excludeSemantics: true,
      child: Row(
        spacing: 8,
        children: [
          Image(
            image: board
                .pieceAssets[Piece(color: Side.white, role: piece.role).kind]!,
            width: 24,
            height: 24,
          ),
          Expanded(child: Text(label)),
          for (var level = 1; level <= 3; level++)
            SizedBox(
              width: 20,
              height: 20,
              child: StarShape(
                outlined: level > completed,
                color: level <= completed
                    ? AppColors.goldColor
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}
