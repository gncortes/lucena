import 'json.dart';
import 'progresso.dart';

enum Ritmo {
  bullet('bullet'),
  blitz('blitz'),
  rapida('rapida');

  const Ritmo(this.wire);

  final String wire;

  static Ritmo? parse(Object? value) => porWire(values, (r) => r.wire, value);
}

enum Resultado {
  vitoria('vitoria'),
  derrota('derrota'),
  empate('empate');

  const Resultado(this.wire);

  final String wire;

  static Resultado? parse(Object? value) =>
      porWire(values, (r) => r.wire, value);
}

enum CorPartida {
  brancas('brancas'),
  pretas('pretas');

  const CorPartida(this.wire);

  final String wire;

  /// Aceita também `white`/`black` e `w`/`b`.
  static CorPartida parse(Object? value) => switch (value) {
    'pretas' || 'black' || 'b' => pretas,
    _ => brancas,
  };
}

/// Em que pé está a análise da partida no servidor.
enum StatusPartida {
  nova('nova'),
  naFila('na_fila'),
  analisando('analisando'),
  pronta('pronta'),
  erro('erro');

  const StatusPartida(this.wire);

  final String wire;

  static StatusPartida parse(Object? value) =>
      porWire(values, (s) => s.wire, value) ?? nova;

  /// Pedida e ainda sem resultado.
  bool get emAndamento => this == naFila || this == analisando;
}

enum TipoExercicio {
  /// Ver a ideia do adversário.
  adversario('adversario'),

  /// Impedir a ameaça.
  profilaxia('profilaxia'),

  /// O melhor lance dele na partida (também o exercício único de uma
  /// partida sem posição-chave, gap 3).
  seuMelhor('seu_melhor'),

  /// O lance que decidiu a partida (em geral no final).
  decisivo('decisivo');

  const TipoExercicio(this.wire);

  final String wire;

  static TipoExercicio parse(Object? value) =>
      porWire(values, (t) => t.wire, value) ?? decisivo;
}

enum ClasseLance {
  ok('ok'),
  imprecisao('imprecisao'),
  erro('erro'),
  grave('grave');

  const ClasseLance(this.wire);

  final String wire;

  static ClasseLance parse(Object? value) =>
      porWire(values, (c) => c.wire, value) ?? ok;

  bool get ruim => this == erro || this == grave;
}

final class Adversario {
  const Adversario({required this.nome, this.rating});

  final String nome;
  final int? rating;

  static Adversario fromJson(Object? json) {
    final m = mapa(json);
    return Adversario(
      nome: texto(m['nome']) ?? '?',
      rating: inteiroOuNulo(m['rating']),
    );
  }

  Map<String, Object?> toJson() => {'nome': nome, 'rating': rating};
}

final class AberturaPartida {
  const AberturaPartida({required this.eco, required this.nome});

  final String eco;
  final String nome;

  static AberturaPartida? fromJson(Object? json) {
    final m = mapa(json);
    final nome = texto(m['nome']);
    if (nome == null) return null;
    return AberturaPartida(eco: texto(m['eco']) ?? '', nome: nome);
  }

  Map<String, Object?> toJson() => {'eco': eco, 'nome': nome};
}

/// O que o Viktor diz no exercício.
final class FalasExercicio {
  const FalasExercicio({
    required this.enunciado,
    required this.acerto,
    required this.erro,
    required this.solucao,
  });

  final String enunciado;
  final String acerto;
  final String erro;
  final String solucao;

