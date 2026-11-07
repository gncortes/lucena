import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/widgets/load_error.dart';
import '../view_models/endgame_lesson_cubit.dart';

Widget? endgameLoadError(BuildContext context, EndgameLessonState state) {
  if (state.failure case final failure?) {
    return LoadErrorScreen(
      kind: LoadErrorKind.fromFailure(failure),
      onAction: context.read<EndgameLessonCubit>().retryLoad,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
    );
  }
  if (state.missing) {
    return LoadErrorScreen(
      kind: LoadErrorKind.notFound,
      onAction: () => context.go(Routes.home),
    );
  }
  return null;
}
