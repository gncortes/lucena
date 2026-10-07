import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/clock.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../routing/routes.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../view_models/speedrun_cubit.dart';
import '../../core/widgets/staggered_entrance.dart';
import 'speedrun_ui.dart';

/// Os speedruns no ritmo escolhido, com o melhor tempo de cada um.
class SpeedrunListScreen extends StatelessWidget {
  const SpeedrunListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<SpeedrunCubit>().state;
    final all = state.all;
    final marathon = state.marathonMode;
    // Fora da dificuldade escolhida, o final some da lista (os speedruns sem
    // dificuldade aparecem sempre).
    bool shown(SpeedrunSummary summary) {
      final category = summary.speedrun.category;
      return state.category == null ||
          category == null ||
          category == state.category;
    }

    Widget section(String title) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return Scaffold(
      key: SpeedrunKeys.listScreen,
      appBar: AppBar(
        title: Text(l10n.speedrunTitle),
        actions: [
          IconButton(
            key: SpeedrunKeys.help,
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.speedrunHelp,
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: scrollPadding(context),
              children: [
                // O modo no alto: cada partida com o seu relógio, ou um
                // relógio só para todas (a Maratona). Fica gravado.
                const _ModePicker(),
                // O que o modo é, em uma frase.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    marathon ? l10n.marathonIntro : l10n.speedrunListIntro,
                    key: SpeedrunKeys.intro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // O ritmo do modo, sempre à vista: a categoria e, dentro
                // dela, o tempo. Cada ritmo tem os seus recordes, e o último
                // de cada modo fica gravado.
                if (state.compactPace)
                  _CompactPace(
                    current: marathon ? state.marathonPace : state.pace,
                    onChosen: marathon
                        ? context.read<SpeedrunCubit>().chooseMarathonPace
                        : context.read<SpeedrunCubit>().choosePace,
                  )
                else
                  _PacePicker(
                    key: SpeedrunKeys.pace,
                    current: marathon ? state.marathonPace : state.pace,
                    onChosen: marathon
                        ? context.read<SpeedrunCubit>().chooseMarathonPace
                        : context.read<SpeedrunCubit>().choosePace,
                  ),
                // A dificuldade dos finais: abre na do nível do jogador; as
                // outras ficam a um toque.
                if (state.category != null &&
                    [
                      ...all,
                      ...state.marathons,
                    ].any((summary) => summary.speedrun.category != null))
                  const _CategoryPicker(),
                if (marathon) ...[
                  section(l10n.speedrunEndingSection),
                  for (final (index, summary) in state.marathons.indexed)
                    if (shown(summary))
                      StaggeredEntrance(
                        index: index,
                        child: _Card(summary: summary),
                      ),
                ] else
                  for (final kind in SpeedrunKind.values)
                    // Modalidade sem speedrun não ganha título.
                    if (all.any(
                      (summary) => summary.speedrun.kind == kind,
                    )) ...[
                      section(switch (kind) {
                        SpeedrunKind.rung => l10n.speedrunRungSection,
                        SpeedrunKind.ending => l10n.speedrunEndingSection,
                        SpeedrunKind.exercises => l10n.speedrunExercisesSection,
                        SpeedrunKind.full => l10n.speedrunFullSection,
                        SpeedrunKind.marathon => l10n.marathonSection,
                      }),
                      for (final (index, summary) in all.indexed)
                        if (summary.speedrun.kind == kind && shown(summary))
                          StaggeredEntrance(
                            index: index,
                            child: _Card(summary: summary),
                          ),
                    ],
              ],
            ),
    );
  }

  void _showHelp(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.speedrunTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.speedrunIntro,
                key: SpeedrunKeys.helpText,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              // O que é "15+10", para quem nunca jogou com relógio.
              Text(
                context.l10n.speedrunPaceHelp,
                key: SpeedrunKeys.paceHelp,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.speedrunPauseHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um speedrun num cartão: a imagem, o nome, as etapas e o melhor tempo.
class _Card extends StatelessWidget {
  const _Card({required this.summary});

  final SpeedrunSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final characters = context.select(
      (SpeedrunCubit cubit) => cubit.state.characters,
    );
    final speedrun = summary.speedrun;
    final best = summary.records.best;
    return Card(
      key: SpeedrunKeys.item(speedrun.id),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final cubit = context.read<SpeedrunCubit>();
          await context.push(Routes.speedrun(speedrun.id));
          if (context.mounted) await cubit.load();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SpeedrunPicture(speedrun, characters: characters),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // No modo Maratona o alto já diz o modo: só o final.
                      speedrun.kind == SpeedrunKind.marathon
                          ? endgameName(
                              l10n,
                              speedrun.stages.first.position.subcategory,
                            )
                          : speedrunName(l10n, characters, speedrun),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.speedrunStagesCount(speedrun.stages.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                best == null
                    ? l10n.speedrunNoRecord
                    : runTime(context, recordTime(speedrun, best)),
                key: SpeedrunKeys.itemBest(speedrun.id),
                style:
                    (best == null
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                          fontWeight: best == null ? null : FontWeight.w800,
                          color: best == null
                              ? colors.onSurfaceVariant
                              : colors.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O ritmo numa linha só ("Ritmo: 15 min + 10 s"), para quem está
/// começando: o toque abre o seletor com todos os ritmos.
class _CompactPace extends StatelessWidget {
  const _CompactPace({required this.current, required this.onChosen});

  final TimeControl current;
  final ValueChanged<TimeControl> onChosen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final time = current.initial < const Duration(minutes: 1)
        ? l10n.paceSeconds(current.initial.inSeconds)
        : l10n.speedrunTimeControl(
            current.initial.inMinutes,
            current.increment.inSeconds,
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          key: SpeedrunKeys.compactPace,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Icon(paceIcon(PaceCategory.of(current))),
          title: Text(l10n.speedrunPaceLine(time)),
          trailing: const Icon(Icons.expand_more),
          onTap: () async {
            final choice = await showPaceSheet(context, current: current);
            final time = choice?.time;
            if (time != null) onChosen(time);
          },
        ),
      ),
    );
  }
}

/// Iniciante, intermediário ou avançado: a dificuldade dos finais da lista.
class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SpeedrunCubit>();
    final category = context.select(
      (SpeedrunCubit cubit) => cubit.state.category,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SegmentedButton<SpeedrunCategory>(
        key: SpeedrunKeys.category,
        showSelectedIcon: false,
        segments: [
          for (final (value, label) in [
            (SpeedrunCategory.beginner, l10n.profileLevelBeginner),
            (SpeedrunCategory.intermediate, l10n.profileLevelIntermediate),
            (SpeedrunCategory.advanced, l10n.profileLevelAdvanced),
          ])
            ButtonSegment(
              value: value,
              label: Text(label, key: SpeedrunKeys.categoryOption(value.name)),
            ),
        ],
        selected: {?category},
        emptySelectionAllowed: true,
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) cubit.chooseCategory(selection.single);
        },
      ),
    );
  }
}

/// Clássico ou Maratona: o modo da lista, no alto.
class _ModePicker extends StatelessWidget {
  const _ModePicker();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SpeedrunCubit>();
    final marathon = context.select(
      (SpeedrunCubit cubit) => cubit.state.marathonMode,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SegmentedButton<bool>(
        key: SpeedrunKeys.mode,
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: false,
            icon: const Icon(Icons.timer_outlined),
            label: Text(
              l10n.speedrunModeClassic,
              key: SpeedrunKeys.modeOption('classic'),
            ),
          ),
          ButtonSegment(
            value: true,
            icon: const Icon(Icons.hourglass_bottom_rounded),
            label: Text(
              l10n.marathonSection,
              key: SpeedrunKeys.modeOption('marathon'),
            ),
          ),
        ],
        selected: {marathon},
        onSelectionChanged: (selection) =>
            cubit.chooseMode(marathon: selection.single),
      ),
    );
  }
}

