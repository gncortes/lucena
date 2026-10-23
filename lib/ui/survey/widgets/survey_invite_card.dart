import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/survey/survey_repository.dart';
import '../../../domain/models/survey.dart';
import '../../../routing/routes.dart';
import '../../core/keys/survey_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../view_models/survey_invite_cubit.dart';

/// De onde o convite aparece, que decide o texto dele.
enum SurveyInviteSource { trail, endgameLesson, schoolLesson }

/// O cartão "O que achou das aulas?" (E1.05): convida a responder o
/// questionário de [kind]. Não é janela nem faixa fixa. Some assim que há
/// resposta enviada daquele [kind]; ao voltar do questionário, lê de novo.
class SurveyInviteCard extends StatelessWidget {
  const SurveyInviteCard({required this.kind, required this.source, super.key});

  final SurveyKind kind;
  final SurveyInviteSource source;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        SurveyInviteCubit(kind: kind, surveys: context.read<SurveyRepository>())
          ..load(),
    child: _InviteView(kind: kind, source: source),
  );
}

class _InviteView extends StatelessWidget {
  const _InviteView({required this.kind, required this.source});

  final SurveyKind kind;
  final SurveyInviteSource source;

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<SurveyInviteCubit>();
    await context.push(
      Routes.survey(kind, fromLesson: source != SurveyInviteSource.trail),
    );
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = context.watch<SurveyInviteCubit>().state;
    if (!visible) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final text = switch (source) {
      SurveyInviteSource.trail => l10n.surveyInviteTrail,
      SurveyInviteSource.endgameLesson => l10n.surveyInviteEndgameLesson,
      SurveyInviteSource.schoolLesson => l10n.surveyInviteSchoolLesson,
    };
    return Container(
      key: SurveyKeys.invite(kind),
      padding: const EdgeInsets.all(AppSpacing.insideCard),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.md,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppShape.medium),
                ),
                child: Icon(
                  Icons.feedback,
                  size: AppIconSize.standard,
                  color: colors.primary,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xs / 2,
                  children: [
                    Text(l10n.surveyInviteTitle, style: context.cardTitle),
                    Text(text, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          FilledButton.tonal(
            key: SurveyKeys.inviteAction(kind),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(kButtonHeightCompact),
            ),
            onPressed: () => _open(context),
            child: Text(l10n.surveyInviteAction),
          ),
        ],
      ),
    );
  }
}
