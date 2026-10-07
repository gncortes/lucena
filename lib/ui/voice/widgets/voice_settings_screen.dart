import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/voice.dart';
import '../../core/keys/voice_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/speech_cubit.dart';
import 'voice_pickers.dart';

/// Configurações da voz: falar sozinho, a velocidade, a voz do professor e as
/// dos adversários. Sem voz no idioma, só o porquê e como resolver.
class VoiceSettingsScreen extends StatelessWidget {
  const VoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final speech = context.read<SpeechCubit>();
    final language = voiceLanguage(context);
    final state = context.watch<SpeechCubit>().state;
    final available = state.availableFor(language);
    final settings = state.settings;
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
    final help = SystemVoicesHelp(missing: !available);
    return Scaffold(
      key: VoiceKeys.settingsSection,
      appBar: AppBar(title: Text(l10n.voiceSection)),
      body: !state.loaded
          ? const SizedBox.shrink()
          : ListView(
              children: [
                if (!available)
                  help
                else ...[
                  SwitchListTile(
                    key: VoiceKeys.enabledSwitch,
                    secondary: const Icon(Icons.record_voice_over_outlined),
                    title: Text(l10n.voiceSpeakAloud),
                    subtitle: Text(l10n.voiceSpeakAloudHint),
                    value: settings.enabled,
                    onChanged: (value) => speech.setEnabled(enabled: value),
                  ),
                  header(l10n.voiceSpeed),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final speed in VoiceSettings.speeds)
                          ChoiceChip(
                            key: VoiceKeys.speed(speed),
                            label: Text(switch (speed) {
                              < 1 => l10n.voiceSpeedSlow,
                              1 => l10n.voiceSpeedNormal,
                              < 1.3 => l10n.voiceSpeedFast,
                              _ => l10n.voiceSpeedFaster,
                            }),
                            selected: settings.speed == speed,
                            onSelected: (_) => speech.setSpeed(speed),
                          ),
                      ],
                    ),
                  ),
                  header(l10n.voiceTeacher),
                  const TeacherVoiceList(),
                  header(l10n.voiceCharacters),
                  const CharacterVoiceList(),
                  help,
                ],
              ],
            ),
    );
  }
}
