import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/would_pay.dart';
import '../../../routing/routes.dart';
import '../../core/keys/would_pay_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/app_bar_progress.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../survey/widgets/survey_parts.dart';
import '../view_models/would_pay_cubit.dart';

/// O "Você pagaria?" (E1.26): curso, treinador e o passo 3. Depois de
/// enviar, o agradecimento do Viktor da E1.05 na mesma tela.
class WouldPayScreen extends StatelessWidget {
  const WouldPayScreen({super.key});

  /// O "X" volta à lista e o rascunho fica.
  void _leave(BuildContext context) {
    context.read<WouldPayCubit>().leave();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.endgames);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WouldPayCubit>();
    return BlocBuilder<WouldPayCubit, WouldPayState>(
      builder: (context, state) {
        final l10n = context.l10n;
        if (state.sent) {
          return ViktorThanks(
            key: WouldPayKeys.thanks,
            title: l10n.payTitle,
            text: l10n.surveyThanks,
            backLabel: l10n.surveyBackToLessons,
            onBack: () => _leave(context),
            viktor: state.viktor,
            closeKey: WouldPayKeys.close,
            backKey: WouldPayKeys.thanksBack,
          );
        }
        return PopScope(
          // Passo 2 em diante: o voltar do sistema volta um passo.
          canPop: state.step == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.back();
          },
          child: Scaffold(
            key: WouldPayKeys.screen,
            appBar: LucenaAppBar(
              leading: state.step == 0
                  ? IconButton(
                      key: WouldPayKeys.close,
                      icon: const Icon(Icons.close),
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      onPressed: () => _leave(context),
                    )
                  : IconButton(
                      key: WouldPayKeys.back,
                      icon: const BackButtonIcon(),
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      onPressed: cubit.back,
                    ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.payTitle),
                  Text(
                    l10n.payStep(state.step + 1),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              bottom: AppBarProgress(
                key: WouldPayKeys.progress,
                value: (state.step + 1) / state.total,
              ),
            ),
            body: state.ready ? _Body(state: state) : const SizedBox.shrink(),
            bottomNavigationBar: ActionsFooter(
              children: [
                if (state.isLast)
                  FilledButton.icon(
                    key: WouldPayKeys.send,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(l10n.paySend),
                    onPressed: state.ready && state.canAdvance && !state.sending
                        ? cubit.send
                        : null,
                  )
                else
                  FilledButton(
                    key: WouldPayKeys.next,
                    onPressed: state.ready && state.canAdvance
                        ? cubit.next
                        : null,
                    child: Text(l10n.payContinue),
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

  final WouldPayState state;

  @override
  Widget build(BuildContext context) {
    final cards = switch (state.step) {
      0 => [_CourseCard(state), _CoursePriceCard(state)],
      1 => [_CoachCard(state), _CoachPriceCard(state)],
      _ => [
        _LearnCard(state),
        _NextCard(state),
        _WhyCard(state),
        if (!state.levelDefined) _LevelCard(state),
      ],
    };
    return ListView(
      // Um passo por vez: a chave troca de passo sem reaproveitar os campos.
      key: ValueKey('wouldPay.step.${state.step}'),
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

String _answer(AppLocalizations l10n, WouldPayAnswer answer) =>
    switch (answer) {
      WouldPayAnswer.yes => l10n.payYes,
      WouldPayAnswer.maybe => l10n.payMaybe,
      WouldPayAnswer.no => l10n.payNo,
    };

class _CourseCard extends StatelessWidget {
  const _CourseCard(this.state);

  final WouldPayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QuestionCard(
      title: l10n.payCourseQuestion,
      hint: l10n.payCourseHelp,
      children: [
        OptionList<WouldPayAnswer>(
          values: WouldPayAnswer.values,
          selected: state.answers.course,
          label: (answer) => _answer(l10n, answer),
          optionKey: (answer) => WouldPayKeys.courseAnswer(answer.code),
          onPick: context.read<WouldPayCubit>().pickCourse,
        ),
      ],
    );
  }
}

class _CoursePriceCard extends StatelessWidget {
  const _CoursePriceCard(this.state);

  final WouldPayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QuestionCard(
      title: l10n.payHowMuch,
      hint: l10n.payHowMuchHelp,
      children: [
        OptionList<CoursePrice>(
          values: CoursePrice.values,
          selected: state.answers.coursePrice,
          label: (price) => switch (price) {
            CoursePrice.none => l10n.payCourseNone,
            CoursePrice.upTo29 => l10n.payCourse1,
            CoursePrice.from30To59 => l10n.payCourse2,
            CoursePrice.from60To99 => l10n.payCourse3,
            CoursePrice.from100 => l10n.payCourse4,
          },
          optionKey: (price) => WouldPayKeys.coursePrice(price.code),
          onPick: context.read<WouldPayCubit>().pickCoursePrice,
        ),
      ],
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard(this.state);

  final WouldPayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QuestionCard(
      title: l10n.payCoachQuestion,
      hint: l10n.payCoachHelp,
      children: [
        OptionList<WouldPayAnswer>(
          values: WouldPayAnswer.values,
          selected: state.answers.coach,
          label: (answer) => _answer(l10n, answer),
          optionKey: (answer) => WouldPayKeys.coachAnswer(answer.code),
          onPick: context.read<WouldPayCubit>().pickCoach,
        ),
      ],
    );
  }
}

class _CoachPriceCard extends StatelessWidget {
  const _CoachPriceCard(this.state);

  final WouldPayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QuestionCard(
      title: l10n.payHowMuch,
      hint: l10n.payHowMuchHelp,
      children: [
        OptionList<MonthPrice>(
          values: MonthPrice.values,
          selected: state.answers.coachPrice,
          label: (price) => switch (price) {
            MonthPrice.none => l10n.payMonthNone,
            MonthPrice.upTo9 => l10n.payMonth1,
            MonthPrice.from10To19 => l10n.payMonth2,
            MonthPrice.from20To39 => l10n.payMonth3,
            MonthPrice.from40 => l10n.payMonth4,
          },
          optionKey: (price) => WouldPayKeys.coachPrice(price.code),
          onPick: context.read<WouldPayCubit>().pickCoachPrice,
        ),
      ],
    );
  }
}

class _LearnCard extends StatelessWidget {
  const _LearnCard(this.state);

  final WouldPayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QuestionCard(
      title: l10n.payLearnQuestion,
      hint: l10n.payLearnHelp,
      children: [
        OptionList<LearnAnswer>(
          values: LearnAnswer.values,
          selected: state.answers.learn,
          label: (answer) => switch (answer) {
            LearnAnswer.yes => l10n.payLearnYes,
            LearnAnswer.some => l10n.payLearnSome,
            LearnAnswer.no => l10n.payLearnNo,
          },
          optionKey: (answer) => WouldPayKeys.learnAnswer(answer.code),
          onPick: context.read<WouldPayCubit>().pickLearn,
        ),
      ],
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard(this.state);

  final WouldPayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QuestionCard(
      title: l10n.payNextQuestion,
      children: [
        SurveyTextBox(
          fieldKey: WouldPayKeys.nextText,
          hint: l10n.payNextHint,
          initial: state.answers.next,
          maxLength: WouldPayAnswers.maxNext,
          // Uma linha no canvas (56 de altura); cresce se a pessoa escrever.
          minLines: 1,
          maxLines: 3,
          onChanged: context.read<WouldPayCubit>().setNext,
        ),
      ],
    );
  }
}

class _WhyCard extends StatelessWidget {
  const _WhyCard(this.state);

  final WouldPayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QuestionCard(
      title: l10n.payWhyQuestion,
      hint: l10n.payWhyHelp,
      children: [
        SurveyChips(
          ids: WouldPayOptions.why,
          selected: state.answers.why,
          label: (id) => switch (id) {
            'learn' => l10n.payWhyLearn,
            'tournament' => l10n.payWhyTournament,
            'rating' => l10n.payWhyRating,
            'teach' => l10n.payWhyTeach,
            _ => l10n.payWhyCurious,
          },
          chipKey: WouldPayKeys.whyChip,
          onToggle: context.read<WouldPayCubit>().toggleWhy,
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard(this.state);

  final WouldPayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final level = state.answers.level;
    return QuestionCard(
      title: l10n.payLevelQuestion,
      hint: l10n.payLevelHelp,
      children: [
        SurveyChips(
          ids: WouldPayOptions.levels,
          selected: {?level},
          label: (id) => switch (id) {
            'beginner' => l10n.payLevelBeginner,
            'middle' => l10n.payLevelMiddle,
            _ => l10n.payLevelAdvanced,
          },
          chipKey: WouldPayKeys.levelChip,
          onToggle: context.read<WouldPayCubit>().toggleLevel,
        ),
      ],
    );
  }
}
