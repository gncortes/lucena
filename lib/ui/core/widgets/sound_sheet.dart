import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/app_settings.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../keys/game_sound_keys.dart';
import '../keys/lesson_sound_keys.dart';
import '../l10n/l10n.dart';
import 'lucena_sheet.dart';
import 'sheet_header.dart';
import 'one_line.dart';
import 'sound_off_icon.dart';

/// Onde a folha "Som e voz" foi aberta (T73, 8.2). A folha é uma só; muda a
/// segunda preferência: nas falas dos adversários (partida) ou na voz do
/// Viktor (aula).
enum SoundSheetScope { game, lesson }

/// A folha "Som e voz" do app: som geral, a voz do contexto e a velocidade da
/// voz. Usa as preferências existentes; fechar não altera nada. Em partida,
/// [onCharacterTalkChanged] liga ou desliga os comentários da que está em curso.
Future<void> showSoundSheet(
  BuildContext context, {
  required SoundSheetScope scope,
  ValueChanged<bool>? onCharacterTalkChanged,
}) {
  final settings = context.read<SettingsCubit>();
  final speech = context.read<SpeechCubit>();
  return showLucenaSheet<void>(
    context,
    sheetKey: scope == SoundSheetScope.game
        ? GameSoundKeys.dialog
        : LessonSoundKeys.dialog,
    closeKey: scope == SoundSheetScope.game
        ? GameSoundKeys.close
        : LessonSoundKeys.close,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settings),
        BlocProvider.value(value: speech),
      ],
      child: _SoundSheetBody(
        scope: scope,
        onCharacterTalkChanged: onCharacterTalkChanged,
      ),
    ),
  );
}

class _SoundSheetBody extends StatelessWidget {
  const _SoundSheetBody({required this.scope, this.onCharacterTalkChanged});

  final SoundSheetScope scope;
  final ValueChanged<bool>? onCharacterTalkChanged;

  static const _speeds = [.75, 1.0, 1.5, 2.0];

  bool get _game => scope == SoundSheetScope.game;

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final speechCubit = context.read<SpeechCubit>();
    final settings =
        context.watch<SettingsCubit>().state ?? const AppSettings();
    final speech = context.watch<SpeechCubit>().state;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).toLanguageTag();
    final speeds = {..._speeds, speech.settings.speed}.toList()..sort();
    final secondOn = _game ? settings.characterTalk : speech.settings.enabled;
    final heard = _game
        ? settings.sound && settings.characterTalk && speech.charactersHeard
        : settings.sound && speech.settings.enabled;
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreferenceSwitch(
          switchKey: _game ? GameSoundKeys.sound : LessonSoundKeys.sound,
          icon: settings.sound
              ? const Icon(Icons.volume_up_outlined, size: AppIconSize.standard)
              : const SoundOffIcon(size: AppIconSize.standard),
          title: l10n.settingsSound,
          subtitle: _game ? l10n.settingsSoundHint : l10n.lessonSoundHint,
          value: settings.sound,
          onChanged: (value) {
            unawaited(settingsCubit.setSound(enabled: value));
            if (_game) {
              unawaited(
                speechCubit.setCharactersHeard(
                  heard: value && settings.characterTalk,
                ),
              );
            } else if (!value &&
                speechCubit.state.speakerId == SpeechCubit.teacherId) {
              unawaited(speechCubit.stop());
            }
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        _PreferenceSwitch(
          switchKey: _game
              ? GameSoundKeys.comments
              : LessonSoundKeys.teacherVoice,
          icon: Icon(
            secondOn
                ? Icons.chat_bubble_outline
                : Icons.speaker_notes_off_outlined,
            size: AppIconSize.standard,
          ),
          title: _game ? l10n.settingsCharacterTalk : l10n.lessonTeacherVoice,
          subtitle: _game
              ? l10n.settingsCharacterTalkHint
              : l10n.lessonTeacherVoiceHint,
          value: secondOn,
          onChanged: (value) {
            if (_game) {
              onCharacterTalkChanged?.call(value);
              unawaited(settingsCubit.setCharacterTalk(enabled: value));
              unawaited(
                speechCubit.setCharactersHeard(heard: settings.sound && value),
              );
            } else {
              unawaited(speechCubit.setEnabled(enabled: value));
            }
          },
        ),
        if (heard && speech.availableFor(language)) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.voiceSpeed, style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<double>(
            key: _game ? GameSoundKeys.speeds : LessonSoundKeys.speeds,
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              tapTargetSize: MaterialTapTargetSize.padded,
              selectedBackgroundColor: theme.colorScheme.secondaryContainer,
              selectedForegroundColor: theme.colorScheme.onSecondaryContainer,
            ),
            segments: [
              for (final speed in speeds)
                ButtonSegment(
                  value: speed,
                  label: OneLine(
                    l10n.voiceSpeedValue(speed),
                    key: _game
                        ? GameSoundKeys.speed(speed)
                        : LessonSoundKeys.speed(speed),
                  ),
                ),
            ],
            selected: {speech.settings.speed},
            onSelectionChanged: (values) =>
                unawaited(speechCubit.setSpeed(values.single)),
          ),
        ],
      ],
    );
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.gameSoundAndVoice),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: body,
          ),
        ],
      ),
    );
  }
}

/// Linhas compactas com alvo de toque de pelo menos 48 dp; o texto cresce
/// livremente com a tradução.
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
  final Widget icon;
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
              icon,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.cardTitle),
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
