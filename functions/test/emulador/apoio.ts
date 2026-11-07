// Apoio aos testes no emulador (Auth e Firestore): limpar entre testes,
// criar admin e chamar uma callable como o painel chamaria.
import assert from 'node:assert/strict';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';

export const PROJETO = process.env.GCLOUD_PROJECT ?? 'demo-lucena';

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error('Rode pelo emulador: npm --prefix functions run test:emulador');
}

export async function limpar(): Promise<void> {
  const firestore = process.env.FIRESTORE_EMULATOR_HOST;
  const auth = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  await fetch(`http://${firestore}/emulator/v1/projects/${PROJETO}/databases/(default)/documents`, {
    method: 'DELETE',
  });
  await fetch(`http://${auth}/emulator/v1/projects/${PROJETO}/accounts`, { method: 'DELETE' });
}

export async function criarAdmin(uid = 'admin'): Promise<void> {
  await getFirestore().doc(`admins/${uid}`).set({ desde: new Date() });
}

export async function criarPessoa(
  uid: string,
  email: string,
  nome?: string,
): Promise<void> {
  await getAuth().createUser({ uid, email, displayName: nome, password: 'senha-de-teste' });
}

type Chamavel = { run(req: unknown): unknown };

/** Chama a callable com o login de [uid] (null = sem login). */
export function chamar<T>(fn: Chamavel, uid: string | null, data: unknown): Promise<T> {
  return Promise.resolve(
    fn.run({
      data,
      auth: uid ? { uid, token: { uid } } : undefined,
      rawRequest: {},
      acceptsStreaming: false,
    }),
  ) as Promise<T>;
}

export async function codigoDoErro(promessa: Promise<unknown>): Promise<string> {
  try {
    await promessa;
  } catch (e) {
    assert.ok(e instanceof HttpsError, String(e));
    return e.code;
  }
  assert.fail('devia ter lançado');
}
