import '../models/placement.dart';
import '../models/rating_level.dart';

/// Por que uma aula da escola foi dispensada pelo teste.
enum SkipReason {
  /// "Você já domina": o jogador acertou o nó no teste.
  confirmed,

  /// "Pelo teste, você já deve saber": inferido pela faixa ou pelos
  /// pré-requisitos.
  likely,
}

/// O selo de uma aula na trilha de finais. Sem selo: a aula fica fora do mapa.
enum EndgameBadge {
  /// Já domina (com "rever").
  mastered,

  /// O próximo passo do roteiro.
  recommended,
}

/// Um passo do roteiro: uma aula de um nó.
class RoadmapStep {
  const RoadmapStep({
    required this.node,
    required this.lessonId,
    required this.school,
    this.soon = false,
  });

  final String node;
  final String lessonId;

  /// Aula da Escola do Viktor (senão, da trilha de finais).
  final bool school;

  /// A aula ainda não existe (catálogo ou nova): a tela mostra "em breve".
  final bool soon;

  @override
  bool operator ==(Object other) =>
      other is RoadmapStep &&
      other.node == node &&
      other.lessonId == lessonId &&
      other.school == school &&
      other.soon == soon;

  @override
  int get hashCode => Object.hash(node, lessonId, school, soon);

  @override
  String toString() => '$node→$lessonId${soon ? ' (em breve)' : ''}';
}

/// O roteiro do jogador (T52, Parte 5): do resultado do teste e do progresso
/// real para o que cada tela mostra. Recalculado sempre que a tela abre; uma
/// aula feita depois do teste conta como feita, não importa o teste. Nós de
/// tática de meio-jogo ficam no resultado, mas nunca no roteiro.
class PlacementRoadmap {
  const PlacementRoadmap({
    required this.nodes,
    required this.steps,
    required this.skippedSchool,
    required this.nextSchool,
    required this.endgameBadges,
  });

  /// Monta o roteiro.
  ///
  /// [schoolLessons] e [endgameLessons] são as aulas que existem no app, na
  /// ordem do curso e da trilha; [completedSchool] e [completedEndgames], as
  /// já concluídas.
  factory PlacementRoadmap.build({
    required PlacementResult result,
    required SkillMap skills,
    required List<String> schoolLessons,
    required List<String> endgameLessons,
    Set<String> completedSchool = const {},
    Set<String> completedEndgames = const {},
  }) {
    final band = RatingLevel.of(result.theta).index;
    final routed = [
      for (final node in skills.nodes)
        if (!node.midgameTactic) node,
    ];

    // As aulas de cada nó, já resolvidas contra o que existe.
    final lessons = {
      for (final node in routed)
        node.id: _resolve(node, schoolLessons, endgameLessons),
    };
    bool done(_Lesson lesson) => lesson.school
        ? completedSchool.contains(lesson.id)
        : completedEndgames.contains(lesson.id);

    // Ordem: lacunas, depois os desconhecidos até a faixa seguinte à de θ,
    // depois o resto; dentro de cada grupo, a ordem topológica.
    int tier(SkillNode node) {
      final status = result.status(node.id);
      if (status.isGap) return 0;
      return node.band.index <= band + 1 ? 1 : 2;
    }

    final pending =
        [
          for (final node in routed)
            if (!result.status(node.id).skippable) node,
        ]..sort((x, y) {
          final byTier = tier(x).compareTo(tier(y));
          return byTier != 0
              ? byTier
              : skills.indexOf(x.id).compareTo(skills.indexOf(y.id));
        });

    final steps = <RoadmapStep>[];
    final nodes = <String>[];
    for (final node in pending) {
      final all = lessons[node.id]!;
      final existing = all.where((lesson) => !lesson.soon);
      final open = existing.where((lesson) => !done(lesson)).toList();
      final nodeSteps = <RoadmapStep>[
        for (final lesson in open)
          RoadmapStep(
            node: node.id,
            lessonId: lesson.id,
            school: lesson.school,
          ),
      ];
      if (existing.isEmpty) {
        final soon = all.where((lesson) => lesson.soon).firstOrNull;
        if (soon != null) {
          nodeSteps.add(
            RoadmapStep(
              node: node.id,
              lessonId: soon.id,
              school: soon.school,
              soon: true,
            ),
          );
        }
      }
      if (nodeSteps.isEmpty) continue;
      nodes.add(node.id);
      steps.addAll(nodeSteps);
    }

    // Escola: dispensada se todos os nós (fora a tática de meio-jogo) que a
    // ensinam forem dispensados pelo teste.
    final skipped = <String, SkipReason>{};
    for (final id in schoolLessons) {
      if (completedSchool.contains(id)) continue;
      final owners = [
        for (final node in routed)
          if (lessons[node.id]!.any((l) => l.school && l.id == id)) node,
      ];
      if (owners.isEmpty) continue;
      final statuses = [for (final node in owners) result.status(node.id)];
      if (!statuses.every((status) => status.skippable)) continue;
      skipped[id] =
          statuses.every(
            (status) => status.state == NodeState.mastered && status.confirmed,
          )
          ? SkipReason.confirmed
          : SkipReason.likely;
    }

    final nextSchool =
        steps
            .where((step) => step.school && !step.soon)
            .map((step) => step.lessonId)
            .firstOrNull ??
        schoolLessons
            .where(
              (id) => !completedSchool.contains(id) && !skipped.containsKey(id),
            )
            .firstOrNull;

    // Trilha de finais: "já domina" se todos os nós que a ensinam forem
    // dispensados; "recomendada" no primeiro passo de finais do roteiro.
    final badges = <String, EndgameBadge>{};
    for (final id in endgameLessons) {
      final owners = [
        for (final node in routed)
          if (lessons[node.id]!.any((l) => !l.school && l.id == id)) node,
      ];
      if (owners.isNotEmpty &&
          owners.every((node) => result.status(node.id).skippable)) {
        badges[id] = EndgameBadge.mastered;
      }
    }
    final recommended = steps
        .where((step) => !step.school && !step.soon)
        .firstOrNull;
    if (recommended != null) {
      badges[recommended.lessonId] = EndgameBadge.recommended;
    }

    return PlacementRoadmap(
      nodes: nodes,
      steps: steps,
      skippedSchool: skipped,
      nextSchool: nextSchool,
      endgameBadges: badges,
    );
  }

