import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/level_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/tip_box.dart';
import '../view_models/level_cubit.dart';
import 'level_band_sheet.dart';
import 'level_ui.dart';

/// "Rating do Chess.com" (canvas `PropV1PerfilChess`): o usuário e o rating
/// público, sem login. O rating é convertido para o Lucena.
class LevelChessScreen extends StatefulWidget {
  const LevelChessScreen({super.key});

  @override
  State<LevelChessScreen> createState() => _LevelChessScreenState();
}

class _LevelChessScreenState extends State<LevelChessScreen> {
  final _user = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user.text = context.read<LevelCubit>().state.chess?.user ?? '';
  }

  @override
  void dispose() {
    _user.dispose();
    super.dispose();
  }

  void _search() => context.read<LevelCubit>().lookUpChess(_user.text);

  Future<void> _pickBand() async {
    final cubit = context.read<LevelCubit>();
    final picked = await showLevelBandSheet(context, initial: cubit.state.band);
    if (picked == null) return;
    cubit.selectBand(picked);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<LevelCubit>();
    return BlocBuilder<LevelCubit, LevelState>(
      builder: (context, state) {
        final chess = state.chess;
        final rating = state.chessRating;
        if (state.chessOffline) {
          return KeyedSubtree(
            key: LevelKeys.chessOfflineScreen,
            child: EntradaDaTela(
              id: 'PropV1AbEstChessSemRede',
              child: LoadErrorScreen(
                kind: LoadErrorKind.offline,
                message: l10n.levelChessNoNet,
                actionKey: LevelKeys.chessRetry,
                backKey: LevelKeys.chessOfflineBack,
                onAction: _search,
                onBack: cubit.dismissOffline,
              ),
            ),
          );
        }
        final noRating = chess != null && rating == null;
        return Scaffold(
          key: LevelKeys.chessScreen,
          appBar: LucenaAppBar(title: Text(l10n.levelChessAppBar)),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            children: [
              TextField(
                key: LevelKeys.chessField,
                controller: _user,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.search,
                enabled: !state.chessBusy,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  labelText: l10n.levelChessField,
                  helperText: l10n.levelChessHelp,
                  errorText: state.chessNotFound
                      ? l10n.levelChessNotFound
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: LevelKeys.chessSearch,
                onPressed: state.chessBusy ? null : _search,
                child: state.chessBusy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.levelChessSearch),
              ),
              if (noRating) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.levelChessNoRatingText,
                  key: LevelKeys.chessNoRating,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                TipBox(text: l10n.levelChessNoRatingTip),
              ],
              if (chess != null && rating != null) ...[
                const SizedBox(height: AppSpacing.lg),
                PlatformFoundCard(
                  title: l10n.levelFoundUser(chess.user),
                  rating: chess,
                  text: levelStartsAt(context, state, chess, rating),
                ),
                const SizedBox(height: AppSpacing.lg),
                TipBox(text: l10n.levelChessTip),
              ],
            ],
          ),
          bottomNavigationBar: ActionsFooter(
            stacked: true,
            children: [
              if (noRating) ...[
                FilledButton(
                  key: LevelKeys.chessTest,
                  onPressed: () => takeLevelTest(context, finish: true),
                  child: Text(l10n.levelTakeTest),
                ),
                OutlinedButton(
                  key: LevelKeys.chessPickBand,
                  onPressed: _pickBand,
                  child: Text(l10n.tourLevelBandTitle),
                ),
              ] else ...[
                FilledButton(
                  key: LevelKeys.chessUse,
                  onPressed: rating == null ? null : cubit.useChess,
                  child: Text(l10n.levelUseRating),
                ),
                const PreferTestButton(),
              ],
            ],
          ),
        );
      },
    );
  }
}
