import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/character.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../voice/widgets/auto_speak.dart';
import '../l10n/l10n.dart';
import '../theme/app_spacing.dart';
import 'character_avatar.dart';
import 'script_speech_sheet.dart';
import 'speech_balloon.dart';
import 'teacher_speech.dart';

/// O cabeçalho do Viktor e o balão com a fala, do tour e do "Seu nível".
class ViktorConversation extends StatelessWidget {
  const ViktorConversation({
    required this.viktor,
    required this.speech,
    this.viktorKey,
    this.speechKey,
    super.key,
  });

  final Character? viktor;
  final String? speech;
  final Key? viktorKey;
  final Key? speechKey;

  @override
  Widget build(BuildContext context) {
    final viktor = this.viktor;
    if (viktor == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final voice = TeacherSpeech.speechOf(context);
    final sound = context.select((SettingsCubit c) => c.state?.sound ?? true);
    Widget balloon = SpeechBalloon(
      key: speechKey,
      tail: BalloonTail.up,
      // A ponta cai no centro do retrato de 64.
      tailX: SpeechBalloon.tailXFor(64),
      speech: speech,
      tapHint: l10n.lessonFullSpeech,
      onTap: speech == null
          ? null
          : () => unawaited(
              showScriptSpeechSheet(
                context,
                viktor: viktor,
                title: l10n.teacherName(viktor.name),
                texts: [speech!],
              ),
            ),
      child: SpeechText(
        text: speech ?? '',
        style: SpeechBalloon.style(context),
      ),
    );
    if (voice != null) {
      balloon = AutoSpeak(
        speech: voice,
        text: speech,
        auto: sound,
        speakerId: 'master',
        child: balloon,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: TeacherSpeech(
            key: viktorKey,
            part: TeacherSpeechPart.header,
            speechContext: SpeechContext.teaching,
            teacher: viktor,
            text: speech,
            avatarSize: CharacterAvatar.tour,
            speaks: true,
            controlsOnlyWithVoice: true,
          ),
        ),
        // O vão de 6 da ponta ao retrato vem do balão.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            0,
          ),
          child: balloon,
        ),
      ],
    );
  }
}
