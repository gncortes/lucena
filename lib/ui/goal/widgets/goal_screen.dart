import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

/// "O que você quer fazer?" (E1.11, canvas página 18): entre o tour e "Seu
/// nível". "Aprender a jogar" pula o nível e cai na tela inicial.
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
        if (state.exit == GoalExit.level) return context.go(Routes.level);
        // O objetivo e a faixa de iniciante já estão no perfil.
        context.read<ProfileCubit>().load();
        context.go(Routes.home);
      },
      builder: (context, state) {
        if (!state.ready) return const Scaffold(key: GoalKeys.screen);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.go(Routes.tour);
          },
          child: Scaffold(
            key: GoalKeys.screen,
            appBar: LucenaAppBar(
              // Volta para o tour (o voltar do sistema fecharia o app).
              leading: BackButton(
                key: GoalKeys.back,
                onPressed: () => context.go(Routes.tour),
              ),
            ),
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
                FilledButton(
                  key: GoalKeys.continueButton,
                  onPressed: cubit.finish,
                  child: Text(l10n.goalContinue),
                ),
                TextButton.icon(
                  key: GoalKeys.haveAccount,
                  onPressed: () => context.go(Routes.account),
                  icon: const Icon(Icons.cloud_sync),
                  label: Text(l10n.goalHaveAccount),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
