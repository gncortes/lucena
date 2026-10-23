import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/character.dart';
import '../l10n/l10n.dart';
import 'character_avatar.dart';

/// Contra quem: o retrato, o nome, o nível e a frase do personagem.
class OpponentCard extends StatelessWidget {
  const OpponentCard({
    required this.name,
    this.character,
    this.level,
    this.tagline = '',
    this.heroTag,
    this.margin = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      0,
    ),
    super.key,
  });

  final String name;
  final Character? character;
  final int? level;
  final String tagline;

  /// Com a marca, o retrato voa até o da tela seguinte.
  final Object? heroTag;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final character = this.character;
    Widget avatar() =>
        CharacterAvatar(character: character!, size: CharacterAvatar.tour);
    return Card(
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            if (character != null) ...[
              heroTag == null ? avatar() : Hero(tag: heroTag!, child: avatar()),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.challengeOpponent,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    [name, if (level case final level?) '$level'].join(' · '),
                    style: context.cardTitle,
                  ),
                  if (tagline.isNotEmpty)
                    Text(
                      '“$tagline”',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
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
