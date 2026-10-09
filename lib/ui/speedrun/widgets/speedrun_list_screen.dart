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
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/one_line.dart';
import '../../../domain/use_cases/speedrun_category.dart';

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
    // Fora da dificuldade escolhida, o speedrun some da lista (o de
    // adversário fica na faixa dele; a Jornada completa aparece sempre).
    bool shown(SpeedrunSummary summary) {
      final category = SpeedrunCategories.of(summary.speedrun);
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
            onPressed: () => _showHelp(context, marathon: marathon),
          ),
        ],
      ),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              // Espaço no fim: o último cartão rola até sair da barra do
              // sistema.
              padding: scrollPadding(context, bottom: 48),
              children: [
                // O modo no alto: cada partida com o seu relógio, ou um
                // relógio só para todas (a Maratona). Fica gravado.
                const _ModePicker(),
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
                    [...all, ...state.marathons].any(
                      (summary) =>
                          SpeedrunCategories.of(summary.speedrun) != null,
                    ))
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
                    // Modalidade sem speedrun na dificuldade não ganha título.
                    if (all.any(
                      (summary) =>
                          summary.speedrun.kind == kind && shown(summary),
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

  /// O ⓘ: o que o modo é e o resto da explicação (antes a frase do modo
  /// ficava fixa no alto da lista e empurrava os cartões para baixo).
  void _showHelp(BuildContext context, {required bool marathon}) {
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
                marathon
                    ? context.l10n.marathonIntro
                    : context.l10n.speedrunListIntro,
                key: SpeedrunKeys.intro,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                    // Sem recorde, o aviso fica embaixo do nome, junto das
                    // etapas: o nome não disputa espaço com ele.
                    Text(
                      best == null
                          ? '${l10n.speedrunStagesCount(speedrun.stages.length)}'
                                ' · ${l10n.speedrunNoRecord}'
                          : l10n.speedrunStagesCount(speedrun.stages.length),
                      key: best == null
                          ? SpeedrunKeys.itemBest(speedrun.id)
                          : null,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // O lado direito é só do melhor tempo, em destaque.
              if (best != null) ...[
                const SizedBox(width: 8),
                Text(
                  runTime(context, recordTime(speedrun, best)),
                  key: SpeedrunKeys.itemBest(speedrun.id),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
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
        borderRadius: BorderRadius.circular(AppShape.large),
        child: ListTile(
          key: SpeedrunKeys.compactPace,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShape.large),
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
              label: OneLine(
                label,
                key: SpeedrunKeys.categoryOption(value.name),
              ),
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
            label: OneLine(
              l10n.speedrunModeClassic,
              key: SpeedrunKeys.modeOption('classic'),
            ),
          ),
          ButtonSegment(
            value: true,
            icon: const Icon(Icons.all_inclusive_rounded),
            label: OneLine(
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
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            segments: [
              for (final category in groups.keys)
                // Ícone em cima e o rótulo embaixo, numa linha só: lado a
                // lado, quatro segmentos não cabem e as palavras quebravam.
                ButtonSegment(
                  value: category,
                  tooltip: category.label(l10n),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(paceIcon(category), size: 20),
                        const SizedBox(height: 2),
                        OneLine(
                          category.label(l10n),
                          key: SpeedrunKeys.paceCategory(category.name),
                        ),
                      ],
                    ),
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
            duration: AppMotion.of(context).state,
            // Os chips alinhados no começo da linha, como as outras fileiras.
            layoutBuilder: (current, previous) => Stack(
              alignment: AlignmentDirectional.topStart,
              children: [...previous, ?current],
            ),
            child: Wrap(
              key: ValueKey(_category),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final time in groups[_category] ?? const <TimeControl>[])
                  ChoiceChip(
                    key: SpeedrunKeys.paceOption(time.code),
                    // O ícone da categoria já está no seletor de cima.
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
