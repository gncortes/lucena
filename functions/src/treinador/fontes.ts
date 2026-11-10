// T87 · Fontes das partidas: Lichess (exportação pública) e chess.com (arquivo do mês).
// Tudo por um `Http` injetado: os testes passam respostas gravadas, o servidor usa o fetch.
import type { Cor, PartidaBruta, Plataforma, Resultado, Ritmo } from './tipos';

export interface RespostaHttp {
  status: number;
  text(): Promise<string>;
}
export type Http = (url: string, init?: { headers?: Record<string, string> }) => Promise<RespostaHttp>;

/** Erro de fonte com motivo legível para o painel (`lichess429`, `fora`). */
export class ErroFonte extends Error {
  constructor(
    readonly plataforma: Plataforma,
    readonly motivo: 'limite' | 'fora',
    readonly status: number,
  ) {
    super(`${plataforma}: ${motivo} (${status})`);
  }
}

/** chess.com pede um User-Agent que identifique o app. */
const AGENTE = 'Lucena/1.0 (treino de xadrez; servidor)';

/** Ritmos que o treinador analisa. */
function ritmoDe(nome: string): Ritmo | null {
  switch (nome) {
    case 'ultraBullet':
    case 'bullet':
      return 'bullet';
    case 'blitz':
      return 'blitz';
    case 'rapid':
    case 'classical':
      return 'rapida';
    default:
      return null;
  }
}

/** Segundos e incremento → "5+0" (meio minuto vira "0,5"). */
export function cadencia(inicialSeg: number, incremento: number): string {
  const min = inicialSeg / 60;
  const texto = Number.isInteger(min) ? String(min) : String(Math.round(min * 100) / 100).replace('.', ',');
  return `${texto}+${incremento}`;
}

/** Partidas curtas demais não rendem análise (abandono, perda no relógio cedo). */
export const MEIO_LANCES_MINIMOS = 10;

function meioLancesDoPgn(pgn: string): number {
  const corpo = pgn.replace(/\[[^\]]*\]/g, ' ').replace(/\{[^}]*\}/g, ' ').replace(/\([^)]*\)/g, ' ');
  return corpo
    .split(/\s+/)
    .filter((t) => t && !/^\d+\.+$/.test(t) && !/^(1-0|0-1|1\/2-1\/2|\*)$/.test(t) && !/^\$\d+$/.test(t))
    .map((t) => t.replace(/^\d+\.+/, ''))
    .filter(Boolean).length;
}

function tag(pgn: string, nome: string): string | null {
  const m = pgn.match(new RegExp(`\\[${nome} "([^"]*)"\\]`));
  return m ? m[1] : null;
}

// ---------------------------------------------------------------- Lichess

interface JogadorLichess {
  user?: { name?: string; id?: string };
  rating?: number;
}
interface PartidaLichess {
  id: string;
  variant?: string;
  speed?: string;
  createdAt?: number;
  lastMoveAt?: number;
  status?: string;
  players?: { white?: JogadorLichess; black?: JogadorLichess };
  winner?: 'white' | 'black';
  opening?: { eco?: string; name?: string };
  clock?: { initial?: number; increment?: number };
  pgn?: string;
}

/** Converte uma linha do NDJSON do Lichess; null = fora do treinador (variante, ritmo, curta). */
export function partidaDoLichess(p: PartidaLichess, usuario: string): PartidaBruta | null {
  if ((p.variant ?? 'standard') !== 'standard') return null;
  if (p.status === 'aborted' || p.status === 'noStart' || p.status === 'created' || p.status === 'started') return null;
  const ritmo = ritmoDe(p.speed ?? '');
  if (!ritmo || !p.pgn || !p.players?.white || !p.players?.black) return null;
  if (meioLancesDoPgn(p.pgn) < MEIO_LANCES_MINIMOS) return null;
  const eu = usuario.toLowerCase();
  const branco = (p.players.white.user?.id ?? p.players.white.user?.name ?? '').toLowerCase();
  const preto = (p.players.black.user?.id ?? p.players.black.user?.name ?? '').toLowerCase();
  let cor: Cor;
  if (branco === eu) cor = 'brancas';
  else if (preto === eu) cor = 'pretas';
  else return null;
  const meu = cor === 'brancas' ? p.players.white : p.players.black;
  const dele = cor === 'brancas' ? p.players.black : p.players.white;
  let resultado: Resultado = 'empate';
  if (p.winner) resultado = (p.winner === 'white') === (cor === 'brancas') ? 'vitoria' : 'derrota';
  return {
    id: `lichess_${p.id}`,
    plataforma: 'lichess',
    idExterno: p.id,
    url: `https://lichess.org/${p.id}${cor === 'pretas' ? '/black' : ''}`,
    jogadaEm: new Date(p.createdAt ?? p.lastMoveAt ?? 0),
    ritmo,
    cadencia: cadencia(p.clock?.initial ?? 0, p.clock?.increment ?? 0),
    cor,
    adversario: { nome: dele.user?.name ?? 'Anônimo', rating: dele.rating ?? null },
    rating: meu.rating ?? null,
    resultado,
    abertura: p.opening?.eco ? { eco: p.opening.eco, nome: p.opening.name ?? '' } : null,
    pgn: p.pgn.trim(),
  };
}

