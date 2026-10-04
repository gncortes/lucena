import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/clock.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';

/// O que foi confirmado no painel do relógio. [config] nulo: sem relógio.
class ClockChoice {
  const ClockChoice(this.config);

  final ClockConfig? config;
}

/// Abre o painel do relógio da partida. Devolve a escolha confirmada, ou nulo
/// se o painel for fechado sem confirmar.
Future<ClockChoice?> showClockSheet(
  BuildContext context, {
  required ClockConfig? current,
}) {
  return showModalBottomSheet<ClockChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    // O botão de começar fica acima da barra de gestos do sistema.
    builder: (context) =>
        SafeArea(top: false, child: _ClockSheet(current: current)),
  );
}

class _ClockSheet extends StatefulWidget {
  const _ClockSheet({required this.current});

  final ClockConfig? current;

  @override
  State<_ClockSheet> createState() => _ClockSheetState();
}

class _ClockSheetState extends State<_ClockSheet> {
  static const _minutes = [1, 3, 5, 10, 15, 30];
  static const _increments = [0, 1, 2, 3, 5, 10];
  static const _default = TimeControl(initial: Duration(minutes: 5));

  late bool _enabled = widget.current != null;
  late bool _same =
      widget.current == null || widget.current!.white == widget.current!.black;
  late TimeControl _white = _offered(widget.current?.white);
  late TimeControl _black = _offered(widget.current?.black);

  // Tempo fora das opções do painel volta ao padrão.
  static TimeControl _offered(TimeControl? time) {
    if (time == null) return _default;
    final offered =
        time.initial.inSeconds % 60 == 0 &&
        _minutes.contains(time.initial.inMinutes) &&
        _increments.contains(time.increment.inSeconds);
    return offered ? time : _default;
  }

  ClockChoice get _choice {
    if (!_enabled) return const ClockChoice(null);
    return ClockChoice(
      _same
          ? ClockConfig.same(_white)
          : ClockConfig(white: _white, black: _black),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      key: FreeBoardKeys.clockSheet,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.freeBoardClock, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                l10n.clockSheetHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Em tela pequena as opções rolam; o botão fica sempre à vista.
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  key: FreeBoardKeys.clockEnabledSwitch,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(l10n.clockUse),
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: !_enabled
                      ? const SizedBox(width: double.infinity)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SwitchListTile(
                              key: FreeBoardKeys.clockSameSwitch,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              title: Text(l10n.clockSameForBoth),
                              value: _same,
                              onChanged: (value) => setState(() {
                                _same = value;
                                // Ao separar, as pretas partem do mesmo tempo.
                                if (!value) _black = _white;
                              }),
                            ),
                            _TimePicker(
                              side: Side.white,
                              title: _same
                                  ? l10n.clockBothSides
                                  : l10n.sideWhite,
                              time: _white,
                              minutes: _minutes,
                              increments: _increments,
                              onChanged: (time) =>
                                  setState(() => _white = time),
                            ),
                            if (!_same)
                              _TimePicker(
                                side: Side.black,
                                title: l10n.sideBlack,
                                time: _black,
                                minutes: _minutes,
                                increments: _increments,
                                onChanged: (time) =>
                                    setState(() => _black = time),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton(
            key: FreeBoardKeys.clockStartButton,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => Navigator.of(context).pop(_choice),
            child: Text(l10n.clockStartGame),
          ),
        ),
      ],
    );
  }
}

/// Minutos e incremento de um lado, em fichas de escolha única.
class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.side,
    required this.title,
    required this.time,
    required this.minutes,
    required this.increments,
    required this.onChanged,
  });

  final Side side;
  final String title;
  final TimeControl time;
  final List<int> minutes;
  final List<int> increments;
  final ValueChanged<TimeControl> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final label = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.clockMinutes, style: label),
          Wrap(
            spacing: 8,
            children: [
              for (final value in minutes)
                _TimeChip(
                  key: FreeBoardKeys.clockMinutes(side, value),
                  value: value,
                  selected: time.initial == Duration(minutes: value),
                  onSelected: () => onChanged(
                    time.copyWith(initial: Duration(minutes: value)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.clockIncrement, style: label),
          Wrap(
            spacing: 8,
            children: [
              for (final value in increments)
                _TimeChip(
                  key: FreeBoardKeys.clockIncrement(side, value),
                  value: value,
                  selected: time.increment == Duration(seconds: value),
                  onSelected: () => onChanged(
                    time.copyWith(increment: Duration(seconds: value)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ficha de um valor de tempo. A escolhida fica na cor principal, sem marca
/// dentro: todas têm a mesma largura, escolhidas ou não.
class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.value,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final int value;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 24),
        child: Text(value.toString(), textAlign: TextAlign.center),
      ),
      showCheckmark: false,
      selected: selected,
      selectedColor: colors.primary,
      labelStyle: TextStyle(
        color: selected ? colors.onPrimary : colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
