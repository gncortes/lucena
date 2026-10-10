import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../school/view_models/lesson_cubit.dart';

class EndgameLessonState {
  const EndgameLessonState({
    this.ready = false,
    this.missing = false,
    this.lesson,
    this.texts = LessonTexts.empty,
    this.progress = const EndgameLessonProgress(),
    this.lessonOngoing = false,
    this.speedrun,
    this.viktor,
    this.lessonNumber = 0,
    this.lessonCount = 0,
    this.nextLesson,
    this.ongoingPart,
    this.ongoingStep = 0,
    this.moduleNumber = 0,
    this.moduleCount = 0,
  });

  /// A posição da aula no módulo dela (1 é a primeira) e quantas ele tem.
  final int moduleNumber;
  final int moduleCount;

  /// A parte aberta quando o aluno saiu da lição (para "Continuar").
  final String? ongoingPart;

  /// O passo em que o aluno saiu da parte aberta (0: nem passou do
  /// primeiro).
  final int ongoingStep;

  /// As partes já feitas.
  Set<String> get partsDone {
    final lesson = this.lesson;
    return lesson == null ? const {} : progress.partsDone(lesson);
  }

  /// A parte recomendada; nula com todas feitas (o próximo é o teste).
  LessonPart? get recommendedPart {
    final lesson = this.lesson;
    return lesson == null
        ? null
        : EndgameLessonRules.recommendedPart(lesson, progress);
  }

  bool get allPartsDone => lesson != null && recommendedPart == null;

  final bool ready;

  /// A aula pedida não existe na trilha.
  final bool missing;
  final EndgameLesson? lesson;
  final LessonTexts texts;
  final EndgameLessonProgress progress;

  /// A lição está começada e não terminada (o botão diz "continuar").
  final bool lessonOngoing;

  /// O speedrun do final desta aula. Nulo se o final não tem speedrun.
  final Speedrun? speedrun;
  final Character? viktor;
  final int lessonNumber;
  final int lessonCount;

  /// A aula seguinte na trilha. Nula na última.
  final String? nextLesson;

  int get score {
    final lesson = this.lesson;
    return lesson == null ? 0 : progress.scoreOf(lesson);
  }

  int get maxScore => lesson?.maxScore ?? 0;
  int get passScore => lesson?.passScore ?? 0;

  /// A faixa da nota atual e as estrelas que cada faixa pede.
  ExerciseGrade get grade {
    final lesson = this.lesson;
    return lesson == null
        ? ExerciseGrade.below
        : EndgameLessonRules.grade(lesson, score);
  }

  Map<ExerciseGrade, int> get gradeStars {
    final lesson = this.lesson;
    return lesson == null ? const {} : EndgameLessonRules.gradeStars(lesson);
  }

  int get solved {
    final lesson = this.lesson;
    return lesson == null ? 0 : progress.solvedOf(lesson);
  }

  int get exerciseCount => lesson?.exercises.length ?? 0;

  bool get allSolved {
    final lesson = this.lesson;
    return lesson != null && EndgameLessonRules.allSolved(lesson, progress);
  }

  /// A nota mínima foi alcançada: o passo final está liberado.
  bool get passed {
    final lesson = this.lesson;
    return lesson != null && EndgameLessonRules.passed(lesson, progress);
  }

  /// O primeiro exercício ainda não resolvido (ou o aberto quando o app
  /// fechou). Nulo com todos resolvidos.
  Exercise? get nextExercise {
    final lesson = this.lesson;
    return lesson == null
        ? null
        : EndgameLessonRules.nextExercise(lesson, progress);
  }

  /// As estrelas ganhas num exercício. Nula se ainda não foi resolvido.
  int? starsOf(String exerciseId) => progress.stars[exerciseId];

  EndgameLessonState copyWith({EndgameLessonProgress? progress}) =>
      EndgameLessonState(
        ready: ready,
        missing: missing,
        lesson: lesson,
        texts: texts,
        progress: progress ?? this.progress,
        lessonOngoing: lessonOngoing,
        speedrun: speedrun,
        viktor: viktor,
        lessonNumber: lessonNumber,
        lessonCount: lessonCount,
        nextLesson: nextLesson,
        ongoingPart: ongoingPart,
        ongoingStep: ongoingStep,
        moduleNumber: moduleNumber,
        moduleCount: moduleCount,
      );
}

/// Uma aula de final: a lição, os exercícios, a nota e o passo final. A
/// lição e cada exercício abrem em telas próprias; aqui fica o quadro geral.
class EndgameLessonCubit extends Cubit<EndgameLessonState> {
  EndgameLessonCubit({
    required this._lessons,
    required this._progress,
    required this._journey,
    required this._characters,
  }) : super(const EndgameLessonState());

  final EndgameLessonRepository _lessons;
  final EndgameProgressRepository _progress;
  final JourneyRepository _journey;
  final CharacterRepository _characters;

  Future<void> load(String lessonId, String language) async {
    final trail = await _lessons.trail();
    final lesson = trail.lesson(lessonId);
    if (lesson == null) {
      if (!isClosed) emit(const EndgameLessonState(ready: true, missing: true));
      return;
    }
    final texts = await _lessons.texts(language);
    var progress = await _progress.load();
    // Exercício cortado da aula: a estrela e o exercício aberto dele saem.
    final pruned = EndgameLessonRules.prune(lesson, progress.of(lessonId));
    if (!identical(pruned, progress.of(lessonId))) {
      progress = progress.withLesson(lessonId, pruned);
      await _progress.save(progress);
    }
    final speedruns = await _journey.speedruns();
    final characters = await _characters.characters();
    if (isClosed) return;
    Character? viktor;
    for (final character in characters) {
      if (character.id == LessonCubit.viktorId) viktor = character;
    }
    final lessons = trail.lessons;
    final checkpoint = progress.ongoing?.lessonId == lessonId
        ? EndgameLessonRules.migrate(lesson, progress.ongoing)
        : null;
    final module = trail.modules.firstWhere(
      (each) => each.lessons.contains(lesson),
    );
    emit(
      EndgameLessonState(
        ready: true,
        lesson: lesson,
        texts: texts,
        progress: progress.of(lessonId),
        lessonOngoing: progress.ongoing?.lessonId == lessonId,
        speedrun: EndgameLessonRules.speedrunOf(lesson, speedruns),
        viktor: viktor,
        lessonNumber: lessons.indexOf(lesson) + 1,
        moduleNumber: module.lessons.indexOf(lesson) + 1,
        moduleCount: module.lessons.length,
        lessonCount: lessons.length,
        nextLesson: trail.after(lessonId)?.id,
        ongoingPart: checkpoint?.part,
        ongoingStep: checkpoint?.step ?? 0,
      ),
    );
  }

  /// Refazer os exercícios: a nota volta a zero e todos ficam por resolver.
  Future<void> redoExercises() async {
    final lesson = state.lesson;
    if (lesson == null) return;
    final all = await _progress.load();
    final cleared = all
        .of(lesson.id)
        .copyWith(stars: const {}, clearExercise: true);
    await _progress.save(all.withLesson(lesson.id, cleared));
    if (isClosed) return;
    emit(state.copyWith(progress: cleared));
  }
}
