import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/clock_settings.dart';
import '../../core/board/clock_settings_ui.dart';
import '../../core/keys/board_settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/choice_sheet.dart';
import '../../settings/view_models/settings_cubit.dart';

/// Onde o relógio aparece e se ele vibra com pouco tempo.
class ClockSettingsScreen extends StatelessWidget {
  const ClockSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    final clock = context.select(
      (SettingsCubit cubit) => cubit.state?.clock ?? const ClockSettings(),
    );
    return Scaffold(
      key: BoardSettingsKeys.clockScreen,
      appBar: AppBar(title: Text(l10n.settingsClock)),
      body: ListView(
        children: [
          ListTile(
            key: BoardSettingsKeys.clockPositionTile,
            leading: Icon(clock.position.icon),
            title: Text(l10n.clockPosition),
            subtitle: Text(
              clock.position.label(l10n),
              key: BoardSettingsKeys.clockPositionValue,
            ),
            trailing: const Icon(Icons.expand_more),
            onTap: () => _pickPosition(context, clock),
          ),
          SwitchListTile(
            key: BoardSettingsKeys.clockVibrationSwitch,
            secondary: const Icon(Icons.vibration),
            title: Text(l10n.clockLowTimeVibration),
            subtitle: Text(l10n.clockLowTimeVibrationHint),
            value: clock.lowTimeVibration,
            onChanged: (value) =>
                cubit.setClock(clock.copyWith(lowTimeVibration: value)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPosition(BuildContext context, ClockSettings clock) async {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    final picked = await showChoiceSheet<ClockPosition>(
      context,
      title: l10n.clockPosition,
      selected: clock.position,
      confirmLabel: l10n.commonConfirm,
      sheetKey: BoardSettingsKeys.choiceSheet,
      confirmKey: BoardSettingsKeys.choiceConfirmButton,
      options: [
        for (final position in ClockPosition.values)
          ChoiceSheetOption(
            value: position,
            label: position.label(l10n),
            icon: position.icon,
            key: BoardSettingsKeys.clockPositionOption(position),
          ),
      ],
    );
    if (picked == null) return;
    // O estado pode ter mudado enquanto o painel estava aberto.
    final current = cubit.state?.clock ?? clock;
    await cubit.setClock(current.copyWith(position: picked));
  }
}
