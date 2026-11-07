import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/training/training_course.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/course_unlocked_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/sucesso_da_compra.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../lesson_end/widgets/lesson_end_parts.dart';
import '../view_models/course_unlocked_cubit.dart';

/// Curso liberado (H-R5-62, canvas `PropV2CursoLiberadoPresente` e
/// `PropV2CursoLiberadoCompra`): o círculo (presente azul ou ✓ verde), o
/// título, a fala do Viktor com o nome e "Montar o meu plano" (ou "Ir para o
/// curso", para quem já tem plano). O X e o voltar voltam para onde estava;
/// sem para onde voltar, o Início.
class CourseUnlockedScreen extends StatelessWidget {
  const CourseUnlockedScreen({required this.origin, super.key});

  final CourseUnlockedOrigin origin;

  static void _close(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final gift = origin == CourseUnlockedOrigin.gift;
    return KeyedSubtree(
      key: CourseUnlockedKeys.screen,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close(context);
        },
        child: Scaffold(
          appBar: LessonEndClose(
            buttonKey: CourseUnlockedKeys.close,
            onClose: () => _close(context),
          ),
          body: SafeArea(
            top: false,
            child: BlocBuilder<CourseUnlockedCubit, CourseUnlockedState>(
              builder: (context, state) {
                if (!state.loaded) return const SizedBox.shrink();
                final hello = switch ((gift, state.name.isEmpty)) {
                  (true, true) => l.unlockedGiftHelloNoName,
                  (true, false) => l.unlockedGiftHello(state.name),
                  (false, true) => l.unlockedPurchaseHelloNoName,
                  (false, false) => l.unlockedPurchaseHello(state.name),
                };
                final speech = [
                  hello,
                  l.unlockedChapters,
                  if (!state.hasPlan) l.unlockedPlanFirst,
                ].join(' ');
                final teacher = state.teacher;
                return SucessoDaCompra(
                  tamanho: 96,
                  icone: gift ? Icons.card_giftcard : CanvasSymbols.check,
                  fundo: gift
                      ? theme.colorScheme.primaryContainer
                      : AppColors.successSurface,
                  cor: gift
                      ? theme.colorScheme.primary
                      : AppColors.successOnSurface,
                  titulo: Text(
                    gift ? l.unlockedGiftTitle : l.unlockedPurchaseTitle,
                    key: CourseUnlockedKeys.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 24,
                      height: 32 / 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  texto: KeyedSubtree(
                    key: CourseUnlockedKeys.speech,
                    child: teacher == null
                        ? Text(
                            speech,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          )
                        : TeacherSpeech(
                            showSpeedBadge: false,
                            canvasTrainingBalloon: true,
                            teacher: teacher,
                            avatarSize: 56,
                            text: speech,
                            speechContext: SpeechContext.teaching,
                          ),
                  ),
                  botoes: [
                    state.hasPlan
                        ? BusyButton(
                            buttonKey: CourseUnlockedKeys.action,
                            label: l.unlockedGoToCourse,
                            onPressed: () => context.go(
                              Routes.training(TrainingCourse.pilares.name),
                            ),
                          )
                        : BusyButton(
                            buttonKey: CourseUnlockedKeys.action,
                            icon: CanvasSymbols.editCalendar,
                            label: l.unlockedMakePlan,
                            onPressed: () => context.go(D2Paths.pilaresGoal),
                          ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
