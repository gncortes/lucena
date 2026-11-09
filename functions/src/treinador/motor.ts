// T87 · Stockfish 19 lite (WASM, 1 thread) por nós fixos, num processo filho UCI.
// O motor vem em `functions/motor/` (GPL-3, ver COPYING-stockfish.txt) e sobe com o deploy.
import { spawn, type ChildProcessWithoutNullStreams } from 'node:child_process';
import path from 'node:path';

export const VERSAO_MOTOR = 'Stockfish 19 lite';

/** Uma linha do MultiPV, com a nota do ponto de vista de quem joga. */
export interface Linha {
  uci: string;
  cp: number | null;
  mate: number | null;
  pv: string[];
}

export interface Motor {
  /** Linhas da posição (MultiPV), a melhor primeiro. Sem lances legais: []. */
  analisar(fen: string, nos: number, multipv?: number): Promise<Linha[]>;
  fechar(): Promise<void>;
}

function arquivoDoMotor(): string {
  // lib/src/treinador/motor.js → functions/motor/
  return path.resolve(__dirname, '..', '..', '..', 'motor', 'stockfish-19-lite-single.js');
}

/** Lê a linha `info` do UCI. */
export function lerInfo(linha: string): { multipv: number; cp: number | null; mate: number | null; pv: string[] } | null {
  if (!linha.startsWith('info ') || !linha.includes(' pv ') || linha.includes(' bound ')) return null;
  const t = linha.split(' ');
  let multipv = 1;
  let cp: number | null = null;
  let mate: number | null = null;
  for (let i = 0; i < t.length; i++) {
    if (t[i] === 'multipv') multipv = Number(t[i + 1]);
    if (t[i] === 'score') {
      if (t[i + 1] === 'cp') cp = Number(t[i + 2]);
      if (t[i + 1] === 'mate') mate = Number(t[i + 2]);
    }
  }
  const pv = t.slice(t.indexOf('pv') + 1);
  return { multipv, cp, mate, pv };
}

/** Sobe um Stockfish UCI e o deixa pronto para várias posições (hash limpo a cada partida). */
export async function abrirMotor(arquivo = arquivoDoMotor()): Promise<Motor> {
  const proc: ChildProcessWithoutNullStreams = spawn(process.execPath, [arquivo], { stdio: 'pipe' });
  let buffer = '';
  let ouvinte: ((l: string) => void) | null = null;
  let erro: Error | null = null;
  proc.stdout.setEncoding('utf8');
  proc.stdout.on('data', (d: string) => {
    buffer += d;
    let i: number;
    while ((i = buffer.indexOf('\n')) >= 0) {
      const l = buffer.slice(0, i).trim();
      buffer = buffer.slice(i + 1);
      if (l && ouvinte) ouvinte(l);
    }
  });
  proc.on('error', (e) => (erro = e));
  proc.on('exit', (c) => (erro ??= new Error(`motor saiu (${c})`)));

  const enviar = (s: string) => proc.stdin.write(`${s}\n`);
  const esperar = (fim: (l: string) => boolean, cada?: (l: string) => void, ms = 120_000) =>
    new Promise<void>((ok, falha) => {
      const t = setTimeout(() => falha(new Error('motor sem resposta')), ms);
      ouvinte = (l) => {
        cada?.(l);
        if (fim(l)) {
          clearTimeout(t);
          ouvinte = null;
          ok();
        }
      };
      if (erro) falha(erro);
    });

  enviar('uci');
  await esperar((l) => l === 'uciok');
  enviar('setoption name Hash value 32');
  enviar('setoption name Threads value 1');
  enviar('isready');
  await esperar((l) => l === 'readyok');

  let multipvAtual = 1;
  return {
    async analisar(fen, nos, multipv = 1) {
      if (erro) throw erro;
      if (multipv !== multipvAtual) {
        enviar(`setoption name MultiPV value ${multipv}`);
        multipvAtual = multipv;
      }
      const linhas = new Map<number, Linha>();
      enviar(`position fen ${fen}`);
      enviar(`go nodes ${nos}`);
      let melhor = '';
      await esperar(
        (l) => l.startsWith('bestmove'),
        (l) => {
          const info = lerInfo(l);
          if (info && info.pv.length) {
            linhas.set(info.multipv, { uci: info.pv[0], cp: info.cp, mate: info.mate, pv: info.pv });
          }
          if (l.startsWith('bestmove')) melhor = l.split(' ')[1] ?? '';
        },
      );
      if (!melhor || melhor === '(none)') return [];
      return [...linhas.entries()].sort((a, b) => a[0] - b[0]).map((e) => e[1]);
    },
    async fechar() {
      if (proc.exitCode === null) {
        enviar('quit');
        await new Promise<void>((ok) => {
          const t = setTimeout(() => {
            proc.kill();
            ok();
          }, 2000);
          proc.once('exit', () => {
            clearTimeout(t);
            ok();
          });
        });
      }
    },
  };
}
