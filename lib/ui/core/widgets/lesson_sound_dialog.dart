import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/app_settings.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../keys/lesson_sound_keys.dart';
import '../l10n/l10n.dart';
import '../theme/app_spacing.dart';

/// Som da aula: usa as preferências existentes e preserva as dos adversários.
/// A tela da aula também deve bloquear a reprodução quando o som geral está off.
Future<void> showLessonSoundDialog(BuildContext context) {
  final settings = context.read<SettingsCubit>();
  final speech = context.read<SpeechCubit>();
  return showDialog<void>(
    context: context,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settings),
        BlocProvider.value(value: speech),
      ],
      child: const _LessonSoundDialog(),
    ),
  );
}

class _LessonSoundDialog extends StatelessWidget {
  const _LessonSoundDialog();

  static const _speeds = [.75, 1.0, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final speechCubit = context.read<SpeechCubit>();
    final settings =
        context.watch<SettingsCubit>().state ?? const AppSettings();
    final speech = context.watch<SpeechCubit>().state;
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).toLanguageTag();
    final speeds = {..._speeds, speech.settings.speed}.toList()..sort();
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
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
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 3,
                    shape: const CircleBorder(),
                    child: SizedBox.square(
                      dimension: 48,
                      child: IconButton(
                        key: LessonSoundKeys.close,
                        padding: EdgeInsets.zero,
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
                ),
              ),
              // O Dialog interno usa a mesma forma/cor do diálogo Material do app.
              Dialog(
                key: LessonSoundKeys.dialog,
                insetPadding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.gameSoundAndVoice,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SwitchListTile(
                        key: LessonSoundKeys.sound,
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          settings.sound
                              ? Icons.volume_up_outlined
                              : Icons.volume_off_outlined,
                        ),
                        title: Text(l10n.settingsSound),
                        subtitle: Text(l10n.lessonSoundHint),
                        value: settings.sound,
                        onChanged: (value) {
                          unawaited(settingsCubit.setSound(enabled: value));
                          if (!value &&
                              speechCubit.state.speakerId ==
                                  SpeechCubit.teacherId) {
                            unawaited(speechCubit.stop());
                          }
                        },
                      ),
                      SwitchListTile(
                        key: LessonSoundKeys.teacherVoice,
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          speech.settings.enabled
                              ? Icons.record_voice_over_outlined
                              : Icons.voice_over_off_outlined,
                        ),
                        title: Text(l10n.lessonTeacherVoice),
                        subtitle: Text(l10n.lessonTeacherVoiceHint),
                        value: speech.settings.enabled,
                        onChanged: (value) =>
                            unawaited(speechCubit.setEnabled(enabled: value)),
                      ),
                      if (settings.sound &&
                          speech.settings.enabled &&
                          speech.availableFor(language)) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.voiceSpeed,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          key: LessonSoundKeys.speeds,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final speed in speeds)
                              ChoiceChip(
                                key: LessonSoundKeys.speed(speed),
                                label: Text(l10n.voiceSpeedValue(speed)),
                                selected: speech.settings.speed == speed,
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
