import 'dart:math' as math;
import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

import 'speech_balloon.dart';
import 'speech_text_tap_notification.dart';
import 'explanation_cards.dart';
import '../../../domain/models/explanation.dart';
import 'viktor_sheet.dart';
import '../keys/viktor_sheet_keys.dart';

import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/wiki_links.dart';
import '../../../domain/use_cases/speech_links.dart';
import '../../../domain/use_cases/wiki_markup.dart';
import '../../../routing/routes.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../../voice/widgets/auto_speak.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../wiki/view_models/wiki_links_cubit.dart';
import '../keys/voice_keys.dart';
import '../l10n/l10n.dart';
import 'character_avatar.dart';
import 'external_page_sheet.dart';
import '../theme/lesson_text_colors.dart';
import 'sound_off_icon.dart';
import 'speech_sheet_fade.dart';

/// Onde a fala acontece, que decide o desenho do balão (regra da T51, G1).
enum SpeechContext {
  /// O professor explica: retrato e nome numa linha e o balão embaixo, na
  /// largura toda, com a ponta virada para o retrato. Falas longas.
  teaching,

  /// O adversário reage na partida: retrato e o balão ao lado, como a
  /// `CharacterBar`. Falas curtas (até 90 caracteres, `check_lines.py`).
  game,
}

/// O professor falando com o aluno: o retrato com a emoção e o balão, que
/// troca de fala com uma transição suave. O desenho vem do [speechContext],
/// sem valor padrão: quem usa diz se é ensino ou partida.
/// Que pedaço da fala desenhar: tudo, só o cabeçalho (retrato, nome e os
/// botões de voz) ou só o balão. A tela pode separar os dois (o cabeçalho
/// acima do tabuleiro e o balão na folha); quem fala sozinho é o balão.
enum TeacherSpeechPart { all, header, bubble }

class TeacherSpeech extends StatelessWidget {
  const TeacherSpeech({
    this.part = TeacherSpeechPart.all,
    this.explanation,
    this.lessonV2 = false,
    this.headerAvatar,
    this.avatarHeroTag,
    this.onVariation,
    this.activeVariation,
    required this.teacher,
    required this.text,
    required this.speechContext,
    this.emotion = Emotion.calm,
    this.avatarSize = CharacterAvatar.speech,
    this.compactInSheet = false,
    this.bubbleKey,
    this.typed = false,
    this.speaks = false,
    this.controlsOnlyWithVoice = false,
    this.onLink,
    this.onSpoken,
    this.headerAction,
    this.onSoundSettings,
    super.key,
  });

  final Character teacher;
  final ExplanationPayload? explanation;
  final bool lessonV2;

  /// Na lição V2, o retrato do cabeçalho maior que o padrão (28), com raio 6
  /// (lição roteirizada, T70).
  final double? headerAvatar;

  /// Com valor, o retrato voa como `Hero` com esta tag (a fala inteira da
  /// lição roteirizada, T70).
  final Object? avatarHeroTag;

  final ValueChanged<VariationCursor?>? onVariation;
  final VariationCursor? activeVariation;

  /// Ver [TeacherSpeechPart].
  final TeacherSpeechPart part;

  /// Com tabuleiro na tela: as casas e os lances da fala ficam tocáveis e
  /// chamam [onLink] (a tela mostra ou tira do tabuleiro). Nulo: texto
  /// simples.
  final ValueChanged<SpeechLink>? onLink;

  /// Com a voz falando, cada casa ou lance quando a voz chega nele.
  final ValueChanged<SpeechLink>? onSpoken;

  /// Um botão a mais no cabeçalho, antes dos de voz (ex.: as marcações da
  /// lição).
  final Widget? headerAction;

  /// Lesson V2 opens its dedicated sound panel without changing preferences.
  final VoidCallback? onSoundSettings;

  /// A fala. Nula: só o retrato e o nome. Pode trazer nomes marcados
  /// (`{{Andersson|ulf-andersson}}`, ver [WikiMarkup]): na tela, sublinhados
  /// e tocáveis (abrem a Wikipedia); na voz, só o texto visível.
  final String? text;

  /// A fala sem a marcação: o que aparece e o que a voz lê.
  String? get _plain {
    if (activeVariation case final cursor?) {
      return cursor.texts.map(WikiMarkup.plain).join('\n\n');
    }
    return explanation == null
        ? (text == null ? null : WikiMarkup.plain(text!))
        : explanation!.explanations
              .expand((block) => block.texts)
              .map(WikiMarkup.plain)
              .join('\n\n');
  }

  final Emotion emotion;
  final double avatarSize;

  /// Na folha recolhida, retrato e texto ficam lado a lado. O cabeçalho
  /// completo reaparece no modal; fonte, fala e links são preservados.
  final bool compactInSheet;
  bool _compact(BuildContext context) =>
      compactInSheet && !ViktorSheet.expandedOf(context);

  final Key? bubbleKey;

  /// Ensino (balão embaixo do retrato) ou partida (balão ao lado).
  final SpeechContext speechContext;

  bool _stackedIn(BuildContext context) =>
      speechContext == SpeechContext.teaching || ViktorSheet.insideOf(context);

  /// A fala aparece aos poucos, como quem fala. Um toque mostra tudo.
  final bool typed;

  /// Com a voz ligada, a fala nova sai em voz alta sozinha. O botão de
  /// áudio aparece sempre que há voz no idioma.
  final bool speaks;

