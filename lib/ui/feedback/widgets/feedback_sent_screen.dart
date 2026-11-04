import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/feedback_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../survey/view_models/viktor_thanks_cubit.dart';
import '../../survey/widgets/survey_parts.dart';

/// "Feedback enviado" (H-OPI-12). O formulário abre esta tela no lugar
/// dele, então o botão, o X e o voltar do sistema voltam todos ao Perfil.
class FeedbackSentScreen extends StatelessWidget {
  const FeedbackSentScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.settingsProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viktor = context.watch<ViktorThanksCubit>().state;
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.settingsProfile);
      },
      child: KeyedSubtree(
        key: FeedbackKeys.thanks,
        child: ViktorThanks(
          title: l10n.surveyTitle,
          text: l10n.surveyThanks,
          backLabel: l10n.feedbackBack,
          onBack: () => _back(context),
          viktor: viktor,
          closeKey: FeedbackKeys.thanksClose,
          backKey: FeedbackKeys.thanksBack,
        ),
      ),
    );
  }
}
