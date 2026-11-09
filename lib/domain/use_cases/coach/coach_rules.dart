import '../../models/course_grant.dart';
import '../../models/coach/coach.dart';
import '../endgame_lesson_rules.dart';

/// As regras do Treinador de partidas (T87) que as telas usam.
abstract final class CoachRules {
  /// Tem o plano de análise agora (o direito `treinador` em `acessos`).
  static bool hasAccess(CourseGrants grants, DateTime currentTime) =>
      grants.active(coachGrantId, currentTime) != null;

  /// A partida abre sem o plano? As já analisadas continuam abertas depois
  /// que o plano acaba (o aluno não perde o que já fez).
  static bool opens(CoachGame game, {required bool grant}) =>
      grant || game.ready;

  /// Os pontos de um exercício: 3 na primeira tentativa, 1 depois de errar,
  /// 0 se viu a solução; cada dica desce um degrau (nunca abaixo de 0).
  static int points({
    required int attempts,
    required bool sawSolution,
    int hints = 0,
  }) {
    if (sawSolution) return 0;
    final base = attempts <= 1 ? maxPoints : 1;
    return base - hints < 0 ? 0 : base - hints;
  }

  /// O que vale o exercício de primeira, sem dica.
  static const maxPoints = 3;

  /// Quantas dicas um exercício tem: a peça que joga e depois o lance.
  static const maxHints = 2;

  /// A faixa da nota pelos acertos: todos = perfeito, 75% = bom, metade =
  /// aprovado, menos = abaixo.
  static ExerciseGrade note(int corrects, int total) {
    if (total <= 0) return ExerciseGrade.below;
    if (corrects >= total) return ExerciseGrade.perfect;
    if (corrects * 4 >= total * 3) return ExerciseGrade.good;
    if (corrects * 2 >= total) return ExerciseGrade.passed;
    return ExerciseGrade.below;
  }

  /// O número do lance (o "8" de "8...f6") do meio-lance [index] (1 = o
  /// primeiro lance das brancas).
  static int moveNumber(int index) => (index + 1) ~/ 2;

  /// O meio-lance do lance [number] de quem jogou com [white].
  static int halfMove(int number, {required bool white}) =>
      white ? number * 2 - 1 : number * 2;
}

/// O filtro da aba Partidas: ritmo e resultado (nulo = todos).
final class GameFilter {
  const GameFilter({this.timeControl, this.result});

  static const everyone = GameFilter();

  final TimeControl? timeControl;
  final GameResult? result;

  bool get empty => timeControl == null && result == null;

  GameFilter withTimeControl(TimeControl? value) =>
      GameFilter(timeControl: value, result: result);

  GameFilter withResult(GameResult? value) =>
      GameFilter(timeControl: timeControl, result: value);

  List<CoachGame> apply(List<CoachGame> games) => [
    for (final p in games)
      if ((timeControl == null || p.timeControl == timeControl) &&
          (result == null || p.result == result))
        p,
  ];

  Map<String, Object?> toJson() => {
    'ritmo': timeControl?.wire,
    'resultado': result?.wire,
  };

  static GameFilter fromJson(Object? json) {
    if (json is! Map) return everyone;
    return GameFilter(
      timeControl: TimeControl.parse(json['ritmo']),
      result: GameResult.parse(json['resultado']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GameFilter &&
      other.timeControl == timeControl &&
      other.result == result;

  @override
  int get hashCode => Object.hash(timeControl, result);
}