  /// Sem voz escolhida, o cabeçalho fica sem a velocidade e sem o botão de
  /// som (tour, PropV2TourBVoz); com voz, mostra os dois.
  final bool controlsOnlyWithVoice;

  @override
  Widget build(BuildContext context) {
    Widget avatar = CharacterAvatar(
      character: teacher,
      emotion: emotion,
      // LICOES-V2 §9: retrato de 28 dp, raio 8, na linha de 48 dp.
      size: lessonV2
          ? (headerAvatar ?? CharacterAvatar.mini)
          : (_compact(context) ? CharacterAvatar.mini : avatarSize),
      radius: lessonV2 ? (headerAvatar == null ? 8 : 6) : null,
    );
    if (avatarHeroTag case final tag?) avatar = Hero(tag: tag, child: avatar);
    if (part == TeacherSpeechPart.header) {
      // Só o cabeçalho: os botões de voz valem para a fala, mas quem a diz
      // sozinho é o balão (sem repetir a voz).
      return _headerRow(context, avatar);
    }
    final speech = speechOf(context);
    final text = _plain;
    final content = _RevealOnChange(
      text: text,
      child: _layout(context, avatar),
    );
    if (speech == null) return content;
    final soundEnabled = _soundEnabled(context);
    final speakingContent = AutoSpeak(
      speech: speech,
      text: text,
      auto: speaks && soundEnabled,
      speakerId: teacher.id,
      child: content,
    );
    final settings = _settingsOf(context);
    if (!_stackedIn(context) || settings == null) return speakingContent;
    return BlocListener<SettingsCubit, AppSettings?>(
      bloc: settings,
      listenWhen: (before, after) =>
          (before?.sound ?? true) && !(after?.sound ?? true),
      listener: (_, _) => speech.stopIf(text),
      child: speakingContent,
    );
  }

