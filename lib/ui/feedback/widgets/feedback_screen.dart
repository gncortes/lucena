import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/feedback_entry.dart';
import '../../../routing/route_names.dart';
import '../../../routing/routes.dart';
import '../../core/keys/feedback_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/theme/app_button.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../survey/widgets/survey_parts.dart';
import '../view_models/feedback_cubit.dart';

/// O "Enviar feedback" do Perfil (E1.26, H-OPI-11): assunto e texto até
/// 500. Enviado, abre o "Feedback enviado" no lugar dela (H-OPI-12); se o
/// envio falha, avisa com "Tentar novamente" e mantém o texto.
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
    final loadState = context.watch<FeedbackCubit>().state;
    if (!loadState.ready && loadState.failure == null) {
      return const LoadSkeletonScreen();
    }
    if (loadState.failure case final failure?) {
      return LoadErrorScreen(
        kind: LoadErrorKind.fromFailure(failure),
        onAction: context.read<FeedbackCubit>().retryLoad,
        onBack: () =>
            context.canPop() ? context.pop() : context.go(Routes.home),
      );
    }

    final cubit = context.read<FeedbackCubit>();
    return BlocListener<FeedbackCubit, FeedbackState>(
      // Sem conta (proteção contra abuso): o assunto e o texto ficam no
      // rascunho e voltam depois da conta.
      listenWhen: (before, now) => now.needsAccount > before.needsAccount,
      listener: (context, state) {
        final l10n = context.l10n;
        showLucenaSnackBar(
          context,
          l10n.feedbackNeedsAccount,
          key: FeedbackKeys.needsAccount,
          action: SnackBarAction(
            key: FeedbackKeys.needsAccountSignIn,
            label: l10n.accountSignIn,
            // A conta toma o lugar do formulário e, no fim, o devolve.
            onPressed: () => context.pushReplacement(
              Routes.accountEnterFrom(Routes.feedback),
            ),
          ),
        );
      },
      child: BlocConsumer<FeedbackCubit, FeedbackState>(
        listenWhen: (before, now) =>
            (now.sent && !before.sent) || now.sendErrors > before.sendErrors,
        listener: (context, state) {
          if (state.sent) {
            context.pushReplacementNamed(RouteNames.feedbackSent);
            return;
          }
          final l10n = context.l10n;
          showLucenaSnackBar(
            context,
            l10n.loadErrorGenericTitle,
            key: FeedbackKeys.sendError,
            action: SnackBarAction(
              label: l10n.loadErrorRetry,
              onPressed: cubit.send,
            ),
          );
        },
        builder: (context, state) {
          final l10n = context.l10n;
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
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
                SizedBox(
                  height: kButtonHeight,
                  child: BusyButton(
                    buttonKey: FeedbackKeys.send,
                    icon: Icons.send,
                    label: l10n.feedbackSend,
                    busy: state.sending,
                    onPressed: state.canSend ? cubit.send : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