/** Confere o usuário; devolve o nome como o Lichess escreve, ou null se não existe/fechado. */
export async function usuarioLichess(http: Http, usuario: string): Promise<string | null> {
  const r = await http(`https://lichess.org/api/user/${encodeURIComponent(usuario)}`, {
    headers: { Accept: 'application/json', 'User-Agent': AGENTE },
  });
  if (r.status === 404) return null;
  if (r.status === 429) throw new ErroFonte('lichess', 'limite', 429);
  if (r.status !== 200) throw new ErroFonte('lichess', 'fora', r.status);
  const j = JSON.parse(await r.text()) as { username?: string; closed?: boolean; disabled?: boolean; tosViolation?: boolean };
  if (j.closed || j.disabled || !j.username) return null;
  return j.username;
}

/**
 * O dono do token do Lichess (login OAuth com PKCE feito no app): `GET /api/account` com o token. É a prova de que a
 * conta é de quem está ligando. Token inválido ou revogado: null. O token não é gravado nem vai para o log.
 */
export async function donoDoTokenLichess(http: Http, token: string): Promise<string | null> {
  const r = await http('https://lichess.org/api/account', {
    headers: { Accept: 'application/json', 'User-Agent': AGENTE, Authorization: `Bearer ${token}` },
  });
  if (r.status === 401 || r.status === 403) return null;
  if (r.status === 429) throw new ErroFonte('lichess', 'limite', 429);
  if (r.status !== 200) throw new ErroFonte('lichess', 'fora', r.status);
  const j = JSON.parse(await r.text()) as { username?: string; closed?: boolean; disabled?: boolean };
  if (j.closed || j.disabled || !j.username) return null;
  return j.username;
}

/** Partidas terminadas desde `desde` (ms, criação), mais novas primeiro, até `max`. */
export async function partidasLichess(
  http: Http,
  usuario: string,
  desde: number | null,
  max: number,
): Promise<PartidaBruta[]> {
  const q = new URLSearchParams({
    max: String(max),
    perfType: 'ultraBullet,bullet,blitz,rapid,classical',
    opening: 'true',
    pgnInJson: 'true',
    clocks: 'false',
    evals: 'false',
    ongoing: 'false',
  });
  if (desde !== null) q.set('since', String(desde));
  const r = await http(`https://lichess.org/api/games/user/${encodeURIComponent(usuario)}?${q}`, {
    headers: { Accept: 'application/x-ndjson', 'User-Agent': AGENTE },
  });
  if (r.status === 404) return [];
  if (r.status === 429) throw new ErroFonte('lichess', 'limite', 429);
  if (r.status !== 200) throw new ErroFonte('lichess', 'fora', r.status);
  const linhas = (await r.text()).split('\n').filter((l) => l.trim());
  const saida: PartidaBruta[] = [];
  for (const l of linhas) {
    const p = partidaDoLichess(JSON.parse(l) as PartidaLichess, usuario);
    if (p) saida.push(p);
  }
  return saida;
}

// ---------------------------------------------------------------- chess.com

interface JogadorChesscom {
  username?: string;
  rating?: number;
  result?: string;
}
interface PartidaChesscom {
  url?: string;
  pgn?: string;
  time_control?: string;
  end_time?: number;
  time_class?: string;
  rules?: string;
  white?: JogadorChesscom;
  black?: JogadorChesscom;
}

const EMPATES_CHESSCOM = new Set([
  'agreed',
  'repetition',
  'stalemate',
  'insufficient',
  '50move',
  'timevsinsufficient',
]);

/** "180+2" → "3+2"; "60" → "1+0"; diária ("1/86400") → null. */
function cadenciaChesscom(tc: string): string | null {
  if (tc.includes('/')) return null;
  const [ini, inc] = tc.split('+');
  const s = Number(ini);
  if (!Number.isFinite(s)) return null;
  return cadencia(s, Number(inc ?? 0) || 0);
}

/** "https://www.chess.com/openings/Sicilian-Defense-Najdorf-Variation-6.Be3" → "Sicilian Defense Najdorf Variation". */
export function nomeDaAberturaChesscom(ecoUrl: string | null): string {
  if (!ecoUrl) return '';
  const slug = decodeURIComponent(ecoUrl.split('/').pop() ?? '');
  const semLances = slug.replace(/-\d+\..*$/, '').replace(/-\d+$/, '');
  return semLances.replace(/-/g, ' ').trim();
}

