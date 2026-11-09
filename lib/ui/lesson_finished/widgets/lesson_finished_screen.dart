import 'package:flutter/material.dart';

import '../../core/widgets/load_error.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/survey.dart';
import '../../../routing/routes.dart';
import '../../core/keys/lesson_finished_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/celebracao.dart';
import '../../core/motion/entrada_de_resultado.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_button_text.dart';
import '../../core/theme/app_spacing.dart';
import '../../catalog/widgets/catalog_ui.dart';
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

  String _backRoute(BuildContext context) {
    final origin = GoRouterState.of(context).uri.queryParameters['origem'];
    if (origin?.startsWith('treino_') == true) {
      return Routes.training(_school ? 'escola' : 'pilares');
    }
    return _school ? Routes.school : Routes.endgames;
  }

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
    final failure = context.watch<LessonFinishedCubit>().state.failure;
    if (failure != null) {
      return LoadErrorScreen(
        kind: LoadErrorKind.fromFailure(failure),
        onAction: () => context.read<LessonFinishedCubit>().load(
          Localizations.localeOf(context).languageCode,
        ),
        onBack: () =>
            context.canPop() ? context.pop() : context.go(Routes.home),
      );
    }
    return BlocBuilder<LessonFinishedCubit, LessonFinishedState>(
      builder: (context, state) => Scaffold(
        key: LessonFinishedKeys.screen,
        appBar: LucenaAppBar(
          title: Text(state.title),
          leading: IconButton(
            key: LessonFinishedKeys.close,
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => context.go(_backRoute(context)),
          ),
        ),
        body: Celebracao(
          tamanho: TamanhoDaCelebracao.pequena,
          escalar: false,
          child:
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
                        // H-ANI-25: o selo salta, o título sobe, os próximos
                        // passos e o convite entram e os botões vêm por último;
                        // a mesma aula concluída de novo na sessão abre pronta.
                        ? EntradaDeResultado(
                            id: 'aula-${state.lessonId}',
                            estrela: const _FinishedBadge(),
                            titulo: Text(
                              l10n.lessonFinishedTitle(state.title),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            viktor: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: _blockGap,
                              children: [
                                if (_steps(context, state) case final steps?
                                    when steps.isNotEmpty) ...[
                                  NextSteps(steps: steps),
                                  const ResultsInfoLine(),
                                ],
                                SurveyInviteCard(
                                  kind: kind,
                                  source: _school
                                      ? SurveyInviteSource.schoolLesson
                                      : SurveyInviteSource.pilaresLesson,
                                ),
                              ],
                            ),
                            botoes: _FinishedButtons(
                              state: state,
                              school: _school,
                              onNext: (id) => _next(context, id),
                              onBack: () => context.go(_backRoute(context)),
                            ),
                            // O selo e o título juntos; o resto com o espaço
                            // do canvas entre os blocos.
                            montar: (partes) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: _blockGap,
                              children: [
                                Column(
                                  spacing: AppSpacing.lg,
                                  children: partes.sublist(0, 2),
                                ),
                                ...partes.sublist(2),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

/// O selo de aula concluída.
class _FinishedBadge extends StatelessWidget {
  const _FinishedBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primaryContainer,
      ),
      child: Icon(
        Icons.check_circle,
        size: LessonFinishedScreen._iconSize,
        color: colors.onPrimaryContainer,
      ),
    );
  }
}

/// Os botões por último: a próxima aula e a volta.
class _FinishedButtons extends StatelessWidget {
  const _FinishedButtons({
    required this.state,
    required this.school,
    required this.onNext,
    required this.onBack,
  });

  final LessonFinishedState state;
  final bool school;
  final ValueChanged<String> onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FooterButtonTheme(
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
                label: Text(l10n.lessonNext(state.nextTitle ?? '')),
                onPressed: () => onNext(state.nextId!),
              ),
            ),
          SizedBox(
            height: kButtonHeight,
            child: OutlinedButton(
              key: LessonFinishedKeys.back,
              onPressed: () => onBack(),
              child: Text(
                school ? l10n.surveyBackToSchool : l10n.surveyBackToLessons,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
