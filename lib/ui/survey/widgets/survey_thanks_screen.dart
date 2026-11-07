import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/survey.dart';
import '../../../routing/routes.dart';
import '../../core/keys/survey_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/viktor_thanks_cubit.dart';
import 'survey_parts.dart';

/// "Obrigado" depois da pesquisa (H-OPI-05, H-OPI-09). A pesquisa abre esta
/// tela no lugar dela, então o botão, o X e o voltar do sistema voltam todos
/// à tela de onde a pesquisa abriu (lição concluída ou diploma). Sem nada
/// embaixo (link direto), vai ao curso.
class SurveyThanksScreen extends StatelessWidget {
  const SurveyThanksScreen({required this.kind, super.key});

  final SurveyKind kind;

  String get _home =>
      Routes.training(kind == SurveyKind.school ? 'escola' : 'pilares');

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viktor = context.watch<ViktorThanksCubit>().state;
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(_home);
      },
      child: KeyedSubtree(
        key: SurveyKeys.thanks,
        child: ViktorThanks(
          title: l10n.surveyTitle,
          text: l10n.surveyThanks,
          backLabel: kind == SurveyKind.school
              ? l10n.surveyBackToSchool
              : l10n.surveyBackToLessons,
          onBack: () => _back(context),
          viktor: viktor,
          closeKey: SurveyKeys.thanksClose,
          backKey: SurveyKeys.thanksBack,
        ),
      ),
    );
  }
}
