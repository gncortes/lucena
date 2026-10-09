import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/use_cases/speech_links.dart';
import '../../../routing/routes.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../../voice/widgets/auto_speak.dart';
import '../keys/voice_keys.dart';
import '../l10n/l10n.dart';
import 'character_avatar.dart';
import '../theme/app_motion.dart';
import '../theme/app_shape.dart';

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
class TeacherSpeech extends StatelessWidget {
  const TeacherSpeech({
    required this.teacher,
    required this.text,
    required this.speechContext,
    this.emotion = Emotion.calm,
    this.avatarSize = 64,
    this.bubbleKey,
    this.typed = false,
    this.speaks = false,
    this.onLink,
    this.onSpoken,
    super.key,
  });

  final Character teacher;

  /// Com tabuleiro na tela: as casas e os lances da fala ficam tocáveis e
  /// chamam [onLink] (a tela mostra ou tira do tabuleiro). Nulo: texto
  /// simples.
  final ValueChanged<SpeechLink>? onLink;

  /// Com a voz falando, cada casa ou lance quando a voz chega nele.
  final ValueChanged<SpeechLink>? onSpoken;

  /// A fala. Nula: só o retrato e o nome.
  final String? text;
  final Emotion emotion;
  final double avatarSize;

  final Key? bubbleKey;

  /// Ensino (balão embaixo do retrato) ou partida (balão ao lado).
  final SpeechContext speechContext;

  bool get _stacked => speechContext == SpeechContext.teaching;

  /// A fala aparece aos poucos, como quem fala. Um toque mostra tudo.
  final bool typed;

  /// Com a voz ligada, a fala nova sai em voz alta sozinha. O botão de
  /// áudio aparece sempre que há voz no idioma.
  final bool speaks;

  static const _tail = Size(18, 9);

  @override
  Widget build(BuildContext context) {
    final avatar = CharacterAvatar(
      character: teacher,
      emotion: emotion,
      size: avatarSize,
    );
    final speech = speechOf(context);
    final content = _RevealOnChange(
      text: text,
      child: _layout(context, avatar),
    );
    if (speech == null) return content;
    return AutoSpeak(
      speech: speech,
      text: text,
      auto: speaks,
      speakerId: teacher.id,
      child: content,
    );
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

  /// O nome e, havendo voz no idioma, o botão de áudio.
  Widget _header(BuildContext context) {
    final speech = speechOf(context);
    final text = this.text;
    if (speech == null || text == null) return _name(context);
    final language = Localizations.localeOf(context).toLanguageTag();
    return Row(
      children: [
        Expanded(child: _name(context)),
        BlocBuilder<SpeechCubit, SpeechState>(
          bloc: speech,
          buildWhen: (a, b) =>
              a.isSpeaking(text) != b.isSpeaking(text) ||
              a.settings.speed != b.settings.speed ||
              a.settings.enabled != b.settings.enabled ||
              a.availableFor(language) != b.availableFor(language),
          builder: (context, state) {
            // Sem voz no idioma, o botão de som continua à vista: o toque
            // leva aos ajustes de voz, onde se instala uma.
            if (!state.availableFor(language)) {
              return IconButton(
                key: VoiceKeys.speakButton,
                visualDensity: VisualDensity.compact,
                tooltip: context.l10n.voiceSection,
                icon: const Icon(Icons.volume_off_outlined),
                onPressed: () => context.push(Routes.settingsVoice),
              );
            }
            final speaking = state.isSpeaking(text);
            final l10n = context.l10n;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A velocidade da voz: cada toque passa para a próxima.
                TextButton(
                  key: VoiceKeys.speedButton,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(48, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: speech.nextSpeed,
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
                    visualDensity: VisualDensity.compact,
                    tooltip: state.settings.enabled
                        ? l10n.voiceAutoOff(teacher.name)
                        : l10n.voiceAutoOn(teacher.name),
                    isSelected: !state.settings.enabled,
                    icon: const Icon(Icons.volume_up_outlined),
                    selectedIcon: const Icon(Icons.volume_off_outlined),
                    onPressed: () async {
                      if (state.settings.enabled) {
                        await speech.setEnabled(enabled: false);
                        return;
                      }
                      await speech.setEnabled(enabled: true);
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
                    visualDensity: VisualDensity.compact,
                    tooltip: speaking ? l10n.voiceStop : l10n.voiceListen,
                    isSelected: speaking,
                    icon: const Icon(Icons.volume_up_outlined),
                    selectedIcon: const Icon(Icons.stop_circle_outlined),
                    onPressed: () => speech.toggle(
                      text,
                      speakerId: teacher.id,
                      language: language,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _layout(BuildContext context, Widget avatar) {
    if (_stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: 10),
              Expanded(child: _header(context)),
            ],
          ),
          const SizedBox(height: 2),
          _speech(context),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 4),
              _speech(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _name(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      context.l10n.teacherName(teacher.name),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          (_stacked ? theme.textTheme.titleMedium : theme.textTheme.labelLarge)
              ?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
    );
  }

  /// O balão, que troca de fala com uma transição suave.
  Widget _speech(BuildContext context) {
    final text = this.text;
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
        child: text == null
            ? const SizedBox(width: double.infinity)
            : KeyedSubtree(key: ValueKey(text), child: _bubble(context, text)),
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
  ) {
    final speech = speechOf(context);
    if (speech == null) return _TypedText(text: words, onTapAt: onTapAt);
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
        text: words,
        onTapAt: onTapAt,
        paced: paced,
        speaking: state.isSpeaking(text),
        revealed: state.isSpeaking(text) ? state.revealed : null,
      ),
    );
  }

  Widget _bubble(BuildContext context, String text) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.surfaceContainerHighest;
    final onLink = this.onLink;
    final links = onLink == null
        ? const <SpeechLink>[]
        : SpeechLinks.find(
            text,
            SpeechLinks.lettersFor(
              Localizations.localeOf(context).languageCode,
            ),
          );
    final style = theme.textTheme.bodyLarge;
    // As casas e os lances em seminegrito, na cor primária: tocáveis sem
    // parecer link de site.
    final linkStyle = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
    final words = links.isEmpty
        ? Text(text, key: bubbleKey, style: style)
        : Text.rich(
            TextSpan(
              children: [
                for (final (index, link) in links.indexed) ...[
                  TextSpan(
                    text: text.substring(
                      index == 0 ? 0 : links[index - 1].end,
                      link.start,
                    ),
                  ),
                  TextSpan(text: link.text, style: linkStyle),
                ],
                TextSpan(text: text.substring(links.last.end)),
              ],
            ),
            key: bubbleKey,
            style: style,
          );
    // O toque numa letra: o trecho que a contém (ou que termina nela). Diz
    // se havia trecho ali.
    bool tapAt(int offset) {
      for (final link in links) {
        if (offset >= link.start && offset <= link.end) {
          onLink!(link);
          return true;
        }
      }
      return false;
    }

    final tappable = links.isEmpty ? null : tapAt;
    final bubble = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: _stacked
            ? BorderRadius.circular(AppShape.large)
            : const BorderRadiusDirectional.only(
                topEnd: Radius.circular(AppShape.large),
                bottomStart: Radius.circular(AppShape.large),
                bottomEnd: Radius.circular(AppShape.large),
                topStart: Radius.circular(AppShape.small),
              ),
      ),
      child: Semantics(
        liveRegion: true,
        label: context.l10n.characterSays(teacher.name, text),
        excludeSemantics: true,
        // Com leitor de tela: uma ação por casa ou lance.
        customSemanticsActions: {
          for (final link in links)
            CustomSemanticsAction(
              label: context.l10n.speechShowOnBoard(link.text),
            ): () =>
                onLink!(link),
        },
        child: _VoiceLinks(
          text: text,
          links: links,
          onLink: onSpoken,
          child: typed
              ? _typed(context, text, words, tappable)
              : tappable == null
              ? words
              : _LinkTapper(text: words, onTapAt: tappable),
        ),
      ),
    );
    if (!_stacked) return bubble;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A ponta do balão, embaixo do meio do retrato.
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: (avatarSize - _tail.width) / 2,
          ),
          child: CustomPaint(size: _tail, painter: _TailPainter(color)),
        ),
        bubble,
      ],
    );
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
class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close(),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

/// A fala aparecendo aos poucos. O texto já ocupa o lugar todo (o balão não
/// pula nem muda de tamanho) e é revelado letra a letra por um recorte; um
/// toque mostra tudo. Com as animações desligadas no aparelho, aparece de uma
/// vez.
class _TypedText extends StatefulWidget {
  const _TypedText({
    required this.text,
    this.onTapAt,
    this.paced = false,
    this.speaking = false,
    this.revealed,
  });

