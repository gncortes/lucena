import '../../models/course_grant.dart';
import '../../models/treinador/treinador.dart';
import '../endgame_lesson_rules.dart';

/// As regras do Treinador de partidas (T87) que as telas usam.
abstract final class TreinadorRegras {
  /// Tem o plano de análise agora (o direito `treinador` em `acessos`).
  static bool temAcesso(CourseGrants grants, DateTime agora) =>
      grants.active(treinadorGrantId, agora) != null;

  /// A partida abre sem o plano? As já analisadas continuam abertas depois
  /// que o plano acaba (o aluno não perde o que já fez).
  static bool abre(PartidaTreinador partida, {required bool acesso}) =>
      acesso || partida.pronta;

  /// Os pontos de um exercício: 3 na primeira tentativa, 1 depois de errar,
  /// 0 se viu a solução; cada dica desce um degrau (nunca abaixo de 0).
  static int pontos({
    required int tentativas,
    required bool viuSolucao,
    int dicas = 0,
  }) {
    if (viuSolucao) return 0;
    final base = tentativas <= 1 ? pontosMaximos : 1;
    return base - dicas < 0 ? 0 : base - dicas;
  }

  /// O que vale o exercício de primeira, sem dica.
  static const pontosMaximos = 3;

  /// Quantas dicas um exercício tem: a peça que joga e depois o lance.
  static const maxDicas = 2;

  /// A faixa da nota pelos acertos: todos = perfeito, 75% = bom, metade =
  /// aprovado, menos = abaixo.
  static ExerciseGrade nota(int acertos, int total) {
    if (total <= 0) return ExerciseGrade.below;
    if (acertos >= total) return ExerciseGrade.perfect;
    if (acertos * 4 >= total * 3) return ExerciseGrade.good;
    if (acertos * 2 >= total) return ExerciseGrade.passed;
    return ExerciseGrade.below;
  }

  /// O número do lance (o "8" de "8...f6") do meio-lance [indice] (1 = o
  /// primeiro lance das brancas).
  static int numeroDoLance(int indice) => (indice + 1) ~/ 2;

  /// O meio-lance do lance [numero] de quem jogou com [brancas].
  static int meioLance(int numero, {required bool brancas}) =>
      brancas ? numero * 2 - 1 : numero * 2;
}

/// O filtro da aba Partidas: ritmo e resultado (nulo = todos).
final class FiltroPartidas {
  const FiltroPartidas({this.ritmo, this.resultado});

  static const todos = FiltroPartidas();

  final Ritmo? ritmo;
  final Resultado? resultado;

  bool get vazio => ritmo == null && resultado == null;

  FiltroPartidas comRitmo(Ritmo? valor) =>
      FiltroPartidas(ritmo: valor, resultado: resultado);

  FiltroPartidas comResultado(Resultado? valor) =>
      FiltroPartidas(ritmo: ritmo, resultado: valor);

  List<PartidaTreinador> aplicar(List<PartidaTreinador> partidas) => [
    for (final p in partidas)
      if ((ritmo == null || p.ritmo == ritmo) &&
          (resultado == null || p.resultado == resultado))
        p,
  ];

  Map<String, Object?> toJson() => {
    'ritmo': ritmo?.wire,
    'resultado': resultado?.wire,
  };

  static FiltroPartidas fromJson(Object? json) {
    if (json is! Map) return todos;
    return FiltroPartidas(
      ritmo: Ritmo.parse(json['ritmo']),
      resultado: Resultado.parse(json['resultado']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FiltroPartidas &&
      other.ritmo == ritmo &&
      other.resultado == resultado;

  @override
  int get hashCode => Object.hash(ritmo, resultado);
}
