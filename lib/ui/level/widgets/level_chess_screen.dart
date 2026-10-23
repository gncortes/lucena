import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../core/keys/level_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/level_cubit.dart';
import 'level_ui.dart';

/// "Rating do Chess.com" (canvas `PropV1PerfilChess`): o usuário e o rating
/// público, sem login. O rating é convertido para o Lucena.
class LevelChessScreen extends StatefulWidget {
  const LevelChessScreen({super.key});

  @override
  State<LevelChessScreen> createState() => _LevelChessScreenState();
}

class _LevelChessScreenState extends State<LevelChessScreen> {
  // Procura depois que a pessoa para de digitar.
  static const _pause = Duration(milliseconds: 600);
  final _user = TextEditingController();
  Timer? _typing;

  @override
  void initState() {
    super.initState();
    _user.text = context.read<LevelCubit>().state.chess?.user ?? '';
  }

  @override
  void dispose() {
    _typing?.cancel();
    _user.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _typing?.cancel();
    _typing = Timer(_pause, () => context.read<LevelCubit>().lookUpChess(text));
  }

  void _submitted(String text) {
    _typing?.cancel();
    context.read<LevelCubit>().lookUpChess(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<LevelCubit>();
    return BlocConsumer<LevelCubit, LevelState>(
      listenWhen: (previous, current) =>
          current.errorCount != previous.errorCount &&
          current.error == LevelError.chessOffline,
      listener: (context, state) =>
          showLucenaSnackBar(context, l10n.levelChessOffline),
      builder: (context, state) {
        final chess = state.chess;
        final rating = state.chessRating;
        final success = AppColors.of(context).success;
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
                onChanged: _changed,
                onSubmitted: _submitted,
                decoration: InputDecoration(
                  labelText: l10n.levelChessField,
                  helperText: l10n.levelChessHelp,
                  errorText: state.chessNotFound
                      ? l10n.levelChessNotFound
                      : null,
                  suffixIcon: state.chessBusy
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              if (chess != null && rating != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: AppIconSize.button,
                              color: success,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                l10n.levelFoundUser(chess.user),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        PlatformRatingsGrid(rating: chess),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          levelStartsAt(context, state, chess, rating),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TipBox(text: l10n.levelChessTip),
              ],
            ],
          ),
          bottomNavigationBar: ActionsFooter(
            stacked: true,
            children: [
              FilledButton(
                key: LevelKeys.chessUse,
                onPressed: rating == null ? null : cubit.useChess,
                child: Text(l10n.levelUseRating),
              ),
              const PreferTestButton(),
            ],
          ),
        );
      },
    );
  }
}
