import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/view_models/review.dart';
import '../../../domain/models/conclusion.dart';
import '../../conclusion/view_models/conclusion_cubit.dart';
import '../view_models/review_prompt_cubit.dart';

/// Na "Aula concluída": pede a avaliação (se a política deixa) 1,5 s depois
/// de a tela abrir.
class LessonReviewPrompt extends StatelessWidget {
  const LessonReviewPrompt({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        createReviewPromptCubit(context, trigger: 'aula')..ask(),
    lazy: false,
    child: child,
  );
}

/// No resultado de uma partida acabada agora ([fresh]): vitória pede a
/// avaliação 1,5 s depois; derrota marca o revés.
class ConclusionReviewPrompt extends StatelessWidget {
  const ConclusionReviewPrompt({
    required this.fresh,
    required this.child,
    super.key,
  });

  final bool fresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!fresh) return child;
    return BlocProvider(
      create: (context) => createReviewPromptCubit(context, trigger: 'final'),
      lazy: false,
      child: BlocListener<ConclusionCubit, ConclusionState>(
        listenWhen: (before, after) => !before.ready && after.ready,
        listener: (context, state) {
          final prompt = context.read<ReviewPromptCubit>();
          switch (state.conclusion?.result) {
            case ConclusionResult.won:
              prompt.ask();
            case ConclusionResult.lost:
              prompt.noteSetback();
            case ConclusionResult.draw || null:
              break;
          }
        },
        child: child,
      ),
    );
  }
}
