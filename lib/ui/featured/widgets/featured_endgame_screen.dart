import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/featured/featured_progress_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/featured.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/maia_level.dart';
import '../../../routing/routes.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/featured_endgame_cubit.dart';
import '../view_models/find_move_cubit.dart';
import 'featured_game_bar.dart';
import 'featured_labels.dart';
import 'find_move_screen.dart';

/// Um final em destaque antes de jogar: a posição, de quem é a vez, o
/// adversário e o relógio (travados ou editáveis) e o botão "Jogar". Nos
/// finais "ache o lance", a tela é a do lance.
class FeaturedEndgameScreen extends StatefulWidget {
  const FeaturedEndgameScreen({super.key});

  @override
  State<FeaturedEndgameScreen> createState() => _FeaturedEndgameScreenState();
}

class _FeaturedEndgameScreenState extends State<FeaturedEndgameScreen> {
  /// O que a imagem compartilhada captura: o cabeçalho e o tabuleiro.
  final _shareBoundary = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeaturedEndgameCubit, FeaturedEndgameState>(
      builder: (context, state) {
        final endgame = state.endgame;
        if (state.ready && endgame != null && endgame.isFindMove) {
          return BlocProvider(
            create: (context) => FindMoveCubit(
              endgame: endgame,
              progress: context.read<FeaturedProgressRepository>(),
            ),
            child: FindMoveScreen(
              endgame: endgame,
              tournament: state.tournament,
              tournamentFinals: state.tournament == null
                  ? 0
                  : state.siblings.length + 1,
            ),
          );
        }
        final l10n = context.l10n;
        return Scaffold(
          key: FeaturedKeys.endgameScreen,
          appBar: LucenaAppBar(
            title: Text(l10n.featuredEndgameTitle),
            actions: [
              if (state.ready && endgame != null)
                FeaturedGameActions(boundary: _shareBoundary, ended: true),
            ],
          ),
          body: !state.ready
              ? const SizedBox.shrink()
              : endgame == null
              ? Center(
                  child: EmptyState(
                    messageKey: FeaturedKeys.endgameMissing,
                    icon: Icons.flag_outlined,
                    message: l10n.featuredEndgameMissing,
                  ),
                )
              : _Ready(
                  state: state,
                  endgame: endgame,
                  shareBoundary: _shareBoundary,
                ),
        );
      },
    );
  }
}

class _Ready extends StatefulWidget {
  const _Ready({
    required this.state,
    required this.endgame,
    required this.shareBoundary,
  });

  final FeaturedEndgameState state;
  final FeaturedEndgame endgame;
  final GlobalKey shareBoundary;

  @override
  State<_Ready> createState() => _ReadyState();
}

class _ReadyState extends State<_Ready> {
  Future<void> _play() async {
    final choice = widget.state.choice;
    if (choice == null) return;
    await context.push(Routes.featuredGame(widget.endgame, choice));
    if (mounted) await context.read<FeaturedEndgameCubit>().load();
  }

  Future<void> _change() async {
    final cubit = context.read<FeaturedEndgameCubit>();
    final choice = widget.state.choice;
    if (choice == null) return;
    final picked = await showFeaturedChoiceSheet(
      context,
      choice,
      widget.state.characters,
    );
    if (picked != null) await cubit.choose(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final endgame = widget.endgame;
    final state = widget.state;
    final choice = state.choice;
    final white = endgame.userSide == Side.white;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: scrollPadding(
              context,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
            ),
            children: [
              RepaintBoundary(
                key: widget.shareBoundary,
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: _Heading(endgame: endgame, state: state, white: white),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (choice != null)
                _ConfigCard(
                  choice: choice,
                  characters: state.characters,
                  locked: !state.canChange,
                  onTap: state.canChange ? _change : null,
                ),
              if (choice != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    state.canChange
                        ? (endgame.playerCanChange
                              ? l10n.featuredNoteSuggested
                              : l10n.featuredNoteUnlocked)
                        : l10n.featuredNoteLocked,
                    key: FeaturedKeys.configNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ActionsFooter(
          fade: true,
          children: [
            FilledButton.icon(
              key: FeaturedKeys.playButton,
              onPressed: choice == null ? null : _play,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.featuredPlay),
            ),
          ],
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.endgame,
    required this.state,
    required this.white,
  });

  final FeaturedEndgame endgame;
  final FeaturedEndgameState state;
  final bool white;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final width = MediaQuery.sizeOf(context).width - 2 * AppSpacing.lg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FeaturedLabels.shortPlayers(l10n, endgame),
          key: FeaturedKeys.endgamePlayers,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: AppWeight.strong,
          ),
        ),
        Text(
          FeaturedLabels.subtitle(l10n, language, endgame, state.tournament),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          spacing: AppSpacing.sm,
          children: [
            Container(
              width: AppIconSize.small,
              height: AppIconSize.small,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: white ? colors.surfaceContainerLow : colors.onSurface,
                border: Border.all(color: colors.outline),
              ),
            ),
            Expanded(
              child: Text(
                white ? l10n.featuredPromptWhite : l10n.featuredPromptBlack,
                key: FeaturedKeys.endgamePrompt,
                style: context.cardTitle,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: PositionBoard(
            boardKey: FeaturedKeys.endgameBoard,
            fen: endgame.fen,
            size: math.min(width, 420),
            orientation: endgame.userSide,
            coordinates: true,
            radius: 0,
          ),
        ),
      ],
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({
    required this.choice,
    required this.characters,
    required this.locked,
    required this.onTap,
  });

  final FeaturedChoice choice;
  final List<Character> characters;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    Widget row(
      Key key,
      IconData icon,
      String title,
      String value, {
      Character? character,
    }) => ListTile(
      key: key,
      leading: character == null
          ? Icon(icon)
          : CharacterAvatar(character: character, size: CharacterAvatar.mini),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Text(value, style: context.cardTitle),
          if (locked)
            Icon(
              Icons.lock_outline,
              key: FeaturedKeys.lockedIcon,
              size: AppIconSize.button,
              color: colors.onSurfaceVariant,
            )
          else
            const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          row(
            FeaturedKeys.opponentRow,
            Icons.psychology_outlined,
            l10n.featuredOpponent,
            FeaturedLabels.opponent(l10n, choice, characters),
            character: FeaturedLabels.character(characters, choice),
          ),
          Divider(
            height: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
            color: colors.outlineVariant,
          ),
          row(
            FeaturedKeys.clockRow,
            Icons.timer_outlined,
            l10n.featuredClock,
            FeaturedLabels.clock(l10n, choice),
          ),
        ],
      ),
    );
  }
}

