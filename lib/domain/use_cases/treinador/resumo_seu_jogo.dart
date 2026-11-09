import '../../models/treinador/treinador.dart';

/// Abaixo disto a aba mostra só o estilo e a precisão média ("poucas
/// partidas", `SeuJogoPoucas` do canvas).
const minimoPartidasSeuJogo = 10;

/// Lances completos (do branco e do preto) que contam como abertura quando a
/// posição ainda não é de final.
const lancesDaAbertura = 12;

enum FaseDoJogo { abertura, meio, finalDaPartida }

/// Aproveitamento de um grupo de partidas (ritmo, cor ou abertura).
final class Aproveitamento {
  const Aproveitamento({
    this.vitorias = 0,
    this.empates = 0,
    this.derrotas = 0,
  });

  final int vitorias, empates, derrotas;

  int get partidas => vitorias + empates + derrotas;

  /// Pontos feitos a cada 100 possíveis (empate vale meio).
  int get porcento =>
      partidas == 0 ? 0 : ((vitorias + empates / 2) * 100 / partidas).round();

  Aproveitamento mais(Resultado r) => Aproveitamento(
    vitorias: vitorias + (r == Resultado.vitoria ? 1 : 0),
    empates: empates + (r == Resultado.empate ? 1 : 0),
    derrotas: derrotas + (r == Resultado.derrota ? 1 : 0),
  );
}

/// Onde ele sai da teoria numa abertura: o lance mais repetido.
final class SaidaDaTeoria {
  const SaidaDaTeoria({
    required this.lance,
    required this.san,
    required this.pretas,
    required this.vezes,
    required this.partidaRecente,
  });

  /// Número do lance (o 8 de "8...Bg4").
  final int lance;

  /// O lance dele, em SAN inglesa (sem número).
  final String san;

  /// Lance das pretas (escreve "8...").
  final bool pretas;
  final int vezes;

  /// A partida mais nova com essa saída: abre a teoria.
  final String partidaRecente;
}

final class ResumoAbertura {
  const ResumoAbertura({
    required this.nome,
    required this.eco,
    required this.cor,
    required this.aproveitamento,
    this.saida,
    this.curso,
  });

  final String nome, eco;
  final CorPartida cor;
  final Aproveitamento aproveitamento;
  final SaidaDaTeoria? saida;

  /// O lugar no curso que o servidor ligou (se veio).
  final CursoLigado? curso;
}

/// Uma posição de um tema, já com a partida para a linha da lista.
final class PosicaoDoTema {
  const PosicaoDoTema({required this.posicao, required this.partida});

  final PosicaoTema posicao;
  final PartidaTreinador partida;
}

final class ResumoTema {
  const ResumoTema({required this.tema, required this.posicoes});

  final String tema;

  /// Da mais recente.
  final List<PosicaoDoTema> posicoes;
}

sealed class FocoSeuJogo {
  const FocoSeuJogo();
}

/// Onde focar: a abertura em que ele sai da teoria sempre no mesmo lance.
final class FocoAbertura extends FocoSeuJogo {
  const FocoAbertura(this.abertura);

  final ResumoAbertura abertura;
  SaidaDaTeoria get saida => abertura.saida!;
}

/// Onde focar: o tema com mais posições.
final class FocoTema extends FocoSeuJogo {
  const FocoTema(this.tema);

  final ResumoTema tema;
}

final class ResumoSeuJogo {
  const ResumoSeuJogo({
    required this.partidas,
    required this.precisao,
    required this.variacaoPrecisao,
    required this.aproveitamento,
    required this.errosPorFase,
    required this.precisaoSemanas,
    required this.temas,
    required this.ritmos,
    required this.brancas,
    required this.pretas,
    required this.aberturas,
    required this.foco,
  });

  /// Partidas prontas no filtro.
  final int partidas;

  /// Precisão média (0 a 100), arredondada.
  final int? precisao;

  /// Últimos 30 dias contra os 30 de antes, em pontos.
  final int? variacaoPrecisao;
  final Aproveitamento aproveitamento;
  final Map<FaseDoJogo, int> errosPorFase;

  /// As 8 últimas semanas (a mais antiga primeiro); `null` = sem partida.
  final List<int?> precisaoSemanas;
  final List<ResumoTema> temas;
  final Map<Ritmo, Aproveitamento> ritmos;
  final Aproveitamento brancas, pretas;
  final List<ResumoAbertura> aberturas;
  final FocoSeuJogo? foco;

