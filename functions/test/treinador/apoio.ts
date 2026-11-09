// T87 · Apoio dos testes do treinador: HTTP falso com as respostas gravadas do Lichess e do chess.com.
import fs from 'node:fs';
import path from 'node:path';
import type { Http } from '../../src/treinador/fontes';

export const FIXTURES = path.resolve(__dirname, '..', '..', '..', 'test', 'fixtures');

export const NDJSON_LICHESS = fs.readFileSync(path.join(FIXTURES, 'lichess-drnykterstein.ndjson'), 'utf8');
export const MES_CHESSCOM = fs.readFileSync(path.join(FIXTURES, 'chesscom-hikaru-mes.json'), 'utf8');

export interface Pedido {
  url: string;
  headers: Record<string, string>;
}

/** HTTP falso: DrNykterstein no Lichess, hikaru no chess.com (um mês), o resto 404. `status` força uma resposta. */
export function httpFalso(pedidos: Pedido[] = [], status: number | null = null): Http {
  return async (url, init) => {
    pedidos.push({ url, headers: init?.headers ?? {} });
    const r = (s: number, corpo = '') => ({ status: s, text: async () => corpo });
    if (status !== null) return r(status);
    if (url === 'https://lichess.org/api/user/DrNykterstein' || url === 'https://lichess.org/api/user/drnykterstein') {
      return r(200, JSON.stringify({ id: 'drnykterstein', username: 'DrNykterstein' }));
    }
    if (url.startsWith('https://lichess.org/api/games/user/DrNykterstein?')) {
      const q = new URL(url).searchParams;
      const desde = Number(q.get('since') ?? 0);
      const max = Number(q.get('max') ?? 100);
      const linhas = NDJSON_LICHESS.split('\n')
        .filter((l) => l.trim())
        .filter((l) => (JSON.parse(l).createdAt as number) >= desde)
        .slice(0, max);
      return r(200, linhas.join('\n'));
    }
    if (url === 'https://api.chess.com/pub/player/hikaru') return r(200, JSON.stringify({ username: 'Hikaru', status: 'premium' }));
    if (url === 'https://api.chess.com/pub/player/hikaru/games/archives') {
      return r(200, JSON.stringify({ archives: ['https://api.chess.com/pub/player/hikaru/games/2026/11'] }));
    }
    if (url === 'https://api.chess.com/pub/player/hikaru/games/2026/11') return r(200, MES_CHESSCOM);
    return r(404);
  };
}
