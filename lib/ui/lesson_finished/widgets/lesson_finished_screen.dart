import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/survey.dart';
import '../../../routing/routes.dart';
import '../../core/keys/lesson_finished_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_button_text.dart';
import '../../core/theme/app_spacing.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/next_steps.dart';
import '../../survey/widgets/survey_invite_card.dart';
import '../view_models/lesson_finished_cubit.dart';

/// "Aula concluída" (E1.05; canvas `PropV1AulasConcluida` e
/// `PropV1AulasEscolaConcluida`): confete, o título, o convite "Sua opinião"
/// acima dos botões, "Próxima: {aula}" (se houver) e "Voltar". Numa aula de
/// final, o bloco "Próximos passos" (canvas V2 · Ligações, L3) vem antes do convite:
/// a Corrida só daquele final, o treino e os exercícios da aula.
class LessonFinishedScreen extends StatelessWidget {
  const LessonFinishedScreen({required this.kind, super.key});

  final SurveyKind kind;

  static const _iconSize = 60.0;

  /// Espaço entre o título, o convite e os botões (canvas: `gap: 20px`).
  static const _blockGap = 20.0;

  /// O curso de onde a pessoa veio: a Escola ou as aulas de finais.
  bool get _school => kind == SurveyKind.school;

  void _next(BuildContext context, String id) {
    final origin = GoRouterState.of(context).uri.queryParameters['origem'];
    context.pushReplacement(
      _school
          ? Routes.lessonScript(id, origin: origin)
          : Routes.endgameLessonScript(id, origin: origin),
    );
  }

  /// As opções dos "Próximos passos"; nulas na Escola.
  List<NextStep>? _steps(BuildContext context, LessonFinishedState state) {
    final practice = state.practice;
    if (_school) return null;
    final l10n = context.l10n;
    final subcategory = state.raceSubcategory;
    final name = subcategory == null ? null : endgameName(l10n, subcategory);
    return [
      if (practice != null && subcategory != null)
        NextStep(
          id: 'raceOnly',
          icon: Icons.timer,
          title: l10n.lessonFinishedRaceOnly(name!),
          body: l10n.lessonFinishedRaceBody,
          onTap: () => context.push(Routes.raceOnly(subcategory: subcategory)),
        ),
      if (practice != null)
        NextStep(
          id: 'train',
          icon: Icons.sports_esports,
          title: name == null
              ? l10n.lessonFinishedTrainTitle
              : l10n.nextStepsPractice(name),
          body: l10n.lessonFinishedTrainBody,
          onTap: () => context.push(
            Routes.setup(
              practice.fen,
              goal: practice.goal.code,
              position: practice.positionId,
            ),
          ),
        ),
      if (state.hasExercises)
        NextStep(
          id: 'exercises',
          icon: Icons.quiz,
          title: l10n.lessonFinishedExercisesTitle,
          body: l10n.lessonFinishedExercisesBody,
          onTap: () =>
              context.push(Routes.endgameExercisesIntro(state.lessonId)),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return BlocBuilder<LessonFinishedCubit, LessonFinishedState>(
      builder: (context, state) => Scaffold(
        key: LessonFinishedKeys.screen,
        appBar: LucenaAppBar(
          title: Text(state.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () =>
                context.go(_school ? Routes.school : Routes.endgames),
          ),
        ),
        body: Stack(
          children: [
            // O bloco fica centralizado na altura quando cabe e rola quando
            // não cabe (canvas: `<main>` com `justify-content: center`).
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 2 * AppSpacing.lg,
                  ),
                  child: state.ready
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: _blockGap,
                          children: [
                            Column(
                              spacing: AppSpacing.lg,
                              children: [
                                Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.primaryContainer,
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: _iconSize,
                                    color: colors.onPrimaryContainer,
                                  ),
                                ),
                                Text(
                                  l10n.lessonFinishedTitle(state.title),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            if (_steps(context, state) case final steps?
                                when steps.isNotEmpty) ...[
                              NextSteps(steps: steps),
                              const ResultsInfoLine(),
                            ],
                            SurveyInviteCard(
                              kind: kind,
                              source: _school
                                  ? SurveyInviteSource.schoolLesson
                                  : SurveyInviteSource.endgameLesson,
                            ),
                            FooterButtonTheme(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: AppSpacing.md,
                                children: [
                                  if (state.nextId != null)
                                    SizedBox(
                                      height: kButtonHeight,
                                      child: FilledButton.icon(
                                        key: LessonFinishedKeys.next,
                                        icon: const Icon(Icons.arrow_forward),
                                        label: Text(
                                          l10n.lessonNext(
                                            state.nextTitle ?? '',
                                          ),
                                        ),
                                        onPressed: () =>
                                            _next(context, state.nextId!),
                                      ),
                                    ),
                                  SizedBox(
                                    height: kButtonHeight,
                                    child: OutlinedButton(
                                      key: LessonFinishedKeys.back,
                                      onPressed: () => context.go(
                                        _school
                                            ? Routes.school
                                            : Routes.endgames,
                                      ),
                                      child: Text(
                                        _school
                                            ? l10n.surveyBackToSchool
                                            : l10n.surveyBackToLessons,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            const Positioned.fill(child: IgnorePointer(child: Celebration())),
          ],
        ),
      ),
    );
  }
}
