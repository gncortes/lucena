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
import '../../core/widgets/lucena_card.dart';
import '../view_models/survey_invite_cubit.dart';

/// De onde o convite aparece: decide o texto, o formato (cartão com botão no
/// fim da lição, linha clicável no diploma) e a origem no registro.
enum SurveyInviteSource {
  pilaresLesson('licao_pilares'),
  schoolLesson('licao_escola'),
  pilaresDiploma('diploma_pilares'),
  schoolDiploma('diploma_escola');

  const SurveyInviteSource(this.origin);

  /// O valor de `origem` no `questionario_aberto`.
  final String origin;

  bool get isDiploma => this == pilaresDiploma || this == schoolDiploma;
}

/// O convite "O que você achou...?" (E1.05, H-OPI-01/02) para o
/// questionário de [kind]. No fim da lição é um cartão com "Responder"; no
/// diploma, uma linha clicável. Some assim que há resposta enviada daquele
/// [kind]; ao voltar do questionário, lê de novo.
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
    await context.push(Routes.survey(kind, origin: source.origin));
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = context.watch<SurveyInviteCubit>().state;
    if (!visible) return const SizedBox.shrink();
    final l10n = context.l10n;
    final school = kind == SurveyKind.school;
    if (source.isDiploma) {
      // A key fica num KeyedSubtree próprio: o LucenaCard repete a key que
      // recebe por dentro e o finder acharia dois.
      return KeyedSubtree(
        key: SurveyKeys.inviteRow(kind),
        child: LucenaCard(
          onTap: () => _open(context),
          child: _InviteHeader(
            title: school
                ? l10n.opiniaoDiplomaSchoolTitle
                : l10n.opiniaoDiplomaPilaresTitle,
            text: l10n.opiniaoDiplomaText,
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      );
    }
    return KeyedSubtree(
      key: SurveyKeys.invite(kind),
      child: LucenaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            _InviteHeader(
              title: l10n.surveyInviteTitle,
              text: school
                  ? l10n.surveyInviteSchoolLesson
                  : l10n.surveyInviteEndgameLesson,
            ),
            // Botão dentro do cartão: 48 no canvas.
            SizedBox(
              height: kButtonHeightCompact,
              child: FilledButton.tonal(
                key: SurveyKeys.inviteAction(kind),
                onPressed: () => _open(context),
                child: Text(l10n.surveyInviteAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícone `feedback`, título e texto do convite.
class _InviteHeader extends StatelessWidget {
  const _InviteHeader({required this.title, required this.text, this.trailing});

  final String title;
  final String text;
  final Widget? trailing;

  static const _iconBox = 40.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      spacing: AppSpacing.md,
      children: [
        Container(
          width: _iconBox,
          height: _iconBox,
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
              Text(title, style: context.cardTitle),
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
