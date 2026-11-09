// T87 · `users/{uid}/treinador/estatisticas`, recalculadas a cada análise a partir das partidas prontas (idempotente).
import type { DocumentData } from 'firebase-admin/firestore';
import { semanaBR } from './politica';
import type { Fases } from './tipos';

/** O que a estatística lê de cada partida pronta. */
export interface PartidaParaEstatistica {
  id: string;
  jogadaEm: Date;
  cor: 'brancas' | 'pretas';
  resultado: 'vitoria' | 'derrota' | 'empate';
  abertura: { eco: string; nome: string } | null;
  precisao: number;
  fases: Fases;
  teoria: { lance: number } | null;
  erros: { lance: number; indice: number; fen: string; fase: keyof Fases; tema: string | null }[];
}

const SEMANAS = 8;
const POSICOES_POR_TEMA = 10;
const ABERTURAS = 10;

const NOME_TEMA: Record<string, string> = {
  mate: 'ameaças de mate',
  garfo: 'garfos',
  peca_solta: 'peças sem defensor',
  xeque_duplo: 'xeques duplos',
  xeque_descoberto: 'xeques descobertos',
  promocao: 'peões perto da promoção',
  final_peoes: 'finais de peões',
  final_torres: 'finais de torres',
  final_pecas_menores: 'finais de peças menores',
  final_dama: 'finais de dama',
  final: 'finais',
};

const NOME_FASE: Record<keyof Fases, string> = { abertura: 'na abertura', meio: 'no meio-jogo', final: 'nos finais' };

function media(v: number[]): number | null {
  return v.length ? Math.round(v.reduce((a, b) => a + b, 0) / v.length) : null;
}

export function calcularEstatisticas(partidas: PartidaParaEstatistica[], agora: Date): DocumentData {
  const ordem = [...partidas].sort((a, b) => b.jogadaEm.getTime() - a.jogadaEm.getTime());

  // Precisão por semana (segunda-feira), das mais antigas para a atual, só semanas com partida.
  const porSemana = new Map<string, number[]>();
  for (const p of ordem) {
    const s = semanaBR(p.jogadaEm);
    porSemana.set(s, [...(porSemana.get(s) ?? []), p.precisao]);
  }
  const atual = semanaBR(agora);
  const precisaoSemanas = [...porSemana.entries()]
    .filter(([s]) => s <= atual)
    .sort((a, b) => a[0].localeCompare(b[0]))
    .slice(-SEMANAS)
    .map(([semana, v]) => ({ semana, precisao: media(v) }));

  const errosPorFase = { abertura: 0, meio: 0, final: 0 };
  const errosPorTema: Record<string, { partida: string; lance: number; fen: string }[]> = {};
  const contaTema = new Map<string, Set<string>>();
  for (const p of ordem) {
    for (const e of p.erros) {
      errosPorFase[e.fase]++;
      if (!e.tema) continue;
      const lista = (errosPorTema[e.tema] ??= []);
      if (lista.length < POSICOES_POR_TEMA) lista.push({ partida: p.id, lance: e.lance, fen: e.fen });
      contaTema.set(e.tema, (contaTema.get(e.tema) ?? new Set()).add(p.id));
    }
  }

  // Aberturas por nome e cor.
  const ab = new Map<string, { nome: string; eco: string; cor: string; partidas: number; vitorias: number; saidas: number[] }>();
  for (const p of ordem) {
    if (!p.abertura?.nome) continue;
    const k = `${p.abertura.nome}|${p.cor}`;
    const a = ab.get(k) ?? { nome: p.abertura.nome, eco: p.abertura.eco, cor: p.cor, partidas: 0, vitorias: 0, saidas: [] };
    a.partidas++;
    if (p.resultado === 'vitoria') a.vitorias++;
    if (p.teoria) a.saidas.push(p.teoria.lance);
    ab.set(k, a);
  }
  const aberturas = [...ab.values()]
    .sort((x, y) => y.partidas - x.partidas)
    .slice(0, ABERTURAS)
    .map((a) => {
      let saidaTeoria: { lance: number; vezes: number } | null = null;
      if (a.saidas.length) {
        const freq = new Map<number, number>();
        for (const s of a.saidas) freq.set(s, (freq.get(s) ?? 0) + 1);
        const [indice, vezes] = [...freq.entries()].sort((x, y) => y[1] - x[1] || x[0] - y[0])[0];
        // Índice do meio-lance → número do lance, como o jogador lê ("saiu no lance 6").
        saidaTeoria = { lance: Math.floor(indice / 2) + 1, vezes };
      }
      return { nome: a.nome, eco: a.eco, cor: a.cor, partidas: a.partidas, vitorias: a.vitorias, saidaTeoria };
    });

  return {
    partidasAnalisadas: partidas.length,
    precisaoSemanas,
    errosPorFase,
    errosPorTema,
    aberturas,
    estilo: estilo(ordem, contaTema),
    atualizadoEm: agora,
  };
}

/** Nível pelo número de partidas e os pontos fortes e a acertar, em texto curto com os números. */
function estilo(ordem: PartidaParaEstatistica[], contaTema: Map<string, Set<string>>): DocumentData {
  const n = ordem.length;
  const nivel = n < 5 ? 'primeira' : n < 20 ? 'formacao' : 'firme';
  const fortes: DocumentData[] = [];
  const acertar: DocumentData[] = [];
  const fases: (keyof Fases)[] = ['abertura', 'meio', 'final'];
  const precisaoFase = fases
    .map((f) => {
      const v = ordem.map((p) => p.fases[f]).filter((x): x is number => typeof x === 'number');
      return { f, media: media(v), partidas: v.length };
    })
    .filter((x) => x.media !== null && x.partidas >= 2) as { f: keyof Fases; media: number; partidas: number }[];
  precisaoFase.sort((a, b) => b.media - a.media);
  const melhor = precisaoFase[0];
  const pior = precisaoFase[precisaoFase.length - 1];
  if (melhor && melhor.media >= 80) {
    fortes.push({ texto: `Precisão de ${melhor.media}% ${NOME_FASE[melhor.f]}`, partidas: melhor.partidas, tema: null });
  }
  if (pior && pior !== melhor && pior.media < 80) {
    acertar.push({ texto: `Precisão de ${pior.media}% ${NOME_FASE[pior.f]}`, partidas: pior.partidas, tema: null });
  }
  const temas = [...contaTema.entries()].sort((a, b) => b[1].size - a[1].size);
  for (const [tema, ps] of temas.slice(0, 2)) {
    if (ps.size < 2) break;
    const nome = NOME_TEMA[tema] ?? tema;
    acertar.push({ texto: `Erros com ${nome} em ${ps.size} partidas`, partidas: ps.size, tema });
  }
  return { nivel, fortes, acertar };
}
