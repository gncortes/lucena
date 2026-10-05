import 'package:flutter/material.dart';

import '../../../domain/models/clock.dart';
import '../../core/keys/game_setup_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';

/// O ritmo montado à mão: o tempo de cada lado.
class CustomPace {
  const CustomPace({required this.user, required this.opponent});

  final TimeControl user;
  final TimeControl opponent;
}

/// Os valores que os controles oferecem: passos curtos nos tempos pequenos e
/// mais largos nos grandes, como no Lichess.
abstract final class CustomPaceSteps {
  static const minutes = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 15, 20, 25, 30, 45, 60, 90, 120, 180, //
  ];
  static const increments = [0, 1, 2, 3, 5, 10, 15, 20, 30, 45, 60];

  /// O passo mais próximo de [value].
  static int nearest(List<int> steps, int value) {
    var best = 0;
    for (var index = 1; index < steps.length; index++) {
      if ((steps[index] - value).abs() < (steps[best] - value).abs()) {
        best = index;
      }
    }
    return best;
  }
}

/// Abre o painel "Personalizar ritmo": minutos e incremento, iguais para os
/// dois lados ou um tempo para cada um. Devolve o ritmo confirmado, ou nulo se
/// o painel for fechado sem confirmar.
Future<CustomPace?> showCustomPaceSheet(
  BuildContext context, {
  required TimeControl user,
  required TimeControl opponent,
}) {
  return showModalBottomSheet<CustomPace>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      top: false,
      child: _CustomPaceSheet(user: user, opponent: opponent),
    ),
  );
}

class _CustomPaceSheet extends StatefulWidget {
  const _CustomPaceSheet({required this.user, required this.opponent});

  final TimeControl user;
  final TimeControl opponent;

  @override
  State<_CustomPaceSheet> createState() => _CustomPaceSheetState();
}

class _CustomPaceSheetState extends State<_CustomPaceSheet> {
  late bool _same = widget.user == widget.opponent;
  late TimeControl _user = _offered(widget.user);
  late TimeControl _opponent = _offered(widget.opponent);

  // Tempo fora dos passos do painel cai no passo mais próximo.
  static TimeControl _offered(TimeControl time) {
    const steps = CustomPaceSteps.minutes;
    const increments = CustomPaceSteps.increments;
    return TimeControl(
      initial: Duration(
        minutes: steps[CustomPaceSteps.nearest(steps, time.initial.inMinutes)],
      ),
      increment: Duration(
        seconds:
            increments[CustomPaceSteps.nearest(
              increments,
              time.increment.inSeconds,
            )],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      key: GameSetupKeys.customSheet,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Text(
            l10n.setupPaceCustomTitle,
            style: theme.textTheme.titleLarge,
          ),
        ),
        // Em tela pequena os controles rolam; o botão fica sempre à vista.
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TimeEditor(
                  who: 'user',
                  title: _same ? l10n.clockBothSides : l10n.setupYourTime,
                  time: _user,
                  onChanged: (time) => setState(() => _user = time),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _same
                      ? const SizedBox(width: double.infinity)
                      : _TimeEditor(
                          who: 'opponent',
                          title: l10n.setupOpponentTime,
                          time: _opponent,
                          onChanged: (time) => setState(() => _opponent = time),
                        ),
                ),
                SwitchListTile(
                  key: GameSetupKeys.customSame,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(l10n.clockSameForBoth),
                  value: _same,
                  onChanged: (value) => setState(() {
                    _same = value;
                    // Ao separar, o adversário parte do mesmo tempo.
                    if (!value) _opponent = _user;
                  }),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: FilledButton(
            key: GameSetupKeys.customConfirm,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => Navigator.of(
              context,
            ).pop(CustomPace(user: _user, opponent: _same ? _user : _opponent)),
            child: Text(l10n.commonConfirm),
          ),
        ),
      ],
    );
  }
}

/// O tempo de um lado: o ritmo em destaque (`10+5`) e um controle deslizante
/// para os minutos e outro para o incremento.
class _TimeEditor extends StatelessWidget {
  const _TimeEditor({
    required this.who,
    required this.title,
    required this.time,
    required this.onChanged,
  });

  final String who;
  final String title;
  final TimeControl time;
  final ValueChanged<TimeControl> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final minutes = time.initial.inMinutes;
    final increment = time.increment.inSeconds;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      paceLabel(l10n, time),
                      key: GameSetupKeys.customValue(who),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              _StepSlider(
                sliderKey: GameSetupKeys.customSlider(who, 'minutes'),
                icon: Icons.timer_outlined,
                label: l10n.setupPaceCustomMinutes(minutes),
                steps: CustomPaceSteps.minutes,
                value: minutes,
                onChanged: (value) => onChanged(
                  TimeControl(
                    initial: Duration(minutes: value),
                    increment: time.increment,
                  ),
                ),
              ),
              _StepSlider(
                sliderKey: GameSetupKeys.customSlider(who, 'increment'),
                icon: Icons.add_circle_outline,
                label: l10n.setupPaceCustomIncrement(increment),
                steps: CustomPaceSteps.increments,
                value: increment,
                onChanged: (value) => onChanged(
                  TimeControl(
                    initial: time.initial,
                    increment: Duration(seconds: value),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um controle deslizante que anda pelos [steps], com o valor por extenso em
/// cima.
class _StepSlider extends StatelessWidget {
  const _StepSlider({
    required this.sliderKey,
    required this.icon,
    required this.label,
    required this.steps,
    required this.value,
    required this.onChanged,
  });

  final Key sliderKey;
  final IconData icon;
  final String label;
  final List<int> steps;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 0),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            ],
          ),
        ),
        Slider(
          key: sliderKey,
          max: steps.length - 1,
          divisions: steps.length - 1,
          value: CustomPaceSteps.nearest(steps, value).toDouble(),
          semanticFormatterCallback: (_) => label,
          onChanged: (index) => onChanged(steps[index.round()]),
        ),
      ],
    );
  }
}