  bool get poucas => partidas < minimoPartidasSeuJogo;

  int get totalErros => errosPorFase.values.fold(0, (a, b) => a + b);

  FaseDoJogo? get faseMaisErros {
    if (totalErros == 0) return null;
    return FaseDoJogo.values.reduce(
      (a, b) => (errosPorFase[b] ?? 0) > (errosPorFase[a] ?? 0) ? b : a,
    );
  }
}

/// Os números da aba Seu jogo, calculados no aparelho a partir das partidas
/// prontas (assim o filtro de ritmo vale para tudo). Do documento de
/// estatísticas do servidor vêm só as posições por tema e o curso ligado a
/// cada abertura.
ResumoSeuJogo resumirSeuJogo({
  required List<PartidaTreinador> partidas,
  required EstatisticasTreinador estatisticas,
  required DateTime agora,
  Ritmo? ritmo,
}) {
  final prontas =
      partidas
          .where((p) => p.pronta && (ritmo == null || p.ritmo == ritmo))
          .toList()
        ..sort((a, b) => b.jogadaEm.compareTo(a.jogadaEm));
  final porId = {for (final p in prontas) p.id: p};

  var aproveitamento = const Aproveitamento();
  var brancas = const Aproveitamento();
  var pretas = const Aproveitamento();
  final ritmos = <Ritmo, Aproveitamento>{};
  final erros = {for (final f in FaseDoJogo.values) f: 0};
  for (final p in prontas) {
    aproveitamento = aproveitamento.mais(p.resultado);
    if (p.cor == CorPartida.brancas) {
      brancas = brancas.mais(p.resultado);
    } else {
      pretas = pretas.mais(p.resultado);
    }
    if (p.ritmo case final r?) {
      ritmos[r] = (ritmos[r] ?? const Aproveitamento()).mais(p.resultado);
    }
    for (final (ply, lance) in p.lances.indexed) {
      if (!_lanceDele(p.cor, ply)) continue;
      if (lance.classe != ClasseLance.erro &&
          lance.classe != ClasseLance.grave) {
        continue;
      }
      final fase = faseDoLance(ply, lance.fen);
      erros[fase] = erros[fase]! + 1;
    }
  }

  final temas = <ResumoTema>[];
  for (final MapEntry(key: tema, value: posicoes)
      in estatisticas.errosPorTema.entries) {
    final lista = [
      for (final pos in posicoes)
        if (porId[pos.partida] case final partida?)
          PosicaoDoTema(posicao: pos, partida: partida),
    ]..sort((a, b) => b.partida.jogadaEm.compareTo(a.partida.jogadaEm));
    if (lista.isNotEmpty) temas.add(ResumoTema(tema: tema, posicoes: lista));
  }
  temas.sort((a, b) {
    final c = b.posicoes.length.compareTo(a.posicoes.length);
    return c != 0 ? c : a.tema.compareTo(b.tema);
  });

  final aberturas = _aberturas(prontas, estatisticas);

  return ResumoSeuJogo(
    partidas: prontas.length,
    precisao: _media(prontas),
    variacaoPrecisao: _variacao(prontas, agora),
    aproveitamento: aproveitamento,
    errosPorFase: erros,
    precisaoSemanas: _semanas(prontas, agora),
    temas: temas,
    ritmos: {for (final r in Ritmo.values) r: ?ritmos[r]},
    brancas: brancas,
    pretas: pretas,
    aberturas: aberturas,
    foco: _foco(aberturas, temas),
  );
}

bool _lanceDele(CorPartida cor, int ply) =>
    cor == CorPartida.brancas ? ply.isEven : ply.isOdd;

/// Final: até 6 peças além de reis e peões (a mesma régua do servidor);
/// abertura: até o lance [lancesDaAbertura]; o resto é meio-jogo.
FaseDoJogo faseDoLance(int ply, String fen) {
  final tabuleiro = fen.split(' ').first;
  final pecas = RegExp('[qrbnQRBN]').allMatches(tabuleiro).length;
  if (tabuleiro.isNotEmpty && pecas <= 6) return FaseDoJogo.finalDaPartida;
  if (ply ~/ 2 + 1 <= lancesDaAbertura) return FaseDoJogo.abertura;
  return FaseDoJogo.meio;
}