  static FalasExercicio fromJson(Object? json) {
    final m = mapa(json);
    return FalasExercicio(
      enunciado: texto(m['enunciado']) ?? '',
      acerto: texto(m['acerto']) ?? '',
      erro: texto(m['erro']) ?? '',
      solucao: texto(m['solucao']) ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'enunciado': enunciado,
    'acerto': acerto,
    'erro': erro,
    'solucao': solucao,
  };
}

/// Uma posição-chave da partida virada exercício.
final class ExercicioTreinador {
  const ExercicioTreinador({
    required this.n,
    required this.tipo,
    required this.fen,
    required this.lance,
    required this.solucao,
    this.aceitos = const [],
    this.jogado,
    this.tema,
    this.estrelas = 1,
    this.falas = const FalasExercicio(
      enunciado: '',
      acerto: '',
      erro: '',
      solucao: '',
    ),
  });

  /// 1 a N, na ordem da partida.
  final int n;
  final TipoExercicio tipo;

  /// A posição antes do lance a achar.
  final String fen;

  /// O número do lance na partida (para "Lance 8").
  final int lance;

  /// O lance certo, em UCI.
  final String solucao;

  /// Outros lances certos, em UCI.
  final List<String> aceitos;

  /// O que ele jogou na partida, em SAN.
  final String? jogado;

  /// O tema (só no histórico: o exercício não diz o tema).
  final String? tema;

  /// 1 a 3.
  final int estrelas;
  final FalasExercicio falas;

  /// [uci] resolve o exercício.
  bool aceita(String uci) => uci == solucao || aceitos.contains(uci);

  static ExercicioTreinador? fromJson(Object? json, int index) {
    final m = mapa(json);
    final fen = texto(m['fen']);
    final solucao = texto(m['solucao']);
    if (fen == null || solucao == null) return null;
    return ExercicioTreinador(
      n: inteiro(m['n'], index + 1),
      tipo: TipoExercicio.parse(m['tipo']),
      fen: fen,
      lance: inteiro(m['lance']),
      solucao: solucao,
      aceitos: textos(m['aceitos']),
      jogado: texto(m['jogado']),
      tema: texto(m['tema']),
      estrelas: inteiro(m['estrelas'], 1).clamp(1, 3),
      falas: FalasExercicio.fromJson(m['falas']),
    );
  }

  Map<String, Object?> toJson() => {
    'n': n,
    'tipo': tipo.wire,
    'fen': fen,
    'lance': lance,
    'solucao': solucao,
    'aceitos': aceitos,
    'jogado': jogado,
    'tema': tema,
    'estrelas': estrelas,
    'falas': falas.toJson(),
  };
}

/// Um meio-lance da partida com a avaliação do servidor.
final class LanceAnalisado {
  const LanceAnalisado({
    required this.san,
    required this.fen,
    this.cp,
    this.mate,
    this.melhor,
    this.classe = ClasseLance.ok,
    this.comentario,
  });

  final String san;

  /// A posição depois do lance.
  final String fen;

  /// Centipeões do ponto de vista das brancas (nulo com [mate]).
  final int? cp;

  /// Mate em N (positivo: brancas dão).
  final int? mate;

  /// O melhor lance na posição anterior, em SAN.
  final String? melhor;
  final ClasseLance classe;

  /// A frase do treinador sobre o lance.
  final String? comentario;

  static LanceAnalisado? fromJson(Object? json) {
    final m = mapa(json);
    final san = texto(m['san']);
    final fen = texto(m['fen']);
    if (san == null || fen == null) return null;
    return LanceAnalisado(
      san: san,
      fen: fen,
      cp: inteiroOuNulo(m['cp']),
      mate: inteiroOuNulo(m['mate']),
      melhor: texto(m['melhor']),
      classe: ClasseLance.parse(m['classe']),
      comentario: texto(m['comentario']),
    );
  }

  Map<String, Object?> toJson() => {
    'san': san,
    'fen': fen,
    'cp': cp,
    'mate': mate,
    'melhor': melhor,
    'classe': classe.wire,
    'comentario': comentario,
  };
}

final class CandidatoTeoria {
  const CandidatoTeoria({
    required this.san,
    required this.partidas,
    required this.brancas,
    required this.empates,
    required this.pretas,
    this.linha = const [],
  });

  final String san;
  final int partidas;

