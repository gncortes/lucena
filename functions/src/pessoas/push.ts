// H-R5-39 · Push do painel (R6; pranchas R4 Push*): todos, público, pessoa ou a lista
// da tela Pessoas; agora ou agendado; cancelar enquanto agendado. Cada envio é
// pushes/{id} (só a Function grava; o admin lê). O push vai "data-only" no
// formato do app (PushData em lib/domain/models/push_alert.dart): o app monta a
// notificação com `titulo` e `texto` e escolhe o canal por `tipo`.
import { Timestamp, type DocumentData, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';
import { cursoExiste } from '../comum/cursos';
import { iso } from '../comum/datas';
import { TOKEN_NAO_REGISTRADO, type Deps } from './acessos';
import { bloqueioVigente } from './bloqueio';

export const TIPOS = ['livre', 'novidade', 'aula', 'dia', 'destaque'] as const;
export type TipoPush = (typeof TIPOS)[number];

export type Destino =
  | { tipo: 'todos' }
  | { tipo: 'publico'; curso: string | null; inativosDias: number | null }
  | { tipo: 'pessoa'; uid: string }
  | { tipo: 'pessoas'; uids: string[] };

export type EstadoPush = 'agendado' | 'enviando' | 'enviado' | 'cancelado';

export interface Contagens {
  /** Contas no público (com aparelho registrado, sem suspensão). */
  pessoas: number;
  /** Delas, com o push permitido e token. */
  comPush: number;
  enviados: number;
  /** Token que o aparelho já invalidou (saiu da conta). */
  semPush: number;
  falhas: number;
}

export const MAX_TITULO = 65;
export const MAX_TEXTO = 240;
export const MAX_PESSOAS = 500;
const MAX_LINK = 300;
const MAX_AGENDA_DIAS = 60;
const LOTE = 50;
const DIA_MS = 86_400_000;

function invalido(msg: string): never {
  throw new HttpsError('invalid-argument', msg);
}

function textoObrigatorio(v: unknown, max: number, campo: string): string {
  const t = typeof v === 'string' ? v.trim() : '';
  if (t.length === 0 || t.length > max) invalido(`${campo}: texto de 1 a ${max} caracteres.`);
  return t;
}

function uidValido(v: unknown): string {
  if (typeof v !== 'string' || v.length === 0 || v.length > 128 || v.includes('/')) invalido('uid inválido.');
  return v;
}

export function lerDestino(v: unknown): Destino {
  const d = (v ?? {}) as Record<string, unknown>;
  switch (d.tipo) {
    case 'todos':
      return { tipo: 'todos' };
    case 'pessoa':
      return { tipo: 'pessoa', uid: uidValido(d.uid) };
    case 'pessoas': {
      if (!Array.isArray(d.uids) || d.uids.length === 0 || d.uids.length > MAX_PESSOAS) {
        invalido(`uids: de 1 a ${MAX_PESSOAS} pessoas.`);
      }
      return { tipo: 'pessoas', uids: [...new Set(d.uids.map(uidValido))] };
    }
    case 'publico': {
      let curso: string | null = null;
      if (d.curso !== undefined && d.curso !== null) {
        if (!cursoExiste(d.curso)) throw new HttpsError('not-found', 'Curso não encontrado.', { codigo: 'cursoNaoExiste' });
        curso = d.curso as string;
      }
      let inativosDias: number | null = null;
      if (d.inativosDias !== undefined && d.inativosDias !== null) {
        const n = d.inativosDias;
        if (typeof n !== 'number' || !Number.isInteger(n) || n < 1 || n > 365) invalido('inativosDias: de 1 a 365.');
        inativosDias = n;
      }
      if (curso === null && inativosDias === null) invalido('Público: escolha o curso ou os dias sem abrir.');
      return { tipo: 'publico', curso, inativosDias };
    }
    default:
      invalido('destino.tipo: todos, publico, pessoa ou pessoas.');
  }
}

export interface PedidoPush {
  destino: Destino;
  titulo: string;
  texto: string;
  tipo: TipoPush;
  link: string | null;
  agendadoPara: Date | null;
}

export function lerPedidoPush(data: unknown, agora: Date): PedidoPush {
  const d = (data ?? {}) as Record<string, unknown>;
  const destino = lerDestino(d.destino);
  const titulo = textoObrigatorio(d.titulo, MAX_TITULO, 'titulo');
  const texto = textoObrigatorio(d.texto, MAX_TEXTO, 'texto');
  const tipo = (d.tipo ?? 'livre') as TipoPush;
  if (!TIPOS.includes(tipo)) invalido(`tipo: ${TIPOS.join(', ')}.`);
  let link: string | null = null;
  if (d.link !== undefined && d.link !== null && d.link !== '') {
    if (typeof d.link !== 'string' || d.link.length > MAX_LINK) invalido(`link: até ${MAX_LINK} caracteres.`);
    link = d.link;
  }
  let agendadoPara: Date | null = null;
  if (d.agendadoPara !== undefined && d.agendadoPara !== null) {
    agendadoPara = typeof d.agendadoPara === 'string' ? new Date(d.agendadoPara) : new Date(NaN);
    if (Number.isNaN(agendadoPara.getTime())) invalido('agendadoPara: data ISO 8601.');
    if (agendadoPara.getTime() <= agora.getTime() + 60_000) invalido('agendadoPara: pelo menos 1 minuto à frente.');
    if (agendadoPara.getTime() > agora.getTime() + MAX_AGENDA_DIAS * DIA_MS) {
      invalido(`agendadoPara: até ${MAX_AGENDA_DIAS} dias à frente.`);
    }
  }
  return { destino, titulo, texto, tipo, link, agendadoPara };
}

interface Alvo {
  uid: string;
  token: string | null;
}

function uidDoAparelho(doc: DocumentSnapshot): string | null {
  return doc.id === 'device' && doc.ref.parent.id === 'push' ? (doc.ref.parent.parent?.id ?? null) : null;
}

async function emLotes<T, R>(itens: T[], tamanho: number, fn: (lote: T[]) => Promise<R[]>): Promise<R[]> {
  const saida: R[] = [];
  for (let i = 0; i < itens.length; i += tamanho) saida.push(...(await fn(itens.slice(i, i + tamanho))));
  return saida;
}

/**
 * Quem recebe: os aparelhos registrados (`users/{uid}/push/device`) do
 * destino, menos as contas suspensas; o público filtra pelo curso vigente em
 * `acessos/{uid}` e pelos dias desde a `ultimaAbertura` do aparelho.
 */
export async function resolverPublico(db: Firestore, destino: Destino, agora: Date): Promise<Alvo[]> {
  let aparelhos: DocumentSnapshot[];
  if (destino.tipo === 'pessoa' || destino.tipo === 'pessoas') {
    const uids = destino.tipo === 'pessoa' ? [destino.uid] : destino.uids;
    aparelhos = await emLotes(uids, 300, (l) => db.getAll(...l.map((u) => db.doc(`users/${u}/push/device`))));
    aparelhos = aparelhos.filter((a) => a.exists);
  } else {
    // Sem filtro na consulta: o índice de grupo de campo único não existe por padrão.
    aparelhos = (await db.collectionGroup('push').get()).docs.filter((a) => uidDoAparelho(a) !== null);
  }
  const porUid = new Map<string, DocumentData>();
  for (const a of aparelhos) {
    const uid = uidDoAparelho(a);
    if (uid) porUid.set(uid, a.data() ?? {});
  }
  const uids = [...porUid.keys()];
  const acessos = await emLotes(uids, 300, (l) => db.getAll(...l.map((u) => db.doc(`acessos/${u}`))));
  const alvos: Alvo[] = [];
  acessos.forEach((ac, i) => {
    const uid = uids[i];
    const device = porUid.get(uid)!;
    const a = ac.data();
    if (bloqueioVigente(a?.bloqueio, agora)) return;
    if (destino.tipo === 'publico') {
      if (destino.curso) {
        const c = a?.cursos?.[destino.curso];
        if (!c || c.revogadoEm) return;
      }
      if (destino.inativosDias) {
        const ultima = iso(device.ultimaAbertura) ?? iso(device.updatedAt);
        if (ultima && agora.getTime() - new Date(ultima).getTime() < destino.inativosDias * DIA_MS) return;
      }
    }
    const token = device.permissao === 'permitida' && typeof device.token === 'string' && device.token ? device.token : null;
    alvos.push({ uid, token });
  });
  return alvos;
}

/** `contarPublico({destino})` → `{pessoas, comPush}`: a contagem da tela antes de enviar. */
export async function contarPublicoCore(deps: Deps, data: unknown): Promise<{ pessoas: number; comPush: number }> {
  const destino = lerDestino((data as Record<string, unknown> | null)?.destino);
  const alvos = await resolverPublico(deps.db, destino, deps.agora);
  return { pessoas: alvos.length, comPush: alvos.filter((a) => a.token).length };
}

function paraFirestore(p: PedidoPush) {
  return {
    destino: p.destino,
    titulo: p.titulo,
    texto: p.texto,
    tipo: p.tipo,
    link: p.link,
    agendadoPara: p.agendadoPara ? Timestamp.fromDate(p.agendadoPara) : null,
  };
}

/** Manda para todos os alvos e grava as contagens; o push fica `enviado`. */
async function disparar(deps: Deps, id: string, push: DocumentData): Promise<Contagens> {
  const { db, mensageiro, agora } = deps;
  const alvos = await resolverPublico(db, push.destino as Destino, agora);
  const comToken = alvos.filter((a) => a.token);
  const dados: Record<string, string> = { tipo: push.tipo, pushId: id, titulo: push.titulo, texto: push.texto };
  if (push.link) dados.link = push.link;
  const resultados = await emLotes(comToken, LOTE, (lote) =>
    Promise.all(
      lote.map(async (a): Promise<'enviado' | 'semPush' | 'falhou'> => {
        try {
          await mensageiro.send({ token: a.token!, data: dados, android: { priority: 'high' } });
          return 'enviado';
        } catch (e) {
          return (e as { code?: unknown })?.code === TOKEN_NAO_REGISTRADO ? 'semPush' : 'falhou';
        }
      }),
    ),
  );
  const contagens: Contagens = {
    pessoas: alvos.length,
    comPush: comToken.length,
    enviados: resultados.filter((r) => r === 'enviado').length,
    semPush: resultados.filter((r) => r === 'semPush').length,
    falhas: resultados.filter((r) => r === 'falhou').length,
  };
  await db.doc(`pushes/${id}`).update({ estado: 'enviado', enviadoEm: Timestamp.fromDate(agora), contagens });
  return contagens;
}

/**
 * `enviarPush({destino, titulo, texto, tipo?, link?, agendadoPara?: ISO})` →
 * `{id, estado: 'enviado', contagens}` ou `{id, estado: 'agendado', agendadoPara}`.
 */
export async function enviarPushCore(
  deps: Deps,
  adminUid: string,
  data: unknown,
): Promise<{ id: string; estado: EstadoPush; agendadoPara?: string; contagens?: Contagens }> {
  const { db, agora } = deps;
  const pedido = lerPedidoPush(data, agora);
  const ref = db.collection('pushes').doc();
  const base = { ...paraFirestore(pedido), criadoPor: adminUid, criadoEm: Timestamp.fromDate(agora) };
  if (pedido.agendadoPara) {
    await ref.set({ ...base, estado: 'agendado' });
    return { id: ref.id, estado: 'agendado', agendadoPara: pedido.agendadoPara.toISOString() };
  }
  await ref.set({ ...base, estado: 'enviando' });
  const contagens = await disparar(deps, ref.id, base);
  return { id: ref.id, estado: 'enviado', contagens };
}

/** `cancelarPush({id})` → `{id, estado: 'cancelado'}`; só enquanto agendado. */
export async function cancelarPushCore(
  deps: Deps,
  adminUid: string,
  data: unknown,
): Promise<{ id: string; estado: 'cancelado' }> {
  const { db, agora } = deps;
  const id = (data as Record<string, unknown> | null)?.id;
  if (typeof id !== 'string' || id.length === 0 || id.length > 64 || id.includes('/')) invalido('Informe o push.');
  const ref = db.doc(`pushes/${id}`);
  await db.runTransaction(async (tx) => {
    const p = await tx.get(ref);
    if (!p.exists) throw new HttpsError('not-found', 'Push não encontrado.');
    const estado = p.get('estado');
    if (estado !== 'agendado') {
      throw new HttpsError('failed-precondition', 'Este push não está mais agendado.', { codigo: 'naoAgendado', estado });
    }
    tx.update(ref, { estado: 'cancelado', canceladoEm: Timestamp.fromDate(agora), canceladoPor: adminUid });
  });
  return { id, estado: 'cancelado' };
}

/**
 * O agendador (a cada 5 min): pega os agendados vencidos, marca `enviando`
 * numa transação (o cancelamento e outra execução não passam juntos) e envia.
 */
export async function dispararAgendadosCore(deps: Deps): Promise<string[]> {
  const { db, agora } = deps;
  const vencidos = await db
    .collection('pushes')
    .where('estado', '==', 'agendado')
    .where('agendadoPara', '<=', Timestamp.fromDate(agora))
    .get();
  const enviados: string[] = [];
  for (const doc of vencidos.docs) {
    const pegou = await db.runTransaction(async (tx) => {
      const p = await tx.get(doc.ref);
      if (p.get('estado') !== 'agendado') return null;
      tx.update(doc.ref, { estado: 'enviando' });
      return p.data()!;
    });
    if (!pegou) continue;
    await disparar(deps, doc.id, pegou);
    enviados.push(doc.id);
  }
  return enviados;
}
