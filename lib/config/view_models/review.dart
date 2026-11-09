import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../data/repositories/progress/progress_repository.dart';
import '../../data/repositories/review/review_repository.dart';
import '../../data/repositories/school/school_progress_repository.dart';
import '../../ui/core/analytics/analytics_context.dart';
import '../../ui/review/view_models/review_prompt_cubit.dart';

/// O pedido de avaliação na loja; [trigger] é o `gatilho` (`aula` ou
/// `final`).
ReviewPromptCubit createReviewPromptCubit(
  BuildContext context, {
  required String trigger,
}) => ReviewPromptCubit(
  review: context.read<ReviewRepository>(),
  school: context.read<SchoolProgressRepository>(),
  endgames: context.read<EndgameProgressRepository>(),
  progress: context.read<ProgressRepository>(),
  trigger: trigger,
  analytics: context.analytics,
);
