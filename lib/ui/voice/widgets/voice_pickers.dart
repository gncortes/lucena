import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/voice.dart';
import '../../core/keys/voice_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../view_models/speech_cubit.dart';
import '../../core/theme/app_shape.dart';

/// O idioma do app, para escolher as vozes que falam nele.
String voiceLanguage(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// O nome de uma voz na lista: o do sistema, quando é um nome de gente
/// ("Luciana"); "Voz 2", quando é um código ("pt-br-x-afs-local").
String voiceLabel(BuildContext context, TtsVoice voice, int index) {
  final technical = RegExp(r'[-_.#]|\d').hasMatch(voice.id);
  return technical ? context.l10n.voiceNumber(index + 1) : voice.id;
}

/// O gênero, quando o sistema informa (no iOS).
String? voiceGenderLabel(BuildContext context, TtsVoice voice) =>
    switch (voice.gender) {
      VoiceGender.male => context.l10n.voiceGenderMale,
      VoiceGender.female => context.l10n.voiceGenderFemale,
      null => null,
    };

/// Uma grade de cartões, três por linha.
class VoiceGrid extends StatelessWidget {
  const VoiceGrid({required this.children, super.key});

  final List<Widget> children;

  static const _spacing = 8.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 2 * _spacing) / 3;
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    ),
  );
}

/// Um cartão de escolha: o desenho no alto, o nome e uma linha a mais
/// opcional. Marcado, fica na cor do app com o sinal de escolhido.
class VoiceCard extends StatelessWidget {
  const VoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leading,
    this.detail,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// O desenho do alto: um ícone ([icon]) ou outro widget ([leading]).
  final IconData? icon;
  final Widget? leading;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected ? colors.onPrimaryContainer : colors.onSurface;
    final detail = this.detail;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.large),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 44,
                  child: Center(
                    child:
                        leading ??
                        Icon(
                          selected ? Icons.check : icon,
                          size: 30,
                          color: selected ? colors.primary : foreground,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: selected
                          ? colors.onPrimaryContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A escolha da voz do professor: as vozes do idioma e, com [withNone],
/// "sem voz" (desliga a voz).
class TeacherVoiceList extends StatelessWidget {
  const TeacherVoiceList({this.withNone = false, super.key});

  final bool withNone;

  @override
  Widget build(BuildContext context) {
    final speech = context.read<SpeechCubit>();
    final language = voiceLanguage(context);
    final l10n = context.l10n;
    return BlocBuilder<SpeechCubit, SpeechState>(
      buildWhen: (a, b) => a.settings != b.settings || a.voices != b.voices,
      builder: (context, state) {
        final voices = state.voicesFor(language);
        final current = state.voiceOf(SpeechCubit.teacherId, language)?.voice;
        final enabled = state.settings.enabled;
        final grid = VoiceGrid(
          children: [
            // Tocar escolhe a voz e já a deixa ouvir.
            for (final (i, voice) in voices.indexed)
              VoiceCard(
                key: VoiceKeys.voice(voice.id),
                icon: Icons.record_voice_over_outlined,
                label: voiceLabel(context, voice, i),
                detail: voiceGenderLabel(context, voice),
                selected: (enabled || !withNone) && voice == current,
                onTap: () {
                  speech.setTeacherVoice(voice.id);
                  speech.preview(
                    l10n.voiceTeacherSample,
                    characterId: SpeechCubit.teacherId,
                    voiceId: voice.id,
                    language: language,
                  );
                },
              ),
            if (withNone)
              VoiceCard(
                key: VoiceKeys.none,
                icon: Icons.volume_off_outlined,
                label: l10n.voiceNone,
                selected: !enabled,
                onTap: () => speech.setEnabled(enabled: false),
              ),
          ],
        );
        if (withNone && !enabled) return grid;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            grid,
            VoiceTonePicker(
              characterId: SpeechCubit.teacherId,
              sample: l10n.voiceTeacherSample,
            ),
          ],
        );
      },
    );
  }
}

/// Os adversários, cada um com a voz que tem agora; tocar num abre a
/// escolha.
class CharacterVoiceList extends StatelessWidget {
  const CharacterVoiceList({super.key});

