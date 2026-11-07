import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/use_cases/race_diagnosis.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/conclusion_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../home/widgets/path_card.dart';

/// "Para aprender com ela" (P9 B), na conclusão de uma partida perdida por
/// desistência: rever a partida e treinar o final. Cada item só entra se o
/// app tem para onde levar: a partida gravada ([gameId]) e a aula liberada
/// do final ([lesson]).
class ResignLearnList extends StatelessWidget {
  const ResignLearnList._({this.gameId, this.lesson});

  /// Nulo quando não há o que mostrar (partida não gravada, ou sem aula).
  static Widget? maybe({int? gameId, RaceFinalLesson? lesson}) =>
      gameId == null && lesson == null
      ? null
      : ResignLearnList._(gameId: gameId, lesson: lesson);

  final int? gameId;
  final RaceFinalLesson? lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final gameId = this.gameId;
    final lesson = this.lesson;
    return Column(
      key: ConclusionKeys.learn,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Text(
          l10n.conclusionLearnTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (gameId != null)
          PathCard(
            key: ConclusionKeys.learnGame,
            icon: Icons.visibility_rounded,
            title: l10n.conclusionLearnGame,
            body: l10n.conclusionLearnGameBody,
            onTap: () => context.push(Routes.game(gameId)),
          ),
        if (lesson != null)
          PathCard(
            key: ConclusionKeys.learnFinal,
            icon: Icons.school_rounded,
            title: l10n.conclusionLearnFinal,
            body: l10n.conclusionLearnFinalBody(
              endgameName(l10n, lesson.subcategory),
            ),
            onTap: () => context.push(
              lesson.school
                  ? Routes.lessonScript(lesson.lessonId)
                  : Routes.endgameLesson(lesson.lessonId),
            ),
          ),
      ],
    );
  }
}
