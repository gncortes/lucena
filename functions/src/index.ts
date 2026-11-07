// Ponto de entrada das Cloud Functions do Lucena (E1.19 R5).
// Cada história acrescenta aqui o export da sua Function. A regra fica no
// módulo (testável no emulador); aqui só a casca: conferir admin e chamar.
import './comum/config';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onCall } from 'firebase-functions/https';
import { defineString } from 'firebase-functions/params';
import { onSchedule } from 'firebase-functions/scheduler';
import { exigeAdmin } from './comum/admin';
import { FUSO } from './comum/config';
import { analyticsDoBigQuery, atencaoDoAnalytics, ativosDoBigQuery } from './fechamento/bigquery';
import { ativosPeriodoCore } from './fechamento/periodo';
import { atualizarHoje, fecharDia, type DepsFechamento } from './fechamento/fechar';
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

/** Dataset do export do Analytics no BigQuery (`analytics_<id da propriedade>`), em `functions/.env.<projeto>`. */
const DATASET_ANALYTICS = defineString('ANALYTICS_DATASET', {
  description: 'Dataset do export do GA4 no BigQuery, ex.: analytics_123456789',
});

function depsFechamento(): DepsFechamento {
  return { db: getFirestore(), analytics: analyticsDoBigQuery(DATASET_ANALYTICS.value()), agora: new Date() };
}

/** H-R5-35 · O id da propriedade GA4 é o do nome do dataset (`analytics_<id>`). */
function depsDoDia(): DepsFechamento {
  const dataset = DATASET_ANALYTICS.value();
  return { ...depsFechamento(), atencao: atencaoDoAnalytics(dataset, dataset.replace(/^analytics_/, '')) };
}

/** H-R5-34 · Fecha ontem às 03:00 (Brasília); sem o export, tenta de hora em hora até 14:00 (R18). */
export const fechamentoDia = onSchedule(
  { schedule: '0 3-14 * * *', timeZone: FUSO, timeoutSeconds: 540, retryCount: 0 },
  async () => {
    await fecharDia(depsDoDia());
  },
);

/** H-R5-36 · Ativos de um período personalizado (`{inicio, fim}` em aaaa-mm-dd), 1 consulta ao BigQuery. */
export const ativosPeriodo = onCall(async (req) => {
  await exigeAdmin(getFirestore(), req.auth?.uid);
  return ativosPeriodoCore(ativosDoBigQuery(DATASET_ANALYTICS.value()), req.data, new Date());
});

/** H-R5-34 · Lote de hora em hora: só `painel/hoje`. */
export const painelHoje = onSchedule({ schedule: '5 * * * *', timeZone: FUSO, retryCount: 0 }, async () => {
  await atualizarHoje(depsFechamento());
});