  @override
  Widget build(BuildContext context) {
    final language = voiceLanguage(context);
    return BlocBuilder<SpeechCubit, SpeechState>(
      buildWhen: (a, b) =>
          a.settings != b.settings ||
          a.voices != b.voices ||
          a.characters != b.characters,
      builder: (context, state) {
        final voices = state.voicesFor(language);
        return VoiceGrid(
          children: [
            for (final character in state.characters)
              VoiceCard(
                key: VoiceKeys.character(character.id),
                leading: CharacterAvatar(character: character, size: 44),
                label: character.name,
                detail: switch (state.voiceOf(character.id, language)?.voice) {
                  final voice? => voiceLabel(
                    context,
                    voice,
                    voices.indexOf(voice),
                  ),
                  null => null,
                },
                selected: false,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (_) => BlocProvider.value(
                    value: context.read<SpeechCubit>(),
                    child: CharacterVoiceSheet(character: character),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A escolha da voz de um adversário: "escolhida pelo app" e as vozes do
/// idioma, cada uma com o "ouvir" na fala de apresentação dele.
class CharacterVoiceSheet extends StatelessWidget {
  const CharacterVoiceSheet({required this.character, super.key});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final speech = context.read<SpeechCubit>();
    final language = voiceLanguage(context);
    final l10n = context.l10n;
    final sample = l10n.voiceCharacterSample(character.name);
    return BlocBuilder<SpeechCubit, SpeechState>(
      buildWhen: (a, b) => a.settings != b.settings,
      builder: (context, state) {
        final voices = state.voicesFor(language);
        final chosen = state.settings.characterVoices[character.id];
        final chosenExists = voices.any((v) => v.id == chosen);
        void hear(String voiceId) => speech.preview(
          sample,
          characterId: character.id,
          voiceId: voiceId,
          language: language,
        );
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    leading: CharacterAvatar(character: character, size: 44),
                    title: Text(
                      character.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  VoiceGrid(
                    children: [
                      VoiceCard(
                        key: VoiceKeys.appChoice,
                        icon: Icons.auto_awesome_outlined,
                        label: l10n.voiceAppChoice,
                        selected: !chosenExists,
                        onTap: () {
                          speech.setCharacterVoice(character.id, null);
                          final auto = speech.state.voiceOf(
                            character.id,
                            language,
                          );
                          if (auto != null) hear(auto.voice.id);
                        },
                      ),
                      for (final (i, voice) in voices.indexed)
                        VoiceCard(
                          key: VoiceKeys.voice(voice.id),
                          icon: Icons.record_voice_over_outlined,
                          label: voiceLabel(context, voice, i),
                          detail: voiceGenderLabel(context, voice),
                          selected: chosenExists && voice.id == chosen,
                          onTap: () {
                            speech.setCharacterVoice(character.id, voice.id);
                            hear(voice.id);
                          },
                        ),
                    ],
                  ),
                  VoiceTonePicker(
                    characterId: character.id,
                    sample: sample,
                    withProfile: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Como ter vozes mais naturais: o que fazer nas configurações de voz do
/// aparelho e o botão que abre essa tela.
class SystemVoicesHelp extends StatelessWidget {
  const SystemVoicesHelp({this.missing = false, super.key});

  /// O aparelho não tem voz no idioma: o texto explica isso.
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  missing ? l10n.voiceUnavailable : l10n.voiceBetterHint,
                  key: missing ? VoiceKeys.unavailable : VoiceKeys.betterVoices,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: VoiceKeys.openSystem,
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.voiceOpenSystem),
              onPressed: () => context.read<SpeechCubit>().openSystemVoices(),
            ),
          ),
        ],
      ),
    );
  }
}

/// O tom da voz de [characterId]: grave, natural, suave ou agudo. Tocar num
/// grava e fala uma amostra nele. [withProfile]: o adversário pode voltar
/// ao tom do perfil dele ("escolhido pelo app").
class VoiceTonePicker extends StatelessWidget {
  const VoiceTonePicker({
    required this.characterId,
    required this.sample,
    this.withProfile = false,
    super.key,
  });

  final String characterId;
  final String sample;
  final bool withProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final speech = context.read<SpeechCubit>();
    final language = voiceLanguage(context);
    final tone = context.select(
      (SpeechCubit cubit) => cubit.state.toneOf(characterId),
    );
    String label(VoiceTone tone) => switch (tone) {
      VoiceTone.deep => l10n.voiceToneDeep,
      VoiceTone.natural => l10n.voiceToneNatural,
      VoiceTone.soft => l10n.voiceToneSoft,
      VoiceTone.high => l10n.voiceToneHigh,
    };
    void choose(VoiceTone? tone) =>
        speech.setTone(characterId, tone, sample: sample, language: language);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.voiceTone, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (withProfile)
                ChoiceChip(
                  key: VoiceKeys.tone(null),
                  label: Text(l10n.voiceAppChoice),
                  selected: tone == null,
                  onSelected: (_) => choose(null),
                ),
              for (final option in VoiceTone.values)
                ChoiceChip(
                  key: VoiceKeys.tone(option),
                  label: Text(label(option)),
                  selected: tone == option,
                  onSelected: (_) => choose(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
