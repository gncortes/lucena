import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/widgets/busy_button.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/skeleton.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/ads/ads_repository.dart';
import '../../../domain/models/goal_preference.dart';
import '../../../routing/routes.dart';
import '../../core/keys/goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/viktor_conversation.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../view_models/goal_cubit.dart';
import 'goal_ui.dart';

/// "O que você quer fazer?" (T85, `PropV2UxObjetivoPrimeiro`): a primeira
/// tela, antes do tour.
class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<GoalCubit>();
    return BlocConsumer<GoalCubit, GoalState>(
      listenWhen: (previous, current) =>
          current.exit != null && previous.exit == null,
      listener: (context, state) {
        // Respondeu a pergunta: é a hora do consentimento do Google (E1.25).
        unawaited(context.read<AdsRepository>().requestConsent());
        // O objetivo (e a faixa de iniciante) já estão no perfil.
        context.read<ProfileCubit>().load();
        context.go(Routes.tour);
      },
      builder: (context, state) {
        if (state.failure case final failure?) {
          return LoadErrorScreen(
            kind: LoadErrorKind.fromFailure(failure),
            onAction: cubit.load,
          );
        }
        if (!state.ready) {
          return const Scaffold(key: GoalKeys.screen, body: SkeletonList());
        }
        // A primeira tela: sem seta de voltar; o voltar do sistema sai do app.
        return Scaffold(
          key: GoalKeys.screen,
          appBar: LucenaAppBar(automaticallyImplyLeading: false),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ViktorConversation(
                  viktor: state.viktor,
                  speech: l10n.goalViktorSay,
                  viktorKey: GoalKeys.viktor,
                  speechKey: GoalKeys.speech,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.goalTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GoalOptions(
                        l10n: l10n,
                        selected: state.goal,
                        without: cubit.fromLink
                            ? const {GoalPreference.learn}
                            : const {},
                        onSelected: cubit.select,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.goalHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: ActionsFooter(
            stacked: true,
            children: [
              BusyButton(
                buttonKey: GoalKeys.continueButton,
                onPressed: cubit.finish,
                label: l10n.goalContinue,
              ),
              TextButton.icon(
                key: GoalKeys.haveAccount,
                onPressed: () => context.push(Routes.accountEnterFrom('tour')),
                icon: const Icon(Icons.cloud_sync),
                label: Text(l10n.goalHaveAccount),
              ),
            ],
          ),
        );
      },
    );
  }
}
