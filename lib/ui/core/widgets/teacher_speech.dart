import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../l10n/l10n.dart';
import 'character_avatar.dart';

/// O professor falando com o aluno: o retrato com a emoção e o balão ao lado,
/// que troca de fala com uma transição suave. Usado no tour e nas aulas.
class TeacherSpeech extends StatelessWidget {
  const TeacherSpeech({
    required this.teacher,
    required this.text,
    this.emotion = Emotion.calm,
    this.avatarSize = 64,
    this.maxLines,
    this.bubbleKey,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = this.text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CharacterAvatar(character: teacher, emotion: emotion, size: avatarSize),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.teacherName(teacher.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSize(
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
                      : Container(
                          key: ValueKey(text),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: const BorderRadiusDirectional.only(
                              topEnd: Radius.circular(16),
                              bottomStart: Radius.circular(16),
                              bottomEnd: Radius.circular(16),
                              topStart: Radius.circular(3),
                            ),
                          ),
                          child: Semantics(
                            liveRegion: true,
                            label: context.l10n.characterSays(
                              teacher.name,
                              text,
                            ),
                            excludeSemantics: true,
                            child: _limited(
                              context,
                              Text(
                                text,
                                key: bubbleKey,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Com [maxLines], o texto fica numa caixa dessa altura e rola nela.
  Widget _limited(BuildContext context, Text text) {
    final lines = maxLines;
    if (lines == null) return text;
    final style = DefaultTextStyle.of(context).style.merge(text.style);
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

  final Text text;

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
