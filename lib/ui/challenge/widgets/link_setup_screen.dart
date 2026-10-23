import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/board_settings.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_appearance_widgets.dart';
import '../../core/keys/challenge_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/section_title.dart';
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
    final theme = Theme.of(context);
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  l10n.challengeSetupHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: BoardPreview(
                  boardKey: ChallengeKeys.setupPreview,
                  size: 216,
                  fen: fen,
                  board: board.copyWith(coordinates: false),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SectionTitle(l10n.boardColors),
              BoardColorsCarousel(
                selected: board.colors,
                keyOf: ChallengeKeys.setupColors,
                onSelected: (colors) =>
                    settings.setBoard(board.copyWith(colors: colors)),
              ),
              SectionTitle(l10n.boardPieces),
              PieceStyleCarousel(
                selected: board.pieces,
                colors: board.colors,
                keyOf: ChallengeKeys.setupPieces,
                onSelected: (pieces) =>
                    settings.setBoard(board.copyWith(pieces: pieces)),
              ),
              SwitchListTile(
                key: ChallengeKeys.setupSound,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                secondary: const Icon(Icons.volume_up_outlined),
                title: Text(l10n.challengeSetupSound),
                value: sound,
                onChanged: (value) => settings.setSound(enabled: value),
              ),
            ],
          ),
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
