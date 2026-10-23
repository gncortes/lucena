import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/race.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/game_clock.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/opponent_card.dart';
import '../../free_board/widgets/game_actions_bar.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/race_warm_up_cubit.dart';
import 'race_game_view.dart';
import 'race_scoreboard.dart';

/// O que a tela do aquecimento precisa de quem a abriu: o adversário que
/// espera, o final do desafio (para escolher os problemas) e o que fazer ao
/// acabar ou pular (abrir a partida).
class RaceWarmUpArgs {
  const RaceWarmUpArgs({
    required this.opponent,
    required this.onPlay,
    this.character,
    this.level,
    this.theme,
  });

  final String opponent;
  final Character? character;

  /// O nível do adversário (`1000`), quando tem.
  final int? level;

  /// O tema do final do desafio. Nulo: os mais fáceis do banco.
  final RaceTheme? theme;
  final void Function(BuildContext context) onPlay;
}

/// O aquecimento: poucos problemas do final do desafio, sem relógio, e depois
/// a partida.
class RaceWarmUpScreen extends StatelessWidget {
  const RaceWarmUpScreen({required this.args, super.key});

  final RaceWarmUpArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<RaceWarmUpCubit>().state;
    final cubit = context.read<RaceWarmUpCubit>();
    final settings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final problem = state.problem;
    return Scaffold(
      key: RaceKeys.warmUpScreen,
      appBar: LucenaAppBar(
        leading: IconButton(
          key: RaceKeys.warmUpClose,
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonLabel,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n.raceWarmUpTitle),
      ),
      body: state.done
          ? _Done(state: state, args: args)
          : problem == null
          ? const SizedBox.shrink()
          : Stack(
              fit: StackFit.expand,
              children: [
                SafeArea(
                  child: CenteredBoardLayout(
                    balanced: true,
                    reserveTop: RaceScoreboard.height,
                    reserveBottom: RaceGameView.bottomRoom(context),
                    footer: const SizedBox(height: GameActionsBar.height),
                    board: LayoutBuilder(
                      builder: (context, box) => RaceFadingBoard(
                        size: box.maxWidth,
                        problem: problem,
                        turn: state.results.length,
                        settings: settings,
                        onMove: (move) => cubit.answer(move.uci),
                      ),
                    ),
                    bottom: PlayersRow(
                      detailed: true,
                      board: settings,
                      players: [
                        PlayerEntry(
                          side: problem.side,
                          name: l10n.reviewYou,
                          detail: l10n.raceWarmUpProgress(
                            state.results.length + 1,
                            state.problems.length,
                          ),
                          detailKey: RaceKeys.warmUpProgress,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: ActionsBar(
                      children: [
                        GameActionButton(
                          buttonKey: RaceKeys.warmUpSkip,
                          icon: Icons.skip_next,
                          label: l10n.raceWarmUpSkip,
                          onPressed: () => args.onPlay(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.state, required this.args});

  static const _fire = 88.0;
  static const _mark = 36.0;

  final RaceWarmUpState state;
  final RaceWarmUpArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final good = ChangeColors.of(context, up: true);
    final language = Localizations.localeOf(context).languageCode;
    return Column(
      key: RaceKeys.warmUpDone,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    spacing: AppSpacing.md,
                    children: [
                      ExcludeSemantics(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(
                              AppShape.extraLarge,
                            ),
                          ),
                          child: SizedBox.square(
                            dimension: _fire,
                            child: Icon(
                              Icons.local_fire_department,
                              size: 52,
                              color: colors.tertiary,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        l10n.raceWarmUpDoneTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.raceWarmUpDoneBody(
                          state.corrects,
                          state.problems.length,
                          args.opponent,
                        ),
                        key: RaceKeys.warmUpDoneBody,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final (index, ok) in state.results.indexed)
                            DecoratedBox(
                              key: RaceKeys.warmUpResult(index),
                              decoration: BoxDecoration(
                                color: ok ? good : colors.error,
                                borderRadius: BorderRadius.circular(
                                  AppShape.small,
                                ),
                              ),
                              child: SizedBox.square(
                                dimension: _mark,
                                child: Icon(
                                  ok ? Icons.check : Icons.close,
                                  size: AppIconSize.standard - 2,
                                  color: colors.onError,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                OpponentCard(
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  name: args.opponent,
                  character: args.character,
                  level: args.level,
                  tagline: args.character?.taglineIn(language) ?? '',
                ),
              ],
            ),
          ),
        ),
        ActionsFooter(
          children: [
            FilledButton.icon(
              key: RaceKeys.warmUpPlay,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.raceWarmUpPlay(args.opponent)),
              onPressed: () => args.onPlay(context),
            ),
          ],
        ),
      ],
    );
  }
}
