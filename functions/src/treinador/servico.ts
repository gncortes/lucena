// T87 · Núcleo do treinador no servidor: ligar a conta, pedir análise (fila com orçamento), a análise na fila,
// a busca periódica e o push. As cascas (onCall, onTaskDispatched, onSchedule) ficam em src/index.ts.
import { type DocumentData, FieldValue, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';
import { TOKEN_NAO_REGISTRADO, type Mensageiro } from '../pessoas/acessos';
import { analisarPartida } from './analise';
import { calcularEstatisticas, type PartidaParaEstatistica } from './estatisticas';
import { buscarPartidas, conferirUsuario, donoDoTokenLichess, ErroFonte, type Http } from './fontes';
import type { Motor } from './motor';
import {
  config,
  configDaAnalise,
  custoUsd,
  decidir,
  diaBR,
  ehAssinante,
  somarCota,
  type Decisao,
  type Plano,
} from './politica';
import {
  atualizarContas,
  atualizarEstado,
  gastoDoMes,
  lerProgresso,
  registrarFalha,
  registrarLichess,
  somarAnalise,
  somarContaNova,
  somarProgresso,
  type MotivoFalha,
} from './painel';
import { acharTeoria, type Explorador } from './teoria';
import type { Exercicio, PartidaBruta, Plataforma, ResultadoAnalise } from './tipos';

export interface DepsTreinador {
  db: Firestore;
  mensageiro: Mensageiro;
  agora: Date;
  http: Http;
  /** Põe a partida na fila de análise (Cloud Tasks; no teste, chama `processarPartida`). */
  enfileirar(uid: string, partida: string): Promise<void>;
  abrirMotor(): Promise<Motor>;
  /** Explorador do Lichess com cache, ou null sem token. */
  explorador(): Promise<Explorador | null>;
}

/** Partidas importadas ao ligar a conta. */
export const IMPORTAR_AO_LIGAR = 3;
/** Partidas por conta a cada busca. */
export const MAX_POR_BUSCA = 20;
/** Análise parada há mais que isso volta para a fila. */
export const PRESA_MS = 15 * 60_000;
/** Push automático no máximo 1 por hora por pessoa (o "me avise" sempre manda). */
export const PUSH_INTERVALO_MS = 60 * 60_000;
const MAX_PARTIDAS_ESTATISTICA = 200;

const USUARIO_VALIDO = /^[A-Za-z0-9][A-Za-z0-9_-]{1,29}$/;
/** Token do Lichess: texto sem espaço, de tamanho razoável (o formato exato é deles). */
const TOKEN_VALIDO = /^[A-Za-z0-9_.-]{16,200}$/;

/** Milissegundos de um Timestamp gravado; sem valor conta como nunca (vem primeiro). */
function quando(v: unknown): number {
  return v instanceof Timestamp ? v.toMillis() : 0;
}

function ts(d: Date): Timestamp {
  return Timestamp.fromDate(d);
}

function data(v: unknown): Date {
  if (v instanceof Timestamp) return v.toDate();
  if (v instanceof Date) return v;
  return new Date(String(v));
}

const refConta = (db: Firestore, uid: string) => db.doc(`users/${uid}/treinador/conta`);
const refContaServidor = (db: Firestore, uid: string) => db.doc(`treinador_contas/${uid}`);
/** Só do servidor e nunca apagado ao desligar: tentativas de ligar no dia e a cota guardada. */
const refLimites = (db: Firestore, uid: string) => db.doc(`treinador_limites/${uid}`);

/** Tentativas de ligar por conta por dia (Brasília). Cada uma custa chamadas às plataformas e importação. */
export const LIGAR_POR_DIA = 5;
const refPartida = (db: Firestore, uid: string, id: string) => db.doc(`users/${uid}/partidas/${id}`);
const refFila = (db: Firestore, uid: string, id: string) => db.doc(`treinador_fila/${uid}_${id}`);

// ---------------------------------------------------------------- partidas

function docDaPartida(p: PartidaBruta): DocumentData {
  return {
    plataforma: p.plataforma,
    idExterno: p.idExterno,
    url: p.url,
    jogadaEm: ts(p.jogadaEm),
    ritmo: p.ritmo,
    cadencia: p.cadencia,
    cor: p.cor,
    adversario: p.adversario,
    rating: p.rating,
    resultado: p.resultado,
    abertura: p.abertura,
    pgn: p.pgn,
    status: 'nova',
  };
}

function partidaDoDoc(id: string, d: DocumentData): PartidaBruta {
  return {
    id,
    plataforma: d.plataforma,
    idExterno: d.idExterno,
    url: d.url,
    jogadaEm: data(d.jogadaEm),
    ritmo: d.ritmo,
    cadencia: d.cadencia,
    cor: d.cor,
    adversario: d.adversario,
    rating: d.rating ?? null,
    resultado: d.resultado,
    abertura: d.abertura ?? null,
    pgn: d.pgn,
  };
}

/** Grava as partidas que ainda não existem (status `nova`). Devolve as novas. */
async function gravarNovas(db: Firestore, uid: string, partidas: PartidaBruta[]): Promise<PartidaBruta[]> {
  if (!partidas.length) return [];
  const refs = partidas.map((p) => refPartida(db, uid, p.id));
  const existentes = await db.getAll(...refs);
  const novas = partidas.filter((_, i) => !existentes[i].exists);
  const lote = db.batch();
  for (const p of novas) lote.set(refPartida(db, uid, p.id), docDaPartida(p));
  if (novas.length) await lote.commit();
  return novas;
}

// ---------------------------------------------------------------- fila

export async function planoDe(deps: DepsTreinador, uid: string): Promise<Plano> {
  return (await ehAssinante(deps.db, uid, deps.agora)) ? 'assinante' : 'gratis';
}

/**
 * Pede a análise: aplica a política (direito, cota, orçamento) e, se entra, marca `na_fila`, soma a cota e
 * enfileira (grátis com orçamento estourado fica na fila esperando, sem tarefa).
 */
export async function pedirAnalise(
  deps: DepsTreinador,
  uid: string,
  partida: string,
  avisar: boolean,
): Promise<Decisao> {
  const { db, agora } = deps;
  const [cfg, plano, conta] = await Promise.all([config(db), planoDe(deps, uid), refContaServidor(db, uid).get()]);
  const gasto = plano === 'gratis' ? (await gastoDoMes(db, agora)).gastoUsd : 0;
  const decisao = decidir(cfg, plano, conta.data(), gasto, agora);
  if (!decisao.entra) return decisao;
  await refContaServidor(db, uid).set(somarCota(conta.data(), plano, agora), { merge: true });
  await refFila(db, uid, partida).set({
    uid,
    partida,
    status: 'na_fila',
    criadaEm: ts(agora),
    espera: decisao.espera,
    plano,
    avisar,
  });
  await refPartida(db, uid, partida).update({ status: 'na_fila' });
  if (!decisao.espera) await deps.enfileirar(uid, partida);
  return decisao;
}

/** "Tentar de novo" do painel (status erro → na_fila): volta para a fila sem gastar cota. */
export async function refazer(deps: DepsTreinador, uid: string, partida: string): Promise<void> {
  const { db, agora } = deps;
  await refFila(db, uid, partida).set({
    uid,
    partida,
    status: 'na_fila',
    criadaEm: ts(agora),
    espera: null,
    plano: await planoDe(deps, uid),
    avisar: false,
  });
  await deps.enfileirar(uid, partida);
}

function motivoDaFalha(e: unknown): MotivoFalha {
  const msg = String((e as Error)?.message ?? e);
  if (/pgn|Invalid move|move/i.test(msg)) return 'pgn';
  if (/variante|variant/i.test(msg)) return 'variante';
  if (/tempo|timeout/i.test(msg)) return 'tempo';
  return 'outro';
}

/** A análise de uma partida da fila (worker). Erro vira status `erro` e entra nas falhas do painel. */
export async function processarPartida(deps: DepsTreinador, uid: string, partida: string): Promise<void> {
  const { db, agora } = deps;
  const [fila, doc] = await Promise.all([refFila(db, uid, partida).get(), refPartida(db, uid, partida).get()]);
  if (!doc.exists || doc.get('status') === 'pronta') {
    await refFila(db, uid, partida).delete();
    return;
  }
  const criadaEm = fila.exists ? data(fila.get('criadaEm')) : agora;
  const plano: Plano = (fila.get('plano') as Plano | undefined) ?? (await planoDe(deps, uid));
  const avisar = fila.get('avisar') === true;
  await refPartida(db, uid, partida).update({ status: 'analisando' });
  if (fila.exists) await refFila(db, uid, partida).update({ status: 'analisando', iniciadaEm: ts(new Date()) });

  let r: ResultadoAnalise;
  try {
    const cfg = await config(db);
    const bruta = partidaDoDoc(partida, doc.data() as DocumentData);
    const explorador = await deps.explorador();
    const teoria = explorador ? await acharTeoria(bruta.pgn, explorador) : null;
    const motor = await deps.abrirMotor();
    try {
      r = await analisarPartida(bruta, motor, configDaAnalise(cfg, plano), teoria);
    } finally {
      await motor.fechar();
    }
  } catch (e) {
    console.error(`treinador: análise de ${uid}/${partida} falhou`, e);
    const motivo = motivoDaFalha(e);
    await refPartida(db, uid, partida).update({ status: 'erro', erroMotivo: motivo });
    await refFila(db, uid, partida).delete();
    await registrarFalha(db, new Date(), uid, partida, motivo);
    return;
  }

  const fim = new Date();
  const custo = custoUsd(r.segundosMotor);
  await refPartida(db, uid, partida).update({
    status: 'pronta',
    resumo: r.resumo,
    precisao: r.precisao,
    exercicios: r.exercicios,
    lances: r.lances,
    teoria: r.teoria,
    fases: r.fases,
    temas: r.temas,
    motor: r.motor,
    erros: r.errosDoUsuario,
    plano,
    segundosMotor: Math.round(r.segundosMotor * 10) / 10,
    analisadaEm: ts(fim),
    erroMotivo: FieldValue.delete(),
    origem: 'servidor',
  });
  await refFila(db, uid, partida).delete();
  await recalcularEstatisticas(db, uid, fim);
  const minutos = (fim.getTime() - criadaEm.getTime()) / 60_000;
  await somarAnalise(db, fim, uid, plano, r.exercicios, custo, minutos);
  await atualizarEstado(db, fim);
  const cfg = await config(db);
  if (avisar || cfg.pushLigado) await avisarAnalise(deps, uid, partida, r, avisar);
}

/** Recalcula `users/{uid}/treinador/estatisticas` com as partidas prontas mais recentes. */
export async function recalcularEstatisticas(db: Firestore, uid: string, agora: Date): Promise<void> {
  const prontas = await db
    .collection(`users/${uid}/partidas`)
    .where('status', '==', 'pronta')
    .orderBy('jogadaEm', 'desc')
    .limit(MAX_PARTIDAS_ESTATISTICA)
    .get();
  const lista: PartidaParaEstatistica[] = prontas.docs.map((d) => ({
    id: d.id,
    jogadaEm: data(d.get('jogadaEm')),
    cor: d.get('cor'),
    resultado: d.get('resultado'),
    abertura: d.get('abertura') ?? null,
    precisao: d.get('precisao') ?? 0,
    fases: d.get('fases') ?? { abertura: null, meio: null, final: null },
    teoria: d.get('teoria') ? { lance: d.get('teoria.lance') } : null,
    erros: d.get('erros') ?? [],
  }));
  const est = calcularEstatisticas(lista, agora);
  await db.doc(`users/${uid}/treinador/estatisticas`).set({ ...est, atualizadoEm: ts(agora) });
}

// ---------------------------------------------------------------- push

export function textoDoPush(r: Pick<ResultadoAnalise, 'precisao' | 'exercicios'>): string {
  const n = r.exercicios.length;
  const ex = n === 1 ? '1 exercício' : `${n} exercícios`;
  return `Precisão de ${r.precisao}%. ${ex} para treinar.`;
}

/** Push data-only (o app monta a notificação). Automático: no máximo 1 por hora. */
export async function avisarAnalise(
  deps: DepsTreinador,
  uid: string,
  partida: string,
  r: Pick<ResultadoAnalise, 'precisao' | 'exercicios'>,
  pedido: boolean,
): Promise<'enviado' | 'semPush' | 'intervalo' | 'falhou'> {
  const { db } = deps;
  const agora = new Date(Math.max(deps.agora.getTime(), Date.now()));
  const contaRef = refContaServidor(db, uid);
  const conta = await contaRef.get();
  const ultimo = conta.get('ultimoPush');
  if (!pedido && ultimo && agora.getTime() - data(ultimo).getTime() < PUSH_INTERVALO_MS) return 'intervalo';
  const device = (await db.doc(`users/${uid}/push/device`).get()).data();
  const token = device?.token;
  if (device?.permissao !== 'permitida' || typeof token !== 'string' || !token) return 'semPush';
  try {
    await deps.mensageiro.send({
      token,
      data: {
        tipo: 'treinador',
        titulo: 'Sua partida foi analisada',
        texto: textoDoPush(r),
        partida,
        pushId: `treinador_${partida}`,
        uid,
      },
      android: { priority: 'high' },
    });
  } catch (e) {
    return (e as { code?: unknown })?.code === TOKEN_NAO_REGISTRADO ? 'semPush' : 'falhou';
  }
  await contaRef.set({ ultimoPush: ts(agora) }, { merge: true });
  return 'enviado';
}

// ---------------------------------------------------------------- callables

function exigeLogin(uid: string | undefined): string {
  if (!uid) throw new HttpsError('unauthenticated', 'Entre na sua conta.');
  return uid;
}

/** `treinadorLigarConta {plataforma, usuario | token}`: confere na plataforma, grava a conta e importa as últimas partidas. */
export async function ligarContaCore(
  deps: DepsTreinador,
  uidLogado: string | undefined,
  dados: unknown,
): Promise<{ usuario: string; importadas: number }> {
  const uid = exigeLogin(uidLogado);
  const d = (dados ?? {}) as { plataforma?: unknown; usuario?: unknown; token?: unknown };
  const plataforma = d.plataforma;
  if (plataforma !== 'lichess' && plataforma !== 'chesscom') {
    throw new HttpsError('invalid-argument', 'Plataforma inválida.');
  }
  // Lichess: só com o login de lá (token OAuth), que prova o dono da conta. chess.com: nome digitado, conferido na
  // API pública, até o OAuth deles ser liberado (acesso por aprovação).
  const token = typeof d.token === 'string' ? d.token.trim() : '';
  const digitado = typeof d.usuario === 'string' ? d.usuario.trim() : '';
  if (plataforma === 'lichess' ? !TOKEN_VALIDO.test(token) : !USUARIO_VALIDO.test(digitado)) {
    throw new HttpsError('invalid-argument', plataforma === 'lichess' ? 'Entre pelo Lichess.' : 'Usuário inválido.');
  }
  await contarTentativaDeLigar(deps.db, uid, deps.agora);
  let oficial: string | null;
  try {
    oficial =
      plataforma === 'lichess'
        ? await donoDoTokenLichess(deps.http, token)
        : await conferirUsuario(deps.http, plataforma as Plataforma, digitado);
  } catch (e) {
    if (e instanceof ErroFonte && plataforma === 'lichess') {
      await registrarLichess(deps.db, deps.agora, false, e.motivo === 'limite');
    }
    throw new HttpsError('unavailable', 'A plataforma não respondeu.');
  }
  if (!oficial) {
    if (plataforma === 'lichess') throw new HttpsError('failed-precondition', 'Entre pelo Lichess de novo.');
    throw new HttpsError('not-found', 'Usuário não encontrado.');
  }

  const { db, agora } = deps;
  const antes = (await refConta(db, uid).get()).data();
  const mesma = antes?.plataforma === plataforma && String(antes?.usuario).toLowerCase() === oficial.toLowerCase();
  await refConta(db, uid).set({
    plataforma,
    usuario: oficial,
    ligadaEm: mesma && antes?.ligadaEm ? antes.ligadaEm : ts(agora),
    ultimaBusca: ts(agora),
    avisoModelos: antes?.avisoModelos === true,
  });
  const contaServidor = (await refContaServidor(db, uid).get()).data();
  // Religou depois de desligar: a cota guardada volta (desligar e ligar não zera o grátis).
  const guardada = contaServidor ? undefined : (await refLimites(db, uid).get()).get('cota');
  await refContaServidor(db, uid).set(
    {
      plataforma,
      usuario: oficial,
      ligadaEm: ts(agora),
      ultimaBusca: ts(agora),
      cursor: mesma ? (contaServidor?.cursor ?? null) : null,
      ...(guardada?.semana ? { semana: guardada.semana } : {}),
      ...(guardada?.mes ? { mes: guardada.mes } : {}),
    },
    { merge: true },
  );
  if (!mesma) await somarContaNova(db, agora);

  let partidas: PartidaBruta[] = [];
  try {
    partidas = await buscarPartidas(deps.http, plataforma as Plataforma, oficial, null, IMPORTAR_AO_LIGAR);
  } catch (e) {
    // A conta fica ligada; a busca periódica tenta de novo.
    console.warn('treinador: importação ao ligar falhou', e);
  }
  const novas = await gravarNovas(db, uid, partidas);
  await avancarCursor(db, uid, partidas);
  for (const p of novas) await pedirAnalise(deps, uid, p.id, false);
  return { usuario: oficial, importadas: novas.length };
}

async function avancarCursor(db: Firestore, uid: string, partidas: PartidaBruta[]): Promise<void> {
  if (!partidas.length) return;
  const maior = Math.max(...partidas.map((p) => p.jogadaEm.getTime()));
  const atual = (await refContaServidor(db, uid).get()).get('cursor');
  if (typeof atual !== 'number' || maior > atual) await refContaServidor(db, uid).set({ cursor: maior }, { merge: true });
}

/** `treinadorDesligarConta {}`: apaga a conta; as partidas e a análise ficam. */
export async function desligarContaCore(deps: DepsTreinador, uidLogado: string | undefined): Promise<{ ok: true }> {
  const uid = exigeLogin(uidLogado);
  const servidor = (await refContaServidor(deps.db, uid).get()).data();
  if (servidor?.semana || servidor?.mes) {
    await refLimites(deps.db, uid).set(
      { cota: { ...(servidor.semana ? { semana: servidor.semana } : {}), ...(servidor.mes ? { mes: servidor.mes } : {}) } },
      { merge: true },
    );
  }
  await refConta(deps.db, uid).delete();
  await refContaServidor(deps.db, uid).delete();
  return { ok: true };
}

/** Conta a tentativa antes de chamar a plataforma; passou de `LIGAR_POR_DIA` no dia, recusa. */
async function contarTentativaDeLigar(db: Firestore, uid: string, agora: Date): Promise<void> {
  const dia = diaBR(agora);
  const ref = refLimites(db, uid);
  const passou = await db.runTransaction(async (t) => {
    const atual = (await t.get(ref)).get('ligar');
    const n = atual?.dia === dia ? Number(atual.n) || 0 : 0;
    if (n >= LIGAR_POR_DIA) return true;
    t.set(ref, { ligar: { dia, n: n + 1 } }, { merge: true });
    return false;
  });
  if (passou) throw new HttpsError('resource-exhausted', 'Muitas tentativas hoje. Tente amanhã.');
}

/** `treinadorAvisoModelos {ligado}`. */
export async function avisoModelosCore(
  deps: DepsTreinador,
  uidLogado: string | undefined,
  dados: unknown,
): Promise<{ ok: true }> {
  const uid = exigeLogin(uidLogado);
  const ligado = (dados as { ligado?: unknown } | null)?.ligado;
  if (typeof ligado !== 'boolean') throw new HttpsError('invalid-argument', 'Valor inválido.');
  await refConta(deps.db, uid).set({ avisoModelos: ligado }, { merge: true });
  return { ok: true };
}

/** `treinadorAnalisar {partida, avisar}`: pede a análise de uma partida (ou marca o "me avise"). */
export async function analisarCore(
  deps: DepsTreinador,
  uidLogado: string | undefined,
  dados: unknown,
): Promise<{ status: string; espera?: string | null }> {
  const uid = exigeLogin(uidLogado);
  const d = (dados ?? {}) as { partida?: unknown; avisar?: unknown };
  if (typeof d.partida !== 'string' || !/^(lichess|chesscom)_[A-Za-z0-9_-]{1,60}$/.test(d.partida)) {
    throw new HttpsError('invalid-argument', 'Partida inválida.');
  }
  const partida = d.partida;
  const avisar = d.avisar === true;
  const doc = await refPartida(deps.db, uid, partida).get();
  if (!doc.exists) throw new HttpsError('not-found', 'Partida não encontrada.');
  const status = doc.get('status') as string;
  if (status === 'pronta') return { status };
  if (status === 'na_fila' || status === 'analisando') {
    const fila = refFila(deps.db, uid, partida);
    if (avisar && (await fila.get()).exists) await fila.update({ avisar: true });
    return { status };
  }
  const decisao = await pedirAnalise(deps, uid, partida, avisar);
  if (!decisao.entra) {
    throw new HttpsError('permission-denied', 'Sem análise disponível no seu plano.', { motivo: decisao.motivo });
  }
  return { status: 'na_fila', espera: decisao.espera };
}

// ---------------------------------------------------------------- busca periódica

/**
 * Rodada da busca: partidas novas de cada conta ligada (desde o cursor), política de cada uma, fila presa de volta,
 * grátis em espera liberada quando há orçamento, e os números de contas e estado do painel.
 */
export async function buscaCore(deps: DepsTreinador): Promise<{ contas: number; novas: number; reenfileiradas: number }> {
  const { db, agora } = deps;
  const contas = await db.collection('treinador_contas').get();
  let novasTotal = 0;
  let assinantes = 0;
  let lichessOk: boolean | null = null;
  let lichessLimite = false;
  // Quem foi buscado há mais tempo vem primeiro: um 429 no meio não deixa sempre os mesmos para trás.
  const ordem = [...contas.docs].sort((a, b) => quando(a.get('ultimaBusca')) - quando(b.get('ultimaBusca')));
  for (const c of ordem) {
    const uid = c.id;
    const plataforma = c.get('plataforma') as Plataforma;
    const usuario = c.get('usuario') as string;
    if (await ehAssinante(db, uid, agora)) assinantes++;
    // 429 do Lichess: pausa só o Lichess nesta rodada; o chess.com segue.
    if (plataforma === 'lichess' && lichessLimite) continue;
    const cursor = c.get('cursor');
    let partidas: PartidaBruta[];
    try {
      partidas = await buscarPartidas(deps.http, plataforma, usuario, typeof cursor === 'number' ? cursor + 1 : null, MAX_POR_BUSCA);
      if (plataforma === 'lichess') lichessOk = lichessOk ?? true;
    } catch (e) {
      if (plataforma === 'lichess' && e instanceof ErroFonte) {
        lichessOk = false;
        lichessLimite ||= e.motivo === 'limite'; // 429: o Lichess pede um minuto de pausa
      }
      console.warn(`treinador: busca de ${uid} falhou`, e);
      continue;
    }
    const novas = await gravarNovas(db, uid, partidas);
    await avancarCursor(db, uid, partidas);
    await c.ref.set({ ultimaBusca: ts(agora) }, { merge: true });
    await refConta(db, uid).set({ ultimaBusca: ts(agora) }, { merge: true });
    // Mais recentes primeiro: com cota curta, o grátis recebe a última partida.
    for (const p of [...novas].sort((a, b) => b.jogadaEm.getTime() - a.jogadaEm.getTime())) {
      const d = await pedirAnalise(deps, uid, p.id, false);
      if (!d.entra) break;
    }
    novasTotal += novas.length;
  }
  if (lichessOk !== null) await registrarLichess(db, agora, lichessOk, lichessLimite);
  const reenfileiradas = await reenfileirar(deps);
  await atualizarContas(db, agora, assinantes);
  await atualizarEstado(db, agora);
  return { contas: contas.size, novas: novasTotal, reenfileiradas };
}

/** Fila parada (tarefa perdida, worker caiu) e grátis à espera do orçamento: de volta ao Cloud Tasks. */
export async function reenfileirar(deps: DepsTreinador): Promise<number> {
  const { db, agora } = deps;
  const fila = await db.collection('treinador_fila').get();
  const cfg = await config(db);
  const gasto = (await gastoDoMes(db, agora)).gastoUsd;
  const temVerba = cfg.orcamentoMensalUsd <= 0 || gasto < cfg.orcamentoMensalUsd;
  let n = 0;
  for (const f of fila.docs) {
    const espera = f.get('espera');
    const desde = data(f.get(f.get('status') === 'analisando' ? 'iniciadaEm' : 'criadaEm') ?? f.get('criadaEm'));
    const presa = agora.getTime() - desde.getTime() > PRESA_MS;
    if (espera === 'orcamento') {
      if (!temVerba) continue;
      await f.ref.update({ espera: null, status: 'na_fila' });
    } else if (presa) {
      await f.ref.update({ status: 'na_fila', criadaEm: f.get('criadaEm') });
    } else continue;
    await deps.enfileirar(f.get('uid'), f.get('partida'));
    n++;
  }
  return n;
}

// ---------------------------------------------------------------- mudança no documento da partida

/** Progresso espelhado pelo app (funil do painel) e o "Tentar de novo" do painel (erro → na_fila). */
export async function partidaMudou(
  deps: DepsTreinador,
  uid: string,
  partida: string,
  antes: DocumentData | undefined,
  depois: DocumentData | undefined,
): Promise<void> {
  if (!depois) return;
  if (antes?.status === 'erro' && depois.status === 'na_fila') {
    // Sem documento na fila = foi o painel; com documento = o próprio servidor (pedirAnalise) já enfileirou.
    if (!(await refFila(deps.db, uid, partida).get()).exists) await refazer(deps, uid, partida);
    return;
  }
  const p = lerProgresso(depois.progresso);
  if (!p || depois.status !== 'pronta') return;
  const a = lerProgresso(antes?.progresso);
  if (a && JSON.stringify(a) === JSON.stringify(p)) return;
  await somarProgresso(
    deps.db,
    deps.agora,
    a,
    p,
    (depois.exercicios as Exercicio[] | undefined) ?? [],
    depois.plano === 'assinante',
  );
}