int? _media(Iterable<PartidaTreinador> partidas) {
  final valores = [for (final p in partidas) ?p.precisao];
  if (valores.isEmpty) return null;
  return (valores.reduce((a, b) => a + b) / valores.length).round();
}

int? _variacao(List<PartidaTreinador> partidas, DateTime agora) {
  final corte = agora.subtract(const Duration(days: 30));
  final antes = agora.subtract(const Duration(days: 60));
  final recentes = _media(partidas.where((p) => p.jogadaEm.isAfter(corte)));
  final anteriores = _media(
    partidas.where(
      (p) => !p.jogadaEm.isAfter(corte) && p.jogadaEm.isAfter(antes),
    ),
  );
  if (recentes == null || anteriores == null) return null;
  return recentes - anteriores;
}

/// Semanas de segunda a domingo, na hora local.
List<int?> _semanas(List<PartidaTreinador> partidas, DateTime agora) {
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final segunda = hoje.subtract(Duration(days: hoje.weekday - 1));
  return [
    for (var i = 7; i >= 0; i--)
      _media(
        partidas.where((p) {
          final local = p.jogadaEm.toLocal();
          final inicio = DateTime(
            segunda.year,
            segunda.month,
            segunda.day - 7 * i,
          );
          final fim = DateTime(inicio.year, inicio.month, inicio.day + 7);
          return !local.isBefore(inicio) && local.isBefore(fim);
        }),
      ),
  ];
}

List<ResumoAbertura> _aberturas(
  List<PartidaTreinador> prontas,
  EstatisticasTreinador estatisticas,
) {
  final grupos = <(String, CorPartida), List<PartidaTreinador>>{};
  for (final p in prontas) {
    final a = p.abertura;
    if (a == null || a.nome.isEmpty) continue;
    grupos.putIfAbsent((a.nome, p.cor), () => []).add(p);
  }
  final lista = <ResumoAbertura>[];
  for (final MapEntry(key: (nome, cor), value: jogos) in grupos.entries) {
    var aprov = const Aproveitamento();
    for (final p in jogos) {
      aprov = aprov.mais(p.resultado);
    }
    final eco = jogos.first.abertura!.eco;
    final servidor = estatisticas.aberturas
        .where((a) => a.cor == cor && (a.nome == nome || a.eco == eco))
        .firstOrNull;
    lista.add(
      ResumoAbertura(
        nome: nome,
        eco: eco,
        cor: cor,
        aproveitamento: aprov,
        saida: _saida(jogos),
        curso: servidor?.curso,
      ),
    );
  }
  lista.sort((a, b) {
    final c = b.aproveitamento.partidas.compareTo(a.aproveitamento.partidas);
    return c != 0 ? c : a.nome.compareTo(b.nome);
  });
  return lista;
}

/// O lance em que ele mais sai da teoria (`teoria.lance` é o índice do meio
/// lance; o lance jogado é `lances[índice]`).
SaidaDaTeoria? _saida(List<PartidaTreinador> jogos) {
  final contagem = <(int, String), List<PartidaTreinador>>{};
  for (final p in jogos) {
    final ply = p.teoria?.lance;
    if (ply == null || ply < 0 || ply >= p.lances.length) continue;
    if (!_lanceDele(p.cor, ply)) continue;
    contagem.putIfAbsent((ply, p.lances[ply].san), () => []).add(p);
  }
  if (contagem.isEmpty) return null;
  final maior = contagem.entries.reduce(
    (a, b) => b.value.length > a.value.length ? b : a,
  );
  final (ply, san) = maior.key;
  return SaidaDaTeoria(
    lance: ply ~/ 2 + 1,
    san: san,
    pretas: ply.isOdd,
    vezes: maior.value.length,
    partidaRecente: maior.value.first.id,
  );
}

/// Abertura com a mesma saída em pelo menos 3 partidas e na metade delas;
/// senão o tema com 3 posições ou mais; senão nada.
FocoSeuJogo? _foco(List<ResumoAbertura> aberturas, List<ResumoTema> temas) {
  final candidatas = [
    for (final a in aberturas)
      if (a.saida case final s?
          when s.vezes >= 3 && s.vezes * 2 >= a.aproveitamento.partidas)
        a,
  ]..sort((a, b) => b.saida!.vezes.compareTo(a.saida!.vezes));
  if (candidatas.isNotEmpty) return FocoAbertura(candidatas.first);
  if (temas.firstOrNull case final t? when t.posicoes.length >= 3) {
    return FocoTema(t);
  }
  return null;
}