/// Bullet, blitz ou rápido no alto e, embaixo, os ritmos da categoria
/// escolhida. Tocar num ritmo troca a lista.
class _PacePicker extends StatefulWidget {
  const _PacePicker({required this.current, required this.onChosen, super.key});

  final TimeControl current;
  final ValueChanged<TimeControl> onChosen;

  @override
  State<_PacePicker> createState() => _PacePickerState();
}

class _PacePickerState extends State<_PacePicker> {
  late PaceCategory _category = PaceCategory.of(widget.current);

  @override
  void didUpdateWidget(_PacePicker old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) {
      _category = PaceCategory.of(widget.current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = SpeedrunPaces.groups;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<PaceCategory>(
            showSelectedIcon: false,
            segments: [
              for (final category in groups.keys)
                ButtonSegment(
                  value: category,
                  icon: Icon(paceIcon(category)),
                  label: Text(
                    category.label(l10n),
                    key: SpeedrunKeys.paceCategory(category.name),
                  ),
                ),
            ],
            selected: {_category},
            onSelectionChanged: (selection) =>
                setState(() => _category = selection.single),
          ),
          const SizedBox(height: 10),
          // Os ritmos da categoria, entrando com um fade quando ela muda.
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            child: Wrap(
              key: ValueKey(_category),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final time in groups[_category] ?? const <TimeControl>[])
                  ChoiceChip(
                    key: SpeedrunKeys.paceOption(time.code),
                    avatar: Icon(paceIcon(_category), size: 18),
                    // O ícone do ritmo fica no lugar do "visto".
                    showCheckmark: false,
                    label: Text(paceShort(l10n, time)),
                    selected: time == widget.current,
                    onSelected: (_) => widget.onChosen(time),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