export function partidaDoChesscom(p: PartidaChesscom, usuario: string): PartidaBruta | null {
  if ((p.rules ?? 'chess') !== 'chess') return null;
  const ritmo = ritmoDe(p.time_class === 'rapid' ? 'rapid' : (p.time_class ?? ''));
  const cad = cadenciaChesscom(p.time_control ?? '');
  if (!ritmo || !cad || !p.pgn || !p.url || !p.white || !p.black) return null;
  if (tag(p.pgn, 'SetUp') === '1') return null;
  if (meioLancesDoPgn(p.pgn) < MEIO_LANCES_MINIMOS) return null;
  const eu = usuario.toLowerCase();
  let cor: Cor;
  if ((p.white.username ?? '').toLowerCase() === eu) cor = 'brancas';
  else if ((p.black.username ?? '').toLowerCase() === eu) cor = 'pretas';
  else return null;
  const meu = cor === 'brancas' ? p.white : p.black;
  const dele = cor === 'brancas' ? p.black : p.white;
  let resultado: Resultado = 'derrota';
  if (meu.result === 'win') resultado = 'vitoria';
  else if (EMPATES_CHESSCOM.has(meu.result ?? '')) resultado = 'empate';
  const idExterno = p.url.split('/').pop() ?? '';
  const eco = tag(p.pgn, 'ECO');
  return {
    id: `chesscom_${idExterno}`,
    plataforma: 'chesscom',
    idExterno,
    url: p.url,
    jogadaEm: new Date((p.end_time ?? 0) * 1000),
    ritmo,
    cadencia: cad,
    cor,
    adversario: { nome: dele.username ?? 'Anônimo', rating: dele.rating ?? null },
    rating: meu.rating ?? null,
    resultado,
    abertura: eco ? { eco, nome: nomeDaAberturaChesscom(tag(p.pgn, 'ECOUrl')) } : null,
    pgn: p.pgn.trim(),
  };
}

async function getChesscom(http: Http, url: string): Promise<unknown | null> {
  const r = await http(url, { headers: { Accept: 'application/json', 'User-Agent': AGENTE } });
  if (r.status === 404 || r.status === 410) return null;
  if (r.status === 429) throw new ErroFonte('chesscom', 'limite', 429);
  if (r.status !== 200) throw new ErroFonte('chesscom', 'fora', r.status);
  return JSON.parse(await r.text());
}

export async function usuarioChesscom(http: Http, usuario: string): Promise<string | null> {
  const j = (await getChesscom(
    http,
    `https://api.chess.com/pub/player/${encodeURIComponent(usuario.toLowerCase())}`,
  )) as { username?: string; status?: string } | null;
  if (!j?.username || (j.status ?? '').startsWith('closed')) return null;
  return j.username;
}

/** Partidas terminadas depois de `desde` (ms), mais novas primeiro, até `max`. Lê o mês atual e, se faltar, o anterior. */
export async function partidasChesscom(
  http: Http,
  usuario: string,
  desde: number | null,
  max: number,
): Promise<PartidaBruta[]> {
  const nome = encodeURIComponent(usuario.toLowerCase());
  const arq = (await getChesscom(http, `https://api.chess.com/pub/player/${nome}/games/archives`)) as {
    archives?: string[];
  } | null;
  const meses = (arq?.archives ?? []).slice(-2).reverse();
  const saida: PartidaBruta[] = [];
  for (const url of meses) {
    const mes = (await getChesscom(http, url)) as { games?: PartidaChesscom[] } | null;
    const jogos = [...(mes?.games ?? [])].sort((a, b) => (b.end_time ?? 0) - (a.end_time ?? 0));
    let antigas = false;
    for (const g of jogos) {
      if (desde !== null && (g.end_time ?? 0) * 1000 <= desde) {
        antigas = true;
        break;
      }
      const p = partidaDoChesscom(g, usuario);
      if (p) saida.push(p);
      if (saida.length >= max) return saida;
    }
    if (antigas) break;
  }
  return saida;
}

// ---------------------------------------------------------------- comum

export function conferirUsuario(http: Http, plataforma: Plataforma, usuario: string): Promise<string | null> {
  return plataforma === 'lichess' ? usuarioLichess(http, usuario) : usuarioChesscom(http, usuario);
}

export function buscarPartidas(
  http: Http,
  plataforma: Plataforma,
  usuario: string,
  desde: number | null,
  max: number,
): Promise<PartidaBruta[]> {
  return plataforma === 'lichess'
    ? partidasLichess(http, usuario, desde, max)
    : partidasChesscom(http, usuario, desde, max);
}

/** O fetch do Node como `Http`. */
export const httpReal: Http = (url, init) => fetch(url, { headers: init?.headers });
