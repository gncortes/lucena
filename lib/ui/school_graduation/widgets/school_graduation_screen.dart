import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/survey.dart';
import '../../../routing/routes.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/share/share_button.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/diploma_card.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../settings/widgets/about_screen.dart';
import '../view_models/school_graduation_cubit.dart';

/// A formatura da Escola (H-ESC-22): o diploma, o resumo por módulo, o cartão
/// de opinião e os dois caminhos seguintes (Pilares e catálogo). Sem abas.
class SchoolGraduationScreen extends StatefulWidget {
  const SchoolGraduationScreen({super.key});

  @override
  State<SchoolGraduationScreen> createState() => _SchoolGraduationScreenState();
}

class _SchoolGraduationScreenState extends State<SchoolGraduationScreen> {
  // O diploma que vira imagem ao compartilhar.
  final _card = GlobalKey();

  void _close() => context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = context.watch<SchoolGraduationCubit>().state;
    final nickname = context.select(
      (ProfileCubit cubit) => cubit.state?.nickname ?? '',
    );
    final locale = Localizations.localeOf(context);
    final date = state.date;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: LucenaAppBar(
          leading: IconButton(
            key: TrainingKeys.diplomaClose,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close_rounded),
            onPressed: _close,
          ),
          actions: [
            ShareIconButton(
              key: TrainingKeys.diplomaShare,
              boundary: _card,
              tooltip: l10n.graduationShare,
              footer: 'Lucena · ${l10n.homeTagline}',
              fileName: 'lucena-escola.png',
              text: l10n.schoolGraduationShareText(
                AboutScreen.websiteFor(locale.languageCode).toString(),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      padding: scrollPadding(
                        context,
                        left: AppSpacing.screen,
                        top: AppSpacing.sm,
                        right: AppSpacing.screen,
                        bottom: AppSpacing.lg,
                      ),
                      children: [
                        if (state.loaded && date != null) ...[
                          RepaintBoundary(
                            key: _card,
                            child: ColoredBox(
                              color: theme.scaffoldBackgroundColor,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: KeyedSubtree(
                                  key: TrainingKeys.diploma,
                                  child: DiplomaCard(
                                    brand: l10n.schoolGraduationBrand,
                                    name: nickname.isEmpty
                                        ? l10n.profileNicknameDefault
                                        : nickname,
                                    nameKey: TrainingKeys.diplomaName,
                                    text: l10n.schoolGraduationText(
                                      state.lessons,
                                    ),
                                    date: DateFormat.yMMMMd(locale.toString())
                                        .format(date),
                                    teacher: l10n.schoolGraduationTeacher,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Column(
                            key: TrainingKeys.diplomaSummary,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.schoolGraduationSummary,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              for (final module in state.modules)
                                Padding(
                                  key: TrainingKeys.diplomaModule(module.id),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(module.title)),
                                      Text(
                                        l10n.schoolGraduationModuleCount(
                                          module.lessons,
                                        ),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Card(
                            key: TrainingKeys.surveyCard,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppShape.large,
                              ),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.feedback_outlined),
                              title: Text(l10n.schoolGraduationSurveyTitle),
                              subtitle: Text(l10n.schoolGraduationSurveyBody),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push(
                                Routes.survey(SurveyKind.school),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // O lugar do confete (animação fora desta entrega).
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: SizedBox.shrink(
                          key: TrainingKeys.diplomaConfetti,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ActionsFooter(
                stacked: true,
                children: [
                  FilledButton.icon(
                    key: TrainingKeys.diplomaPilares,
                    icon: const Icon(Icons.auto_stories),
                    onPressed: () => context.push(Routes.pilaresSale),
                    label: Text(l10n.schoolGraduationPilares),
                  ),
                  OutlinedButton(
                    key: TrainingKeys.diplomaCatalog,
                    onPressed: () =>
                        context.go(Routes.trainingCatalog('escola')),
                    child: Text(l10n.trainingViewCatalog),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
