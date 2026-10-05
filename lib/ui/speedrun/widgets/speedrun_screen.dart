import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../routing/routes.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../journey/widgets/journey_ui.dart';
import '../view_models/speedrun_cubit.dart';
import 'speedrun_ui.dart';
import '../../core/widgets/scroll_padding.dart';

/// Um speedrun: o recorde, o melhor tempo de cada etapa, começar ou continuar
/// a tentativa e os tempos de antes, por mês.
class SpeedrunScreen extends StatelessWidget {
  const SpeedrunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = context.select(
      (SpeedrunCubit cubit) => cubit.state.selected,
    );
    final loaded = context.select(
      (SpeedrunCubit cubit) => cubit.state.all != null,
    );
    if (summary == null) {
      return Scaffold(
        key: SpeedrunKeys.screen,
        appBar: AppBar(title: Text(l10n.speedrunTitle)),
        body: loaded ? null : const Center(child: CircularProgressIndicator()),
      );
    }
    final speedrun = summary.speedrun;
    final records = summary.records;
    final ongoing = summary.ongoing;
    final best = records.best;
    final tabular = theme.textTheme.titleMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Scaffold(
      key: SpeedrunKeys.screen,
      appBar: AppBar(
        title: SpeedrunTitle(speedrun, style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        padding: scrollPadding(context),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '${speedrunDescription(l10n, speedrun)} · '
              '${l10n.speedrunTimeControl(speedrun.time.initial.inMinutes, speedrun.time.increment.inSeconds)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Card(
            margin: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.speedrunBest,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Text(
                    best == null
                        ? l10n.speedrunNoRecord
                        : RunTimeFormat.format(best),
                    key: SpeedrunKeys.best,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ongoing == null
                ? FilledButton.icon(
                    key: SpeedrunKeys.start,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l10n.speedrunStart),
                    onPressed: () async {
                      final cubit = context.read<SpeedrunCubit>();
                      final id = await cubit.start();
                      if (id == null || !context.mounted) return;
                      await context.push(
                        Routes.speedrunAttempt(speedrun.id, id),
                      );
                      if (context.mounted) {
                        await cubit.load(speedrunId: speedrun.id);
                      }
                    },
                  )
                : FilledButton.icon(
                    key: SpeedrunKeys.resume,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.timelapse),
                    label: Text(
                      l10n.speedrunResume(
                        ongoing.currentStage + 1,
                        speedrun.stages.length,
                      ),
                    ),
                    onPressed: () async {
                      final cubit = context.read<SpeedrunCubit>();
                      await context.push(
                        Routes.speedrunAttempt(speedrun.id, ongoing.attempt.id),
                      );
                      if (context.mounted) {
                        await cubit.load(speedrunId: speedrun.id);
                      }
                    },
                  ),
          ),
          _header(context, l10n.speedrunStages),
          for (final (index, stage) in speedrun.stages.indexed)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                child: Text((index + 1).toString()),
              ),
              title: Text(opponentRefLabel(l10n, stage.opponent)),
              trailing: Text(
                switch (records.bestStages[index]) {
                  final time? => RunTimeFormat.format(time),
                  null => '',
                },
                key: SpeedrunKeys.stageRecord(index),
                style: tabular,
              ),
            ),
          if (records.completed.isNotEmpty) ...[
            _header(context, l10n.speedrunHistory),
            ..._history(context, records.completed, tabular),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 4),
      child: Text(text, style: theme.textTheme.titleMedium),
    );
  }

  // Os tempos das tentativas concluídas, da mais recente para a mais antiga,
  // com o título de cada mês.
  List<Widget> _history(
    BuildContext context,
    List<SpeedrunRun> runs,
    TextStyle? style,
  ) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final month = DateFormat.yMMMM(locale);
    final date = DateFormat.MMMd(locale).add_Hm();
    final children = <Widget>[];
    String? current;
    var months = 0;
    for (final (index, run) in runs.indexed) {
      final finishedAt = run.finishedAt!.toLocal();
      final label = month.format(finishedAt);
      if (label != current) {
        current = label;
        children.add(
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Text(
              label,
              key: SpeedrunKeys.month(months++),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      }
      children.add(
        ListTile(
          key: SpeedrunKeys.run(index),
          dense: true,
          leading: const Icon(Icons.flag_outlined),
          title: Text(RunTimeFormat.format(run.total), style: style),
          subtitle: Text(
            '${date.format(finishedAt)} · ${l10n.speedrunLosses(run.losses)}',
          ),
        ),
      );
    }
    return children;
  }
}
