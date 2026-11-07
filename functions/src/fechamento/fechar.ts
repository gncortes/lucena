// H-R5-34 · `fechamentoDia` e o lote de hora em hora (`painel/hoje`), R5 §2 e §11 R18.
// O dia fechado não muda: o documento é criado numa transação que desiste se ele já existe.
import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { CURSOS } from '../comum/cursos';
import { lerPontosAtencao, type FonteAtencao, type PontosAtencao } from './atencao';
import type { LinhaEvento } from './consultas';
import { diaLocal, horaLocal, inicioDoDia, somarDias, ultimoDoMes } from './datas';
import {
  contar,
  montarRelatorio,
  montarResumoDia,
  somarNoMes,
  VERSAO_ESQUEMA,
  type Arvore,
  type Compra,
  type EstadoAnalytics,
  type ResumoMes,
} from './resumo';

/** O export do Analytics (BigQuery em produção, fixture nos testes). */
export interface Analytics {
  /** A tabela `events_aaaammdd` do dia já existe? */
  exportPronto(dia: string): Promise<boolean>;
  linhasDoDia(dia: string): Promise<LinhaEvento[]>;
  /** Linhas da tabela `events_intraday_` de hoje; null se ela não existe. */
  linhasDeHoje(dia: string): Promise<LinhaEvento[] | null>;
  /** Pessoas ativas nas janelas (nome → dias) que terminam no dia. */
  ativos(dia: string, janelas: Record<string, number>): Promise<Record<string, number>>;
}

export interface DepsFechamento {
  db: Firestore;
  analytics: Analytics;
  agora: Date;
  /** Funis e telas (H-R5-35); sem ela, o dia fecha com `pontosAtencao` vazio. */
  atencao?: FonteAtencao;
}

/** Depois desta hora (Brasília) o dia fecha mesmo sem o Analytics. */
export const HORA_LIMITE = 14;

const JANELAS_DIA = { ativos7: 7, ativos15: 15, ativos30: 30, ativos45: 45 };

function janelasDoMes(dia: string): Record<string, number> {
  return { ativosMes: Number(dia.slice(8, 10)), ativos3m: 90, ativos6m: 180, ativos12m: 365 };
}

/** Cursos liberados no intervalo, de `acessos` (revogados não contam). */
export async function lerCompras(db: Firestore, inicio: Date, fim: Date): Promise<Compra[]> {
  const compras: Compra[] = [];
  for (const curso of Object.keys(CURSOS)) {
    const campo = `cursos.${curso}.dadoEm`;
    const snap = await db
      .collection('acessos')
      .where(campo, '>=', Timestamp.fromDate(inicio))
      .where(campo, '<', Timestamp.fromDate(fim))
      .get();
    for (const doc of snap.docs) {
      const a = doc.get(`cursos.${curso}`) as Record<string, unknown> | undefined;
      if (!a || a.revogadoEm) continue;
      compras.push({
        curso,
        origem: String(a.origem ?? 'compra'),
        plano: String(a.plano ?? 'vitalicio'),
        pais: String(a.pais ?? 'ZZ'),
        receitaCentavos: typeof a.receitaCentavos === 'number' ? a.receitaCentavos : 0,
      });
    }
  }
  return compras;
}

export type ResultadoFechamento = { dia: string; estado: 'jaFechado' | 'atrasado' | 'ok' | 'incompleto' };

