// H-R5-39 · Bloquear e desbloquear a conta pela Ficha (R4 resposta 1; pranchas FichaBloquear*).
// Numa transação: bloqueios/{uid} (o app lê e as regras recusam as gravações),
// o resumo acessos/{uid}.bloqueio (a Ficha e o app fecham os cursos enquanto
// vigente) e um item no registro. Depois, fora dela, revoga os tokens do Auth
// para o app pedir login de novo. O reembolso, quando houver, é manual na Play.
import { FieldValue, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';
import { pessoaDoAuth, type Deps } from './acessos';

const MAX_MOTIVO = 64; // o mesmo limite das regras de bloqueios/{uid}
const MAX_REGRA = 16;

function invalido(msg: string): never {
  throw new HttpsError('invalid-argument', msg);
}

function uidValido(v: unknown): string {
  if (typeof v !== 'string' || v.length === 0 || v.length > 128) invalido('Informe o uid da pessoa.');
  return v;
}

function motivoValido(v: unknown): string {
  const m = typeof v === 'string' ? v.trim() : '';
  if (m.length === 0 || m.length > MAX_MOTIVO) invalido(`Informe o motivo (até ${MAX_MOTIVO} caracteres).`);
  return m;
}

/** Bloqueio vigente: existe e não tem `ate` no passado (a mesma conta das regras). */
export function bloqueioVigente(b: DocumentData | undefined, agora: Date): boolean {
  if (!b) return false;
  const ate = b.ate;
  if (ate === undefined || ate === null) return true;
  return ate instanceof Timestamp ? ate.toDate() > agora : true;
}

export interface PedidoBloqueio {
  uid: string;
  motivo: string;
  regra: string | null;
  ate: Date | null;
}

export function lerPedidoBloqueio(data: unknown, agora: Date): PedidoBloqueio {
  const d = (data ?? {}) as Record<string, unknown>;
  const uid = uidValido(d.uid);
  const motivo = motivoValido(d.motivo);
  let regra: string | null = null;
  if (d.regra !== undefined && d.regra !== null && d.regra !== '') {
    if (typeof d.regra !== 'string' || d.regra.length > MAX_REGRA) invalido(`regra: até ${MAX_REGRA} caracteres.`);
    regra = d.regra;
  }
  let ate: Date | null = null;
  if (d.ate !== undefined && d.ate !== null) {
    ate = typeof d.ate === 'string' ? new Date(d.ate) : new Date(NaN);
    if (Number.isNaN(ate.getTime())) invalido('ate: data ISO 8601.');
    if (ate <= agora) invalido('ate: a suspensão termina no futuro.');
  }
  return { uid, motivo, regra, ate };
}

/** `bloquearConta({uid, motivo, regra?, ate?: ISO | null})` → `{registroId, tokensRevogados}`. */
export async function bloquearContaCore(
  deps: Deps,
  adminUid: string,
  data: unknown,
): Promise<{ registroId: string; tokensRevogados: boolean }> {
  const { db, auth, agora } = deps;
  const pedido = lerPedidoBloqueio(data, agora);
  if (pedido.uid === adminUid) {
    throw new HttpsError('failed-precondition', 'Você não pode suspender a própria conta.', { codigo: 'propriaConta' });
  }
  await pessoaDoAuth(auth, pedido.uid);
  const bloqueioRef = db.doc(`bloqueios/${pedido.uid}`);
  const acessosRef = db.doc(`acessos/${pedido.uid}`);
  const registroRef = acessosRef.collection('registro').doc();
  const desde = Timestamp.fromDate(agora);
  const ate = pedido.ate ? Timestamp.fromDate(pedido.ate) : null;
  await db.runTransaction(async (tx) => {
    const atual = await tx.get(bloqueioRef);
    if (atual.exists && bloqueioVigente(atual.data(), agora)) {
      throw new HttpsError('failed-precondition', 'Esta conta já está suspensa.', { codigo: 'jaBloqueada' });
    }
    tx.set(bloqueioRef, {
      motivo: pedido.motivo,
      ...(pedido.regra ? { regra: pedido.regra } : {}),
      desde,
      ate,
      adminUid,
    });
    tx.set(acessosRef, { bloqueio: { motivo: pedido.motivo, desde, ate } }, { merge: true });
    tx.set(registroRef, { acao: 'bloquear', motivo: pedido.motivo, ate, adminUid, em: desde });
  });
  // A suspensão já vale pelas regras; sem a revogação o app só sai na próxima renovação do token.
  let tokensRevogados = true;
  try {
    await auth.revokeRefreshTokens(pedido.uid);
  } catch {
    tokensRevogados = false;
  }
  await registroRef.update({ tokensRevogados });
  return { registroId: registroRef.id, tokensRevogados };
}

/** `desbloquearConta({uid, motivo})` → `{registroId}` (o "Desfazer com motivo" da Ficha suspensa). */
export async function desbloquearContaCore(
  deps: Deps,
  adminUid: string,
  data: unknown,
): Promise<{ registroId: string }> {
  const { db, agora } = deps;
  const d = (data ?? {}) as Record<string, unknown>;
  const uid = uidValido(d.uid);
  const motivo = motivoValido(d.motivo);
  const bloqueioRef = db.doc(`bloqueios/${uid}`);
  const acessosRef = db.doc(`acessos/${uid}`);
  const registroRef = acessosRef.collection('registro').doc();
  await db.runTransaction(async (tx) => {
    const atual = await tx.get(bloqueioRef);
    if (!atual.exists || !bloqueioVigente(atual.data(), agora)) {
      throw new HttpsError('failed-precondition', 'Esta conta não está suspensa.', { codigo: 'naoBloqueada' });
    }
    tx.delete(bloqueioRef);
    tx.set(acessosRef, { bloqueio: FieldValue.delete() }, { merge: true });
    tx.set(registroRef, { acao: 'desbloquear', motivo, adminUid, em: Timestamp.fromDate(agora) });
  });
  return { registroId: registroRef.id };
}
