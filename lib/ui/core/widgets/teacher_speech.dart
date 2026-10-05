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

  /// Linhas no máximo; nulo deixa crescer.
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
                            child: Text(
                              text,
                              key: bubbleKey,
                              maxLines: maxLines,
                              overflow: maxLines == null
                                  ? null
                                  : TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge,
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
}
