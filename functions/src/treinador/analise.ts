// T87 · Análise de uma partida: motor por nós fixos em cada posição, classificação dos lances, precisão por fase,
// temas confirmados pela linha do motor e exercícios (regras do spike, seção "Exercícios").
import { Chess, type Move } from 'chess.js';
import { comentarioDoLance, falasDoExercicio, resumoDaPartida } from './falas';
import { VERSAO_MOTOR, type Linha, type Motor } from './motor';
import type {
  ClasseLance,
  Cor,
  Exercicio,
  Fases,
  LanceAnalisado,
  PartidaBruta,
  ResultadoAnalise,
  Teoria,
  TipoExercicio,
} from './tipos';
import {
  chance,
  detectarTema,
  ehFinal,
  lanceNumerado,
  lancesLegais,
  linhaPt,
  numeroDoLance,
  precisaoDoLance,
  precisaoMedia,
  type Achado,
  uciParaSan,
} from './xadrez';

export interface ConfigAnalise {
  /** Nós antes dos lances do usuário (e nos candidatos a exercício). */
  nosUsuario: number;
  /** Nós nas demais posições. */
  nosDemais: number;
  /** 1 a 6. */
  exercicios: number;
  /** Tipos ligados (painel). Profilaxia fica fora da V1. */
  tipos: { seu_melhor: boolean; adversario: boolean; decisivo: boolean };
}

export const CONFIG_PADRAO: ConfigAnalise = {
  nosUsuario: 1_000_000,
  nosDemais: 300_000,
  exercicios: 4,
  tipos: { seu_melhor: true, adversario: true, decisivo: true },
};

/** Limiares (spike e Lichess). */
export const LIMIAR = {
  imprecisao: 5,
  erro: 10,
  grave: 15,
  /** Perda para virar candidato a exercício: 20 pontos de chance ou 150 cp. */
  exercicioChance: 20,
  exercicioCp: 150,
  /** O melhor tem de superar o 2º por 15 pontos de chance ou 100 cp. */
  unicoChance: 15,
  unicoCp: 100,
  /** Aceita outro lance a até 30 cp do melhor. */
  aceitaCp: 30,
  /** Lances iniciais com menos nós (abertura conhecida). */
  meioLancesDeAbertura: 8,
  nosAbertura: 100_000,
};

interface Nota {
  /** Do ponto de vista das brancas. */
  cp: number | null;
  mate: number | null;
}

function notaBrancas(l: Linha | undefined, vez: 'w' | 'b'): Nota {
  if (!l) return { cp: 0, mate: null };
  const s = vez === 'w' ? 1 : -1;
  return { cp: l.cp === null ? null : l.cp * s, mate: l.mate === null ? null : l.mate * s };
}

function chanceDe(n: Nota, cor: 'w' | 'b'): number {
  const s = cor === 'w' ? 1 : -1;
  return chance(n.cp === null ? null : n.cp * s, n.mate === null ? null : n.mate * s);
}

function cpDe(n: Nota, cor: 'w' | 'b'): number {
  if (n.mate !== null) return (cor === 'w' ? 1 : -1) * (n.mate > 0 ? 2000 : -2000);
  return (n.cp ?? 0) * (cor === 'w' ? 1 : -1);
}

function classe(perda: number): ClasseLance {
  if (perda >= LIMIAR.grave) return 'grave';
  if (perda >= LIMIAR.erro) return 'erro';
  if (perda >= LIMIAR.imprecisao) return 'imprecisao';
  return 'ok';
}

function fase(meioLance: number, fen: string): keyof Fases {
  if (ehFinal(fen)) return 'final';
  return meioLance < 20 ? 'abertura' : 'meio';
}

function uci(m: Move): string {
  return `${m.from}${m.to}${m.promotion ?? ''}`;
}

/** Nota da posição final (mate, afogado, empate) sem motor. */
function notaFinal(fen: string): Nota | null {
  const c = new Chess(fen);
  if (c.isCheckmate()) return { cp: null, mate: 0 };
  if (c.isDraw() || c.isStalemate()) return { cp: 0, mate: null };
  return null;
}

interface Candidato {
  i: number;
  tipo: TipoExercicio;
  perda: number;
  linhas: Linha[];
}

/**
 * Analisa a partida. `teoria` vem pronta (explorador do Lichess) ou null.
 * `relogio` mede o tempo real de motor (para custo).
 */
