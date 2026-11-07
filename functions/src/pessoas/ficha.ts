// A Ficha da pessoa (R4 "Ficha: o que carrega"; R5 §7 e §11 R19) e a busca
// por e-mail. 1ª carga = Auth (0 leituras) + acessos/{uid} + users/{uid} +
// users/{uid}/push/device = 3 leituras, num getAll só.
import type { Auth, UserRecord } from 'firebase-admin/auth';
import type { DocumentData, Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';
import { iso } from '../comum/datas';

export type Situacao = 'ativa' | 'suspensa' | 'encerrada';
export type Permissao = 'permitida' | 'negada' | 'nunca';

export interface AcessoFicha {
  curso: string;
  origem: string | null;
  plano: string | null;
  ate: string | null;
  motivo: string | null;
  dadoPor: string | null;
  dadoEm: string | null;
  revogadoEm: string | null;
  pushEm: string | null;
  vistoEm: string | null;
  pais: string | null;
}

export interface Ficha {
  uid: string;
  email: string | null;
  nome: string | null;
  provedores: string[];
  cadastroEm: string | null;
  ultimoLoginEm: string | null;
  situacao: Situacao;
  bloqueio: { motivo: string | null; desde: string | null; ate: string | null } | null;
  acessos: AcessoFicha[];
  notificacoes: {
    permissao: Permissao;
    conferidoEm: string | null;
    ultimaAbertura: string | null;
    temToken: boolean;
  };
}

export interface PessoaEncontrada {
  uid: string;
  email: string | null;
  nome: string | null;
  cadastroEm: string | null;
}

const texto = (v: unknown): string | null => (typeof v === 'string' && v.length > 0 ? v : null);

/**
 * Situação da conta: encerrada (Auth desativado), suspensa (resumo do
 * bloqueio vigente que a bloquearConta grava em acessos/{uid}.bloqueio) ou
 * ativa.
 */
export function situacaoDaConta(
  desativada: boolean,
  bloqueio: DocumentData | undefined,
  agora: Date,
): Situacao {
  if (desativada) return 'encerrada';
  if (bloqueio && typeof bloqueio === 'object') {
    const ate = iso(bloqueio.ate);
    if (ate === null || new Date(ate) > agora) return 'suspensa';
  }
  return 'ativa';
}

export function permissaoDoAparelho(device: DocumentData | undefined): Permissao {
  const p = device?.permissao;
  return p === 'permitida' || p === 'negada' ? p : 'nunca';
}

export function acessosDaFicha(acessos: DocumentData | undefined): AcessoFicha[] {
  const cursos = (acessos?.cursos ?? {}) as Record<string, DocumentData>;
  const vistos = (acessos?.vistos ?? {}) as Record<string, unknown>;
  return Object.keys(cursos)
    .sort()
    .map((curso) => {
      const c = cursos[curso] ?? {};
      return {
        curso,
        origem: texto(c.origem),
        plano: texto(c.plano),
        ate: iso(c.ate),
        motivo: texto(c.motivo),
        dadoPor: texto(c.dadoPor),
        dadoEm: iso(c.dadoEm),
        revogadoEm: iso(c.revogadoEm),
        pushEm: iso(c.pushEm),
        vistoEm: iso(vistos[curso]),
        pais: texto(c.pais),
      };
    });
}

function nomeDe(user: UserRecord, perfil: DocumentData | undefined): string | null {
  return texto(perfil?.name) ?? texto(user.displayName);
}

async function usuarioOuNulo(promessa: Promise<UserRecord>): Promise<UserRecord | null> {
  try {
    return await promessa;
  } catch (e) {
    if ((e as { code?: string }).code === 'auth/user-not-found') return null;
    throw e;
  }
}

/** A 1ª carga da Ficha. Pessoa inexistente → `not-found`. */
export async function montarFicha(
  db: Firestore,
  auth: Auth,
  uid: unknown,
  agora: Date,
): Promise<Ficha> {
  if (typeof uid !== 'string' || uid.length === 0 || uid.length > 128) {
    throw new HttpsError('invalid-argument', 'Informe o uid da pessoa.');
  }
  const [user, docs] = await Promise.all([
    usuarioOuNulo(auth.getUser(uid)),
    db.getAll(db.doc(`acessos/${uid}`), db.doc(`users/${uid}`), db.doc(`users/${uid}/push/device`)),
  ]);
  if (user === null) throw new HttpsError('not-found', 'Pessoa não encontrada.');
  const [acessos, perfil, device] = docs.map((d) => d.data());
  const bloqueio = acessos?.bloqueio as DocumentData | undefined;
  const situacao = situacaoDaConta(user.disabled, bloqueio, agora);
  return {
    uid,
    email: user.email ?? null,
    nome: nomeDe(user, perfil),
    provedores: user.providerData.map((p) => p.providerId).sort(),
    cadastroEm: iso(user.metadata.creationTime),
    ultimoLoginEm: iso(user.metadata.lastRefreshTime ?? user.metadata.lastSignInTime),
    situacao,
    bloqueio:
      situacao === 'suspensa' && bloqueio
        ? { motivo: texto(bloqueio.motivo), desde: iso(bloqueio.desde), ate: iso(bloqueio.ate) }
        : null,
    acessos: acessosDaFicha(acessos),
    notificacoes: {
      permissao: permissaoDoAparelho(device),
      conferidoEm: iso(device?.conferidoEm),
      ultimaAbertura: iso(device?.ultimaAbertura),
      temToken: typeof device?.token === 'string' && device.token.length > 0,
    },
  };
}

/**
 * Busca por e-mail exato (ou uid) direto no Auth: acha quem se cadastrou há
 * minutos, sem esperar índice nem fechamento. Sem resultado → `pessoa: null`.
 */
export async function buscarPessoaPor(
  db: Firestore,
  auth: Auth,
  termo: unknown,
): Promise<{ pessoa: PessoaEncontrada | null }> {
  if (typeof termo !== 'string' || termo.trim().length === 0 || termo.length > 320) {
    throw new HttpsError('invalid-argument', 'Informe o e-mail da pessoa.');
  }
  const t = termo.trim();
  const user = t.includes('@')
    ? await usuarioOuNulo(auth.getUserByEmail(t.toLowerCase()))
    : await usuarioOuNulo(auth.getUser(t));
  if (user === null) return { pessoa: null };
  const perfil = (await db.doc(`users/${user.uid}`).get()).data();
  return {
    pessoa: {
      uid: user.uid,
      email: user.email ?? null,
      nome: nomeDe(user, perfil),
      cadastroEm: iso(user.metadata.creationTime),
    },
  };
}
