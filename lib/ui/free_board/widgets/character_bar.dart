import 'package:flutter/material.dart';

import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../view_models/talk_cubit.dart';

/// O adversário como personagem, acima do tabuleiro: o retrato com a emoção,
/// o nome e o balão com a última fala. O balão fica ao lado do retrato e nunca
/// cobre o tabuleiro.
class CharacterBar extends StatelessWidget {
  const CharacterBar({required this.talk, super.key});

  /// Altura reservada para a fileira, para o tabuleiro caber.
  static const height = 76.0;

  final TalkState talk;

  @override
  Widget build(BuildContext context) {
    final character = talk.character!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final line = talk.enabled ? talk.line : null;
    return SizedBox(
      key: FreeBoardKeys.characterBar,
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: CharacterAvatar(
                key: FreeBoardKeys.characterAvatar(talk.emotion),
                character: character,
                emotion: talk.emotion,
                size: 52,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.characterNameLevel(
                      character.name,
                      character.level,
                    ),
                    key: FreeBoardKeys.characterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          alignment: Alignment.topCenter,
                          child: child,
                        ),
                      ),
                      child: line == null
                          ? const SizedBox(width: double.infinity)
                          : Align(
                              key: ValueKey(line.id),
                              alignment: AlignmentDirectional.topStart,
                              child: Container(
                                key: FreeBoardKeys.speechBubble,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius:
                                      const BorderRadiusDirectional.only(
                                        topEnd: Radius.circular(12),
                                        bottomStart: Radius.circular(12),
                                        bottomEnd: Radius.circular(12),
                                        topStart: Radius.circular(2),
                                      ),
                                ),
                                child: Semantics(
                                  liveRegion: true,
                                  label: context.l10n.characterSays(
                                    character.name,
                                    line.text,
                                  ),
                                  excludeSemantics: true,
                                  child: Text(
                                    line.text,
                                    key: FreeBoardKeys.speechText(line.id),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium,
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
        ),
      ),
    );
  }
}
