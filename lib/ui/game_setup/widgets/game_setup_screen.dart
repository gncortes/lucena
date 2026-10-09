import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../domain/models/attempt.dart';
import '../../../domain/models/game_setup.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/maia_level.dart';
import '../../core/widgets/character_avatar.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/game_setup_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../view_models/game_setup_cubit.dart';
import '../../core/keys/blind_keys.dart';
import '../../voice/view_models/speech_cubit.dart';
import 'custom_pace_sheet.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/position_board.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';

/// Antes de jogar: a posição, o objetivo, o lado do jogador, o adversário e o
/// relógio de cada lado.
class GameSetupScreen extends StatelessWidget {
  const GameSetupScreen({super.key});

  // A partida substitui esta tela: voltar dela cai de onde a posição veio.
  void _start(BuildContext context, GameSetupState state) =>
      context.pushReplacement(state.gameRoute);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<GameSetupCubit>().state;
    final language = Localizations.localeOf(context).toLanguageTag();
    final blind =
        state.setup.opponent != OpponentKind.twoPlayers &&
        context.select(
          (SpeechCubit cubit) => cubit.state.availableFor(language),
        );
    return Scaffold(
      key: GameSetupKeys.screen,
      appBar: AppBar(title: Text(l10n.setupTitle)),
      // A posição já aparece antes de a configuração ser lida: é nela que o
      // tabuleiro do catálogo pousa. O resto entra quando estiver pronto.
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                _Header(state: state),
                if (state.ready) ...[
                  const _SectionTitle.yourSide(),
                  _SidePicker(state: state),
                  const _SectionTitle.opponent(),
                  _OpponentPicker(state: state),
                  // Às cegas: só contra a máquina e com voz no idioma.
                  if (blind) _ModePicker(state: state),
                  const Divider(height: 24),
                  _ClockSection(state: state),
                  if (state.attempts.isNotEmpty) _History(state: state),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    key: GameSetupKeys.startButton,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: state.canStart
                        ? () => _start(context, state)
                        : null,
                    child: Text(l10n.clockStartGame),
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

/// Normal ou às cegas (os lances falados, digitados ou tocados, sem ver as
/// peças).
class _ModePicker extends StatelessWidget {
  const _ModePicker({required this.state});

  final GameSetupState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<GameSetupCubit>();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.setupMode,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            key: GameSetupKeys.mode,
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.grid_on),
                label: Text(l10n.setupModeNormal),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(
                  Icons.record_voice_over_outlined,
                  key: BlindKeys.playButton,
                ),
                label: Text(l10n.setupModeBlind),
              ),
            ],
            selected: {state.setup.blind},
            onSelectionChanged: (selected) =>
                cubit.setBlind(blind: selected.single),
          ),
        ],
      ),
    );
  }
}

/// A posição vista pelo lado do jogador, com o objetivo.
class _Header extends StatelessWidget {
  const _Header({required this.state});