export async function analisarPartida(
  partida: PartidaBruta,
  motor: Motor,
  cfg: ConfigAnalise,
  teoria: Teoria | null,
  relogio: () => number = () => Date.now(),
): Promise<ResultadoAnalise> {
  const inicio = relogio();
  const c = new Chess();
  c.loadPgn(partida.pgn);
  const lances = c.history({ verbose: true });
  if (!lances.length) throw new Error('pgn sem lances');
  const minhaCor: 'w' | 'b' = partida.cor === 'brancas' ? 'w' : 'b';

  // 1) Motor em cada posição (antes de cada lance e a final).
  const fens = [...lances.map((m) => m.before), lances[lances.length - 1].after];
  const notas: Nota[] = [];
  const melhores: (Linha | undefined)[] = [];
  for (let i = 0; i < fens.length; i++) {
    const final = i === fens.length - 1 ? notaFinal(fens[i]) : null;
    if (final) {
      notas.push(final);
      melhores.push(undefined);
      continue;
    }
    const vez = fens[i].split(' ')[1] as 'w' | 'b';
    const nos =
      i < LIMIAR.meioLancesDeAbertura
        ? Math.min(cfg.nosDemais, LIMIAR.nosAbertura)
        : i < lances.length && lances[i].color === minhaCor
          ? cfg.nosUsuario
          : cfg.nosDemais;
    const [l] = await motor.analisar(fens[i], nos, 1);
    notas.push(notaBrancas(l, vez));
    melhores.push(l);
  }

  // 2) Classificação dos lances.
  const perdas: number[] = [];
  const saida: LanceAnalisado[] = [];
  const precisaoPorFase: Record<keyof Fases, number[]> = { abertura: [], meio: [], final: [] };
  const todasMinhas: number[] = [];
  const contagem = { grave: 0, erro: 0, imprecisao: 0 };
  const errosPorFase: Record<keyof Fases, number> = { abertura: 0, meio: 0, final: 0 };
  for (let i = 0; i < lances.length; i++) {
    const m = lances[i];
    const melhor = melhores[i];
    let perda = Math.max(0, chanceDe(notas[i], m.color) - chanceDe(notas[i + 1], m.color));
    if (melhor && melhor.uci === uci(m)) perda = 0;
    perdas.push(perda);
    const cl = classe(perda);
    const f = fase(i, m.before);
    if (m.color === minhaCor) {
      const p = precisaoDoLance(perda);
      precisaoPorFase[f].push(p);
      todasMinhas.push(p);
      if (cl !== 'ok') {
        contagem[cl]++;
        if (cl !== 'imprecisao') errosPorFase[f]++;
      }
    }
    const melhorSan = melhor ? uciParaSan(m.before, melhor.uci) : null;
    // Resposta que pune: o melhor lance do outro lado na posição seguinte, com o tema confirmado.
    let resposta: { lance: string; achado: Achado } | null = null;
    const prox = melhores[i + 1];
    if (cl === 'erro' || cl === 'grave') {
      if (prox) {
        const san = uciParaSan(m.after, prox.uci);
        if (san) resposta = { lance: lanceNumerado(m.after, san), achado: detectarTema(m.after, prox.pv, prox.mate) };
      }
    }
    saida.push({
      san: m.san,
      fen: m.after,
      cp: notas[i + 1].mate !== null ? null : notas[i + 1].cp,
      mate: notas[i + 1].mate,
      melhor: melhorSan,
      classe: cl,
      comentario: comentarioDoLance(cl, melhorSan ? lanceNumerado(m.before, melhorSan) : null, resposta),
    });
  }

  // 3) Candidatos a exercício.
  const candidatos: Candidato[] = [];
  for (let i = 0; i < lances.length; i++) {
    const m = lances[i];
    const meu = m.color === minhaCor;
    const tipo: TipoExercicio = meu ? 'seu_melhor' : 'adversario';
    if (!cfg.tipos[tipo === 'adversario' ? 'adversario' : 'seu_melhor'] && !(meu && cfg.tipos.decisivo)) continue;
    const quedaCp = cpDe(notas[i], m.color) - cpDe(notas[i + 1], m.color);
    if (perdas[i] < LIMIAR.exercicioChance && !(quedaCp >= LIMIAR.exercicioCp && perdas[i] >= LIMIAR.imprecisao)) {
      continue;
    }
    candidatos.push({ i, tipo, perda: perdas[i], linhas: [] });
  }

  const exercicios: Exercicio[] = [];
  const temas = new Set<string>();
  const errosDoUsuario: ResultadoAnalise['errosDoUsuario'] = [];

  // Temas dos erros do usuário (tema da resposta que pune) para as estatísticas.
  for (let i = 0; i < lances.length; i++) {
    const m = lances[i];
    if (m.color !== minhaCor || (saida[i].classe !== 'erro' && saida[i].classe !== 'grave')) continue;
    const prox = melhores[i + 1];
    const t = prox ? detectarTema(m.after, prox.pv, prox.mate).tema : null;
    errosDoUsuario.push({ lance: numeroDoLance(m.before), indice: i, fen: m.before, fase: fase(i, m.before), tema: t });
    if (t) temas.add(t);
  }

  // Confere cada candidato com MultiPV 3 (lance único, filtros) e escolhe.
  const aprovados: (Candidato & { achado: Achado; aceitos: string[] })[] = [];
  candidatos.sort((a, b) => b.perda - a.perda);
  for (const cand of candidatos) {
    if (aprovados.length >= cfg.exercicios * 2) break;
    if (aprovados.some((a) => Math.abs(a.i - cand.i) <= 2)) continue;
    const m = lances[cand.i];
    if (lancesLegais(m.before) <= 2) continue;
    const linhas = await motor.analisar(m.before, cfg.nosUsuario, 3);
    if (!linhas.length) continue;
    const [l1, l2] = linhas;
    if (l1.uci === uci(m)) continue;
    if (l1.mate !== null && l1.mate === 1) continue;
    // Recaptura: o lance anterior capturou na casa que a solução recaptura.
    const ant = lances[cand.i - 1];
    if (ant?.captured && l1.uci.slice(2, 4) === ant.to) continue;
    const vezNota = (l: Linha) => ({ cp: l.cp, mate: l.mate });
    const ch1 = chance(vezNota(l1).cp, vezNota(l1).mate);
    // Posição decidida: já ganha por muito e continua ganha depois do lance jogado.
    if (ch1 > 97 && chanceDe(notas[cand.i + 1], m.color) > 75) continue;
    if (ch1 < 5) continue;
    const aceitos: string[] = [];
    if (l2) {
      const ch2 = chance(l2.cp, l2.mate);
      const cp1 = l1.mate !== null ? (l1.mate > 0 ? 2000 : -2000) : (l1.cp ?? 0);
      const cp2 = l2.mate !== null ? (l2.mate > 0 ? 2000 : -2000) : (l2.cp ?? 0);
      const ambosMate = l1.mate !== null && l1.mate > 0 && l2.mate !== null && l2.mate > 0;
      if (ambosMate) {
        for (const l of linhas.slice(1)) if (l.mate !== null && l.mate > 0 && l.mate <= l1.mate! + 2) aceitos.push(l.uci);
      } else {
        if (ch1 - ch2 < LIMIAR.unicoChance && cp1 - cp2 < LIMIAR.unicoCp) continue;
        for (const l of linhas.slice(1)) {
          const cp = l.mate !== null ? (l.mate > 0 ? 2000 : -2000) : (l.cp ?? 0);
          if (cp1 - cp <= LIMIAR.aceitaCp) aceitos.push(l.uci);
        }
      }
    }
    aprovados.push({ ...cand, linhas, aceitos, achado: detectarTema(m.before, l1.pv, l1.mate) });
  }

  // Escolha: maior perda primeiro, com pelo menos um do adversário quando houver e couber.
  let escolhidos = aprovados.filter((a) => cfg.tipos[a.tipo === 'adversario' ? 'adversario' : 'seu_melhor'] || a.tipo !== 'adversario');
  escolhidos = escolhidos.slice(0, cfg.exercicios);
  const adv = aprovados.find((a) => a.tipo === 'adversario');
  if (cfg.exercicios >= 3 && adv && !escolhidos.includes(adv) && cfg.tipos.adversario) {
    escolhidos[escolhidos.length - 1] = adv;
  }
  if (!cfg.tipos.adversario) escolhidos = escolhidos.filter((a) => a.tipo !== 'adversario');

  // Decisivo: o erro do usuário que virou a partida (cruzou os 50% contra ele), o maior.
  if (cfg.tipos.decisivo) {
    let maior: (typeof escolhidos)[number] | null = null;
    for (const e of escolhidos) {
      if (e.tipo !== 'seu_melhor') continue;
      const cor = lances[e.i].color;
      if (chanceDe(notas[e.i], cor) >= 50 && chanceDe(notas[e.i + 1], cor) < 50 && (!maior || e.perda > maior.perda)) {
        maior = e;
      }
    }
    if (maior) maior.tipo = 'decisivo';
  }
  if (!cfg.tipos.seu_melhor) escolhidos = escolhidos.filter((a) => a.tipo !== 'seu_melhor');

  // Gap 3: sem posição-chave, 1 exercício do melhor lance dele (o lance único que ele achou).
  if (!escolhidos.length) {
    const fallback = await melhorLanceDele(lances, minhaCor, melhores, motor, cfg);
    if (fallback) escolhidos.push(fallback);
  }

  escolhidos.sort((a, b) => a.i - b.i);
  escolhidos.forEach((e, k) => {
    const m = lances[e.i];
    const l1 = e.linhas[0];
    const solSan = uciParaSan(m.before, l1.uci) ?? l1.uci;
    const lado: Cor = m.color === 'w' ? 'brancas' : 'pretas';
    const aposSol = new Chess(m.before);
    aposSol.move({ from: l1.uci.slice(0, 2), to: l1.uci.slice(2, 4), promotion: l1.uci[4] });
    if (e.achado.tema) temas.add(e.achado.tema);
    exercicios.push({
      n: k + 1,
      tipo: e.tipo,
      fen: m.before,
      lance: numeroDoLance(m.before),
      solucao: l1.uci,
      aceitos: e.aceitos,
      jogado: m.san,
      tema: e.achado.tema,
      estrelas: estrelas(m.before, l1, e.achado),
      falas: falasDoExercicio({
        tipo: e.tipo,
        solucao: lanceNumerado(m.before, solSan),
        jogado: lanceNumerado(m.before, m.san),
        continuacao: linhaPt(aposSol.fen(), l1.pv.slice(1), 3),
        lado,
        achado: e.achado,
      }),
    });
  });

  const fases: Fases = {
    abertura: precisaoMedia(precisaoPorFase.abertura),
    meio: precisaoMedia(precisaoPorFase.meio),
    final: precisaoMedia(precisaoPorFase.final),
  };
  const precisao = precisaoMedia(todasMinhas) ?? 100;
  const piorFase = (Object.keys(errosPorFase) as (keyof Fases)[])
    .filter((f) => errosPorFase[f] > 0)
    .sort((a, b) => errosPorFase[b] - errosPorFase[a])[0] ?? null;

  return {
    resumo: resumoDaPartida(precisao, contagem, piorFase),
    precisao,
    exercicios,
    lances: saida,
    teoria,
    fases,
    temas: [...temas],
    motor: { versao: VERSAO_MOTOR, nos: cfg.nosUsuario },
    errosDoUsuario,
    segundosMotor: (relogio() - inicio) / 1000,
  };
}