  /// Vitórias das brancas, empates e vitórias das pretas, em partidas.
  final int brancas;
  final int empates;
  final int pretas;

  /// A linha a que o lance chega, em SAN.
  final List<String> linha;

  static CandidatoTeoria? fromJson(Object? json) {
    final m = mapa(json);
    final san = texto(m['san']);
    if (san == null) return null;
    return CandidatoTeoria(
      san: san,
      partidas: inteiro(m['partidas']),
      brancas: inteiro(m['brancas']),
      empates: inteiro(m['empates']),
      pretas: inteiro(m['pretas']),
      linha: textos(m['linha']),
    );
  }

  Map<String, Object?> toJson() => {
    'san': san,
    'partidas': partidas,
    'brancas': brancas,
    'empates': empates,
    'pretas': pretas,
    'linha': linha,
  };
}

/// O lance em que ele saiu da teoria e o que a teoria joga ali.
final class TeoriaPartida {
  const TeoriaPartida({
    required this.lance,
    required this.fen,
    required this.candidatos,
  });

  /// O índice do meio-lance (0 = 1º lance das brancas) em que saiu.
  final int lance;
  final String fen;
  final List<CandidatoTeoria> candidatos;

  static TeoriaPartida? fromJson(Object? json) {
    final m = mapa(json);
    final fen = texto(m['fen']);
    if (fen == null) return null;
    final candidatos = [
      for (final c in lista(m['candidatos'])) ?CandidatoTeoria.fromJson(c),
    ];
    if (candidatos.isEmpty) return null;
    return TeoriaPartida(
      lance: inteiro(m['lance']),
      fen: fen,
      candidatos: candidatos,
    );
  }

  Map<String, Object?> toJson() => {
    'lance': lance,
    'fen': fen,
    'candidatos': [for (final c in candidatos) c.toJson()],
  };
}

/// A precisão (0 a 100) em cada fase. Nulo: a partida não chegou à fase.
final class FasesPartida {
  const FasesPartida({this.abertura, this.meio, this.finalDaPartida});

  final double? abertura;
  final double? meio;
  final double? finalDaPartida;

  static FasesPartida fromJson(Object? json) {
    final m = mapa(json);
    return FasesPartida(
      abertura: numero(m['abertura']),
      meio: numero(m['meio']),
      finalDaPartida: numero(m['final']),
    );
  }

  Map<String, Object?> toJson() => {
    'abertura': abertura,
    'meio': meio,
    'final': finalDaPartida,
  };
}

/// `users/{uid}/partidas/{id}` (id = `plataforma_idExterno`).
final class PartidaTreinador {
  const PartidaTreinador({
    required this.id,
    required this.jogadaEm,
    required this.cor,
    required this.adversario,
    required this.resultado,
    this.url,
    this.ritmo,
    this.cadencia,
    this.rating,
    this.abertura,
    this.pgn,
    this.status = StatusPartida.nova,
    this.resumo,
    this.precisao,
    this.exercicios = const [],
    this.lances = const [],
    this.teoria,
    this.fases = const FasesPartida(),
    this.temas = const [],
    this.analisadaEm,
    this.erroMotivo,
    this.progresso,
  });

  final String id;
  final String? url;
  final DateTime jogadaEm;
  final Ritmo? ritmo;

  /// "5+0".
  final String? cadencia;
  final CorPartida cor;
  final Adversario adversario;

  /// O rating dele na partida.
  final int? rating;
  final Resultado resultado;
  final AberturaPartida? abertura;
  final String? pgn;
  final StatusPartida status;

  /// A frase do resumo da partida.
  final String? resumo;

  /// 0 a 100.
  final double? precisao;
  final List<ExercicioTreinador> exercicios;
  final List<LanceAnalisado> lances;
  final TeoriaPartida? teoria;
  final FasesPartida fases;
  final List<String> temas;
  final DateTime? analisadaEm;

