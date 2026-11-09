import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/account/account_repository.dart';
import '../../data/repositories/characters/character_repository.dart';
import '../../data/repositories/training/course_download_repository.dart';
import '../../domain/models/content_session.dart';
import '../../domain/models/training/training_course_config.dart';
import '../../ui/course_entry/view_models/course_entry_cubit.dart';

/// A entrada do curso [config] (conta e pacote baixado), no capítulo
/// [chapterId] quando há.
CourseEntryCubit createCourseEntryCubit(
  BuildContext context, {
  required TrainingCourseConfig config,
  String? chapterId,
}) => CourseEntryCubit(
  accounts: context.read<AccountRepository>(),
  downloads: context.read<CourseDownloadRepository>(),
  characters: context.read<CharacterRepository>(),
  config: config,
  chapterId: chapterId,
);

/// Prende o conteúdo instalado enquanto a lição, o exercício ou o teste
/// estiver aberto. Nulo nas composições sem conteúdo remoto.
ContentSession? beginCourseContentSession(BuildContext context) {
  try {
    return context.read<CourseDownloadRepository>().beginSession();
  } on ProviderNotFoundException {
    return null;
  }
}
