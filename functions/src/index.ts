// Ponto de entrada das Cloud Functions do Lucena (E1.19 R5).
// Cada história acrescenta aqui o export da sua Function. A regra fica no
// módulo (testável no emulador); aqui só a casca: conferir admin e chamar.
import './comum/config';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/https';
import { exigeAdmin } from './comum/admin';
import { buscarPessoaPor, montarFicha } from './pessoas/ficha';

initializeApp();

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
