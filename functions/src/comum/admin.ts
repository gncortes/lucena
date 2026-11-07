// Quem pode chamar as Functions do painel: só quem tem documento em
// admins/{uid} (criado no console), a mesma regra do isAdmin() das regras do
// Firestore (firebase/firestore.rules).
import { HttpsError } from 'firebase-functions/https';

/** O mínimo do Firestore que a conferência usa (o Admin SDK cumpre). */
export interface LeitorAdmins {
  doc(caminho: string): { get(): Promise<{ exists: boolean }> };
}

/**
 * Confere que [uid] é administrador; senão lança `permission-denied`.
 * Sem login (uid nulo ou vazio) lança `unauthenticated`.
 */
export async function exigeAdmin(db: LeitorAdmins, uid: string | null | undefined): Promise<string> {
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Entre com a conta de administrador.');
  }
  const doc = await db.doc(`admins/${uid}`).get();
  if (!doc.exists) {
    throw new HttpsError('permission-denied', 'Só administradores.');
  }
  return uid;
}
