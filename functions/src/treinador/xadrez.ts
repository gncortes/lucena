// T87 · Apoio de xadrez sobre o chess.js: avaliação em chance de vitória, precisão, notação em português,
// material e temas que o motor confirma com segurança.
import { Chess, type Color, type PieceSymbol, type Square } from 'chess.js';

export const VALOR: Record<PieceSymbol, number> = { p: 1, n: 3, b: 3, r: 5, q: 9, k: 100 };

const NOME: Record<PieceSymbol, { nome: string; art: 'o' | 'a' }> = {
  p: { nome: 'peão', art: 'o' },
  n: { nome: 'cavalo', art: 'o' },
  b: { nome: 'bispo', art: 'o' },
  r: { nome: 'torre', art: 'a' },
  q: { nome: 'dama', art: 'a' },
  k: { nome: 'rei', art: 'o' },
};

/** "a torre branca em a1". */
export function pecaEm(tipo: PieceSymbol, cor: Color, casa: string): string {
  const n = NOME[tipo];
  const adj = n.art === 'a' ? (cor === 'w' ? 'branca' : 'preta') : cor === 'w' ? 'branco' : 'preto';
  return `${n.art} ${n.nome} ${adj} em ${casa}`;
}

export function nomePeca(tipo: PieceSymbol): string {
  return `${NOME[tipo].art} ${NOME[tipo].nome}`;
}

/** Centipeões (ou mate) → chance de vitória 0–100 de quem tem a nota (fórmula do Lichess, nota limitada a ±1000). */
export function chance(cp: number | null, mate: number | null): number {
  let c: number;
  if (mate !== null) c = mate > 0 ? 1000 : -1000;
  else c = Math.max(-1000, Math.min(1000, cp ?? 0));
  return 50 + 50 * (2 / (1 + Math.exp(-0.00368208 * c)) - 1);
}

/** Precisão do lance (0–100) pela perda de chance (fórmula do Lichess). */
export function precisaoDoLance(perda: number): number {
  const v = 103.1668 * Math.exp(-0.04354 * Math.max(0, perda)) - 3.1669;
  return Math.max(0, Math.min(100, v));
}

/** Precisão da partida: média entre a média simples e a harmônica (pune erro grave como o Lichess). */
export function precisaoMedia(valores: number[]): number | null {
  if (!valores.length) return null;
  const media = valores.reduce((a, b) => a + b, 0) / valores.length;
  const harm = valores.length / valores.reduce((a, b) => a + 1 / Math.max(1, b), 0);
  return Math.round((media + harm) / 2);
}

/** SAN inglês → notação em português (R, D, T, B, C). */
export function sanPt(san: string): string {
  const mapa: Record<string, string> = { K: 'R', Q: 'D', R: 'T', B: 'B', N: 'C' };
  let s = san.replace(/^[KQRBN]/, (c) => mapa[c]);
  s = s.replace(/=([QRBN])/, (_, c: string) => `=${mapa[c]}`);
  return s;
}

/** "14.Cf3" ou "14...Cf6" a partir do FEN antes do lance. */
export function lanceNumerado(fenAntes: string, san: string): string {
  const [, vez, , , , num] = fenAntes.split(' ');
  return `${num}${vez === 'w' ? '.' : '...'}${sanPt(san)}`;
}

/** Número do lance ("Lance 8") a partir do FEN antes dele. */
export function numeroDoLance(fenAntes: string): number {
  return Number(fenAntes.split(' ')[5]) || 1;
}

export function uciParaSan(fen: string, uci: string): string | null {
  try {
    const c = new Chess(fen);
    const m = c.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
    return m.san;
  } catch {
    return null;
  }
}

/** Linha de lances UCI em notação numerada ("15...Dxd4 16.Txd4"), até `max` meios-lances. */
export function linhaPt(fen: string, pv: string[], max: number): string {
  const c = new Chess(fen);
  const partes: string[] = [];
  for (const uci of pv.slice(0, max)) {
    const antes = c.fen();
    let m;
    try {
      m = c.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
    } catch {
      break;
    }
    const vez = antes.split(' ')[1];
    partes.push(vez === 'w' || !partes.length ? lanceNumerado(antes, m.san) : sanPt(m.san));
  }
  return partes.join(' ');
}

/** Peças (sem reis e peões) no tabuleiro. */
export function pecasMaiores(fen: string): number {
  const campo = fen.split(' ')[0];
  return (campo.match(/[qrbnQRBN]/g) ?? []).length;
}

/** Final: até 6 peças (sem reis e peões). */
export function ehFinal(fen: string): boolean {
  return pecasMaiores(fen) <= 6;
}