/** Estrelas (1–3) por heurística: o Maia não roda no servidor. */
export function estrelas(fen: string, l: Linha, a: Achado): number {
  const c = new Chess(fen);
  let m;
  try {
    m = c.move({ from: l.uci.slice(0, 2), to: l.uci.slice(2, 4), promotion: l.uci[4] });
  } catch {
    return 2;
  }
  const forcante = !!m.captured || c.isCheck();
  if (l.mate !== null && l.mate > 0) return l.mate <= 2 ? 1 : l.mate <= 3 ? 2 : 3;
  if (!forcante) return 3;
  if (a.tema === 'peca_solta' || (m.captured && !a.tema)) return 1;
  return 2;
}

/** Gap 3: posição em que ele jogou o melhor lance e o 2º era bem pior; o lance único dele. */
async function melhorLanceDele(
  lances: Move[],
  cor: 'w' | 'b',
  melhores: (Linha | undefined)[],
  motor: Motor,
  cfg: ConfigAnalise,
): Promise<(Candidato & { achado: Achado; aceitos: string[] }) | null> {
  const posicoes: number[] = [];
  for (let i = LIMIAR.meioLancesDeAbertura; i < lances.length && posicoes.length < 12; i++) {
    const m = lances[i];
    if (m.color === cor && melhores[i]?.uci === uci(m) && lancesLegais(m.before) > 2) posicoes.push(i);
  }
  let melhor: { i: number; gap: number; linhas: Linha[] } | null = null;
  for (const i of posicoes) {
    const linhas = await motor.analisar(lances[i].before, cfg.nosDemais, 2);
    if (linhas.length < 2) continue;
    const gap = chance(linhas[0].cp, linhas[0].mate) - chance(linhas[1].cp, linhas[1].mate);
    if (!melhor || gap > melhor.gap) melhor = { i, gap, linhas };
  }
  if (!melhor || melhor.gap < 5) return null;
  const m = lances[melhor.i];
  return {
    i: melhor.i,
    tipo: 'seu_melhor',
    perda: 0,
    linhas: melhor.linhas,
    aceitos: [],
    achado: detectarTema(m.before, melhor.linhas[0].pv, melhor.linhas[0].mate),
  };
}
