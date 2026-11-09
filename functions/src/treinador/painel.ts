// T87 · Agregados do painel: `treinador_painel/dia-AAAA-MM-DD` (somas do dia) e `treinador_painel/estado`.
// Formato no contrato (docs/tasks/T87-treinador.md, "Formato de treinador_painel/*").
import { FieldValue, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { diaBR, diasNoMes, mesBR, type Plano } from './politica';
import type { Exercicio } from './tipos';

export type MotivoFalha = 'variante' | 'tempo' | 'lichess429' | 'pgn' | 'outro';

const MAX_FALHAS = 50;
const MAX_TEMPOS = 500;

function refDia(db: Firestore, agora: Date) {
  return db.doc(`treinador_painel/dia-${diaBR(agora)}`);
}

/** Soma uma análise pronta no dia corrente. */
export async function somarAnalise(
  db: Firestore,
  agora: Date,
  uid: string,
  plano: Plano,
  exercicios: Exercicio[],
  custo: number,
  minutosAtePronta: number | null,
): Promise<void> {
  const chave = plano === 'assinante' ? 'pagas' : 'gratis';
  const inc = FieldValue.increment;
  const porTipo: Record<string, unknown> = {};
  for (const e of exercicios) {
    const t = (porTipo[e.tipo] ??= { gerados: 0, estrelas: 0 }) as { gerados: number; estrelas: number };
    t.gerados++;
    t.estrelas += e.estrelas;
  }
  const doc: Record<string, unknown> = {
    data: diaBR(agora),
    atualizadoEm: Timestamp.fromDate(agora),
    partidas: { [chave]: inc(1) },
    exercicios: { gerados: inc(exercicios.length) },
    porTipo: Object.fromEntries(
      Object.entries(porTipo).map(([k, v]) => {
        const t = v as { gerados: number; estrelas: number };
        return [k, { gerados: inc(t.gerados), estrelas: inc(t.estrelas) }];
      }),
    ),
    custoUsd: { [chave]: inc(custo) },
  };
  if (plano === 'assinante') doc.funil = { analisadas: inc(1) };
  else doc.uidsGratis = FieldValue.arrayUnion(uid);
  const ref = refDia(db, agora);
  await ref.set(doc, { merge: true });
  await db.runTransaction(async (t) => {
    const s = await t.get(ref);
    const tempos = ((s.get('temposPushMin') as number[] | undefined) ?? []).slice(-(MAX_TEMPOS - 1));
    if (minutosAtePronta !== null) tempos.push(Math.round(minutosAtePronta * 10) / 10);
    const uids = (s.get('uidsGratis') as string[] | undefined) ?? [];
    t.set(ref, { temposPushMin: tempos, gratisComAnalise: uids.length }, { merge: true });
  });
}

export async function somarContaNova(db: Firestore, agora: Date): Promise<void> {
  await refDia(db, agora).set(
    { data: diaBR(agora), atualizadoEm: Timestamp.fromDate(agora), contas: { novas: FieldValue.increment(1) } },
    { merge: true },
  );
}

/** Mudança no `progresso` espelhado pelo app: funil e exercícios feitos (só o que aumentou). */
export async function somarProgresso(
  db: Firestore,
  agora: Date,
  antes: { feitos: number; acertos: number } | null,
  depois: { feitos: number; acertos: number },
  totalExercicios: number,
  paga: boolean,
): Promise<void> {
  const inc = FieldValue.increment;
  const dFeitos = Math.max(0, depois.feitos - (antes?.feitos ?? 0));
  const dAcertos = Math.max(0, depois.acertos - (antes?.acertos ?? 0));
  const funil: Record<string, unknown> = {};
  if (paga) {
    if (!antes) funil.abriram = inc(1);
    if ((antes?.feitos ?? 0) === 0 && depois.feitos > 0) funil.comecaram = inc(1);
    if (totalExercicios > 0 && (antes?.feitos ?? 0) < totalExercicios && depois.feitos >= totalExercicios) {
      funil.terminaram = inc(1);
    }
  }
  if (!dFeitos && !dAcertos && !Object.keys(funil).length) return;
  await refDia(db, agora).set(
    {
      data: diaBR(agora),
      atualizadoEm: Timestamp.fromDate(agora),
      exercicios: { feitos: inc(dFeitos), acertos: inc(dAcertos) },
      ...(Object.keys(funil).length ? { funil } : {}),
    },
    { merge: true },
  );
}

/** Falha de uma análise: conta no dia e entra em `estado.falhasHoje` (até 50, zera na virada do dia). */
export async function registrarFalha(
  db: Firestore,
  agora: Date,
  uid: string,
  partida: string,
  motivo: MotivoFalha,
): Promise<void> {
  await refDia(db, agora).set(
    { data: diaBR(agora), atualizadoEm: Timestamp.fromDate(agora), falhas: FieldValue.increment(1) },
    { merge: true },
  );
  const ref = db.doc('treinador_painel/estado');
  await db.runTransaction(async (t) => {
    const s = await t.get(ref);
    const mesmoDia = s.get('falhasDia') === diaBR(agora);
    const lista = mesmoDia ? ((s.get('falhasHoje') as unknown[] | undefined) ?? []) : [];
    lista.push({ em: Timestamp.fromDate(agora), partida, uid, motivo, refazivel: motivo !== 'variante' });
    t.set(ref, { falhasDia: diaBR(agora), falhasHoje: lista.slice(-MAX_FALHAS) }, { merge: true });
  });
}

/** Lichess respondeu (ok) ou ficou fora/limitou. */
export async function registrarLichess(db: Firestore, agora: Date, ok: boolean, limite: boolean): Promise<void> {
  const ref = db.doc('treinador_painel/estado');
  await db.runTransaction(async (t) => {
    const s = await t.get(ref);
    const atual = (s.get('lichess') ?? {}) as Record<string, unknown>;
    const novo: Record<string, unknown> = { ok };
    if (!ok) novo.foraDesde = atual.ok === false && atual.foraDesde ? atual.foraDesde : Timestamp.fromDate(agora);
    if (limite) novo.ultimo429 = Timestamp.fromDate(agora);
    else if (atual.ultimo429) novo.ultimo429 = atual.ultimo429;
    t.set(ref, { lichess: novo }, { merge: true });
  });
}

function percentil(v: number[], p: number): number | null {
  if (!v.length) return null;
  const o = [...v].sort((a, b) => a - b);
  return o[Math.min(o.length - 1, Math.floor((p / 100) * o.length))];
}

/** Gasto do mês até agora (soma dos dias) e a previsão linear até o último dia. */
export async function gastoDoMes(db: Firestore, agora: Date): Promise<{ gastoUsd: number; previsaoUsd: number }> {
  const mes = mesBR(agora);
  const dias = await db
    .collection('treinador_painel')
    .where('data', '>=', `${mes}-01`)
    .where('data', '<=', `${mes}-31`)
    .get();
  let gasto = 0;
  for (const d of dias.docs) {
    const c = (d.get('custoUsd') ?? {}) as Record<string, number>;
    gasto += (c.pagas ?? 0) + (c.gratis ?? 0) + (c.infra ?? 0);
  }
  const hoje = Number(diaBR(agora).slice(8, 10));
  const previsao = (gasto / Math.max(1, hoje)) * diasNoMes(mes);
  return { gastoUsd: Math.round(gasto * 10000) / 10000, previsaoUsd: Math.round(previsao * 10000) / 10000 };
}

/** Reescreve `treinador_painel/estado` (fila, tempos de push de hoje, gasto do mês). */
export async function atualizarEstado(db: Firestore, agora: Date): Promise<void> {
  const fila = db.collection('treinador_fila');
  const [naFila, analisando, dia, mes] = await Promise.all([
    fila.where('status', '==', 'na_fila').count().get(),
    fila.where('status', '==', 'analisando').count().get(),
    refDia(db, agora).get(),
    gastoDoMes(db, agora),
  ]);
  const p = (dia.get('partidas') ?? {}) as Record<string, number>;
  const tempos = (dia.get('temposPushMin') as number[] | undefined) ?? [];
  await db.doc('treinador_painel/estado').set(
    {
      atualizadoEm: Timestamp.fromDate(agora),
      fila: {
        naFila: naFila.data().count,
        analisando: analisando.data().count,
        prontasHoje: (p.pagas ?? 0) + (p.gratis ?? 0),
        pushMedianaMin: percentil(tempos, 50),
        push95Min: percentil(tempos, 95),
      },
      mes,
    },
    { merge: true },
  );
}

/** Fecha os números de contas e assinantes do dia (rodada da busca). */
export async function atualizarContas(db: Firestore, agora: Date, assinantes: number): Promise<void> {
  const ligadas = (await db.collection('treinador_contas').count().get()).data().count;
  await refDia(db, agora).set(
    { data: diaBR(agora), atualizadoEm: Timestamp.fromDate(agora), contas: { ligadas }, assinantes },
    { merge: true },
  );
}
