import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../core/board/board_appearance_widgets.dart';
import '../../core/keys/board_settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../settings/view_models/settings_cubit.dart';

/// Cores, peças e coordenadas do tabuleiro, com uma amostra que muda na hora.
class BoardAppearanceScreen extends StatelessWidget {
  const BoardAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    return Scaffold(
      key: BoardSettingsKeys.appearanceScreen,
      appBar: AppBar(title: Text(l10n.settingsBoardAppearance)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // A amostra fica fixa no alto; as opções rolam embaixo dela.
            final previewSize = math.min(
              constraints.maxWidth - 48,
              constraints.maxHeight * 0.42,
            );
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: BoardPreview(
                    boardKey: BoardSettingsKeys.preview,
                    size: previewSize,
                    board: board,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      AppearanceSectionTitle(l10n.boardColors),
                      BoardColorsCarousel(
                        selected: board.colors,
                        keyOf: BoardSettingsKeys.colorsOption,
                        onSelected: (colors) =>
                            cubit.setBoard(board.copyWith(colors: colors)),
                      ),
                      AppearanceSectionTitle(l10n.boardPieces),
                      PieceStyleCarousel(
                        selected: board.pieces,
                        colors: board.colors,
                        keyOf: BoardSettingsKeys.piecesOption,
                        onSelected: (pieces) =>
                            cubit.setBoard(board.copyWith(pieces: pieces)),
                      ),
                      SwitchListTile(
                        key: BoardSettingsKeys.coordinatesSwitch,
                        secondary: const Icon(Icons.grid_on_outlined),
                        title: Text(l10n.boardCoordinates),
                        value: board.coordinates,
                        onChanged: (value) =>
                            cubit.setBoard(board.copyWith(coordinates: value)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: OutlinedButton.icon(
                          key: BoardSettingsKeys.resetButton,
                          icon: const Icon(Icons.restart_alt),
                          label: Text(l10n.boardRestoreDefault),
                          onPressed: cubit.resetBoardAppearance,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
