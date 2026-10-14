import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/app_settings.dart';
import '../../core/keys/game_sound_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../view_models/talk_cubit.dart';
import '../../core/widgets/sound_off_icon.dart';

/// Preferências persistidas pelos view models existentes; fechar não altera nada.
Future<void> showGameSoundDialog(BuildContext context) {
  final settings = context.read<SettingsCubit>();
  final speech = context.read<SpeechCubit>();
  TalkCubit? talk;
  try {
    talk = context.read<TalkCubit>();
  } on ProviderNotFoundException {
    // O diálogo também pode ser exercitado sem uma partida em andamento.
  }
  return showDialog<void>(
    context: context,
    builder: (context) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settings),
        BlocProvider.value(value: speech),
      ],
      child: _SoundDialog(talk: talk),
    ),
  );
}

class _SoundDialog extends StatelessWidget {
  const _SoundDialog({this.talk});

  final TalkCubit? talk;
  static const _speeds = [.75, 1.0, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final speechCubit = context.read<SpeechCubit>();
    final settings =
        context.watch<SettingsCubit>().state ?? const AppSettings();
    final voice = context.watch<SpeechCubit>().state;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).toLanguageTag();
    final heard =
        settings.sound && settings.characterTalk && voice.charactersHeard;
    final speeds = {..._speeds, voice.settings.speed}.toList()..sort();
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    elevation: 3,
                    shape: const CircleBorder(),
                    child: SizedBox.square(
                      dimension: 44,
                      child: IconButton(
                        key: GameSoundKeys.close,
                        padding: EdgeInsets.zero,
                        color: Colors.black87,
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                key: GameSoundKeys.dialog,
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppShape.extraLarge),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.gameSoundAndVoice,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        key: GameSoundKeys.sound,
                        contentPadding: EdgeInsets.zero,
                        secondary: settings.sound
                            ? const Icon(Icons.volume_up_outlined)
                            : const SoundOffIcon(),
                        title: Text(l10n.settingsSound),
                        subtitle: Text(l10n.settingsSoundHint),
                        value: settings.sound,
                        onChanged: (value) {
                          unawaited(settingsCubit.setSound(enabled: value));
                          unawaited(
                            speechCubit.setCharactersHeard(
                              heard: value && settings.characterTalk,
                            ),
                          );
                        },
                      ),
                      SwitchListTile(
                        key: GameSoundKeys.comments,
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          settings.characterTalk
                              ? Icons.chat_bubble_outline
                              : Icons.speaker_notes_off_outlined,
                        ),
                        title: Text(l10n.settingsCharacterTalk),
                        subtitle: Text(l10n.settingsCharacterTalkHint),
                        value: settings.characterTalk,
                        onChanged: (value) {
                          talk?.setEnabled(enabled: value);
                          unawaited(
                            settingsCubit.setCharacterTalk(enabled: value),
                          );
                          unawaited(
                            speechCubit.setCharactersHeard(
                              heard: settings.sound && value,
                            ),
                          );
                        },
                      ),
                      if (heard && voice.availableFor(language)) ...[
                        const SizedBox(height: 14),
                        Text(
                          l10n.voiceSpeed,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          key: GameSoundKeys.speeds,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final speed in speeds)
                              ChoiceChip(
                                key: GameSoundKeys.speed(speed),
                                label: Text(l10n.voiceSpeedValue(speed)),
                                selected: voice.settings.speed == speed,
                                onSelected: (_) =>
                                    unawaited(speechCubit.setSpeed(speed)),
                              ),
                          ],
                        ),
                      ],
                    ],
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
