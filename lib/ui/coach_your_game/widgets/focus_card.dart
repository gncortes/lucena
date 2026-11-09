import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/view_models/coach.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/use_cases/coach/opening_in_course.dart';
import '../../../domain/use_cases/coach/your_game_summary.dart';
import '../../../routing/frentes/coach_your_game_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/coach_your_game_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_card.dart';
import '../view_models/opening_course_cubit.dart';
import 'your_game_texts.dart';
import '../../core/theme/app_text.dart';

/// "Onde focar agora": o ponto que mais pesa nas partidas, com a posição e,
/// quando a abertura é do Pilares, a ligação ao curso.
class FocusCard extends StatelessWidget {
  const FocusCard({required this.focus, super.key});

  final YourGameFocus focus;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final (title, text, button, destination) = switch (focus) {
      OpeningFocus(:final opening, :final exit) => (
        t.sjFocoAbertura,
        t.sjFocoAberturaTexto(
          opening.name,
          exit.times,
          opening.scoreRate.games,
          t.fullMove(
            chessMove: exit.chessMove,
            black: exit.black,
            san: exit.san,
          ),
        ),
        t.sjFocoVerPosicao,
        YourGamePaths.theoryOf(exit.recentGame),
      ),
      MotifFocus(:final motif) => (
        t.motifName(motif.motif),
        t.sjFocoTemaTexto(motif.positions.length),
        t.sjVerPosicoes,
        YourGamePaths.motifOf(motif.motif),
      ),
    };
    return KeyedSubtree(
      key: YourGameKeys.focus,
      child: LucenaCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppShape.large),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(
                  color: primaryColor,
                  child: const SizedBox(width: 4),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              size: AppIconSize.compact,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                t.sjFocoTitulo,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: primaryColor,
                                  fontWeight: AppWeight.medium,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: AppWeight.medium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(text, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          key: YourGameKeys.focusSee,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(kButtonHeight),
                          ),
                          onPressed: () => context.push(destination),
                          child: Text(button),
                        ),
                        if (focus case OpeningFocus(
                          :final opening,
                          :final exit,
                        ))
                          if (openingSlot(
                                eco: opening.eco,
                                name: opening.name,
                                color: opening.color,
                                course: opening.course,
                              )
                              case final slot?)
                            BlocProvider(
                              key: ValueKey(slot),
                              create: (c) => createOpeningCourseCubit(
                                c,
                                slot: slot,
                                part: opening.course?.part,
                              )..load(),
                              child: _CourseLink(
                                slot: slot,
                                serverPart: opening.course?.part,
                                chessMove: exit.chessMove,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Com o Pilares: a parte em evidência nas metas de hoje. Sem o curso: a
/// abertura com cadeado e a oferta.
class _CourseLink extends StatelessWidget {
  const _CourseLink({
    required this.slot,
    required this.serverPart,
    required this.chessMove,
  });

  final String slot;
  final int? serverPart;
  final int chessMove;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OpeningCourseCubit>().state;
    final opening = state.opening;
    if (state.loading || opening == null) return const SizedBox.shrink();
    final t = context.l10n;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: TextButton(
        key: YourGameKeys.focusCourse,
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(kButtonHeightCompact),
        ),
        onPressed: () => context.push(
          state.hasCourse
              ? Routes.trainingGoals(
                  TrainingCourse.pilares.name,
                  destaque: opening.highlight.lessonEntry.id,
                )
              : YourGamePaths.pilaresOf(
                  slot,
                  part: serverPart,
                  chessMove: serverPart == null ? null : '$chessMove',
                ),
        ),
        child: Text(
          state.hasCourse
              ? t.sjFocoFazerParte(opening.highlight.number)
              : t.sjFocoEstudar,
          textAlign: TextAlign.center,
          style: TextStyle(color: primaryColor, fontWeight: AppWeight.medium),
        ),
      ),
    );
  }
}
