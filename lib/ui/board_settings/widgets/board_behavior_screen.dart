import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/board_settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/choice_sheet.dart';
import '../../core/widgets/figurine.dart';
import '../../settings/view_models/settings_cubit.dart';

/// Como o tabuleiro reage: jeito de mover, ajudas visuais, pré-lances e
/// notação da lista de lances.
class BoardBehaviorScreen extends StatelessWidget {
  const BoardBehaviorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    return Scaffold(
      key: BoardSettingsKeys.behaviorScreen,
      appBar: AppBar(title: Text(l10n.settingsBoardBehavior)),
      body: ListView(
        children: [
          ListTile(
            key: BoardSettingsKeys.moveMethodTile,
            leading: Icon(board.moveMethod.icon),
            title: Text(l10n.boardMoveMethod),
            subtitle: Text(
              board.moveMethod.label(l10n),
              key: BoardSettingsKeys.moveMethodValue,
            ),
            trailing: const Icon(Icons.expand_more),
            onTap: () => _pickMoveMethod(context, board),
          ),
          SwitchListTile(
            key: BoardSettingsKeys.legalMovesSwitch,
            secondary: const Icon(Icons.adjust),
            title: Text(l10n.boardShowLegalMoves),
            value: board.showLegalMoves,
            onChanged: (value) =>
                cubit.setBoard(board.copyWith(showLegalMoves: value)),
          ),
          SwitchListTile(
            key: BoardSettingsKeys.lastMoveSwitch,
            secondary: const Icon(Icons.highlight_alt),
            title: Text(l10n.boardHighlightLastMove),
            value: board.highlightLastMove,
            onChanged: (value) =>
                cubit.setBoard(board.copyWith(highlightLastMove: value)),
          ),
          SwitchListTile(
            key: BoardSettingsKeys.animationSwitch,
            secondary: const Icon(Icons.animation),
            title: Text(l10n.boardAnimation),
            value: board.animation,
            onChanged: (value) =>
                cubit.setBoard(board.copyWith(animation: value)),
          ),
          SwitchListTile(
            key: BoardSettingsKeys.premovesSwitch,
            secondary: const Icon(Icons.fast_forward_outlined),
            title: Text(l10n.boardPremoves),
            subtitle: Text(l10n.boardPremovesHint),
            value: board.premoves,
            onChanged: (value) =>
                cubit.setBoard(board.copyWith(premoves: value)),
          ),
          ListTile(
            key: BoardSettingsKeys.notationTile,
            leading: const Icon(Icons.format_list_numbered),
            title: Text(l10n.boardNotation),
            subtitle: Text(
              board.notation.label(l10n),
              key: BoardSettingsKeys.notationValue,
            ),
            trailing: const Icon(Icons.expand_more),
            onTap: () => _pickNotation(context, board),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMoveMethod(
    BuildContext context,
    BoardSettings board,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    final picked = await showChoiceSheet<MoveMethod>(
      context,
      title: l10n.boardMoveMethod,
      selected: board.moveMethod,
      confirmLabel: l10n.commonConfirm,
      sheetKey: BoardSettingsKeys.choiceSheet,
      confirmKey: BoardSettingsKeys.choiceConfirmButton,
      options: [
        for (final method in MoveMethod.values)
          ChoiceSheetOption(
            value: method,
            label: method.label(l10n),
            icon: method.icon,
            key: BoardSettingsKeys.moveMethodOption(method),
          ),
      ],
    );
    if (picked == null) return;
    // O estado pode ter mudado enquanto o painel estava aberto.
    final current = cubit.state?.board ?? board;
    await cubit.setBoard(current.copyWith(moveMethod: picked));
  }

  Future<void> _pickNotation(BuildContext context, BoardSettings board) async {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    final picked = await showChoiceSheet<MoveNotation>(
      context,
      title: l10n.boardNotation,
      selected: board.notation,
      confirmLabel: l10n.commonConfirm,
      sheetKey: BoardSettingsKeys.choiceSheet,
      confirmKey: BoardSettingsKeys.choiceConfirmButton,
      options: [
        ChoiceSheetOption(
          value: MoveNotation.figurine,
          label: MoveNotation.figurine.label(l10n),
          // O mesmo exemplo nas duas opções: cavalo para f3, bispo para c4.
          description: _example(Figurine.ofLetter),
          descriptionStyle: const TextStyle(fontFamily: Figurine.fontFamily),
          key: BoardSettingsKeys.notationOption(MoveNotation.figurine),
        ),
        ChoiceSheetOption(
          value: MoveNotation.letters,
          label: MoveNotation.letters.label(l10n),
          description: _example(MoveNotation.letters.pieceLetters(l10n)!),
          key: BoardSettingsKeys.notationOption(MoveNotation.letters),
        ),
      ],
    );
    if (picked == null) return;
    final current = cubit.state?.board ?? board;
    await cubit.setBoard(current.copyWith(notation: picked));
  }

  // A notação de xadrez é sempre da esquerda para a direita: a marca de
  // direção segura a ordem em idiomas da direita para a esquerda.
  String _example(Map<String, String> letters) =>
      '‎${letters['N']}f3  ${letters['B']}c4  ${letters['Q']}xf7';
}