  final Text text;

  /// Um toque numa letra já à vista: a posição dela. Devolve se havia uma
  /// casa ou um lance ali.
  final bool Function(int)? onTapAt;

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

  int get _length => _span.toPlainText().length;

  // O texto como trecho (simples ou com as casas destacadas).
  InlineSpan get _span =>
      widget.text.textSpan ?? TextSpan(text: widget.text.data);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.paced
          // Uns 15 caracteres por segundo, como quem fala.
          ? Duration(milliseconds: (_length * 65).clamp(600, 60000))
          : Duration(milliseconds: (_length * 14).clamp(300, 2800)),
    )..forward();
  }

  @override
  void didUpdateWidget(_TypedText old) {
    super.didUpdateWidget(old);
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
  TextPainter _measure(BuildContext context, double width) {
    final cached = _painter;
    if (cached != null && _width == width) return cached;
    cached?.dispose();
    var style = DefaultTextStyle.of(context).style.merge(widget.text.style);
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    _width = width;
    return _painter = TextPainter(
      text: TextSpan(style: style, children: [_span]),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    )..layout(maxWidth: width);
  }

  @override
  Widget build(BuildContext context) {
    final onTapAt = widget.onTapAt;
    if (AppMotion.of(context).disabled) {
      return onTapAt == null
          ? widget.text
          : _LinkTapper(text: widget.text, onTapAt: onTapAt);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = _measure(context, constraints.maxWidth);
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
                )) {
              return;
            }
            _controller.value = 1;
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
bool _tapNear(TextPainter painter, Offset at, bool Function(int) onTapAt) {
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
  const _LinkTapper({required this.text, required this.onTapAt});

  final Text text;
  final bool Function(int) onTapAt;

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
          final painter = TextPainter(
            text: TextSpan(
              style: style,
              children: [text.textSpan ?? TextSpan(text: text.data)],
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            locale: Localizations.maybeLocaleOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          _tapNear(painter, details.localPosition, onTapAt);
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