export type Tema =
  | 'mate'
  | 'garfo'
  | 'peca_solta'
  | 'xeque_duplo'
  | 'xeque_descoberto'
  | 'promocao'
  | 'final_peoes'
  | 'final_torres'
  | 'final_pecas_menores'
  | 'final_dama'
  | 'final';

export const TEMAS_TATICOS: readonly Tema[] = ['mate', 'garfo', 'peca_solta', 'xeque_duplo', 'xeque_descoberto', 'promocao'];

function tipoDeFinal(fen: string): Tema | null {
  if (!ehFinal(fen)) return null;
  const campo = fen.split(' ')[0].toLowerCase();
  const q = (campo.match(/q/g) ?? []).length;
  const r = (campo.match(/r/g) ?? []).length;
  const m = (campo.match(/[bn]/g) ?? []).length;
  if (q + r + m === 0) return 'final_peoes';
  if (q > 0 && r + m === 0) return 'final_dama';
  if (r > 0 && q + m === 0) return 'final_torres';
  if (m > 0 && q + r === 0) return 'final_pecas_menores';
  return 'final';
}

export interface Achado {
  tema: Tema | null;
  /** Detalhes para a fala (casas e peças envolvidas). */
  peca?: string;
  alvos?: string[];
  casa?: string;
}

function mover(c: Chess, uci: string) {
  return c.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] });
}

/**
 * Tema do lance `pv[0]` na posição `fen`, confirmado pela linha do motor.
 * Só devolve tema quando o padrão é inequívoco; senão, tema de final pelo material ou null.
 */
export function detectarTema(fen: string, pv: string[], mate: number | null): Achado {
  if (!pv.length) return { tema: tipoDeFinal(fen) };
  if (mate !== null && mate > 0 && mate <= 5) return { tema: 'mate' };
  const c = new Chess(fen);
  const eu = c.turn();
  const ele: Color = eu === 'w' ? 'b' : 'w';
  let m;
  try {
    m = mover(c, pv[0]);
  } catch {
    return { tema: null };
  }
  // Xeque duplo e descoberto.
  if (c.isCheck()) {
    const rei = c.findPiece({ type: 'k', color: ele })[0];
    const atacantes = rei ? c.attackers(rei, eu) : [];
    if (atacantes.length >= 2) return { tema: 'xeque_duplo', peca: pecaEm(m.piece, eu, m.to) };
    if (!atacantes.includes(m.to as Square)) return { tema: 'xeque_descoberto', peca: pecaEm(m.piece, eu, m.to) };
  }
  // Garfo: a peça que chegou ataca duas peças valiosas (ou sem defensor, ou o rei) e a linha captura uma delas.
  const alvos: { casa: Square; tipo: PieceSymbol }[] = [];
  for (const linha of c.board()) {
    for (const p of linha) {
      if (!p || p.color !== ele) continue;
      const atac = c.attackers(p.square, eu);
      if (!atac.includes(m.to as Square)) continue;
      const defendida = c.attackers(p.square, ele).length > 0;
      if (p.type === 'k' || VALOR[p.type] > VALOR[m.piece] || !defendida) alvos.push({ casa: p.square, tipo: p.type });
    }
  }
  if (alvos.length >= 2 && pv.length >= 3) {
    const c2 = new Chess(c.fen());
    try {
      mover(c2, pv[1]);
      const terceiro = mover(c2, pv[2]);
      const alvo = alvos.find((a) => a.casa === terceiro.to && a.tipo !== 'k');
      if (terceiro.captured && alvo) {
        return {
          tema: 'garfo',
          peca: pecaEm(m.piece, eu, m.to),
          alvos: alvos.map((a) => pecaEm(a.tipo, ele, a.casa)),
        };
      }
    } catch {
      /* linha curta: sem tema */
    }
  }
  // Peça solta: captura de peça que não tinha defensor.
  if (m.captured) {
    const antes = new Chess(fen);
    const defensores = antes.attackers(m.to as Square, ele);
    if (defensores.length === 0 && m.captured !== 'p') {
      return { tema: 'peca_solta', casa: m.to, peca: pecaEm(m.captured, ele, m.to) };
    }
  }
  // Promoção: o lance ou o próximo do mesmo lado promove.
  if (m.promotion) return { tema: 'promocao' };
  if (pv.length >= 3) {
    const c3 = new Chess(c.fen());
    try {
      mover(c3, pv[1]);
      if (mover(c3, pv[2]).promotion) return { tema: 'promocao' };
    } catch {
      /* sem tema */
    }
  }
  return { tema: tipoDeFinal(fen) };
}

export function lancesLegais(fen: string): number {
  return new Chess(fen).moves().length;
}

export { Chess };
