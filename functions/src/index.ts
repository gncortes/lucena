// Ponto de entrada das Cloud Functions do Lucena (E1.19 R5).
// Cada história acrescenta aqui o export da sua Function. A regra fica no
// módulo (testável no emulador); aqui só a casca: conferir admin e chamar.
import './comum/config';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { HttpsError, onCall, onRequest } from 'firebase-functions/https';
import { defineString } from 'firebase-functions/params';
import { onSchedule } from 'firebase-functions/scheduler';
import { exigeAdmin } from './comum/admin';
import { getStorage } from 'firebase-admin/storage';
import { AgentesPausados, importarLoteCore } from './agentes/importar';
import { decidirEntregaCore, marcarFonteConferidaCore } from './conteudo/entregas';
import { leitorDoStorage } from './conteudo/storage';
import {
  conferirVersaoCore,
  pedirCorrecaoCore,
  publicarVersaoCore,
  reverterVersaoCore,
  type DepsVersoes,
} from './conteudo/versoes';
import { FUSO } from './comum/config';
import { analyticsDoBigQuery, atencaoDoAnalytics, ativosDoBigQuery } from './fechamento/bigquery';
import { ativosPeriodoCore } from './fechamento/periodo';
import { atualizarHoje, fecharDia, type DepsFechamento } from './fechamento/fechar';
import { darCursoCore, desfazerCore, revogarCursoCore, type Deps, type Mensageiro } from './pessoas/acessos';
import { bloquearContaCore, desbloquearContaCore } from './pessoas/bloqueio';
import { buscarPessoaPor, montarFicha } from './pessoas/ficha';
import { playNaoConfigurada } from './promocoes/play';
import { conferirCompraCore } from './compras/compras';
import {
  playComprasNaoConfigurada,
  playComprasSimulada,
  playSimuladaNoAmbiente,
  type PlayCompras,
} from './compras/play';
import { PRODUTO } from './promocoes/regras';
import {
  criarPromocaoCore,
  editarPromocaoCore,
  encerrarPromocaoCore,
  republicarPromocaoCore,
  reservarVagaCore,
  validarCupomCore,
  type DepsPromocoes,
  type PlayOfertas,
} from './promocoes/promocoes';
import { cancelarPushCore, contarPublicoCore, dispararAgendadosCore, enviarPushCore } from './pessoas/push';

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

/** H-R5-37 · Aprovar ou reprovar um item da Caixa (`{id, decisao, motivo?, frase?, agendadoPara?}`, R9/R13). */
export const decidirEntrega = onCall(async (req) => {
  const db = getFirestore();
  const admin = await exigeAdmin(db, req.auth?.uid);
  return decidirEntregaCore({ db, agora: new Date() }, admin, req.data);
});

/** H-R5-37 · Marcar a fonte `indice` do item como conferida (`{id, indice}`, R13). */
export const marcarFonteConferida = onCall(async (req) => {
  const db = getFirestore();
  const admin = await exigeAdmin(db, req.auth?.uid);
  return marcarFonteConferidaCore({ db, agora: new Date() }, admin, req.data);
});

let bucketDeTeste: string | null = null;

/** Só para os testes no emulador: o bucket do Storage com o pacote de fixture. */
export function usarBucket(nome: string | null): void {
  bucketDeTeste = nome;
}

function depsVersoes(): DepsVersoes {
  const bucket = bucketDeTeste ? getStorage().bucket(bucketDeTeste) : getStorage().bucket();
  return { db: getFirestore(), conteudo: leitorDoStorage(bucket), agora: new Date() };
}

/** H-R5-38 · Publicar uma revisão no app de teste ou no dos alunos (`{id, destino}`). */
export const publicarVersao = onCall(async (req) => {
  const d = depsVersoes();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return publicarVersaoCore(d, admin, req.data);
});

/** H-R5-38 · "Marcar como conferida" no app de teste (`{id}`). */
export const conferirVersao = onCall(async (req) => {
  const d = depsVersoes();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return conferirVersaoCore(d, admin, req.data);
});

/** H-R5-38 · Voltar o app dos alunos para uma versão que já esteve no ar (`{id}`). */
export const reverterVersao = onCall(async (req) => {
  const d = depsVersoes();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return reverterVersaoCore(d, admin, req.data);
});

