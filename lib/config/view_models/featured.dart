import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../data/repositories/featured/featured_progress_repository.dart';
import '../../domain/models/featured.dart';
import '../../domain/models/find_move_checkpoint.dart';
import '../../ui/featured/view_models/find_move_cubit.dart';

/// "Ache o lance" do final em destaque [endgame], retomando de [initial].
FindMoveCubit createFindMoveCubit(
  BuildContext context, {
  required FeaturedEndgame endgame,
  FindMoveCheckpoint? initial,
}) => FindMoveCubit(
  endgame: endgame,
  initial: initial,
  progress: context.read<FeaturedProgressRepository>(),
);

/// O título da aula [lessonId] no idioma [language], para o "E agora?".
Future<String> featuredLessonTitle(
  BuildContext context, {
  required String lessonId,
  required String language,
}) async {
  final texts = await context.read<EndgameLessonRepository>().texts(language);
  return texts.lessonTitle(lessonId);
}