  SettingsCubit? _settingsOf(BuildContext context) {
    try {
      return context.read<SettingsCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  bool _soundEnabled(BuildContext context) {
    if (!_stackedIn(context)) return true;
    try {
      return context.watch<SettingsCubit>().state?.sound ?? true;
    } on ProviderNotFoundException {
      return true;
    }
  }

  /// A voz do app, se houver (fora do app, nos testes de um widget só, não
  /// há).
  static SpeechCubit? speechOf(BuildContext context) {
    try {
      return context.read<SpeechCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// As páginas da Wikipedia dos nomes, se o app as tem (fora do app, nos
  /// testes de um widget só, não há: os nomes ficam como texto normal).
  static WikiLinks wikiOf(BuildContext context) {
    try {
      return context.watch<WikiLinksCubit>().state;
    } on ProviderNotFoundException {
      return WikiLinks.empty;
    }
  }

  /// O nome e, havendo voz no idioma, o botão de áudio.
  Widget _header(BuildContext context) {
    final speech = speechOf(context);
    final soundEnabled = _soundEnabled(context);
    final text = _plain;
    final action = headerAction;
    if (speech == null || text == null) {
      return action == null
          ? _name(context)
          : Row(
              children: [
                Expanded(child: _name(context)),
                action,
              ],
            );
    }
    final language = Localizations.localeOf(context).toLanguageTag();
    return Row(
      children: [
        Expanded(child: _name(context)),
        ?action,
        BlocBuilder<SpeechCubit, SpeechState>(
          bloc: speech,
          buildWhen: (a, b) =>
              a.isSpeaking(text) != b.isSpeaking(text) ||
              a.settings.speed != b.settings.speed ||
              a.settings.enabled != b.settings.enabled ||
              a.availableFor(language) != b.availableFor(language),
          builder: (context, state) {
            if (lessonV2) {
              final audible =
                  soundEnabled &&
                  state.settings.enabled &&
                  state.availableFor(language);
              return LessonVoiceButton(
                audible: audible,
                speed: state.settings.speed,
                onPressed: onSoundSettings,
              );
            }
            // Sem voz no idioma, o botão de som continua à vista: o toque
            // leva aos ajustes de voz, onde se instala uma.
            if (controlsOnlyWithVoice && !state.settings.enabled) {
              return const SizedBox.shrink();
            }
            if (!state.availableFor(language)) {
              return IconButton(
                key: VoiceKeys.speakButton,
                visualDensity: lessonV2
                    ? VisualDensity.standard
                    : VisualDensity.compact,
                tooltip: context.l10n.voiceSection,
                icon: const SoundOffIcon(),
                onPressed: () => context.push(Routes.settingsVoice),
              );
            }
            final speaking = state.isSpeaking(text);
            final l10n = context.l10n;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A velocidade da voz: cada toque passa para a próxima.
                // Voz desligada: sem o chip de velocidade (CompFalaViktor, `voz`).
                if (soundEnabled && state.settings.enabled)
                  TextButton(
                    key: VoiceKeys.speedButton,
                    style: TextButton.styleFrom(
                      visualDensity: lessonV2
                          ? VisualDensity.standard
                          : VisualDensity.compact,
                      minimumSize: Size(48, lessonV2 ? 48 : 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                    ),
                    onPressed: soundEnabled ? speech.nextSpeed : null,
                    child: Tooltip(
                      message: l10n.voiceSpeed,
                      child: Text(l10n.voiceSpeedValue(state.settings.speed)),
                    ),
                  ),
                // Onde ele fala sozinho, um botão só: ligado, um toque cala
                // a voz dele (a escolha fica gravada); desligado, liga e já
                // fala. Nos outros balões, ouvir e parar.
                if (speaks)
                  IconButton(
                    key: VoiceKeys.speakButton,
                    visualDensity: lessonV2
                        ? VisualDensity.standard
                        : VisualDensity.compact,
                    tooltip: state.settings.enabled
                        ? l10n.voiceAutoOff(teacher.name)
                        : l10n.voiceAutoOn(teacher.name),
                    isSelected: !state.settings.enabled,
                    icon: const Icon(Icons.volume_up_outlined),
                    selectedIcon: const SoundOffIcon(),
                    onPressed: () async {
                      if (_stackedIn(context) &&
                          !(_settingsOf(context)?.state?.sound ?? true)) {
                        return;
                      }
                      if (state.settings.enabled) {
                        await speech.setEnabled(enabled: false);
                        return;
                      }
                      await speech.setEnabled(enabled: true);
                      if (!context.mounted ||
                          !speech.state.settings.enabled ||
                          (_stackedIn(context) &&
                              !(_settingsOf(context)?.state?.sound ?? true))) {
                        return;
                      }
                      await speech.say(
                        text,
                        speakerId: teacher.id,
                        language: language,
                      );
                    },
                  )
                else
                  IconButton(
                    key: VoiceKeys.speakButton,
                    visualDensity: lessonV2
                        ? VisualDensity.standard
                        : VisualDensity.compact,
                    tooltip: speaking ? l10n.voiceStop : l10n.voiceListen,
                    isSelected: speaking,
                    icon: const Icon(Icons.volume_up_outlined),
                    selectedIcon: const Icon(Icons.stop_circle_outlined),
                    onPressed: soundEnabled
                        ? () => speech.toggle(
                            text,
                            speakerId: teacher.id,
                            language: language,
                          )
                        : null,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _layout(BuildContext context, Widget avatar) {
    if (part == TeacherSpeechPart.bubble) return _closable(context);
    if (_compact(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          SizedBox(width: lessonV2 ? 8 : 10),
          Expanded(child: _closable(context)),
        ],
      );
    }
    if (_stackedIn(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // O vão de 6 da ponta ao retrato vem do balão.
          _headerRow(context, avatar),
          _closable(context),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        // O nome a 14 do retrato; o vão de 6 da ponta vem do balão.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
                child: _header(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              _closable(context),
            ],
          ),
        ),
      ],
    );
  }

  /// Retrato, nome e botões. Na lição V2 é a linha de 48 dp do canvas
  /// (`cabecalho(c, 'linha')`): retrato 28, 8 dp, nome, som na ponta.
  Widget _headerRow(BuildContext context, Widget avatar) {
    final row = Row(
      children: [
        avatar,
        SizedBox(width: lessonV2 ? 8 : 10),
        Expanded(child: _header(context)),
      ],
    );
    if (!lessonV2) return row;
    final avatarSize = headerAvatar ?? 0;
    return SizedBox(
      key: ViktorSheetKeys.header,
      height: avatarSize > 48 ? avatarSize : 48,
      child: row,
    );
  }

  /// "Mestre" é só do Viktor; os adversários aparecem só pelo nome.
  String _label(BuildContext context) =>
      teacher.isMaster ? context.l10n.teacherName(teacher.name) : teacher.name;

  Widget _name(BuildContext context) {
    final name = _plainName(context);
    // Na faixa que abre a folha da fala (o retrato voa até ela), o nome some
    // junto enquanto a folha está aberta.
    return avatarHeroTag == null ? name : SpeechSheetFade(child: name);
  }

  Widget _plainName(BuildContext context) {
    final theme = Theme.of(context);
    if (lessonV2) {
      return Text(
        _label(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    return Text(
      _label(context),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          (_stackedIn(context)
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.labelLarge)
              ?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
    );
  }

  /// O balão (ou, na folha, o texto direto). Sem ✕: a folha tem o dela.
  Widget _closable(BuildContext context) => _speech(context);

  /// O balão, que troca de fala com uma transição suave.
  Widget _speech(BuildContext context) {
    if (explanation case final payload?) {
      var paragraphIndex = 0;
      return ExplanationCards(
        payload: payload,
        lessonV2: lessonV2,
        onVariation: onVariation,
        activeCursor: activeVariation,
        hasInlineNavigation: (text, variation, origin) =>
            onVariation != null &&
            // O rótulo real é "A"/"B": vale o primeiro lance da variação.
            variation.movesSan.isNotEmpty &&
            SpeechLinks.find(
              variation.movesSan.first,
              SpeechLinks.lettersFor(
                Localizations.localeOf(context).languageCode,
              ),
            ).any(
              (link) => link.isMove && link.text == variation.movesSan.first,
            ) &&
            SpeechLinks.find(
              WikiMarkup.plain(text),
              SpeechLinks.lettersFor(
                Localizations.localeOf(context).languageCode,
              ),
            ).any(
              (link) =>
                  link.isMove &&
                  payload
                          .cursorForNotation(
                            link.text,
                            preferred: origin,
                            strictPreferred: origin != null,
                          )
                          ?.variation
                          .id ==
                      variation.id,
            ),
        groupedParagraph: (paragraphs) {
          final text = paragraphs.map((p) => p.text).join('\n\n');
          ExplanationVariation? originOf(SpeechLink link) {
            var start = 0;
            for (final paragraph in paragraphs) {
              final end = start + WikiMarkup.plain(paragraph.text).length;
              if (link.start >= start && link.start < end) {
                return paragraph.variation;
              }
              start = end + 2;
            }
            return null;
          }

          return _bubble(
            context,
            WikiMarkup.parse(text),
            useBubbleKey: paragraphIndex++ == 0,
            originOf: originOf,
            onLinkOverride: (link) {
              final origin = originOf(link);
              final cursor = link.isMove
                  ? payload.cursorForNotation(
                      link.text,
                      preferred: origin,
                      strictPreferred: origin != null,
                    )
                  : null;
              if (cursor != null && onVariation != null) {
                onVariation!(cursor);
              } else {
                onLink?.call(link);
              }
            },
          );
        },
        paragraph: (text) => _bubble(
          context,
          WikiMarkup.parse(text),
          useBubbleKey: paragraphIndex++ == 0,
        ),
        variationParagraph: (text, variation) => _bubble(
          context,
          WikiMarkup.parse(text),
          useBubbleKey: paragraphIndex++ == 0,
          originOf: (_) => variation,
          onLinkOverride: variation == null
              ? null
              : (link) {
                  final cursor = link.isMove
                      ? payload.cursorForNotation(
                          link.text,
                          preferred: variation,
                          strictPreferred: true,
                        )
                      : null;
                  if (cursor != null && onVariation != null) {
                    onVariation!(cursor);
                  } else {
                    onLink?.call(link);
                  }
                },
        ),
      );
    }
    final text = this.text;
    final plain = _plain;
    return AnimatedSize(
      duration: AppMotion.state,
      curve: AppMotion.enter,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: AppMotion.component,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        layoutBuilder: (current, previous) => Stack(
          alignment: AlignmentDirectional.topStart,
          children: [?current],
        ),
        child: text == null || plain == null
            ? const SizedBox(width: double.infinity)
            : KeyedSubtree(
                key: ValueKey(plain),
                child: _bubble(context, WikiMarkup.parse(text)),
              ),
      ),
    );
  }

  /// O texto que aparece aos poucos; com a voz, acompanha até onde ela
  /// chegou.
  Widget _typed(
    BuildContext context,
    String text,
    Text words,
    bool Function(int)? onTapAt,
    int Function(int) toDrawn, {
    List<(int, int)>? snap,
  }) {
    final speech = speechOf(context);
    if (speech == null) {
      return _TypedText(
        key: ValueKey(text),
        text: words,
        onTapAt: onTapAt,
        snap: snap,
      );
    }
    final language = Localizations.localeOf(context).toLanguageTag();
    final state = speech.state;
    // Vai falar sozinho: o texto anda no passo da voz, não no da leitura.
    final paced =
        speaks &&
        state.settings.enabled &&
        state.availableFor(language) &&
        !MediaQuery.accessibleNavigationOf(context);
    return BlocBuilder<SpeechCubit, SpeechState>(
      bloc: speech,
      buildWhen: (a, b) =>
          a.isSpeaking(text) != b.isSpeaking(text) ||
          (b.isSpeaking(text) && a.revealed != b.revealed),
      builder: (context, state) => _TypedText(
        // Fala nova no mesmo lugar (explicação seguinte): digita de novo.
        key: ValueKey(text),
        text: words,
        onTapAt: onTapAt,
        snap: snap,
        paced: paced,
        speaking: state.isSpeaking(text),
        // The voice counts in the source text; the clip, in the drawn one.
        revealed: state.isSpeaking(text)
            ? switch (state.revealed) {
                final revealed? => toDrawn(revealed),
                null => null,
              }
            : null,
      ),
    );
  }

  /// O destaque do lance que está no tabuleiro, pintado atrás do texto.
  Widget _withBackdrop(
    Text words,
    (int, int)? range,
    Color color,
    Widget child,
  ) => _MoveBackdrop(text: words, range: range, color: color, child: child);

  Widget _bubble(
    BuildContext context,
    MarkedText marked, {
    bool useBubbleKey = true,
    ValueChanged<SpeechLink>? onLinkOverride,
    ExplanationVariation? Function(SpeechLink)? originOf,
  }) {
    final text = marked.text;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    // Os nomes com página na Wikipedia; chave sem página: texto normal.
    final wiki = wikiOf(context);
    final pages = [
      for (final mark in marked.marks)
        if (!lessonV2)
          if (wiki.url(mark.key, language) case final url?) (mark, url),
    ];
    final onLink = onLinkOverride ?? this.onLink;
    final links = onLink == null
        ? const <SpeechLink>[]
        : [
            for (final link in SpeechLinks.find(
              text,
              SpeechLinks.lettersFor(language),
            ))
              // Dentro de um nome, não é casa nem lance.
              if (!pages.any(
                (page) => link.start < page.$1.end && link.end > page.$1.start,
              ))
                link,
          ];
    final section = lessonV2 || ViktorSheet.insideOf(context);
    final colors = theme.colorScheme;
    // Corpo da lição V2: 15/22,5, peso 400, onSurface.
    final style = theme.textTheme.bodyLarge?.copyWith(
      fontSize: section ? 15 : null,
      height: section ? 1.5 : null,
      fontWeight: section ? FontWeight.w400 : null,
      color: section ? colors.onSurface : null,
    );
    // As casas e os lances na cor primária: tocáveis sem parecer link de
    // site. Na lição V2 o lance é peso 500, mesmo com `?`/`!` (o símbolo
    // carrega o resultado); fora dela, seminegrito.
    final linkStyle = TextStyle(
      color: colors.primary,
      fontWeight: section ? FontWeight.w500 : AppWeight.strong,
    );
    // A casa citada (variante A): um tom mais claro que o do lance.
    final squareStyle = linkStyle.copyWith(
      color: LessonTextColors.square(colors),
    );
    // Os nomes, sublinhados como link de site: abrem a Wikipedia.
    final pageStyle = TextStyle(
      color: colors.primary,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.underline,
      decorationColor: colors.primary,
    );
    bool isActiveMove(SpeechLink link) {
      final active = activeVariation;
      if (!lessonV2 || !link.isMove || active == null) return false;
      final origin = originOf?.call(link);
      final cursor = explanation?.cursorForNotation(
        link.text,
        preferred: origin,
        strictPreferred: origin != null,
      );
      return cursor != null &&
          cursor.variation.id == active.variation.id &&
          cursor.fen == active.fen &&
          cursor.ply == active.ply;
    }

    // Parágrafos da mesma ideia viram um só fluxo (0 dp entre eles): o par de
    // quebras vira espaço, de mesmo tamanho para não mexer nos deslocamentos.
    Iterable<InlineSpan> plainSpans(String value, int offset) sync* {
      yield TextSpan(
        text: lessonV2 ? value.replaceAll('\n\n', ' \u200B') : value,
      );
    }

    final spans = [
      for (final link in links)
        (
          link.start,
          link.end,
          link.isMove || !lessonV2 ? linkStyle : squareStyle,
        ),
      for (final (mark, _) in pages) (mark.start, mark.end, pageStyle),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    // Authored fallback prose keeps its own reading direction while the
    // surrounding controls follow the selected app locale.
    final direction = lessonV2
        ? Bidi.detectRtlDirectionality(text)
              ? TextDirection.rtl
              : TextDirection.ltr
        : null;
    // In an RTL paragraph the move number after an Arabic letter would be
    // reordered ("Ke3.1"): each notation is isolated as LTR (LRI…PDI). The
    // drawn text then differs from the source; [offsets] maps the two.
    final offsets = _BidiOffsets(
      lessonV2 && (direction ?? Directionality.of(context)) == TextDirection.rtl
          ? [
              for (final link in SpeechLinks.find(
                text,
                SpeechLinks.lettersFor(language),
              ))
                (link.start, link.end),
            ]
          : const [],
    );
    InlineSpan? styledSpans() {
      if (spans.isEmpty && !lessonV2) return null;
      final breaks = <int>{
        0,
        text.length,
        for (final (start, end, _) in spans) ...[start, end],
        for (final (start, end) in offsets.ranges) ...[start, end],
      }.toList()..sort();
      return TextSpan(
        children: [
          for (var i = 0; i < breaks.length; i++) ...[
            if (offsets.endsAt(breaks[i])) const TextSpan(text: _pdi),
            if (offsets.startsAt(breaks[i])) const TextSpan(text: _lri),
            if (i + 1 < breaks.length)
              if (spans
                      .where(
                        (span) => span.$1 <= breaks[i] && span.$2 > breaks[i],
                      )
                      .firstOrNull
                  case final span?)
                TextSpan(
                  text: text.substring(breaks[i], breaks[i + 1]),
                  style: span.$3,
                )
              else
                ...plainSpans(
                  text.substring(breaks[i], breaks[i + 1]),
                  breaks[i],
                ),
          ],
        ],
      );
    }

    final rich = styledSpans();
    final words = rich == null
        ? Text(text, key: useBubbleKey ? bubbleKey : null, style: style)
        : Text.rich(
            rich,
            key: useBubbleKey ? bubbleKey : null,
            style: style,
            textDirection: direction,
          );
    // O toque numa letra: o trecho que a contém (ou que termina nela). Diz
    // se havia trecho ali.
    // Tocar numa casa abre o destaque dela e baixa o painel até a borda do
    // tabuleiro (A11); o lance só chama [onLink].
    void fire(SpeechLink link) {
      if (lessonV2 && !link.isMove) ViktorSheet.collapse(context);
      onLink!(link);
    }

    bool tapAt(int drawn) {
      final offset = offsets.toSource(drawn);
      for (final (mark, url) in pages) {
        if (offset >= mark.start && offset < mark.end) {
          showExternalPage(context, url);
          return true;
        }
      }
      for (final link in links) {
        if (offset >= link.start && offset <= link.end) {
          fire(link);
          return true;
        }
      }
      return false;
    }

    final tappable = spans.isEmpty ? null : tapAt;
    // Alvo de toque de 48 dp (A6): o toque perto do glifo vale no link mais
    // próximo. Só na lição V2.
    final snap = lessonV2
        ? [
            for (final link in links)
              (offsets.toDrawn(link.start), offsets.toDrawn(link.end)),
          ]
        : null;
    final activeLink = links.where(isActiveMove).firstOrNull;
    final content = Semantics(
      liveRegion: true,
      label: context.l10n.characterSays(teacher.name, text),
      excludeSemantics: true,
      // Com leitor de tela: uma ação por casa ou lance.
      customSemanticsActions: {
        for (final (mark, url) in pages)
          CustomSemanticsAction(label: context.l10n.wikiOpen(mark.text)): () =>
              showExternalPage(context, url),
        for (final link in links)
          CustomSemanticsAction(
            label: context.l10n.speechShowOnBoard(link.text),
          ): () =>
              fire(link),
      },
      child: _VoiceLinks(
        text: text,
        links: links,
        onLink: onSpoken,
        child: _withBackdrop(
          words,
          activeLink == null
              ? null
              : (
                  offsets.toDrawn(activeLink.start),
                  offsets.toDrawn(activeLink.end),
                ),
          LessonTextColors.activeMoveBackground(colors),
          typed
              ? _typed(
                  context,
                  text,
                  words,
                  tappable,
                  offsets.toDrawn,
                  snap: snap,
                )
              : tappable == null
              ? words
              : _LinkTapper(text: words, onTapAt: tappable, snap: snap),
        ),
      ),
    );
    if (section) return SizedBox(width: double.infinity, child: content);
    // O balão único do app (branco, ponta e animação de `SpeechBalloon`): a
    // ponta fica embaixo do meio do retrato no ensino e ao lado na partida.
    final stacked = _stackedIn(context);
    return SpeechBalloon(
      pop: false,
      tail: _compact(context) || part == TeacherSpeechPart.bubble
          ? BalloonTail.none
          : stacked
          ? BalloonTail.up
          : BalloonTail.start,
      tailX: SpeechBalloon.tailXFor(avatarSize),
      tailY: avatarSize / 2,
      child: content,
    );
  }
}

const _lri = '\u2066';
const _pdi = '\u2069';

/// The LTR isolates wrapped around notations in an RTL paragraph, and the map
/// between offsets in the drawn text (with the isolates) and in the source
/// text (what Semantics, the voice and the links use).
class _BidiOffsets {
  _BidiOffsets(this.ranges)
    : _inserts = [
        for (final (start, end) in ranges) ...[start, end],
      ]..sort();

  /// Source ranges isolated as LTR, in order and without overlap.
  final List<(int, int)> ranges;

  /// Source offsets before which one isolate character is drawn.
  final List<int> _inserts;

  bool startsAt(int offset) => ranges.any((range) => range.$1 == offset);
  bool endsAt(int offset) => ranges.any((range) => range.$2 == offset);

  /// The drawn offset of the source character at [source].
  int toDrawn(int source) =>
      source + _inserts.where((insert) => insert <= source).length;

  /// The source offset of the drawn character at [drawn]; an isolate maps to
  /// the edge of the notation it wraps.
  int toSource(int drawn) {
    for (final (index, insert) in _inserts.indexed) {
      final at = insert + index;
      if (drawn == at) return insert;
      if (drawn < at) return drawn - index;
    }
    return drawn - _inserts.length;
  }
}

/// Uma fala nova: se o começo dela está fora da área que rola (o aluno desceu
/// para ler a anterior, longa), a tela rola suavemente até o retrato.
class _RevealOnChange extends StatefulWidget {
  const _RevealOnChange({required this.text, required this.child});

  final String? text;
  final Widget child;

  @override
  State<_RevealOnChange> createState() => _RevealOnChangeState();
}

class _RevealOnChangeState extends State<_RevealOnChange> {
  @override
  void didUpdateWidget(_RevealOnChange old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text && widget.text != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  void _reveal() {
    if (!mounted) return;
    final scrollable = Scrollable.maybeOf(context);
    final box = context.findRenderObject();
    final viewport = scrollable?.context.findRenderObject();
    if (scrollable == null || box is! RenderBox || viewport is! RenderBox) {
      return;
    }
    if (!box.attached || !viewport.attached) return;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    // O começo à vista, com uma folga para a primeira linha: nada a fazer.
    if (top >= 0 && top <= viewport.size.height - 48) return;
    Scrollable.ensureVisible(
      context,
      duration: AppMotion.of(context).component,
      curve: AppMotion.enter,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A ponta do balão: um triângulo virado para cima.
/// A fala aparecendo aos poucos. O texto já ocupa o lugar todo (o balão não
/// pula nem muda de tamanho) e é revelado letra a letra por um recorte; um
/// toque mostra tudo. Com as animações desligadas no aparelho, aparece de uma
/// vez.
class _TypedText extends StatefulWidget {
  const _TypedText({
    required this.text,
    super.key,
    this.onTapAt,
    this.snap,
    this.paced = false,
    this.speaking = false,
    this.revealed,
  });

  final Text text;

  /// Um toque numa letra já à vista: a posição dela. Devolve se havia uma
  /// casa ou um lance ali.
  final bool Function(int)? onTapAt;

  /// Os trechos (casas e lances) onde o toque perto vale, em posições do
  /// texto desenhado; ver [_tapNear].
  final List<(int, int)>? snap;

  /// A voz vai falar: o texto anda no passo de quem fala.
  final bool paced;

  /// A voz está falando este texto.
  final bool speaking;

  /// Até onde a voz chegou (posição no texto). Nulo: sem andamento.
  final int? revealed;

  @override
  State<_TypedText> createState() => _TypedTextState();
}

class _TypedTextState extends State<_TypedText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  TextPainter? _painter;
  double? _width;
  double? _minWidth;

  int get _length => _span.toPlainText().length;

  // O texto como trecho (simples ou com as casas destacadas).
  InlineSpan get _span =>
      widget.text.textSpan ?? TextSpan(text: widget.text.data);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.typedText(_length, paced: widget.paced),
    )..forward();
  }

  @override
  void didUpdateWidget(_TypedText old) {
    super.didUpdateWidget(old);
    // Another text (or direction) in the same place: measure it again.
    if (old.text.textSpan != widget.text.textSpan ||
        old.text.data != widget.text.data ||
        old.text.textDirection != widget.text.textDirection ||
        old.text.style != widget.text.style) {
      _painter?.dispose();
      _painter = null;
    }
    final revealed = widget.revealed;
    if (revealed != null && revealed != old.revealed && _length > 0) {
      // A voz conta onde está: o texto vai até a palavra falada.
      final target = (revealed / _length).clamp(0.0, 1.0);
      if (target > _controller.value) {
        _controller.animateTo(target, duration: AppMotion.tap);
      } else {
        _controller.stop();
      }
    }
    // A voz terminou (ou parou): a fala inteira à vista.
    if (old.speaking && !widget.speaking) _controller.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Estilo, escala ou direção mudaram: as linhas são medidas de novo.
    _painter?.dispose();
    _painter = null;
  }

  @override
  void dispose() {
    _controller.dispose();
    _painter?.dispose();
    super.dispose();
  }

  /// As linhas do texto na largura [width], medidas como o [Text] as desenha.
  TextPainter _measure(BuildContext context, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final cached = _painter;
    if (cached != null &&
        _width == width &&
        _minWidth == constraints.minWidth) {
      return cached;
    }
    cached?.dispose();
    var style = DefaultTextStyle.of(context).style.merge(widget.text.style);
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    _width = width;
    _minWidth = constraints.minWidth;
    return _painter = TextPainter(
      text: TextSpan(style: style, children: [_span]),
      textDirection: widget.text.textDirection ?? Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      // Same width as the RenderParagraph, so RTL lines line up with it.
    )..layout(minWidth: constraints.minWidth, maxWidth: width);
  }

  @override
  Widget build(BuildContext context) {
    final onTapAt = widget.onTapAt;
    if (AppMotion.of(context).disabled) {
      return onTapAt == null
          ? widget.text
          : _LinkTapper(text: widget.text, onTapAt: onTapAt, snap: widget.snap);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = _measure(context, constraints);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Numa casa ou lance já à vista, o toque vale nele (mesmo com a
          // fala ainda aparecendo); fora deles, mostra a fala inteira.
          onTapUp: (details) {
            final shown = (_controller.value * _length).ceil();
            if (onTapAt != null &&
                _tapNear(
                  painter,
                  details.localPosition,
                  (offset) => offset < shown && onTapAt(offset),
                  snap: widget.snap,
                )) {
              return;
            }
            _controller.value = 1;
            SpeechTextTapNotification().dispatch(context);
          },
          child: Builder(
            builder: (context) {
              return AnimatedBuilder(
                animation: _controller,
                // Pelo valor, não pelo estado: depois de ir até a palavra falada
                // (animateTo), o controle fica "completo" no meio do texto, e a
                // fala inteira piscaria a cada palavra.
                builder: (context, child) => _controller.value >= 1
                    ? child!
                    : ClipPath(
                        clipper: _RevealClipper(
                          painter,
                          (_controller.value * _length).ceil(),
                        ),
                        child: child,
                      ),
                child: widget.text,
              );
            },
          ),
        );
      },
    );
  }
}

/// Um texto com casas tocáveis, sem a revelação letra a letra: mede o texto
/// como ele é desenhado e acha a letra tocada.
/// O toque do dedo erra por pouco uma casa curta como "a7": vale a casa ou o
/// lance no ponto tocado ou, se não houver, o mais perto dele (até uns 20 px
/// para os lados ou meia linha para cima e para baixo).
bool _tapNear(
  TextPainter painter,
  Offset at,
  bool Function(int) onTapAt, {
  List<(int, int)>? snap,
}) {
  if (snap != null) {
    // LICOES-V2 §2 (A6): alvo de pelo menos 48×48 dp em volta do centro da
    // caixa do glifo, sem mudar a altura da linha. Vale o link de menor
    // distância ao centro.
    (int, int)? best;
    var bestDistance = double.infinity;
    for (final range in snap) {
      for (final box in painter.getBoxesForSelection(
        TextSelection(baseOffset: range.$1, extentOffset: range.$2),
      )) {
        final rect = box.toRect();
        final target = Rect.fromCenter(
          center: rect.center,
          width: math.max(rect.width, 48),
          height: math.max(rect.height, 48),
        );
        if (!target.contains(at)) continue;
        final distance = (at - rect.center).distance;
        if (distance < bestDistance) {
          bestDistance = distance;
          best = range;
        }
      }
    }
    if (best != null && onTapAt(best.$1)) return true;
  }
  const near = [
    Offset.zero,
    Offset(-10, 0),
    Offset(10, 0),
    Offset(-20, 0),
    Offset(20, 0),
    Offset(0, -10),
    Offset(0, 10),
  ];
  for (final delta in near) {
    if (onTapAt(painter.getPositionForOffset(at + delta).offset)) return true;
  }
  return false;
}

class _LinkTapper extends StatelessWidget {
  const _LinkTapper({required this.text, required this.onTapAt, this.snap});

  final Text text;
  final bool Function(int) onTapAt;
  final List<(int, int)>? snap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          var style = DefaultTextStyle.of(context).style.merge(text.style);
          if (MediaQuery.boldTextOf(context)) {
            style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
          }
          final painter =
              TextPainter(
                text: TextSpan(
                  style: style,
                  children: [text.textSpan ?? TextSpan(text: text.data)],
                ),
                textDirection: text.textDirection ?? Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                locale: Localizations.maybeLocaleOf(context),
                // Same width as the RenderParagraph: a tight box (RTL text aligned
                // to the right of it) must not be measured shrink-wrapped.
              )..layout(
                minWidth: constraints.minWidth,
                maxWidth: constraints.maxWidth,
              );
          if (!_tapNear(painter, details.localPosition, onTapAt, snap: snap)) {
            SpeechTextTapNotification().dispatch(context);
          }
          painter.dispose();
        },
        child: text,
      ),
    );
  }
}

/// Com a voz falando a fala, cada casa ou lance aparece no tabuleiro quando
/// a voz chega nele.
class _VoiceLinks extends StatefulWidget {
  const _VoiceLinks({
    required this.text,
    required this.links,
    required this.onLink,
    required this.child,
  });

  final String text;
  final List<SpeechLink> links;
  final ValueChanged<SpeechLink>? onLink;
  final Widget child;

  @override
  State<_VoiceLinks> createState() => _VoiceLinksState();
}

class _VoiceLinksState extends State<_VoiceLinks> {
  // Os trechos já mostrados nesta fala.
  int _shown = 0;

  @override
  void didUpdateWidget(_VoiceLinks old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _shown = 0;
  }

  @override
  Widget build(BuildContext context) {
    final speech = TeacherSpeech.speechOf(context);
    final onLink = widget.onLink;
    if (speech == null || onLink == null || widget.links.isEmpty) {
      return widget.child;
    }
    return BlocListener<SpeechCubit, SpeechState>(
      bloc: speech,
      listenWhen: (a, b) =>
          b.isSpeaking(widget.text) && a.revealed != b.revealed,
      listener: (context, state) {
        final revealed = state.revealed ?? 0;
        // O último trecho que a voz já passou e ainda não foi mostrado.
        var next = _shown;
        while (next < widget.links.length &&
            widget.links[next].start < revealed) {
          next++;
        }
        if (next == _shown) return;
        _shown = next;
        onLink(widget.links[next - 1]);
      },
      child: widget.child,
    );
  }
}

/// Deixa à vista só as [count] primeiras letras.
class _RevealClipper extends CustomClipper<Path> {
  const _RevealClipper(this.painter, this.count);

  final TextPainter painter;
  final int count;

  @override
  Path getClip(Size size) {
    final path = Path();
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: count),
      boxHeightStyle: BoxHeightStyle.max,
    );
    for (final box in boxes) {
      path.addRect(box.toRect().inflate(0.5));
    }
    return path;
  }

  @override
  bool shouldReclip(_RevealClipper old) =>
      old.count != count || old.painter != painter;
}

/// O destaque do lance que está no tabuleiro (LICOES-V2 §2, A5): fundo
/// translúcido com cantos de 4 dp, 2 dp de folga nos lados, pintado atrás do
/// texto com as caixas da seleção (`TextStyle.background` não tem canto) e
/// sem mexer na métrica da linha.
class _MoveBackdrop extends StatelessWidget {
  const _MoveBackdrop({
    required this.text,
    required this.range,
    required this.color,
    required this.child,
  });

  final Text text;

  /// Nulo: sem destaque. A árvore é a mesma com ou sem ele, para o texto que
  /// aparece aos poucos não recomeçar quando o destaque entra e sai.
  final (int, int)? range;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final range = this.range;
    return LayoutBuilder(
      builder: (context, constraints) {
        var style = DefaultTextStyle.of(context).style.merge(text.style);
        if (MediaQuery.boldTextOf(context)) {
          style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
        }
        final painter =
            TextPainter(
              text: TextSpan(
                style: style,
                children: [text.textSpan ?? TextSpan(text: text.data)],
              ),
              textDirection: text.textDirection ?? Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              locale: Localizations.maybeLocaleOf(context),
            )..layout(
              minWidth: constraints.minWidth,
              maxWidth: constraints.maxWidth,
            );
        final rects = range == null
            ? const <Rect>[]
            : [
                for (final box in painter.getBoxesForSelection(
                  TextSelection(baseOffset: range.$1, extentOffset: range.$2),
                ))
                  box.toRect(),
              ];
        painter.dispose();
        return CustomPaint(
          painter: range == null ? null : _BackdropPainter(rects, color),
          child: child,
        );
      },
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter(this.rects, this.color);

  final List<Rect> rects;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final rect in rects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(rect.left - 2, rect.top, rect.right + 2, rect.bottom),
          const Radius.circular(AppShape.tiny),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.color != color || !listEquals(old.rects, rects);
}

/// O botão de som do cabeçalho da fala (lição V2, exercício): o alto-falante
/// com a velocidade na etiqueta, ou o som desligado.
class LessonVoiceButton extends StatelessWidget {
  const LessonVoiceButton({
    required this.audible,
    required this.speed,
    required this.onPressed,
    super.key,
  });

  final bool audible;
  final double speed;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return IconButton(
      key: VoiceKeys.speakButton,
      color: colors.onSurfaceVariant,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      tooltip: audible
          ? l10n.lessonSoundOn(l10n.voiceSpeedValue(speed))
          : l10n.lessonSoundOff,
      onPressed: onPressed,
      icon: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (audible)
              const Icon(Icons.volume_up_outlined)
            else
              const SoundOffIcon(),
            if (audible)
              PositionedDirectional(
                start: -4,
                top: -4,
                child: ExcludeSemantics(
                  child: Container(
                    height: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(AppShape.full),
                    ),
                    child: Text(
                      l10n.voiceSpeedValue(speed),
                      // Decorative badge: the button tooltip exposes
                      // the full speed using the user's text scale.
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 10,
                        height: 1.6,
                        fontWeight: AppWeight.heavy,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
