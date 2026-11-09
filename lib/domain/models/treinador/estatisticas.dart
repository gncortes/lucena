import 'json.dart';
import 'json.dart' as j;
import 'partida.dart';

/// Uma posição do histórico de um tema (Seu jogo › Erros por tema).
final class PosicaoTema {
  const PosicaoTema({
    required this.partida,
    required this.lance,
    required this.fen,
  });

  /// O id da partida.
  final String partida;
  final int lance;
  final String fen;

  static PosicaoTema? fromJson(Object? json) {
    final m = mapa(json);
    final partida = texto(m['partida']);
    final fen = texto(m['fen']);
    if (partida == null || fen == null) return null;
    return PosicaoTema(partida: partida, lance: inteiro(m['lance']), fen: fen);
  }

  Map<String, Object?> toJson() => {
    'partida': partida,
    'lance': lance,
    'fen': fen,
  };
}

/// Onde a abertura sai da teoria com mais frequência.
final class SaidaTeoria {
  const SaidaTeoria({required this.lance, required this.vezes});

  final int lance;
  final int vezes;

  static SaidaTeoria? fromJson(Object? json) {
    if (json is! Map) return null;
    final m = mapa(json);
    return SaidaTeoria(lance: inteiro(m['lance']), vezes: inteiro(m['vezes']));
  }

  Map<String, Object?> toJson() => {'lance': lance, 'vezes': vezes};
}

/// O lugar da abertura num curso do Lucena (ligação com Pilares/Metas).
final class CursoLigado {
  const CursoLigado({required this.id, required this.parte});

  final String id;
  final int parte;

  static CursoLigado? fromJson(Object? json) {
    final m = mapa(json);
    final id = texto(m['id']);
    if (id == null) return null;
    return CursoLigado(id: id, parte: inteiro(m['parte']));
  }

  Map<String, Object?> toJson() => {'id': id, 'parte': parte};
}

final class AberturaJogada {
  const AberturaJogada({
    required this.nome,
    required this.eco,
    required this.cor,
    required this.partidas,
    required this.vitorias,
    this.saidaTeoria,
    this.curso,
  });

  final String nome;
  final String eco;
  final CorPartida cor;
  final int partidas;
  final int vitorias;
  final SaidaTeoria? saidaTeoria;
  final CursoLigado? curso;

  static AberturaJogada? fromJson(Object? json) {
    final m = mapa(json);
    final nome = texto(m['nome']);
    if (nome == null) return null;
    return AberturaJogada(
      nome: nome,
      eco: texto(m['eco']) ?? '',
      cor: CorPartida.parse(m['cor']),
      partidas: inteiro(m['partidas']),
      vitorias: inteiro(m['vitorias']),
      saidaTeoria: SaidaTeoria.fromJson(m['saidaTeoria']),
      curso: m['curso'] == null ? null : CursoLigado.fromJson(m['curso']),
    );
  }

  Map<String, Object?> toJson() => {
    'nome': nome,
    'eco': eco,
    'cor': cor.wire,
    'partidas': partidas,
    'vitorias': vitorias,
    'saidaTeoria': saidaTeoria?.toJson(),
    'curso': curso?.toJson(),
  };
}

/// Até 19 partidas = primeira leitura; 20 a 49 = em formação; 50+ = firme.
enum NivelEstilo {
  primeira('primeira'),
  formacao('formacao'),
  firme('firme');

  const NivelEstilo(this.wire);

  final String wire;

  static NivelEstilo parse(Object? value) =>
      porWire(values, (n) => n.wire, value) ?? primeira;
}

/// Um ponto do estilo: o texto, em quantas partidas apareceu e a ação.
/// O servidor pode mandar só o texto.
final class PontoEstilo {
  const PontoEstilo({required this.texto, this.partidas, this.tema});

  final String texto;
  final int? partidas;

  /// O tema ligado (leva à aula ou ao exercício).
  final String? tema;

  static PontoEstilo? fromJson(Object? json) {
    if (json is String) return PontoEstilo(texto: json);
    final m = mapa(json);
    final t = j.texto(m['texto']);
    if (t == null) return null;
    return PontoEstilo(
      texto: t,
      partidas: inteiroOuNulo(m['partidas']),
      tema: j.texto(m['tema']),
    );
  }

  Map<String, Object?> toJson() => {
    'texto': texto,
    'partidas': partidas,
    'tema': tema,
  };
}

