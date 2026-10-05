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
                // O ritmo da lista, sempre à vista: a categoria e, dentro
                // dela, o tempo. Cada ritmo tem os seus recordes, e o último
                // escolhido fica gravado.
                _PacePicker(current: state.pace),
                // O que é o speedrun, em uma frase, para quem chega.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    l10n.speedrunListIntro,
                    key: SpeedrunKeys.intro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final kind in SpeedrunKind.values)
                  // Modalidade sem speedrun não ganha título.
                  if (all.any((summary) => summary.speedrun.kind == kind)) ...[
                    section(switch (kind) {
                      SpeedrunKind.rung => l10n.speedrunRungSection,
                      SpeedrunKind.ending => l10n.speedrunEndingSection,
                      SpeedrunKind.exercises => l10n.speedrunExercisesSection,
                      SpeedrunKind.full => l10n.speedrunFullSection,
                    }),
                    for (final (index, summary) in all.indexed)
                      if (summary.speedrun.kind == kind)
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
                      speedrunName(l10n, characters, speedrun),
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
                best == null ? l10n.speedrunNoRecord : runTime(context, best),
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

/// Bullet, blitz ou rápido no alto e, embaixo, os ritmos da categoria
/// escolhida. Tocar num ritmo troca a lista.
class _PacePicker extends StatefulWidget {
  const _PacePicker({required this.current});

  final TimeControl current;

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
    final cubit = context.read<SpeedrunCubit>();
    final groups = SpeedrunPaces.groups;
    return Padding(
      key: SpeedrunKeys.pace,
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
                    label: Text(paceShort(l10n, time)),
                    selected: time == widget.current,
                    onSelected: (_) => cubit.choosePace(time),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
