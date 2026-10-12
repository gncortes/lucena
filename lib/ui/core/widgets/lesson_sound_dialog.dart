import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/app_settings.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../keys/lesson_sound_keys.dart';
import '../l10n/l10n.dart';
import '../theme/app_spacing.dart';
import 'one_line.dart';

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
    final theme = Theme.of(context);
    final panelColor =
        theme.bottomSheetTheme.modalBackgroundColor ??
        theme.colorScheme.surface;
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).toLanguageTag();
    final speeds = {..._speeds, speech.settings.speed}.toList()..sort();
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
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
                    color: panelColor,
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
              // A superfície segue os painéis do app, inclusive no tema escuro.
              Dialog(
                key: LessonSoundKeys.dialog,
                backgroundColor: panelColor,
                surfaceTintColor: Colors.transparent,
                insetPadding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg + AppSpacing.xs,
                    AppSpacing.lg + AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.lg + AppSpacing.xs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.gameSoundAndVoice,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PreferenceSwitch(
                        switchKey: LessonSoundKeys.sound,
                        icon: settings.sound
                            ? Icons.volume_up_outlined
                            : Icons.volume_off_outlined,
                        title: l10n.settingsSound,
                        subtitle: l10n.lessonSoundHint,
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
                      const SizedBox(height: AppSpacing.xs),
                      _PreferenceSwitch(
                        switchKey: LessonSoundKeys.teacherVoice,
                        icon: speech.settings.enabled
                            ? Icons.chat_bubble_outline
                            : Icons.speaker_notes_off_outlined,
                        title: l10n.lessonTeacherVoice,
                        subtitle: l10n.lessonTeacherVoiceHint,
                        value: speech.settings.enabled,
                        onChanged: (value) =>
                            unawaited(speechCubit.setEnabled(enabled: value)),
                      ),
                      if (settings.sound &&
                          speech.settings.enabled &&
                          speech.availableFor(language)) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.voiceSpeed,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SegmentedButton<double>(
                          key: LessonSoundKeys.speeds,
                          expandedInsets: EdgeInsets.zero,
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            tapTargetSize: MaterialTapTargetSize.padded,
                            selectedBackgroundColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            selectedForegroundColor: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                          segments: [
                            for (final speed in speeds)
                              ButtonSegment(
                                value: speed,
                                label: OneLine(
                                  l10n.voiceSpeedValue(speed),
                                  key: LessonSoundKeys.speed(speed),
                                ),
                              ),
                          ],
                          selected: {speech.settings.speed},
                          onSelectionChanged: (values) =>
                              unawaited(speechCubit.setSpeed(values.single)),
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

/// Mantém as linhas compactas do Canvas com alvo de toque de pelo menos 48dp.
/// Os textos podem crescer livremente com a escala de fonte e a tradução.
class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.switchKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(subtitle, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Switch(
                key: switchKey,
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
