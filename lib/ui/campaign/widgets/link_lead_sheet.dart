import 'package:flutter/material.dart';

import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/linked_lesson.dart';
import '../../../domain/use_cases/link_lesson_rules.dart';
import '../../core/keys/challenge_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/roadmap_step_card.dart';

/// O que a pessoa escolheu na folha da aula gratuita.
enum LinkLeadChoice {
  /// "Criar conta e ver a aula": o cadastro, e a aula no fim dele.
  create,

  /// "Já tenho conta": entrar, e a aula no fim.
  signIn,

  /// Já tem conta: "Ver a aula", direto.
  lesson,
}

/// A folha da aula gratuita no fim do desafio de um link de campanha (T84,
/// canvas `t84-lead`, variante A): sobre o fim, com o resultado atrás. O
/// tabuleirinho, a categoria e o nome da aula, a frase pelo resultado, os
/// três passos e os botões. Nulo: "Agora não" ou o X, que deixam o fim à
/// vista. [offer] [LinkLessonOffer.none]: o link só de aula, sem desafio
/// jogado (a frase neutra e só aprender e praticar).
Future<LinkLeadChoice?> showLinkLeadSheet(
  BuildContext context, {
  required LinkLessonOffer offer,
  required bool hasAccount,
  PositionGoal goal = PositionGoal.win,
  LinkedLessonInfo? info,
}) => showLucenaSheet<LinkLeadChoice>(
  context,
  sheetKey: ChallengeKeys.leadSheet,
  closeKey: ChallengeKeys.leadClose,
  builder: (_) => SafeArea(
    top: false,
    child: _LeadSheet(
      offer: offer,
      goal: goal,
      hasAccount: hasAccount,
      info: info,
    ),
  ),
);

class _LeadSheet extends StatelessWidget {
  const _LeadSheet({
    required this.offer,
    required this.goal,
    required this.hasAccount,
    required this.info,
  });

  final LinkLessonOffer offer;
  final PositionGoal goal;
  final bool hasAccount;
  final LinkedLessonInfo? info;

  /// Os idiomas em que o módulo entra no meio da frase, em minúscula ("Aula
  /// de finais de torre").
  static const _lowerModule = {'pt', 'en', 'es', 'fr', 'it', 'nl'};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final draw = goal == PositionGoal.draw;
    final text = switch (offer) {
      LinkLessonOffer.none => l10n.challengeLeadLesson,
      LinkLessonOffer.secondary => l10n.challengeLeadDone,
      LinkLessonOffer.primary when draw => l10n.challengeLeadFailedDraw,
      LinkLessonOffer.primary => l10n.challengeLeadFailedWin,
    };
    final retry = switch (offer) {
      LinkLessonOffer.none => null,
      LinkLessonOffer.secondary => l10n.challengeLeadStepRetryDone,
      LinkLessonOffer.primary when draw => l10n.challengeLeadStepRetryDraw,
      LinkLessonOffer.primary => l10n.challengeLeadStepRetryWin,
    };
    final steps = [
      (l10n.challengeLeadStepIdea, l10n.challengeLeadStepIdeaHint),
      (l10n.challengeLeadStepPractice, l10n.challengeLeadStepPracticeHint),
      // Sem desafio jogado (o link só de aula), nada a refazer.
      if (retry != null) (l10n.challengeLeadStepRetry, retry),
    ];
    void choose(LinkLeadChoice choice) => Navigator.of(context).pop(choice);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (info case final info?) ...[
                  _LessonCard(info: info, lowerModule: _lowerModule),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(
                  text,
                  key: ChallengeKeys.leadText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final (index, (title, subtitle)) in steps.indexed)
                  Padding(
                    key: ChallengeKeys.leadStep(index),
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: RoadmapStepCard(
                      index: index,
                      title: title,
                      subtitle: subtitle,
                      icon: Icons.auto_stories_outlined,
                    ),
                  ),
              ],
            ),
          ),
        ),
        ActionsFooter(
          margin: AppSpacing.xl,
          stacked: true,
          children: [
            if (hasAccount)
              FilledButton.icon(
                key: ChallengeKeys.leadLesson,
                onPressed: () => choose(LinkLeadChoice.lesson),
                icon: const Icon(Icons.school),
                label: Text(l10n.challengeEndLesson),
              )
            else ...[
              FilledButton.icon(
                key: ChallengeKeys.leadCreate,
                onPressed: () => choose(LinkLeadChoice.create),
                icon: const Icon(Icons.school),
                label: Text(l10n.challengeLeadCreate),
              ),
              OutlinedButton(
                key: ChallengeKeys.leadHaveAccount,
                onPressed: () => choose(LinkLeadChoice.signIn),
                child: Text(l10n.challengeLeadHaveAccount),
              ),
            ],
            TextButton(
              key: ChallengeKeys.leadNotNow,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.accountLater),
            ),
          ],
        ),
      ],
    );
  }
}

/// O tabuleirinho da aula, a categoria e o nome.
class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.info, required this.lowerModule});

  final LinkedLessonInfo info;
  final Set<String> lowerModule;

  static const _board = 96.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final module = info.module;
    final lower = lowerModule.contains(
      Localizations.localeOf(context).languageCode,
    );
    final category = switch ((info.kind, module)) {
      (LinkedLessonKind.school, _) => l10n.challengeLeadCategorySchool,
      (LinkedLessonKind.endgame, final String module) when module.isNotEmpty =>
        l10n.challengeLeadCategory(
          lower ? module[0].toLowerCase() + module.substring(1) : module,
        ),
      _ => null,
    };
    final fen = info.fen;
    return Row(
      children: [
        if (fen != null) ...[
          PositionBoard(
            key: ChallengeKeys.leadBoard,
            fen: fen,
            size: _board,
            radius: AppShape.small,
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (category != null)
                Text(
                  category,
                  key: ChallengeKeys.leadCategory,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              Text(
                info.title,
                key: ChallengeKeys.leadTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
