// Dar, revogar e desfazer curso pela Ficha (R5 §7 e §11 R19; R4 roteiro 4).
// Cada ação grava acessos/{uid} e um item em acessos/{uid}/registro numa
// transação; o push do presente vai depois, fora dela, e grava `pushEm`.
import type { Auth } from 'firebase-admin/auth';
import { FieldValue, Firestore, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';
import { CURSOS, cursoExiste } from '../comum/cursos';

/** O mínimo do FCM que o presente usa (o getMessaging() cumpre; fake nos testes). */
export interface Mensageiro {
  send(mensagem: {
    token: string;
    notification?: { title: string; body: string };
    data: Record<string, string>;
    android?: { priority: 'high' | 'normal' };
  }): Promise<string>;
}

export type ResultadoPush = 'enviado' | 'semPush' | 'naoPedido' | 'falhou';

/** Código do FCM para token que não existe mais (o app chama `deleteToken` ao sair). */
export const TOKEN_NAO_REGISTRADO = 'messaging/registration-token-not-registered';

export interface Deps {
  db: Firestore;
  auth: Auth;
  mensageiro: Mensageiro;
  agora: Date;
}

const ORIGENS_DO_PAINEL = ['presente', 'pagoPorFora'] as const;
const PLANOS = ['vitalicio', 'mensal'] as const;

function invalido(msg: string): never {
  throw new HttpsError('invalid-argument', msg);
}

function textoOpcional(v: unknown, max: number, campo: string): string | null {
  if (v === undefined || v === null || v === '') return null;
  if (typeof v !== 'string' || v.length > max) invalido(`${campo}: texto até ${max} caracteres.`);
  return v.trim();
}

function uidValido(v: unknown): string {
  if (typeof v !== 'string' || v.length === 0 || v.length > 128) invalido('Informe o uid da pessoa.');
  return v;
}

function cursoValido(v: unknown): string {
  if (!cursoExiste(v)) throw new HttpsError('not-found', 'Curso não encontrado.', { codigo: 'cursoNaoExiste' });
  return v;
}

function primeiroNome(nome: string | null | undefined, email: string | null | undefined): string {
  const base = (nome ?? '').trim() || (email ?? '').split('@')[0] || 'A pessoa';
  return base.split(/\s+/)[0];
}

/** Acesso vigente: dado e não revogado. */
function vigente(c: DocumentData | undefined): boolean {
  return !!c && !c.revogadoEm;
}

/** País do perfil (ProgressSummary.profile.country), para a venda por país. */
async function paisDoPerfil(db: Firestore, uid: string): Promise<string | null> {
  const p = (await db.doc(`users/${uid}/progress/summary`).get()).get('profile.country');
  return typeof p === 'string' && p.length > 0 ? p.toUpperCase() : null;
}

export interface PedidoDarCurso {
  uid: string;
  curso: string;
  origem: (typeof ORIGENS_DO_PAINEL)[number];
  plano: (typeof PLANOS)[number];
  ate: Date | null;
  motivo: string | null;
  enviarPush: boolean;
}

export function lerPedidoDarCurso(data: unknown, agora: Date): PedidoDarCurso {
  const d = (data ?? {}) as Record<string, unknown>;
  const origem = d.origem ?? 'presente';
  if (!ORIGENS_DO_PAINEL.includes(origem as never)) invalido('origem: presente ou pagoPorFora.');
  const plano = d.plano ?? 'vitalicio';
  if (!PLANOS.includes(plano as never)) invalido('plano: vitalicio ou mensal.');
  let ate: Date | null = null;
  if (d.ate !== undefined && d.ate !== null) {
    ate = new Date(String(d.ate));
    if (Number.isNaN(ate.getTime())) invalido('ate: data ISO.');
    if (ate <= agora) invalido('ate: a data tem de ser futura.');
  }
  if (plano === 'mensal' && ate === null) invalido('plano mensal pede a data final (ate).');
  if (plano === 'vitalicio' && ate !== null) invalido('plano vitalício não tem data final.');
  return {
    uid: uidValido(d.uid),
    curso: cursoValido(d.curso),
    origem: origem as PedidoDarCurso['origem'],
    plano: plano as PedidoDarCurso['plano'],
    ate,
    motivo: textoOpcional(d.motivo, 200, 'motivo'),
    enviarPush: d.enviarPush !== false,
  };
}

export async function pessoaDoAuth(auth: Auth, uid: string) {
  try {
    return await auth.getUser(uid);
  } catch (e) {
    if ((e as { code?: string }).code === 'auth/user-not-found') {
      throw new HttpsError('not-found', 'Pessoa não encontrada.');
    }
    throw e;
  }
}

/** O texto do aviso de presente (R5 §7). */
export function textoDoPresente(curso: string): { title: string; body: string } {
  return { title: `Você ganhou o ${CURSOS[curso].nome}`, body: 'Os 20 capítulos já estão abertos.' };
}

export async function darCursoCore(
  deps: Deps,
  adminUid: string,
  data: unknown,
): Promise<{ registroId: string; push: ResultadoPush }> {
  const { db, auth, agora } = deps;
  const pedido = lerPedidoDarCurso(data, agora);
  const { uid, curso } = pedido;
  const user = await pessoaDoAuth(auth, uid);
  const pais = await paisDoPerfil(db, uid);
  const acessosRef = db.doc(`acessos/${uid}`);
  const registroRef = acessosRef.collection('registro').doc();
  const quando = Timestamp.fromDate(agora);

  const device = await db.runTransaction(async (tx) => {
    const [acessos, device, perfil] = await tx.getAll(
      acessosRef,
      db.doc(`users/${uid}/push/device`),
      db.doc(`users/${uid}`),
    );
    if (vigente(acessos.get(`cursos.${curso}`))) {
      const nome = primeiroNome(perfil.get('name'), user.email);
      throw new HttpsError('already-exists', `${nome} já tem o ${CURSOS[curso].nome.split(' ')[0]}.`, {
        codigo: 'jaTem',
      });
    }
    const acesso: DocumentData = {
      origem: pedido.origem,
      plano: pedido.plano,
      dadoPor: adminUid,
      dadoEm: quando,
      pais,
    };
    if (pedido.ate) acesso.ate = Timestamp.fromDate(pedido.ate);
    if (pedido.motivo) acesso.motivo = pedido.motivo;
    // O acesso anterior (revogado) sai inteiro: o novo começa limpo.
    tx.set(acessosRef, { cursos: { [curso]: acesso } }, { mergeFields: [`cursos.${curso}`] });
    tx.set(registroRef, {
      acao: 'dar',
      curso,
      origem: pedido.origem,
      plano: pedido.plano,
      ate: acesso.ate ?? null,
      motivo: pedido.motivo,
      anterior: acessos.get(`cursos.${curso}`) ?? null,
      adminUid,
      em: quando,
    });
    return device.data();
  });

  const push = await enviarPresente(deps, pedido, device, registroRef.id);
  return { registroId: registroRef.id, push };
}

async function enviarPresente(
  deps: Deps,
  pedido: PedidoDarCurso,
  device: DocumentData | undefined,
  registroId: string,
): Promise<ResultadoPush> {
  const { db, mensageiro, agora } = deps;
  const registroRef = db.doc(`acessos/${pedido.uid}/registro/${registroId}`);
  if (!pedido.enviarPush) {
    await registroRef.update({ push: 'naoPedido' });
    return 'naoPedido';
  }
  const token = device?.token;
  if (device?.permissao !== 'permitida' || typeof token !== 'string' || token.length === 0) {
    await registroRef.update({ push: 'semPush' });
    return 'semPush';
  }
  try {
    await mensageiro.send({
      token,
      notification: textoDoPresente(pedido.curso),
      data: { tipo: 'presente', curso: pedido.curso },
      android: { priority: 'high' },
    });
  } catch (e) {
    // O acesso já está garantido; o app mostra o presente na próxima abertura.
    // Token que o app invalidou ao sair da conta (Dúvida 3) = sem push; o resto (FCM fora) = falhou.
    const semPush = (e as { code?: unknown })?.code === TOKEN_NAO_REGISTRADO;
    const resultado: ResultadoPush = semPush ? 'semPush' : 'falhou';
    await registroRef.update({ push: resultado });
    return resultado;
  }
  const quando = Timestamp.fromDate(agora);
  await db.doc(`acessos/${pedido.uid}`).update({ [`cursos.${pedido.curso}.pushEm`]: quando });
  await registroRef.update({ push: 'enviado', pushEm: quando });
  return 'enviado';
}

export async function revogarCursoCore(
  deps: Deps,
  adminUid: string,
  data: unknown,
): Promise<{ registroId: string }> {
  const { db, agora } = deps;
  const d = (data ?? {}) as Record<string, unknown>;
  const uid = uidValido(d.uid);
  const curso = cursoValido(d.curso);
  const motivo = textoOpcional(d.motivo, 200, 'motivo');
  if (!motivo) invalido('Informe o motivo da revogação.');
  const acessosRef = db.doc(`acessos/${uid}`);
  const registroRef = acessosRef.collection('registro').doc();
  const quando = Timestamp.fromDate(agora);
  await db.runTransaction(async (tx) => {
    const acessos = await tx.get(acessosRef);
    if (!vigente(acessos.get(`cursos.${curso}`))) {
      throw new HttpsError('failed-precondition', 'A pessoa não tem este curso.', { codigo: 'semCurso' });
    }
    tx.update(acessosRef, {
      [`cursos.${curso}.revogadoEm`]: quando,
      [`cursos.${curso}.revogadoPor`]: adminUid,
      [`cursos.${curso}.motivoRevogacao`]: motivo,
    });
    tx.set(registroRef, { acao: 'revogar', curso, motivo, adminUid, em: quando });
  });
  return { registroId: registroRef.id };
}

/**
 * Desfaz um "dar" (o curso volta ao que era antes: sem acesso ou o acesso
 * revogado anterior) ou um "revogar" (o acesso volta a valer). Só o último
 * registro daquele curso pode ser desfeito, uma vez.
 */
export async function desfazerCore(
  deps: Deps,
  adminUid: string,
  data: unknown,
): Promise<{ registroId: string }> {
  const { db, agora } = deps;
  const d = (data ?? {}) as Record<string, unknown>;
  const uid = uidValido(d.uid);
  if (typeof d.registroId !== 'string' || d.registroId.length === 0 || d.registroId.length > 64) {
    invalido('Informe o registro a desfazer.');
  }
  const acessosRef = db.doc(`acessos/${uid}`);
  const alvoRef = acessosRef.collection('registro').doc(d.registroId);
  const novoRef = acessosRef.collection('registro').doc();
  const quando = Timestamp.fromDate(agora);
  await db.runTransaction(async (tx) => {
    const alvo = await tx.get(alvoRef);
    if (!alvo.exists) throw new HttpsError('not-found', 'Registro não encontrado.');
    const r = alvo.data()!;
    if (r.desfeitoEm) {
      throw new HttpsError('failed-precondition', 'Esta ação já foi desfeita.', { codigo: 'jaDesfeito' });
    }
    if (r.acao !== 'dar' && r.acao !== 'revogar') {
      throw new HttpsError('failed-precondition', 'Esta ação não se desfaz por aqui.', { codigo: 'naoDesfaz' });
    }
    const ultimos = await tx.get(
      acessosRef.collection('registro').where('curso', '==', r.curso).orderBy('em', 'desc').limit(1),
    );
    if (ultimos.docs[0]?.id !== alvo.id) {
      throw new HttpsError('failed-precondition', 'O curso mudou depois desta ação.', { codigo: 'mudou' });
    }
    if (r.acao === 'dar') {
      tx.update(acessosRef, {
        [`cursos.${r.curso}`]: r.anterior ?? FieldValue.delete(),
      });
    } else {
      tx.update(acessosRef, {
        [`cursos.${r.curso}.revogadoEm`]: FieldValue.delete(),
        [`cursos.${r.curso}.revogadoPor`]: FieldValue.delete(),
        [`cursos.${r.curso}.motivoRevogacao`]: FieldValue.delete(),
      });
    }
    tx.update(alvoRef, { desfeitoEm: quando, desfeitoPor: adminUid });
    tx.set(novoRef, { acao: 'desfazer', curso: r.curso, desfaz: alvo.id, adminUid, em: quando });
  });
  return { registroId: novoRef.id };
}