/** Fecha ontem (Brasília). Roda às 03:00 e de hora em hora até 14:00. */
export async function fecharDia(d: DepsFechamento): Promise<ResultadoFechamento> {
  const dia = somarDias(diaLocal(d.agora), -1);
  const refDia = d.db.doc(`resumosDia/${dia}`);
  if ((await refDia.get()).exists) return { dia, estado: 'jaFechado' };

  const pronto = await d.analytics.exportPronto(dia);
  if (!pronto && horaLocal(d.agora) < HORA_LIMITE) {
    const proxima = new Date(d.agora.getTime() + 3600_000);
    proxima.setUTCMinutes(0, 0, 0);
    await d.db.doc('painel/fechamento').set({
      dia,
      estado: 'atrasado',
      tentativaEm: Timestamp.fromDate(d.agora),
      proximaTentativa: Timestamp.fromDate(proxima),
    });
    return { dia, estado: 'atrasado' };
  }

  const fimDoMes = ultimoDoMes(dia);
  const janelas = fimDoMes ? { ...JANELAS_DIA, ...janelasDoMes(dia) } : JANELAS_DIA;
  const [linhas, todosAtivos, compras] = await Promise.all([
    pronto ? d.analytics.linhasDoDia(dia) : Promise.resolve([]),
    pronto ? d.analytics.ativos(dia, janelas) : Promise.resolve({} as Record<string, number>),
    lerCompras(d.db, inicioDoDia(dia), inicioDoDia(somarDias(dia, 1))),
  ]);
  const ativosDia: Record<string, number> = {};
  const ativosMes: Record<string, number> = {};
  for (const [k, v] of Object.entries(todosAtivos)) {
    if (k in JANELAS_DIA) ativosDia[k] = v;
    else ativosMes[k] = v;
  }
  const estado = pronto ? 'ok' : 'incompleto';
  let analytics: EstadoAnalytics = estado;
  let pontosAtencao: PontosAtencao | null = null;
  if (pronto && d.atencao) {
    try {
      pontosAtencao = await lerPontosAtencao(d.atencao, dia);
    } catch (e) {
      console.warn(`pontos de atenção de ${dia}: ${(e as Error).message}`);
      analytics = 'atrasado';
    }
  }

  return d.db.runTransaction(async (tx) => {
    if ((await tx.get(refDia)).exists) return { dia, estado: 'jaFechado' as const };
    const anteriores = await tx.get(
      d.db
        .collection('resumosDia')
        .where('dia', '<', dia)
        .orderBy('dia', 'desc')
        .limit(1),
    );
    const refMes = d.db.doc(`resumosMes/${dia.slice(0, 7)}`);
    const mesSnap = await tx.get(refMes);

    const resumo = montarResumoDia({
      dia,
      contadores: contar(linhas, compras),
      ativos: ativosDia,
      acumAnterior: anteriores.empty ? null : ((anteriores.docs[0].get('acum') as Arvore) ?? null),
      analytics,
      fechadoEm: d.agora,
      pontosAtencao,
    });
    const mes = somarNoMes(mesSnap.exists ? paraMes(mesSnap.data()!) : null, resumo, ativosMes);
    const { relatorio, cortado } = montarRelatorio(resumo);

    tx.create(refDia, resumo);
    tx.set(refMes, mes);
    tx.set(d.db.doc(`relatorios/${dia}`), { ...relatorio, cortado });
    tx.set(d.db.doc('painel/fechamento'), {
      dia,
      estado,
      fechadoEm: Timestamp.fromDate(d.agora),
    });
    return { dia, estado };
  });
}

function paraMes(dados: Record<string, unknown>): ResumoMes {
  const em = dados.atualizadoEm;
  return { ...(dados as unknown as ResumoMes), atualizadoEm: em instanceof Timestamp ? em.toDate() : new Date(0) };
}

/** Lote de hora em hora: só `painel/hoje` (a tabela intraday e as compras de hoje até agora). */
export async function atualizarHoje(d: DepsFechamento): Promise<{ dia: string; analytics: 'ok' | 'atrasado' }> {
  const dia = diaLocal(d.agora);
  const [linhas, compras] = await Promise.all([
    d.analytics.linhasDeHoje(dia),
    lerCompras(d.db, inicioDoDia(dia), d.agora),
  ]);
  const analytics = linhas === null ? 'atrasado' : 'ok';
  await d.db.doc('painel/hoje').set({
    dia,
    atualizadoEm: Timestamp.fromDate(d.agora),
    versaoEsquema: VERSAO_ESQUEMA,
    fontes: { analytics, play: 'ok' },
    ...contar(linhas ?? [], compras),
  });
  return { dia, analytics };
}