  final GameSetupState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final positionId = state.positionId;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth - 32, 340.0);
        return Column(
          children: [
            const SizedBox(height: 8),
            // O tabuleiro chega voando do cartão de onde veio (catálogo ou
            // aula).
            PositionBoard(
              boardKey: GameSetupKeys.preview,
              fen: state.position.fen,
              size: size,
              orientation: state.userSide,
              coordinates: true,
              radius: 8,
              heroTag: setupBoardTag(
                positionId: positionId,
                fen: state.position.fen,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Chip(
                  key: GameSetupKeys.goal,
                  avatar: Icon(
                    GoalStyle.of(context, state.goal).icon,
                    size: 18,
                    color: GoalStyle.of(context, state.goal).onContainer,
                  ),
                  label: Text(
                    goalLabel(l10n, state.goal),
                    style: TextStyle(
                      color: GoalStyle.of(context, state.goal).onContainer,
                    ),
                  ),
                  backgroundColor: GoalStyle.of(context, state.goal).container,
                  side: BorderSide.none,
                ),
                Chip(
                  label: Text(
                    state.position.turn == Side.white
                        ? l10n.freeBoardWhiteToMove
                        : l10n.freeBoardBlackToMove,
                  ),
                  side: BorderSide.none,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle.yourSide() : _yourSide = true;
  const _SectionTitle.opponent() : _yourSide = false;

  final bool _yourSide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 8),
      child: Text(
        _yourSide ? l10n.setupYourSide : l10n.setupOpponent,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _SidePicker extends StatelessWidget {
  const _SidePicker({required this.state});

  final GameSetupState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<GameSetupCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<Side>(
          showSelectedIcon: false,
          segments: [
            for (final (side, label) in [
              (Side.white, l10n.sideWhite),
              (Side.black, l10n.sideBlack),
            ])
              ButtonSegment(
                value: side,
                icon: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: side == Side.white ? Colors.white : Colors.black,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                label: Text(label, key: GameSetupKeys.side(side)),
              ),
          ],
          selected: {state.userSide},
          onSelectionChanged: (selected) => cubit.setUserSide(selected.single),
        ),
      ),
    );
  }
}

class _OpponentPicker extends StatelessWidget {
  const _OpponentPicker({required this.state});

  final GameSetupState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<GameSetupCubit>();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (final kind in OpponentKind.training)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                key: GameSetupKeys.opponent(kind),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppShape.large),
                ),
                selected: state.setup.opponent == kind,
                selectedTileColor: colors.secondaryContainer,
                selectedColor: colors.onSecondaryContainer,
                leading: Icon(kind.icon),
                title: Text(kind.label(l10n)),
                subtitle: Text(kind.hint(l10n)),
                trailing: AnimatedSwitcher(
                  duration: AppMotion.state,
                  child: state.setup.opponent == kind
                      ? const Icon(Icons.check, key: ValueKey('on'))
                      : const SizedBox.square(
                          dimension: 24,
                          key: ValueKey('off'),
                        ),
                ),
                onTap: () => cubit.setOpponent(kind),
              ),
            ),
          AnimatedSize(
            duration: AppMotion.state,
            curve: AppMotion.enter,
            alignment: Alignment.topCenter,
            child: state.setup.opponent == OpponentKind.maia
                ? _LevelPicker(state: state)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// O nível do Maia: um rating de 1000 a 2600. O que combina com o rating do
/// perfil vem marcado.
class _LevelPicker extends StatelessWidget {
  const _LevelPicker({required this.state});

  final GameSetupState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final cubit = context.read<GameSetupCubit>();
    return Padding(
      key: GameSetupKeys.levels,
      padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.setupMaiaLevel,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final level in MaiaLevels.all)
                ChoiceChip(
                  key: GameSetupKeys.level(level),
                  showCheckmark: false,
                  avatar: switch (state.characters.forLevel(level)) {
                    final character? => CharacterAvatar(
                      character: character,
                      size: 24,
                    ),
                    null => null,
                  },
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        switch (state.characters.forLevel(level)) {
                          final character? => l10n.characterNameLevel(
                            character.name,
                            level,
                          ),
                          null => level.toString(),
                        },
                        style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (level == state.suggestedLevel) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.recommend_rounded, size: 16),
                      ],
                    ],
                  ),
                  selected: level == state.maiaLevel,
                  onSelected: (_) => cubit.setMaiaLevel(level),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.recommend_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  switch (state.rating) {
                    final rating? => l10n.setupSuggestedRating(rating),
                    null => l10n.setupMaiaSuggested(state.suggestedLevel),
                  },
                  key: GameSetupKeys.suggestedLevel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClockSection extends StatelessWidget {
  const _ClockSection({required this.state});

  final GameSetupState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<GameSetupCubit>();
    final setup = state.setup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: GameSetupKeys.clockSwitch,
          secondary: const Icon(Icons.av_timer_outlined),
          title: Text(l10n.clockUse),
          value: setup.clock,
          onChanged: (value) => cubit.setClock(enabled: value),
        ),
        _PacePicker(state: state),
        if (state.hasZeroTime)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.setupTimeZero,
                    key: GameSetupKeys.timeError,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Os ritmos nomeados, com a categoria (`3+2 · Blitz`): um toque põe o mesmo
/// tempo para os dois lados. No fim, "Personalizar" abre o painel com os
/// minutos e o incremento de cada lado.
class _PacePicker extends StatelessWidget {
  const _PacePicker({required this.state});

  final GameSetupState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final cubit = context.read<GameSetupCubit>();
    final selected = state.pace;
    final setup = state.setup;
    // Relógio ligado com um tempo que não é de nenhum ritmo nomeado.
    final custom = setup.clock && selected == null;
    final customTime = setup.userTime == setup.opponentTime
        ? paceShort(l10n, setup.userTime)
        : '${paceShort(l10n, setup.userTime)} / '
              '${paceShort(l10n, setup.opponentTime)}';
    return Padding(
      key: GameSetupKeys.paces,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.setupPace,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final pace in state.paces)
                ChoiceChip(
                  key: GameSetupKeys.pace(pace.id),
                  label: Text(
                    l10n.paceChip(pace.id, pace.category.label(l10n)),
                  ),
                  selected: pace == selected,
                  onSelected: (_) => cubit.setPace(pace),
                ),
              ChoiceChip(
                key: GameSetupKeys.customPace,
                avatar: custom ? null : const Icon(Icons.tune, size: 18),
                label: Text(
                  custom
                      ? l10n.setupPaceCustomValue(customTime)
                      : l10n.setupPaceCustom,
                ),
                selected: custom,
                onSelected: (_) async {
                  final choice = await showCustomPaceSheet(
                    context,
                    user: setup.userTime,
                    opponent: setup.opponentTime,
                  );
                  if (choice == null) return;
                  await cubit.setTimes(
                    user: choice.user,
                    opponent: choice.opponent,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.setupPaceHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// As partidas já jogadas nesta posição, da mais recente para a mais antiga.
class _History extends StatelessWidget {
  const _History({required this.state});

  final GameSetupState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMd(locale).add_Hm();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 4),
            child: Text(
              l10n.setupHistory,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.primary,
              ),
            ),
          ),
          for (final (index, attempt) in state.attempts.indexed)
            ListTile(
              key: GameSetupKeys.attempt(index),
              dense: true,
              leading: Icon(
                attempt.fulfilled ? Icons.check_circle : Icons.cancel_outlined,
                color: attempt.fulfilled ? colors.primary : colors.error,
              ),
              title: Text(switch (attempt.outcome) {
                AttemptOutcome.win => l10n.attemptWin,
                AttemptOutcome.draw => l10n.attemptDraw,
                AttemptOutcome.loss => l10n.attemptLoss,
              }),
              subtitle: Text(
                l10n.attemptDetails(
                  attempt.opponent.label(l10n, level: attempt.opponentLevel),
                  date.format(attempt.playedAt.toLocal()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
