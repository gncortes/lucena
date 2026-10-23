import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/survey.dart';
import '../../../routing/routes.dart';
import '../../core/keys/survey_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/app_bar_progress.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/survey_cubit.dart';
import 'survey_face.dart';
import 'survey_parts.dart';

/// O questionário "Sua opinião" (E1.05): 2 passos nas aulas de finais, 3 na
/// Escola. Depois de enviar, o agradecimento do Viktor na mesma tela.
class SurveyScreen extends StatelessWidget {
  const SurveyScreen({required this.fromLesson, super.key});

  /// Aberto pela aula concluída: o agradecimento volta às aulas.
  final bool fromLesson;

  /// Onde o agradecimento leva.
  String _home(SurveyKind kind) =>
      kind == SurveyKind.school ? Routes.school : Routes.endgames;

  void _leave(BuildContext context, SurveyKind kind) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_home(kind));
    }
  }

  void _thanksBack(BuildContext context, SurveyKind kind) {
    // Da trilha, volta a ela; da aula concluída, vai às aulas.
    if (fromLesson || !context.canPop()) {
      context.go(_home(kind));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SurveyCubit>();
    return BlocBuilder<SurveyCubit, SurveyState>(
      builder: (context, state) {
        if (state.sent) {
          final l10n = context.l10n;
          return ViktorThanks(
            key: SurveyKeys.thanks,
            title: l10n.surveyTitle,
            text: l10n.surveyThanks,
            backLabel: state.kind == SurveyKind.school
                ? l10n.surveyBackToSchool
                : l10n.surveyBackToLessons,
            onBack: () => _thanksBack(context, state.kind),
            viktor: state.viktor,
            closeKey: SurveyKeys.close,
            backKey: SurveyKeys.thanksBack,
          );
        }
        final l10n = context.l10n;
        return PopScope(
          // Passo 2 em diante: o voltar do sistema volta um passo.
          canPop: state.step == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.back();
          },
          child: Scaffold(
            key: SurveyKeys.screen,
            appBar: LucenaAppBar(
              leading: state.step == 0
                  ? IconButton(
                      key: SurveyKeys.close,
                      icon: const Icon(Icons.close),
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      onPressed: () => _leave(context, state.kind),
                    )
                  : IconButton(
                      key: SurveyKeys.back,
                      icon: const BackButtonIcon(),
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      onPressed: cubit.back,
                    ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.surveyTitle),
                  Text(
                    l10n.surveyStep(state.step + 1, state.total),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              bottom: AppBarProgress(
                key: SurveyKeys.progress,
                value: (state.step + 1) / state.total,
              ),
            ),
            body: state.ready ? _Body(state: state) : const SizedBox.shrink(),
            bottomNavigationBar: ActionsFooter(
              children: [
                if (state.isLast)
                  FilledButton.icon(
                    key: SurveyKeys.send,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(l10n.surveySend),
                    onPressed: state.ready && state.canAdvance && !state.sending
                        ? cubit.send
                        : null,
                  )
                else
                  FilledButton(
                    key: SurveyKeys.next,
                    onPressed: state.ready && state.canAdvance
                        ? cubit.next
                        : null,
                    child: Text(l10n.surveyContinue),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final SurveyState state;

  @override
  Widget build(BuildContext context) {
    final school = state.kind == SurveyKind.school;
    final cards = switch ((school, state.step)) {
      (_, 0) => [_RatingCard(state), _ImproveCard(state)],
      (false, _) => [
        _InterestCard(state),
        _ReReviewCard(state),
        _WishCard(state),
      ],
      (true, 1) => [_InterestCard(state), _TopicsCard(state)],
      (true, _) => [_DifficultyCard(state), _ReReviewCard(state)],
    };
    return ListView(
      // Um passo por vez: a chave troca de passo sem reaproveitar os campos.
      key: ValueKey('survey.step.${state.step}'),
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        for (final card in cards) ...[
          card,
          const SizedBox(height: AppSpacing.betweenCards),
        ],
      ],
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard(this.state);

  final SurveyState state;

  static const _faceBox = 52.0;

  static String _name(AppLocalizations l10n, int rating) => switch (rating) {
    1 => l10n.surveyRating1,
    2 => l10n.surveyRating2,
    3 => l10n.surveyRating3,
    4 => l10n.surveyRating4,
    _ => l10n.surveyRating5,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final selected = state.answers.rating;
    final cubit = context.read<SurveyCubit>();
    return QuestionCard(
      title: state.kind == SurveyKind.school
          ? l10n.surveyRatingSchool
          : l10n.surveyRatingEndgames,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var n = 1; n <= 5; n++)
              Semantics(
                button: true,
                selected: selected == n,
                label: _name(l10n, n),
                child: ExcludeSemantics(
                  child: InkResponse(
                    key: SurveyKeys.face(n),
                    onTap: () => cubit.pickRating(n),
                    radius: 30,
                    child: Container(
                      alignment: Alignment.center,
                      width: _faceBox,
                      height: _faceBox,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected == n
                            ? colors.primaryContainer
                            : Colors.transparent,
                      ),
                      child: SurveyFace(
                        rating: n,
                        color: selected == n ? colors.primary : colors.outline,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (selected != null)
          Center(
            child: Text(
              _name(l10n, selected),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: AppWeight.strong,
              ),
            ),
          ),
      ],
    );
  }
}

class _ImproveCard extends StatelessWidget {
  const _ImproveCard(this.state);

  final SurveyState state;

  static String _label(AppLocalizations l10n, String id) => switch (id) {
    'viktor' => l10n.surveyImproveViktor,
    'voice' => l10n.surveyImproveVoice,
    'examples' => l10n.surveyImproveExamples,
    'exercises' => l10n.surveyImproveExercises,
    'boardMarks' => l10n.surveyImproveBoardMarks,
    'difficulty' => l10n.surveyImproveDifficulty,
    'length' => l10n.surveyImproveLength,
    _ => l10n.surveyImproveNotation,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SurveyCubit>();
    return QuestionCard(
      title: l10n.surveyImproveTitle,
      hint: l10n.surveyMultiHint,
      children: [
        SurveyChips(
          ids: SurveyOptions.improveOf(state.kind),
          selected: state.answers.improve,
          label: (id) => _label(l10n, id),
          chipKey: SurveyKeys.improveChip,
          onToggle: cubit.toggleImprove,
        ),
        SurveyTextBox(
          maxLength: SurveyAnswers.maxText,
          fieldKey: SurveyKeys.improveText,
          hint: l10n.surveyImproveTextHint,
          initial: state.answers.improveText,
          onChanged: cubit.setImproveText,
        ),
      ],
    );
  }
}

class _TopicsCard extends StatelessWidget {
  const _TopicsCard(this.state);

  final SurveyState state;

  static String _label(AppLocalizations l10n, String id) => switch (id) {
    'solidOpenings' => l10n.surveyTopicSolidOpenings,
    'aggressiveOpenings' => l10n.surveyTopicAggressiveOpenings,
    'tactics' => l10n.surveyTopicTactics,
    'positional' => l10n.surveyTopicPositional,
    'endgames' => l10n.surveyTopicEndgames,
    'tournament' => l10n.surveyTopicTournament,
    _ => l10n.surveyTopicAnnotatedGames,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QuestionCard(
      title: l10n.surveyTopicsTitle,
      hint: l10n.surveyMultiHint,
      children: [
        SurveyChips(
          ids: SurveyOptions.topics,
          selected: state.answers.topics,
          label: (id) => _label(l10n, id),
          chipKey: SurveyKeys.topicChip,
          onToggle: context.read<SurveyCubit>().toggleTopic,
        ),
      ],
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard(this.state);

  final SurveyState state;

  static String _label(AppLocalizations l10n, String id) => switch (id) {
    'afterOpening' => l10n.surveyDifficultyAfterOpening,
    'hangingPieces' => l10n.surveyDifficultyHangingPieces,
    'missTactics' => l10n.surveyDifficultyMissTactics,
    'plan' => l10n.surveyDifficultyPlan,
    'convertWin' => l10n.surveyDifficultyConvertWin,
    'endgames' => l10n.surveyDifficultyEndgames,
    _ => l10n.surveyDifficultyClock,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SurveyCubit>();
    return QuestionCard(
      title: l10n.surveyDifficultyTitle,
      hint: l10n.surveyMultiHint,
      children: [
        SurveyChips(
          ids: SurveyOptions.difficulties,
          selected: state.answers.difficulties,
          label: (id) => _label(l10n, id),
          chipKey: SurveyKeys.difficultyChip,
          onToggle: cubit.toggleDifficulty,
        ),
        SurveyTextBox(
          maxLength: SurveyAnswers.maxText,
          fieldKey: SurveyKeys.difficultyText,
          hint: l10n.surveyDifficultyTextHint,
          initial: state.answers.difficultyText,
          onChanged: cubit.setDifficultyText,
        ),
      ],
    );
  }
}

class _InterestCard extends StatelessWidget {
  const _InterestCard(this.state);

  final SurveyState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final school = state.kind == SurveyKind.school;
    final cubit = context.read<SurveyCubit>();
    final labels = {
      SurveyInterest.yes: l10n.surveyInterestYes,
      SurveyInterest.maybe: l10n.surveyInterestMaybe,
      SurveyInterest.no: l10n.surveyInterestNo,
    };
    return QuestionCard(
      title: school
          ? l10n.surveyInterestSchoolTitle
          : l10n.surveyInterestEndgamesTitle,
      hint: school
          ? l10n.surveyInterestSchoolHint
          : l10n.surveyInterestEndgamesHint,
      children: [
        OptionList<SurveyInterest>(
          values: SurveyInterest.values,
          selected: state.answers.interest,
          label: (interest) => labels[interest]!,
          optionKey: SurveyKeys.interest,
          onPick: cubit.pickInterest,
        ),
      ],
    );
  }
}

class _ReReviewCard extends StatelessWidget {
  const _ReReviewCard(this.state);

  final SurveyState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SurveyCubit>();
    final value = state.answers.reReview;
    return QuestionCard(
      title: l10n.surveyReReviewTitle,
      children: [
        SegmentedButton<bool>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: [
            ButtonSegment(
              value: true,
              label: Text(l10n.surveyYes, key: SurveyKeys.reReview(yes: true)),
            ),
            ButtonSegment(
              value: false,
              label: Text(l10n.surveyNo, key: SurveyKeys.reReview(yes: false)),
            ),
          ],
          selected: {?value},
          onSelectionChanged: (set) {
            if (set.isNotEmpty) cubit.pickReReview(yes: set.first);
          },
        ),
      ],
    );
  }
}

class _WishCard extends StatelessWidget {
  const _WishCard(this.state);

  final SurveyState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QuestionCard(
      title: l10n.surveyWishTitle,
      children: [
        SurveyTextBox(
          maxLength: SurveyAnswers.maxText,
          fieldKey: SurveyKeys.wishText,
          hint: l10n.surveyWishHint,
          initial: state.answers.wishText,
          onChanged: context.read<SurveyCubit>().setWishText,
        ),
      ],
    );
  }
}
