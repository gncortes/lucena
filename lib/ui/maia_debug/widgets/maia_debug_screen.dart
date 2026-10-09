import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/maia_level.dart';
import '../../../domain/models/maia_timing.dart';
import '../../../domain/models/move_prediction.dart';
import '../../core/keys/maia_debug_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/maia_debug_cubit.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/theme/app_shape.dart';

/// Tela de depuração do Maia (só em build de desenvolvimento e de teste):
/// avalia uma posição num nível e mostra o que o modelo respondeu e em quanto
/// tempo.
class MaiaDebugScreen extends StatefulWidget {
  const MaiaDebugScreen({super.key});

  @override
  State<MaiaDebugScreen> createState() => _MaiaDebugScreenState();
}

class _MaiaDebugScreenState extends State<MaiaDebugScreen> {
  late final _fen = TextEditingController(
    text: context.read<MaiaDebugCubit>().state.fen,
  );

  @override
  void dispose() {
    _fen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<MaiaDebugCubit>();
    final state = context.watch<MaiaDebugCubit>().state;
    final prediction = state.prediction;
    final timing = state.timing;
    final running = state.status == MaiaDebugStatus.running;
    return Scaffold(
      key: MaiaDebugKeys.screen,
      appBar: AppBar(title: Text(l10n.maiaDebugTitle)),
      body: ListView(
        padding: scrollPadding(
          context,
          left: 16,
          top: 16,
          right: 16,
          bottom: 16,
        ),
        children: [
          // O FEN é sempre da esquerda para a direita.
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              key: MaiaDebugKeys.fen,
              controller: _fen,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: InputDecoration(
                labelText: l10n.maiaDebugPosition,
                border: const OutlineInputBorder(),
                errorText: state.status == MaiaDebugStatus.invalidPosition
                    ? l10n.positionErrorInvalidFen
                    : null,
              ),
              onChanged: cubit.setFen,
            ),
          ),
          const SizedBox(height: 16),
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
                  key: MaiaDebugKeys.level(level),
                  showCheckmark: false,
                  label: Text(level.toString()),
                  selected: level == state.level,
                  onSelected: (_) => cubit.setLevel(level),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: MaiaDebugKeys.evaluate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: running ? null : cubit.evaluate,
            child: Text(l10n.maiaDebugEvaluate),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: MaiaDebugKeys.measure,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: running ? null : cubit.measure,
            icon: const Icon(Icons.speed),
            label: Text(l10n.maiaDebugMeasure),
          ),
          const SizedBox(height: 16),
          if (timing != null) _Timing(timing: timing),
          if (state.status == MaiaDebugStatus.invalidPosition)
            const SizedBox.shrink(key: MaiaDebugKeys.invalid),
          if (state.status == MaiaDebugStatus.failed)
            Text(
              l10n.maiaDebugFailed,
              key: MaiaDebugKeys.failed,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          if (prediction != null) _Result(prediction: prediction),
        ],
      ),
    );
  }
}

class _Timing extends StatelessWidget {
  const _Timing({required this.timing});

  final MaiaTiming timing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppShape.medium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            context.l10n.maiaDebugTiming(
              timing.median.inMilliseconds,
              timing.fastest.inMilliseconds,
              timing.slowest.inMilliseconds,
              timing.runs,
            ),
            key: MaiaDebugKeys.timing,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.prediction});

  final MovePrediction prediction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String percent(double value) => (value * 100).toStringAsFixed(1);
    final moves = prediction.moves.entries.take(_shown).toList();
    return Column(
      key: MaiaDebugKeys.result,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.maiaDebugElapsed(prediction.elapsed.inMilliseconds),
          key: MaiaDebugKeys.elapsed,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.maiaDebugOutcome(
            percent(prediction.win),
            percent(prediction.draw),
            percent(prediction.loss),
          ),
          key: MaiaDebugKeys.outcome,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (final (index, MapEntry(key: move, value: probability))
            in moves.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  // Lance em UCI: sempre da esquerda para a direita.
                  child: Text(
                    move,
                    key: MaiaDebugKeys.move(index),
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppShape.small),
                    child: LinearProgressIndicator(
                      value: probability,
                      minHeight: 8,
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    l10n.maiaDebugPercent(percent(probability)),
                    key: MaiaDebugKeys.probability(index),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Quantos lances aparecem (os mais prováveis).
  static const _shown = 8;
}
