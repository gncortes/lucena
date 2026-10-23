import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/feedback_entry.dart';
import '../../../routing/routes.dart';
import '../../core/keys/feedback_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../survey/widgets/survey_parts.dart';
import '../view_models/feedback_cubit.dart';

/// O "Enviar feedback" do Perfil (E1.26): assunto, texto até 500 e o
/// agradecimento do Viktor com "Voltar ao perfil".
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.settingsProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FeedbackCubit>();
    return BlocBuilder<FeedbackCubit, FeedbackState>(
      builder: (context, state) {
        final l10n = context.l10n;
        if (state.sent) {
          return ViktorThanks(
            key: FeedbackKeys.thanks,
            title: l10n.feedbackTitle,
            text: l10n.surveyThanks,
            backLabel: l10n.feedbackBack,
            onBack: () => _leave(context),
            viktor: state.viktor,
            closeKey: FeedbackKeys.close,
            backKey: FeedbackKeys.thanksBack,
          );
        }
        final theme = Theme.of(context);
        final gray = theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );
        final type = state.type;
        return Scaffold(
          key: FeedbackKeys.screen,
          appBar: LucenaAppBar(
            leading: IconButton(
              key: FeedbackKeys.close,
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => _leave(context),
            ),
            title: Text(l10n.feedbackTitle),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Text(l10n.feedbackIntro, style: gray),
              const SizedBox(height: AppSpacing.betweenCards),
              QuestionCard(
                title: l10n.feedbackKindQuestion,
                children: [
                  SurveyChips(
                    ids: [for (final kind in FeedbackType.values) kind.code],
                    selected: {?type?.code},
                    label: (code) => switch (FeedbackType.byCode(code)) {
                      FeedbackType.problem => l10n.feedbackKindProblem,
                      FeedbackType.idea => l10n.feedbackKindIdea,
                      _ => l10n.feedbackKindPraise,
                    },
                    chipKey: (code) =>
                        FeedbackKeys.kindChip(FeedbackType.byCode(code)!),
                    onToggle: (code) =>
                        cubit.pickType(FeedbackType.byCode(code)!),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.betweenCards),
              QuestionCard(
                title: l10n.feedbackTextTitle,
                hint: l10n.feedbackTextHelp,
                children: [
                  SurveyTextBox(
                    fieldKey: FeedbackKeys.text,
                    hint: l10n.feedbackTextHint,
                    initial: state.text,
                    maxLength: FeedbackEntry.maxText,
                    counterKey: FeedbackKeys.counter,
                    // 120 de altura no canvas.
                    minLines: 5,
                    maxLines: 8,
                    onChanged: cubit.setText,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.betweenCards),
              Text(l10n.feedbackAttached, style: gray),
            ],
          ),
          bottomNavigationBar: ActionsFooter(
            children: [
              FilledButton.icon(
                key: FeedbackKeys.send,
                icon: const Icon(Icons.send_outlined),
                label: Text(l10n.feedbackSend),
                onPressed: state.canSend ? cubit.send : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
