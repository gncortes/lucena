// H-R5-36 · Ativos de um período personalizado (R5 §1 e §11 R12): os resumos do dia guardam só as janelas fixas
// (7, 15, 30 dias…); no "Personalizado" o painel pede aqui as pessoas distintas, numa consulta só ao BigQuery.
import { HttpsError } from 'firebase-functions/https';
import { diaLocal, somarDias } from './datas';

/** Primeiro dia com dados (lançamento do app). */
export const LANCAMENTO = '2026-11-05';
export const MAXIMO_DIAS = 366;

const DIA = /^\d{4}-\d{2}-\d{2}$/;

export interface Periodo {
  inicio: string;
  fim: string;
}

/** Conta as pessoas distintas ativas de `inicio` a `fim` (aaaa-mm-dd, inclusive). */
export interface FonteAtivos {
  ativosEntre(inicio: string, fim: string): Promise<number>;
}

function diaValido(v: unknown): v is string {
  return typeof v === 'string' && DIA.test(v) && somarDias(v, 0) === v;
}

/** Dias do período, contando as duas pontas. */
export function diasDoPeriodo(p: Periodo): number {
  return Math.round((Date.parse(`${p.fim}T00:00:00Z`) - Date.parse(`${p.inicio}T00:00:00Z`)) / 86_400_000) + 1;
}

/** As regras do calendário do painel: início ≥ lançamento, fim ≤ ontem (Brasília), até 366 dias. */
export function validarPeriodo(dados: unknown, agora: Date): Periodo {
  const { inicio, fim } = (dados ?? {}) as Record<string, unknown>;
  if (!diaValido(inicio) || !diaValido(fim)) {
    throw new HttpsError('invalid-argument', 'Período com datas inválidas (aaaa-mm-dd).');
  }
  if (inicio > fim) throw new HttpsError('invalid-argument', 'O início vem depois do fim.');
  if (inicio < LANCAMENTO) throw new HttpsError('invalid-argument', `Não há dados antes de ${LANCAMENTO}.`);
  const ontem = somarDias(diaLocal(agora), -1);
  if (fim > ontem) throw new HttpsError('invalid-argument', 'O período só vai até ontem.');
  if (diasDoPeriodo({ inicio, fim }) > MAXIMO_DIAS) {
    throw new HttpsError('invalid-argument', `O período tem mais de ${MAXIMO_DIAS} dias.`);
  }
  return { inicio, fim };
}

export interface AtivosPeriodo extends Periodo {
  dias: number;
  ativos: number;
}

export async function ativosPeriodoCore(fonte: FonteAtivos, dados: unknown, agora: Date): Promise<AtivosPeriodo> {
  const p = validarPeriodo(dados, agora);
  return { ...p, dias: diasDoPeriodo(p), ativos: await fonte.ativosEntre(p.inicio, p.fim) };
}
