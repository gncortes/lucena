// Ponto de entrada das Cloud Functions do Lucena (E1.19 R5).
// Cada história acrescenta aqui o export da sua Function. A regra fica no
// módulo (testável no emulador); aqui só a casca: conferir admin e chamar.
import './comum/config';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onCall } from 'firebase-functions/https';
import { exigeAdmin } from './comum/admin';
import { darCursoCore, desfazerCore, revogarCursoCore, type Deps, type Mensageiro } from './pessoas/acessos';
import { buscarPessoaPor, montarFicha } from './pessoas/ficha';

initializeApp();

let mensageiroDeTeste: Mensageiro | null = null;

/** Só para os testes no emulador: troca o FCM por um fake (null volta ao real). */
export function usarMensageiro(m: Mensageiro | null): void {
  mensageiroDeTeste = m;
}

function deps(): Deps {
  return {
    db: getFirestore(),
    auth: getAuth(),
    mensageiro: mensageiroDeTeste ?? getMessaging(),
    agora: new Date(),
  };
}

/** H-R5-32 · A 1ª carga da Ficha (`{uid}`). */
export const fichaUsuario = onCall(async (req) => {
  const db = getFirestore();
  await exigeAdmin(db, req.auth?.uid);
  return montarFicha(db, getAuth(), req.data?.uid, new Date());
});

/** H-R5-32 · Busca por e-mail exato ou uid (`{termo}`). */
export const buscarPessoa = onCall(async (req) => {
  const db = getFirestore();
  await exigeAdmin(db, req.auth?.uid);
  return buscarPessoaPor(db, getAuth(), req.data?.termo);
});

/** H-R5-33 · Dar curso (`{uid, curso, origem?, plano?, ate?, motivo?, enviarPush?}`). */
export const darCurso = onCall(async (req) => {
  const d = deps();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return darCursoCore(d, admin, req.data);
});

/** H-R5-33 · Revogar curso (`{uid, curso, motivo}`). */
export const revogarCurso = onCall(async (req) => {
  const d = deps();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return revogarCursoCore(d, admin, req.data);
});

/** H-R5-33 · Desfazer o último dar/revogar de um curso (`{uid, registroId}`, R19). */
export const desfazer = onCall(async (req) => {
  const d = deps();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return desfazerCore(d, admin, req.data);
});
