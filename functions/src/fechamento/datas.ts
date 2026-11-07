// Dias no fuso de Brasília (R5 §2: "dias usam o fuso de Brasília em tudo").
import { FUSO } from '../comum/config';

const formato = new Intl.DateTimeFormat('en-CA', {
  timeZone: FUSO,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hourCycle: 'h23',
});

function partes(instante: Date): Record<string, number> {
  const p: Record<string, number> = {};
  for (const { type, value } of formato.formatToParts(instante)) {
    if (type !== 'literal') p[type] = Number(value);
  }
  return p;
}

/** `aaaa-mm-dd` do instante em Brasília. */
export function diaLocal(instante: Date): string {
  const p = partes(instante);
  return `${p.year}-${String(p.month).padStart(2, '0')}-${String(p.day).padStart(2, '0')}`;
}

/** Hora (0–23) do instante em Brasília. */
export function horaLocal(instante: Date): number {
  return partes(instante).hour;
}

/** Soma [n] dias a um `aaaa-mm-dd` (calendário, sem fuso). */
export function somarDias(dia: string, n: number): string {
  const d = new Date(`${dia}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
}

/** Meia-noite de Brasília do dia, como instante UTC. */
export function inicioDoDia(dia: string): Date {
  const meioDiaUtc = new Date(`${dia}T12:00:00Z`);
  const p = partes(meioDiaUtc);
  const comoUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second);
  const deslocamento = comoUtc - meioDiaUtc.getTime();
  return new Date(Date.parse(`${dia}T00:00:00Z`) - deslocamento);
}

/** `aaaammdd`, o sufixo das tabelas do export do Analytics. */
export function sufixo(dia: string): string {
  return dia.replaceAll('-', '');
}

/** Último dia do mês? (o fechamento dele também fecha o mês). */
export function ultimoDoMes(dia: string): boolean {
  return somarDias(dia, 1).slice(0, 7) !== dia.slice(0, 7);
}