final class EstiloJogador {
  const EstiloJogador({
    this.nivel = NivelEstilo.primeira,
    this.fortes = const [],
    this.acertar = const [],
  });

  final NivelEstilo nivel;
  final List<PontoEstilo> fortes;
  final List<PontoEstilo> acertar;

  static EstiloJogador fromJson(Object? json) {
    final m = mapa(json);
    return EstiloJogador(
      nivel: NivelEstilo.parse(m['nivel']),
      fortes: [for (final p in lista(m['fortes'])) ?PontoEstilo.fromJson(p)],
      acertar: [for (final p in lista(m['acertar'])) ?PontoEstilo.fromJson(p)],
    );
  }

  Map<String, Object?> toJson() => {
    'nivel': nivel.wire,
    'fortes': [for (final p in fortes) p.toJson()],
    'acertar': [for (final p in acertar) p.toJson()],
  };
}

/// A precisão média de uma semana.
final class PrecisaoSemana {
  const PrecisaoSemana({required this.precisao, this.semana});

  /// O início da semana (nulo se o servidor mandou só o número).
  final DateTime? semana;
  final double precisao;

  static PrecisaoSemana? fromJson(Object? json) {
    if (json is num) return PrecisaoSemana(precisao: json.toDouble());
    final m = mapa(json);
    final p = numero(m['precisao']);
    if (p == null) return null;
    return PrecisaoSemana(precisao: p, semana: data(m['semana']));
  }

  Map<String, Object?> toJson() => {
    'semana': semana?.toIso8601String(),
    'precisao': precisao,
  };
}

/// Quantos erros em cada fase.
final class ErrosPorFase {
  const ErrosPorFase({
    this.abertura = 0,
    this.meio = 0,
    this.finalDaPartida = 0,
  });

  final int abertura;
  final int meio;
  final int finalDaPartida;

  int get total => abertura + meio + finalDaPartida;

  static ErrosPorFase fromJson(Object? json) {
    final m = mapa(json);
    return ErrosPorFase(
      abertura: inteiro(m['abertura']),
      meio: inteiro(m['meio']),
      finalDaPartida: inteiro(m['final']),
    );
  }

  Map<String, Object?> toJson() => {
    'abertura': abertura,
    'meio': meio,
    'final': finalDaPartida,
  };
}

/// `users/{uid}/treinador/estatisticas`.
final class EstatisticasTreinador {
  const EstatisticasTreinador({
    this.partidasAnalisadas = 0,
    this.precisaoSemanas = const [],
    this.errosPorFase = const ErrosPorFase(),
    this.errosPorTema = const {},
    this.aberturas = const [],
    this.estilo = const EstiloJogador(),
  });

  static const vazia = EstatisticasTreinador();

  final int partidasAnalisadas;
  final List<PrecisaoSemana> precisaoSemanas;
  final ErrosPorFase errosPorFase;

  /// Tema → posições, da mais recente.
  final Map<String, List<PosicaoTema>> errosPorTema;
  final List<AberturaJogada> aberturas;
  final EstiloJogador estilo;

  static EstatisticasTreinador fromJson(Object? json) {
    final m = mapa(json);
    return EstatisticasTreinador(
      partidasAnalisadas: inteiro(m['partidasAnalisadas']),
      precisaoSemanas: [
        for (final p in lista(m['precisaoSemanas']))
          ?PrecisaoSemana.fromJson(p),
      ],
      errosPorFase: ErrosPorFase.fromJson(m['errosPorFase']),
      errosPorTema: {
        for (final e in mapa(m['errosPorTema']).entries)
          e.key: [for (final p in lista(e.value)) ?PosicaoTema.fromJson(p)],
      },
      aberturas: [
        for (final a in lista(m['aberturas'])) ?AberturaJogada.fromJson(a),
      ],
      estilo: EstiloJogador.fromJson(m['estilo']),
    );
  }

  Map<String, Object?> toJson() => {
    'partidasAnalisadas': partidasAnalisadas,
    'precisaoSemanas': [for (final p in precisaoSemanas) p.toJson()],
    'errosPorFase': errosPorFase.toJson(),
    'errosPorTema': {
      for (final e in errosPorTema.entries)
        e.key: [for (final p in e.value) p.toJson()],
    },
    'aberturas': [for (final a in aberturas) a.toJson()],
    'estilo': estilo.toJson(),
  };
}
