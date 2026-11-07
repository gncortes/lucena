// H-R5-33 · darCurso, revogarCurso e desfazer no emulador, com FCM fake.
import { afterEach, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { darCurso, desfazer, revogarCurso, usarMensageiro } from '../../src/index';
import type { Mensageiro, ResultadoPush } from '../../src/pessoas/acessos';
import { chamar, codigoDoErro, criarAdmin, criarPessoa, limpar } from './apoio';

type Enviada = Parameters<Mensageiro['send']>[0];
let enviadas: Enviada[] = [];
let fcmFalha = false;

beforeEach(async () => {
  await limpar();
  await criarAdmin();
  enviadas = [];
  fcmFalha = false;
  usarMensageiro({
    async send(m) {
      if (fcmFalha) throw new Error('registration-token-not-registered');
      enviadas.push(m);
      return 'msg-1';
    },
  });
});

afterEach(() => usarMensageiro(null));

async function aparelho(uid: string, permissao: string, token = 'tok-' + uid): Promise<void> {
  await getFirestore().doc(`users/${uid}/push/device`).set({ token, updatedAt: Timestamp.now(), permissao });
}

async function acessos(uid: string) {
  return (await getFirestore().doc(`acessos/${uid}`).get()).data();
}

async function registros(uid: string) {
  const s = await getFirestore().collection(`acessos/${uid}/registro`).orderBy('em').get();
  return s.docs.map((d) => ({ id: d.id, ...d.data() }));
}

type Dado = { registroId: string; push: ResultadoPush };

describe('darCurso', () => {
  test('grava o acesso, o registro e manda o presente com pushEm', async () => {
    await criarPessoa('rafael', 'rafael@exemplo.com', 'Rafael Lima');
    await aparelho('rafael', 'permitida');
    await getFirestore().doc('users/rafael/progress/summary').set({ profile: { country: 'br' } });

    const r = await chamar<Dado>(darCurso, 'admin', { uid: 'rafael', curso: 'pilares', motivo: 'Sorteio da live' });

    assert.equal(r.push, 'enviado');
    const a = (await acessos('rafael'))!.cursos.pilares;
    assert.equal(a.origem, 'presente');
    assert.equal(a.plano, 'vitalicio');
    assert.equal(a.motivo, 'Sorteio da live');
    assert.equal(a.dadoPor, 'admin');
    assert.equal(a.pais, 'BR');
    assert.ok(a.pushEm instanceof Timestamp);
    assert.equal(enviadas.length, 1);
    assert.equal(enviadas[0].token, 'tok-rafael');
    assert.deepEqual(enviadas[0].data, { tipo: 'presente', curso: 'pilares' });
    const [reg] = await registros('rafael');
    assert.equal(reg.id, r.registroId);
    assert.equal((reg as Record<string, unknown>).acao, 'dar');
    assert.equal((reg as Record<string, unknown>).push, 'enviado');
  });

  test('sem permissão ou sem token: acesso dado, "Sem push" no registro, nada enviado', async () => {
    await criarPessoa('marina', 'marina@exemplo.com');
    await aparelho('marina', 'negada');
    const r = await chamar<Dado>(darCurso, 'admin', { uid: 'marina', curso: 'pilares' });
    assert.equal(r.push, 'semPush');
    assert.equal(enviadas.length, 0);
    assert.equal((await acessos('marina'))!.cursos.pilares.pushEm, undefined);

    await criarPessoa('ana', 'ana@exemplo.com');
    assert.equal((await chamar<Dado>(darCurso, 'admin', { uid: 'ana', curso: 'pilares' })).push, 'semPush');
  });

  test('FCM falha: o acesso fica e o registro diz "falhou"', async () => {
    await criarPessoa('rafael', 'rafael@exemplo.com');
    await aparelho('rafael', 'permitida');
    fcmFalha = true;
    const r = await chamar<Dado>(darCurso, 'admin', { uid: 'rafael', curso: 'pilares' });
    assert.equal(r.push, 'falhou');
    assert.ok((await acessos('rafael'))!.cursos.pilares.dadoEm);
  });

  test('quem já tem: "Rafael já tem o Pilares"; não admin, sem pessoa e curso inexistente', async () => {
    await criarPessoa('rafael', 'rafael@exemplo.com');
    await getFirestore().doc('users/rafael').set({ name: 'Rafael Lima' });
    await chamar<Dado>(darCurso, 'admin', { uid: 'rafael', curso: 'pilares', enviarPush: false });
    await assert.rejects(chamar(darCurso, 'admin', { uid: 'rafael', curso: 'pilares' }), {
      code: 'already-exists',
      message: 'Rafael já tem o Pilares.',
    });
    assert.equal(await codigoDoErro(chamar(darCurso, 'rafael', { uid: 'rafael', curso: 'pilares' })), 'permission-denied');
    assert.equal(await codigoDoErro(chamar(darCurso, 'admin', { uid: 'ninguem', curso: 'pilares' })), 'not-found');
    assert.equal(await codigoDoErro(chamar(darCurso, 'admin', { uid: 'rafael', curso: 'xyz' })), 'not-found');
    assert.equal((await registros('rafael')).length, 1);
  });
});

describe('revogarCurso e desfazer', () => {
  test('revogar pede motivo e marca revogadoEm; desfazer devolve o acesso', async () => {
    await criarPessoa('rafael', 'rafael@exemplo.com');
    await chamar<Dado>(darCurso, 'admin', { uid: 'rafael', curso: 'pilares', enviarPush: false });
    assert.equal(
      await codigoDoErro(chamar(revogarCurso, 'admin', { uid: 'rafael', curso: 'pilares' })),
      'invalid-argument',
    );
    const rev = await chamar<{ registroId: string }>(revogarCurso, 'admin', {
      uid: 'rafael',
      curso: 'pilares',
      motivo: 'Dado por engano',
    });
    assert.ok((await acessos('rafael'))!.cursos.pilares.revogadoEm);
    assert.equal(
      await codigoDoErro(chamar(revogarCurso, 'admin', { uid: 'rafael', curso: 'pilares', motivo: 'de novo' })),
      'failed-precondition',
    );

    await chamar(desfazer, 'admin', { uid: 'rafael', registroId: rev.registroId });
    const a = (await acessos('rafael'))!.cursos.pilares;
    assert.equal(a.revogadoEm, undefined);
    assert.equal(a.motivoRevogacao, undefined);
    assert.equal(
      await codigoDoErro(chamar(desfazer, 'admin', { uid: 'rafael', registroId: rev.registroId })),
      'failed-precondition',
    );
  });

  test('desfazer um "dar" tira o curso; só o último registro se desfaz', async () => {
    await criarPessoa('rafael', 'rafael@exemplo.com');
    const dado = await chamar<Dado>(darCurso, 'admin', { uid: 'rafael', curso: 'pilares', enviarPush: false });
    await chamar(desfazer, 'admin', { uid: 'rafael', registroId: dado.registroId });
    assert.deepEqual((await acessos('rafael'))!.cursos, {});

    const dado2 = await chamar<Dado>(darCurso, 'admin', { uid: 'rafael', curso: 'pilares', enviarPush: false });
    await chamar(revogarCurso, 'admin', { uid: 'rafael', curso: 'pilares', motivo: 'teste' });
    assert.equal(
      await codigoDoErro(chamar(desfazer, 'admin', { uid: 'rafael', registroId: dado2.registroId })),
      'failed-precondition',
    );
    assert.equal(await codigoDoErro(chamar(desfazer, 'admin', { uid: 'rafael', registroId: 'nada' })), 'not-found');
  });

  test('dar de novo depois de revogar guarda o acesso anterior; desfazer volta a ele', async () => {
    await criarPessoa('rafael', 'rafael@exemplo.com');
    await chamar<Dado>(darCurso, 'admin', { uid: 'rafael', curso: 'pilares', enviarPush: false, motivo: 'primeiro' });
    await chamar(revogarCurso, 'admin', { uid: 'rafael', curso: 'pilares', motivo: 'engano' });
    const dado = await chamar<Dado>(darCurso, 'admin', { uid: 'rafael', curso: 'pilares', enviarPush: false });
    assert.equal((await acessos('rafael'))!.cursos.pilares.motivo, undefined);
    await chamar(desfazer, 'admin', { uid: 'rafael', registroId: dado.registroId });
    const a = (await acessos('rafael'))!.cursos.pilares;
    assert.equal(a.motivo, 'primeiro');
    assert.ok(a.revogadoEm);
  });
});
