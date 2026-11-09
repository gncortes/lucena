// T87 · Teoria pelo explorador do Lichess (precisa de token). Sem token, sem resposta ou fora da base: null.
// Cache por FEN em `treinador_teoria/{fen sem relógios}`; o aparelho nunca fala com o Lichess para isso.
import { Chess } from 'chess.js';
import type { Firestore } from 'firebase-admin/firestore';
import type { Http } from './fontes';
import type { CandidatoTeoria, Teoria } from './tipos';

const AGENTE = 'Lucena/1.0 (treino de xadrez; servidor)';
/** Lance com menos partidas que isso na base está fora da teoria. */
export const MIN_PARTIDAS = 20;
/** Até onde procurar a saída da teoria (meio-lances). */
export const MAX_MEIO_LANCES = 30;
const CANDIDATOS = 3;
/** Lances na linha de cada candidato (o candidato e as respostas mais jogadas). */
const PROFUNDIDADE = 3;

export interface LanceExplorador {
  uci: string;
  san: string;
  white: number;
  draws: number;
  black: number;
}
export interface RespostaExplorador {
  moves: LanceExplorador[];
}

export type Explorador = (fen: string) => Promise<RespostaExplorador | null>;

/** Chave do cache: FEN sem os contadores de meio-lance e lance (a mesma posição na base). */
export function chaveFen(fen: string): string {
  return fen.split(' ').slice(0, 4).join(' ').replace(/\//g, '_');
}

/** Explorador real (base do Lichess, ritmos blitz a clássica, faixas a partir de 1600). */
export function exploradorLichess(http: Http, token: string): Explorador {
  return async (fen) => {
    const q = new URLSearchParams({
      variant: 'standard',
      fen,
      speeds: 'blitz,rapid,classical',
      ratings: '1600,1800,2000,2200,2500',
      moves: '8',
      topGames: '0',
      recentGames: '0',
    });
    const r = await http(`https://explorer.lichess.ovh/lichess?${q}`, {
      headers: { Accept: 'application/json', 'User-Agent': AGENTE, Authorization: `Bearer ${token}` },
    });
    if (r.status !== 200) throw new Error(`explorador ${r.status}`);
    const j = JSON.parse(await r.text()) as { moves?: LanceExplorador[] };
    return { moves: (j.moves ?? []).map((m) => ({ uci: m.uci, san: m.san, white: m.white, draws: m.draws, black: m.black })) };
  };
}

/** Explorador com cache no Firestore (o cache não expira: a base muda devagar). */
export function comCache(db: Firestore, explorador: Explorador): Explorador {
  return async (fen) => {
    const ref = db.doc(`treinador_teoria/${chaveFen(fen)}`);
    const s = await ref.get();
    if (s.exists) return { moves: (s.get('moves') ?? []) as LanceExplorador[] };
    const r = await explorador(fen);
    if (r) await ref.set({ moves: r.moves, fen });
    return r;
  };
}

function total(m: LanceExplorador): number {
  return m.white + m.draws + m.black;
}

function mover(c: Chess, uci: string) {
  return c.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
}

/**
 * Onde a partida saiu da teoria: o primeiro meio-lance que não está na base (ou tem menos de MIN_PARTIDAS).
 * `lance` = índice do meio-lance, `fen` = posição antes dele, candidatos = os mais jogados ali, com a linha.
 * Partida que segue a teoria até o fim da busca, ou erro do explorador: null.
 */
export async function acharTeoria(pgn: string, explorador: Explorador): Promise<Teoria | null> {
  try {
    const c = new Chess();
    c.loadPgn(pgn);
    const lances = c.history({ verbose: true });
    for (let i = 0; i < Math.min(lances.length, MAX_MEIO_LANCES); i++) {
      const m = lances[i];
      const r = await explorador(m.before);
      if (!r || !r.moves.length) return null;
      const naBase = r.moves.find((x) => x.san === m.san || x.uci === `${m.from}${m.to}${m.promotion ?? ''}`);
      if (naBase && total(naBase) >= MIN_PARTIDAS) continue;
      if (i === 0) return null;
      const candidatos: CandidatoTeoria[] = [];
      for (const cand of r.moves.filter((x) => total(x) >= MIN_PARTIDAS).slice(0, CANDIDATOS)) {
        const linha = [cand.san];
        const pos = new Chess(m.before);
        mover(pos, cand.uci);
        for (let k = 1; k < PROFUNDIDADE; k++) {
          const prox = await explorador(pos.fen());
          const top = prox?.moves[0];
          if (!top || total(top) < MIN_PARTIDAS) break;
          linha.push(top.san);
          mover(pos, top.uci);
        }
        candidatos.push({
          san: cand.san,
          partidas: total(cand),
          brancas: cand.white,
          empates: cand.draws,
          pretas: cand.black,
          linha,
        });
      }
      if (!candidatos.length) return null;
      return { lance: i, fen: m.before, candidatos };
    }
    return null;
  } catch {
    return null;
  }
}

/**
 * Token do Lichess, só em tempo de execução: variável `LICHESS_TOKEN` (segredo montado na Function) ou o Secret
 * Manager pela conta de serviço. Ausente ou sem permissão: null (a análise sai sem teoria).
 */
export async function tokenLichess(
  http: Http,
  projeto: string | undefined,
  tokenDeAcesso: () => Promise<string | null>,
): Promise<string | null> {
  const env = process.env.LICHESS_TOKEN;
  if (env) return env;
  if (!projeto) return null;
  try {
    const acesso = await tokenDeAcesso();
    if (!acesso) return null;
    const r = await http(
      `https://secretmanager.googleapis.com/v1/projects/${projeto}/secrets/LICHESS_TOKEN/versions/latest:access`,
      { headers: { Authorization: `Bearer ${acesso}` } },
    );
    if (r.status !== 200) return null;
    const j = JSON.parse(await r.text()) as { payload?: { data?: string } };
    const v = j.payload?.data ? Buffer.from(j.payload.data, 'base64').toString('utf8').trim() : '';
    return v || null;
  } catch {
    return null;
  }
}