  /// Por que a análise falhou (só com [StatusPartida.erro]): `variante`
  /// (não dá para refazer), `tempo`, `pgn` ou `outro`.
  final String? erroMotivo;

  /// A análise falhou de um jeito que tentar de novo resolve.
  bool get podeRefazer => erroMotivo != 'variante';

  /// O espelho do progresso gravado pelo app.
  final ProgressoPartida? progresso;

  bool get pronta => status == StatusPartida.pronta;

  /// Só a parte de antes do `_`.
  String get plataforma => id.split('_').first;

  static PartidaTreinador? fromJson(String id, Object? json) {
    final m = mapa(json);
    final jogadaEm = data(m['jogadaEm']);
    final resultado = Resultado.parse(m['resultado']);
    if (jogadaEm == null || resultado == null) return null;
    final exercicios = <ExercicioTreinador>[];
    for (final (i, e) in lista(m['exercicios']).indexed) {
      if (ExercicioTreinador.fromJson(e, i) case final ex?) exercicios.add(ex);
    }
    exercicios.sort((a, b) => a.n.compareTo(b.n));
    return PartidaTreinador(
      id: id,
      url: texto(m['url']),
      jogadaEm: jogadaEm,
      ritmo: Ritmo.parse(m['ritmo']),
      cadencia: texto(m['cadencia']),
      cor: CorPartida.parse(m['cor']),
      adversario: Adversario.fromJson(m['adversario']),
      rating: inteiroOuNulo(m['rating']),
      resultado: resultado,
      abertura: AberturaPartida.fromJson(m['abertura']),
      pgn: texto(m['pgn']),
      status: StatusPartida.parse(m['status']),
      resumo: texto(m['resumo']),
      precisao: numero(m['precisao']),
      exercicios: exercicios,
      lances: [for (final l in lista(m['lances'])) ?LanceAnalisado.fromJson(l)],
      teoria: TeoriaPartida.fromJson(m['teoria']),
      fases: FasesPartida.fromJson(m['fases']),
      temas: textos(m['temas']),
      analisadaEm: data(m['analisadaEm']),
      erroMotivo: texto(m['erroMotivo']),
      progresso: m['progresso'] == null
          ? null
          : ProgressoPartida.fromJson(m['progresso']),
    );
  }

  Map<String, Object?> toJson() => {
    'url': url,
    'jogadaEm': jogadaEm.toIso8601String(),
    'ritmo': ritmo?.wire,
    'cadencia': cadencia,
    'cor': cor.wire,
    'adversario': adversario.toJson(),
    'rating': rating,
    'resultado': resultado.wire,
    'abertura': abertura?.toJson(),
    'pgn': pgn,
    'status': status.wire,
    'resumo': resumo,
    'precisao': precisao,
    'exercicios': [for (final e in exercicios) e.toJson()],
    'lances': [for (final l in lances) l.toJson()],
    'teoria': teoria?.toJson(),
    'fases': fases.toJson(),
    'temas': temas,
    'analisadaEm': analisadaEm?.toIso8601String(),
    if (erroMotivo != null) 'erroMotivo': erroMotivo,
    if (progresso != null) 'progresso': progresso!.toJson(),
  };

  PartidaTreinador copyWith({
    StatusPartida? status,
    ProgressoPartida? progresso,
  }) => PartidaTreinador(
    id: id,
    url: url,
    jogadaEm: jogadaEm,
    ritmo: ritmo,
    cadencia: cadencia,
    cor: cor,
    adversario: adversario,
    rating: rating,
    resultado: resultado,
    abertura: abertura,
    pgn: pgn,
    status: status ?? this.status,
    resumo: resumo,
    precisao: precisao,
    exercicios: exercicios,
    lances: lances,
    teoria: teoria,
    fases: fases,
    temas: temas,
    analisadaEm: analisadaEm,
    erroMotivo: erroMotivo,
    progresso: progresso ?? this.progresso,
  );
}
