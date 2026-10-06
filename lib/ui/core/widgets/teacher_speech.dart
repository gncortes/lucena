import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../l10n/l10n.dart';
import 'character_avatar.dart';

/// O professor falando com o aluno: o retrato com a emoção e o balão ao lado,
/// que troca de fala com uma transição suave. Usado no tour e nas aulas.
///
/// Com [stacked], o retrato e o nome ficam numa linha e o balão vem embaixo,
/// na largura toda, com a ponta virada para o retrato: é o arranjo da lição,
/// em que o Viktor fala muito e fica abaixo do tabuleiro.
class TeacherSpeech extends StatelessWidget {
  const TeacherSpeech({
    required this.teacher,
    required this.text,
    this.emotion = Emotion.calm,
    this.avatarSize = 64,
    this.maxLines,
    this.bubbleKey,
    this.stacked = false,
    this.typed = false,
    super.key,
  });

  final Character teacher;

  /// A fala. Nula: só o retrato e o nome.
  final String? text;
  final Emotion emotion;
  final double avatarSize;

  /// A altura do balão em linhas, no máximo; nulo deixa crescer. A fala
  /// mais longa não é cortada: rola dentro do balão.
  final int? maxLines;
  final Key? bubbleKey;

  /// O balão embaixo do retrato e do nome, em vez de ao lado.
  final bool stacked;

  /// A fala aparece aos poucos, como quem fala. Um toque mostra tudo.
  final bool typed;

  static const _tail = Size(18, 9);

  @override
  Widget build(BuildContext context) {
    final avatar = CharacterAvatar(
      character: teacher,
      emotion: emotion,
      size: avatarSize,
    );
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: 10),
              Expanded(child: _name(context)),
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
              _name(context),
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
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  /// O balão, que troca de fala com uma transição suave.
  Widget _speech(BuildContext context) {
    final text = this.text;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
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

  Widget _bubble(BuildContext context, String text) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.surfaceContainerHighest;
    final words = Text(text, key: bubbleKey, style: theme.textTheme.bodyLarge);
    final bubble = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: stacked
            ? BorderRadius.circular(16)
            : const BorderRadiusDirectional.only(
                topEnd: Radius.circular(16),
                bottomStart: Radius.circular(16),
                bottomEnd: Radius.circular(16),
                topStart: Radius.circular(3),
              ),
      ),
      child: Semantics(
        liveRegion: true,
        label: context.l10n.characterSays(teacher.name, text),
        excludeSemantics: true,
        child: _limited(context, typed ? _TypedText(text: words) : words),
      ),
    );
    if (!stacked) return bubble;
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

  /// Com [maxLines], o texto fica numa caixa dessa altura e rola nela.
  Widget _limited(BuildContext context, Widget text) {
    final lines = maxLines;
    if (lines == null) return text;
    final style = DefaultTextStyle.of(context).style
        .merge(Theme.of(context).textTheme.bodyLarge);
    final lineHeight = MediaQuery.textScalerOf(context)
        .scale((style.fontSize ?? 14) * (style.height ?? 1.2));
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: lineHeight * lines),
      child: _ScrollingText(text: text),
    );
  }
}

/// A fala que não cabe no balão: rola, com a barra à vista.
class _ScrollingText extends StatefulWidget {
  const _ScrollingText({required this.text});

  final Widget text;

  @override
  State<_ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<_ScrollingText> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _controller,
    thumbVisibility: true,
    child: SingleChildScrollView(
      controller: _controller,
      // Espaço para a barra não cobrir o texto.
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: widget.text,
    ),
  );
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
  const _TypedText({required this.text});

  final Text text;

  @override
  State<_TypedText> createState() => _TypedTextState();
}

class _TypedTextState extends State<_TypedText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  TextPainter? _painter;
  double? _width;

  int get _length => widget.text.data?.length ?? 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_length * 14).clamp(300, 2800)),
    )..forward();
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
      text: TextSpan(text: widget.text.data, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    )..layout(maxWidth: width);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _controller.value = 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = _measure(context, constraints.maxWidth);
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => _controller.isCompleted
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
