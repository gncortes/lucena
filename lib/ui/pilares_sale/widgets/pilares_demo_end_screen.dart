import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/pilares_access.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/pilares_demo_end_cubit.dart';
import '../view_models/pilares_prices_cubit.dart';
import 'pilares_sale_parts.dart';

/// "Capítulo 1 concluído" (H-VEN-04, quadro `PropV2DemoOferta`): o que o
/// aluno fez na demonstração, o que o curso completo traz e o preço. Não
/// persiste: a seta, o voltar e "Agora não" levam ao Catálogo com a
/// demonstração concluída.
class PilaresDemoEndScreen extends StatelessWidget {
  const PilaresDemoEndScreen({super.key});

  void _later(BuildContext context) =>
      context.go(Routes.trainingCatalog(TrainingCourse.pilares.name));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final prices = context.watch<PilaresPricesCubit>().state;
    final monthly = prices[PilaresPlan.monthly] ?? l10n.venRefMonthly;
    final lifetime = prices[PilaresPlan.lifetime] ?? l10n.venRefLifetime;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _later(context);
      },
      child: Scaffold(
        key: PurchaseKeys.demoEndScreen,
        appBar: LucenaAppBar(
          leading: BackButton(onPressed: () => _later(context)),
          title: Text(l10n.venEndedBar),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          children: [
            Text(l10n.venDemoEndTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.venDemoEndText, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.md),
            PilaresBenefitSection(
              compact: true,
              label: l10n.venDemoEndDone,
              items: [
                (
                  Icons.menu_book,
                  l10n.venDemoEndLessons,
                  l10n.venDemoEndLessonsText,
                ),
                (
                  // chess_pawn ainda não está nos ícones do Flutter.
                  Icons.extension,
                  l10n.venDemoEndExercises,
                  l10n.venDemoEndExercisesText,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PilaresBenefitSection(
              compact: true,
              label: l10n.venDemoEndFull,
              items: [
                (Icons.quiz, l10n.venBenefitLevel, l10n.venBenefitLevelText),
                (
                  Icons.stadium,
                  l10n.venBenefitTournament,
                  l10n.venDemoEndTournamentText,
                ),
                (
                  Icons.task_alt,
                  l10n.venBenefitGoals,
                  l10n.venDemoEndGoalsText,
                ),
                (Icons.bolt, l10n.venDemoEndDirect, l10n.venDemoEndDirectText),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              key: PurchaseKeys.demoEndPrice,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppShape.card),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      l10n.venDemoEndPrice(monthly, lifetime),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      l10n.venDemoEndPriceText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 20 / 14,
                        letterSpacing: 0,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: ActionsFooter(
          stacked: true,
          children: [
            BusyButton(
              buttonKey: PurchaseKeys.demoEndSeeOptions,
              label: l10n.venSaleBuy,
              onPressed: () {
                context.read<PilaresDemoEndCubit>().seeOptions();
                context.push(D2Paths.offer(origin: 'fim_demo'));
              },
            ),
            BusyButton(
              buttonKey: PurchaseKeys.demoEndLater,
              style: BusyButtonStyle.text,
              label: l10n.venDemoEndLater,
              onPressed: () => _later(context),
            ),
          ],
        ),
      ),
    );
  }
}
