import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/analysis/analysis_repository.dart';
import '../../data/repositories/characters/character_repository.dart';
import '../../data/repositories/lesson_ad/course_access_repository.dart';
import '../../data/repositories/lesson_ad/course_grants_repository.dart';
import '../../data/repositories/settings/settings_repository.dart';
import '../../data/repositories/training/course_training_repository.dart';
import '../../data/repositories/treinador/curiosidades_repository.dart';
import '../../data/repositories/treinador/seu_jogo_filtro_repository.dart';
import '../../data/repositories/treinador/treinador_preferencias.dart';
import '../../data/repositories/treinador/treinador_repository.dart';
import '../../domain/models/imported_game.dart';
import '../../domain/models/treinador/treinador.dart';
import '../../domain/use_cases/now.dart';
import '../../ui/game_details/view_models/game_details_cubit.dart';
import '../../ui/survey/view_models/viktor_thanks_cubit.dart';
import '../../ui/treinador/view_models/coach_analysis_cubit.dart';
import '../../ui/treinador/view_models/curiosidades_cubit.dart';
import '../../ui/treinador/view_models/ligar_conta_cubit.dart';
import '../../ui/treinador/view_models/treinador_cubit.dart';
import '../../ui/treinador/view_models/treinador_exercicio_cubit.dart';
import '../../ui/treinador/view_models/treinador_partida_cubit.dart';
import '../../ui/treinador_seu_jogo/view_models/curso_da_abertura_cubit.dart';
import '../../ui/treinador_seu_jogo/view_models/partidas_modelo_cubit.dart';
import '../../ui/treinador_seu_jogo/view_models/seu_jogo_cubit.dart';
import '../../ui/treinador_seu_jogo/view_models/teoria_cubit.dart';

/// A lista do Treinador (as três abas).
TreinadorCubit createCoachCubit(BuildContext context) => TreinadorCubit(
  repository: context.read<TreinadorRepository>(),
  grants: context.read<CourseGrantsRepository>(),
  preferencias: context.read<TreinadorPreferencias>(),
  now: context.read<Now>(),
);

/// Ligar a conta de [plataforma].
LigarContaCubit createLinkAccountCubit(
  BuildContext context, {
  required Plataforma plataforma,
}) => LigarContaCubit(
  repository: context.read<TreinadorRepository>(),
  plataforma: plataforma,
);

/// Uma partida analisada pelo servidor.
TreinadorPartidaCubit createCoachGameCubit(
  BuildContext context, {
  required String id,
}) => TreinadorPartidaCubit(
  id: id,
  repository: context.read<TreinadorRepository>(),
  grants: context.read<CourseGrantsRepository>(),
  preferencias: context.read<TreinadorPreferencias>(),
  now: context.read<Now>(),
);

/// As curiosidades que passam enquanto a partida é analisada.
CuriosidadesCubit createTriviaCubit(BuildContext context) => CuriosidadesCubit(
  repository: context.read<CuriosidadesRepository>(),
  now: context.read<Now>(),
);

/// O agradecimento do Viktor nas telas do Treinador.
ViktorThanksCubit createViktorThanksCubit(BuildContext context) =>
    ViktorThanksCubit(characters: context.read<CharacterRepository>());

/// Os exercícios de uma partida; [redo] recomeça do primeiro.
TreinadorExercicioCubit createCoachExerciseCubit(
  BuildContext context, {
  required String id,
  required bool redo,
}) => TreinadorExercicioCubit(
  id: id,
  repository: context.read<TreinadorRepository>(),
  preferencias: context.read<TreinadorPreferencias>(),
  refazer: redo,
);

/// A partida da análise completa.
CoachAnalysisCubit createCoachAnalysisCubit(
  BuildContext context, {
  required String id,
}) =>
    CoachAnalysisCubit(repository: context.read<TreinadorRepository>(), id: id);

/// A análise completa de uma partida importada, na base da análise do app.
GameDetailsCubit createImportedGameDetailsCubit(
  BuildContext context,
  ImportedGame game,
) => GameDetailsCubit.imported(
  game,
  analysis: context.read<AnalysisRepository>(),
  settings: context.read<SettingsRepository>(),
);

/// A aba Seu jogo (e as telas de estilo e de tema, que leem o mesmo resumo).
SeuJogoCubit createYourGameCubit(BuildContext context) => SeuJogoCubit(
  repository: context.read<TreinadorRepository>(),
  filtro: context.read<SeuJogoFiltroRepository>(),
  now: context.read<Now>(),
);

/// Onde a partida [partidaId] saiu da teoria.
TeoriaCubit createTheoryCubit(
  BuildContext context, {
  required String partidaId,
}) => TeoriaCubit(
  repository: context.read<TreinadorRepository>(),
  partidaId: partidaId,
);

/// As partidas-modelo da abertura [eco].
PartidasModeloCubit createModelGamesCubit(
  BuildContext context, {
  required String eco,
}) => PartidasModeloCubit(
  repository: context.read<TreinadorRepository>(),
  eco: eco,
);

/// A abertura [slot] no Pilares e se ele já tem o curso.
CursoDaAberturaCubit createOpeningCourseCubit(
  BuildContext context, {
  required String slot,
  int? parte,
}) => CursoDaAberturaCubit(
  training: context.read<TrainingRepository>(),
  access: context.read<CourseAccessRepository>(),
  slot: slot,
  parte: parte,
);