  /// Os nós do roteiro, na ordem (só os que têm um passo).
  final List<String> nodes;

  /// Todos os passos, na ordem: o primeiro é o "Continuar" da tela inicial.
  final List<RoadmapStep> steps;

  /// Aulas da escola dispensadas pelo teste (`LessonStatus.skippedByTest`),
  /// com o selo. Aula já concluída nunca aparece aqui.
  final Map<String, SkipReason> skippedSchool;

  /// A aula da escola em que o jogador começa. Nula se não sobrou nenhuma.
  final String? nextSchool;

  /// Os selos da trilha de finais (aula sem selo fica fora do mapa).
  final Map<String, EndgameBadge> endgameBadges;

  /// O próximo passo de qualquer lado.
  RoadmapStep? get next => steps.firstOrNull;

  /// Os passos da trilha de finais, com os "em breve".
  /// Uma aula ensinada por dois nós aparece uma vez só, na primeira vez.
  List<RoadmapStep> get endgameSteps {
    final seen = <String>{};
    return [
      for (final step in steps)
        if (!step.school && seen.add(step.lessonId)) step,
    ];
  }

  /// "Seu próximo final".
  RoadmapStep? get nextEndgame => endgameSteps.firstOrNull;

  /// Os passos de finais depois do próximo (até [count]).
  List<RoadmapStep> followingEndgames([int count = 3]) =>
      endgameSteps.skip(1).take(count).toList();

  /// Aulas da escola que existem e que o roteiro ainda pede.
  List<RoadmapStep> get schoolSteps => [
    for (final step in steps)
      if (step.school) step,
  ];

  /// Liga as aulas de [node] ao que existe no app. A aula de tipo `school`
  /// procura na escola; `endgame` e `catalog`, na trilha; `new` (proposta),
  /// nos dois. Aula que ainda não existe vira "em breve": `new` fica na
  /// escola se o nó for de faixa até `casual` (as aulas novas da Parte 6.1),
  /// senão na trilha de finais (6.2).
  static List<_Lesson> _resolve(
    SkillNode node,
    List<String> schoolLessons,
    List<String> endgameLessons,
  ) {
    final result = <_Lesson>[];
    void add(_Lesson lesson) {
      if (!result.any((l) => l.id == lesson.id && l.school == lesson.school)) {
        result.add(lesson);
      }
    }

    for (final lesson in node.lessons) {
      final inSchool =
          lesson.kind != SkillLessonKind.endgame &&
              lesson.kind != SkillLessonKind.catalog
          ? schoolLessons.where(lesson.matches).toList()
          : const <String>[];
      final inTrail = lesson.kind != SkillLessonKind.school
          ? endgameLessons.where(lesson.matches).toList()
          : const <String>[];
      for (final id in inSchool) {
        add(_Lesson(id, school: true));
      }
      for (final id in inTrail) {
        add(_Lesson(id, school: false));
      }
      if (inSchool.isEmpty && inTrail.isEmpty) {
        final school = switch (lesson.kind) {
          SkillLessonKind.school => true,
          SkillLessonKind.endgame || SkillLessonKind.catalog => false,
          SkillLessonKind.proposed =>
            node.band.index <= RatingLevel.casual.index,
        };
        // Prefixo sem nenhuma aula feita: o "em breve" leva o prefixo.
        final id = lesson.id.endsWith('.*')
            ? lesson.id.substring(0, lesson.id.length - 2)
            : lesson.id;
        add(_Lesson(id, school: school, soon: true));
      }
    }
    // Aulas que existem primeiro, na ordem do curso e da trilha.
    int order(_Lesson lesson) => lesson.soon
        ? 1 << 20
        : lesson.school
        ? schoolLessons.indexOf(lesson.id)
        : (1 << 10) + endgameLessons.indexOf(lesson.id);
    return result..sort((x, y) => order(x).compareTo(order(y)));
  }
}

class _Lesson {
  const _Lesson(this.id, {required this.school, this.soon = false});

  final String id;
  final bool school;
  final bool soon;
}