/** H-R5-38 · Pedir a correção de uma fala (`{chave, revisao, problema, texto?, numero?}`, R16). */
export const pedirCorrecao = onCall(async (req) => {
  const d = depsVersoes();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return pedirCorrecaoCore(d, admin, req.data);
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

/** H-R5-39 · Suspender a conta (`{uid, motivo, regra?, ate?}`). */
export const bloquearConta = onCall(async (req) => {
  const d = deps();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return bloquearContaCore(d, admin, req.data);
});

/** H-R5-39 · Desfazer a suspensão (`{uid, motivo}`). */
export const desbloquearConta = onCall(async (req) => {
  const d = deps();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return desbloquearContaCore(d, admin, req.data);
});

/** H-R5-39 · Quantos recebem (`{destino}`), antes de confirmar. */
export const contarPublico = onCall(async (req) => {
  const d = deps();
  await exigeAdmin(d.db, req.auth?.uid);
  return contarPublicoCore(d, req.data);
});

/** H-R5-39 · Enviar agora ou agendar (`{destino, titulo, texto, tipo?, link?, agendadoPara?}`). */
export const enviarPush = onCall({ timeoutSeconds: 300 }, async (req) => {
  const d = deps();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return enviarPushCore(d, admin, req.data);
});

/** H-R5-39 · Cancelar um push agendado (`{id}`). */
export const cancelarPush = onCall(async (req) => {
  const d = deps();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return cancelarPushCore(d, admin, req.data);
});

/** H-R5-39 · Os agendados vencidos saem a cada 5 minutos. */
export const pushesAgendados = onSchedule(
  { schedule: 'every 5 minutes', timeZone: FUSO, timeoutSeconds: 540, retryCount: 0 },
  async () => {
    await dispararAgendadosCore(deps());
  },
);

/** H-R5-34 · Lote de hora em hora: só `painel/hoje`. */
export const painelHoje = onSchedule({ schedule: '5 * * * *', timeZone: FUSO, retryCount: 0 }, async () => {
  await atualizarHoje(depsFechamento());
});

let playDeTeste: PlayOfertas | null = null;

/** Só para os testes: troca a Play Developer API por um fake (null volta à real). */
export function usarPlay(p: PlayOfertas | null): void {
  playDeTeste = p;
}

function depsPromocoes(): DepsPromocoes {
  return { db: getFirestore(), play: playDeTeste ?? playNaoConfigurada, agora: new Date() };
}

/** H-R5-74 · Criar Para todos ou link (`{tipo, nome, desconto, inicio?, fim?, origem?, parceiro?, codigo?, limite?}`, R21/R22). */
export const criarPromocao = onCall(async (req) => {
  const d = depsPromocoes();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return criarPromocaoCore(d, admin, req.data);
});

/** H-R5-74 · Só nome e limite de usos (`{id, nome?, limite?}`, regra 7). */
export const editarPromocao = onCall(async (req) => {
  const d = depsPromocoes();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return editarPromocaoCore(d, admin, req.data);
});

/** H-R5-74 · Encerrar à mão (`{id}`, R25). */
export const encerrarPromocao = onCall(async (req) => {
  const d = depsPromocoes();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return encerrarPromocaoCore(d, admin, req.data);
});

/** H-R5-74 · Tentar de novo uma "Não publicada" (`{id}`). */
export const republicarPromocao = onCall(async (req) => {
  const d = depsPromocoes();
  const admin = await exigeAdmin(d.db, req.auth?.uid);
  return republicarPromocaoCore(d, admin, req.data);
});

/** H-R5-74 · App: o código do link vale? (`{codigo}`, R23; pede conta). */
export const validarCupom = onCall(async (req) => validarCupomCore(depsPromocoes(), req.auth?.uid, req.data));

/** H-R5-74 · App: segura a vaga do link por 30 min antes de comprar (`{codigo}`, R24). */
export const reservarVaga = onCall(async (req) => reservarVagaCore(depsPromocoes(), req.auth?.uid, req.data));

let playComprasDeTeste: PlayCompras | null = null;
// Dev e emulador: Play simulada por tokens `teste:` (decisão do Gabriel); produção: a real, quando ligada.
const playComprasDoAmbiente: PlayCompras = playSimuladaNoAmbiente() ? playComprasSimulada(PRODUTO) : playComprasNaoConfigurada;

/** Só para os testes: troca a conferência de compras da Play (null volta à do ambiente). */
export function usarPlayCompras(p: PlayCompras | null): void {
  playComprasDeTeste = p;
}

/** H-R5-3A · App: confere a compra pelo token (`{token}`, R24) e libera o curso. */
export const conferirCompra = onCall(async (req) => {
  const p = depsPromocoes();
  return conferirCompraCore(
    { db: p.db, play: playComprasDeTeste ?? playComprasDoAmbiente, ofertas: p.play, agora: p.agora },
    req.auth?.uid,
    req.data,
  );
});

/**
 * AG-5b.1 · O porteiro dos agentes noturnos (`POST {loteId, conteudo}`, E1.21 §6.1). Sem acesso público: o
 * run.invoker da conta porteiro-agentes (WIF) e a reconferência do ID token entram na AG-5b.3; motor e
 * tablebase na AG-5b.2.
 */
export const importarLote = onRequest({ invoker: 'private', timeoutSeconds: 60 }, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ erro: 'Use POST.' });
    return;
  }
  try {
    res.json(await importarLoteCore({ db: getFirestore(), agora: new Date() }, req.body));
  } catch (e) {
    if (e instanceof AgentesPausados) {
      res.status(423).json({ erro: e.message, detalhes: { codigo: 'pausado', motivo: e.motivo } });
      return;
    }
    if (e instanceof HttpsError) {
      res.status(e.httpErrorCode.status).json({ erro: e.message, detalhes: e.details ?? null });
      return;
    }
    throw e;
  }
});
