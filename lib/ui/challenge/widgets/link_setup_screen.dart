import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena_ui/lucena_ui.dart';
import 'package:lucena_ui/lucena_ui_board.dart';

import '../../../domain/models/board_settings.dart';
import '../../../routing/routes.dart';
import '../../core/keys/challenge_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/link_setup_cubit.dart';

/// O "Antes do desafio" (canvas `PropV1LinkMiniSetup`): a única tela da
/// primeira abertura por link. Cores e peças do tabuleiro e o som das peças;
/// o resto (voz, nome, tour) fica para depois. [next] é onde o desafio abre.
class LinkSetupScreen extends StatelessWidget {
  const LinkSetupScreen({required this.next, this.fen, super.key});

  /// O endereço do desafio, que substitui esta tela quando ela termina.
  final String next;

  /// A posição do desafio, na miniatura. Sem ela, a posição de amostra.
  final String? fen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.read<SettingsCubit>();
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final sound = context.select((SettingsCubit c) => c.state?.sound ?? true);
    return BlocListener<LinkSetupCubit, bool>(
      listenWhen: (previous, current) => current && !previous,
      listener: (context, _) => context.pushReplacement(next),
      child: Scaffold(
        key: ChallengeKeys.setupScreen,
        appBar: LucenaAppBar(
          title: Text(l10n.challengeSetupTitle),
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: ChallengeKeys.setupClose,
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => context.go(Routes.home),
          ),
        ),
        body: LinkSetupForm(
          hint: l10n.challengeSetupHint,
          fen: fen,
          appearance: board.appearance,
          animated: board.animation,
          previewKey: ChallengeKeys.setupPreview,
          colorsTitle: l10n.boardColors,
          piecesTitle: l10n.boardPieces,
          colorLabelOf: (colors) => colors.label(l10n),
          colorKeyOf: ChallengeKeys.setupColors,
          pieceKeyOf: ChallengeKeys.setupPieces,
          onColors: (colors) =>
              settings.setBoard(board.copyWith(colors: colors)),
          onPieces: (pieces) =>
              settings.setBoard(board.copyWith(pieces: pieces)),
          soundKey: ChallengeKeys.setupSound,
          soundTitle: l10n.challengeSetupSound,
          sound: sound,
          onSound: (value) => settings.setSound(enabled: value),
        ),
        bottomNavigationBar: ActionsFooter(
          children: [
            FilledButton.icon(
              key: ChallengeKeys.setupPlay,
              onPressed: context.read<LinkSetupCubit>().finish,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.challengeSetupPlay),
            ),
          ],
        ),
      ),
    );
  }
}