/// A folha "Adversário e relógio". Devolve a escolha, ou nulo se fechou.
Future<FeaturedChoice?> showFeaturedChoiceSheet(
  BuildContext context,
  FeaturedChoice current,
  List<Character> characters,
) {
  return showLucenaSheet<FeaturedChoice>(
    context,
    sheetKey: FeaturedKeys.choiceSheet,
    // Folha cinza: os cartões brancos aparecem sobre ela (canvas).
    color: Theme.of(context).colorScheme.surface,
    builder: (context) => SafeArea(
      top: false,
      child: _ChoiceSheet(initial: current, characters: characters),
    ),
  );
}

class _ChoiceSheet extends StatefulWidget {
  const _ChoiceSheet({required this.initial, required this.characters});

  final FeaturedChoice initial;
  final List<Character> characters;

  @override
  State<_ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends State<_ChoiceSheet> {
  late FeaturedChoice _choice = widget.initial;

  /// O nível do Maia ao voltar do Stockfish: o que o final traz.
  late final int _level = widget.initial.level ?? MaiaLevels.all.first;

  /// O retrato do nível; no escolhido, o ✓.
  Widget? _levelAvatar(int level) {
    if (_choice.level == level) {
      return const Icon(Icons.check, size: AppIconSize.small);
    }
    final character = widget.characters.forLevel(level);
    return character == null
        ? null
        : CharacterAvatar(character: character, size: CharacterAvatar.mini);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stockfish = _choice.opponent == OpponentKind.stockfish;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: l10n.featuredChoiceTitle),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.featuredOpponent, style: context.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    _OpponentTile(
                      kind: OpponentKind.maia,
                      selected: !stockfish,
                      onTap: () => setState(
                        () => _choice = FeaturedChoice(
                          opponent: OpponentKind.maia,
                          level: _level,
                          clock: _choice.clock,
                        ),
                      ),
                    ),
                    // Os níveis do Maia logo abaixo dele; o ✓ toma o lugar
                    // do retrato no escolhido (CompChip).
                    if (!stockfish)
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final level in MaiaLevels.all)
                            ChoiceChip(
                              key: FeaturedKeys.choiceLevel(level),
                              materialTapTargetSize: AppChip.tapTarget,
                              visualDensity: AppChip.density,
                              showCheckmark: false,
                              avatar: _levelAvatar(level),
                              label: Text(switch (widget.characters.forLevel(
                                level,
                              )) {
                                final character? => l10n.characterNameLevel(
                                  character.name,
                                  level,
                                ),
                                null => l10n.featuredOpponentMaia(level),
                              }),
                              selected: _choice.level == level,
                              onSelected: (_) => setState(
                                () => _choice = FeaturedChoice(
                                  opponent: OpponentKind.maia,
                                  level: level,
                                  clock: _choice.clock,
                                ),
                              ),
                            ),
                        ],
                      ),
                    _OpponentTile(
                      kind: OpponentKind.stockfish,
                      selected: stockfish,
                      onTap: () => setState(
                        () => _choice = FeaturedChoice(
                          opponent: OpponentKind.stockfish,
                          clock: _choice.clock,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.featuredClock, style: context.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final clock in FeaturedLabels.clocks)
                      ChoiceChip(
                        key: FeaturedKeys.choiceClock(clock ?? 'none'),
                        materialTapTargetSize: AppChip.tapTarget,
                        visualDensity: AppChip.density,
                        label: Text(
                          clock == null
                              ? l10n.featuredNoClock
                              : FeaturedLabels.clockCode(clock),
                        ),
                        selected: _choice.clock == clock,
                        onSelected: (_) => setState(
                          () => _choice = _choice.copyWith(
                            clock: clock,
                            noClock: clock == null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        ActionsFooter(
          margin: AppSpacing.xl,
          children: [
            FilledButton(
              key: FeaturedKeys.choiceDone,
              onPressed: () => Navigator.of(context).pop(_choice),
              child: Text(l10n.featuredDone),
            ),
          ],
        ),
      ],
    );
  }
}

/// Um adversário da folha, num cartão branco; o escolhido leva ✓ e o tom do
/// seletor.
class _OpponentTile extends StatelessWidget {
  const _OpponentTile({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final OpponentKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: FeaturedKeys.choiceOpponent(kind.code),
        selected: selected,
        selectedTileColor: colors.secondaryContainer,
        selectedColor: colors.onSecondaryContainer,
        leading: Icon(kind.icon),
        title: Text(kind.label(l10n)),
        subtitle: Text(kind.hint(l10n)),
        trailing: selected ? const Icon(Icons.check) : null,
        onTap: onTap,
      ),
    );
  }
}
