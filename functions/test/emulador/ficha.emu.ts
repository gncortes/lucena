// H-R5-32 · fichaUsuario e buscarPessoa no emulador (Auth e Firestore).
import { beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { buscarPessoa, fichaUsuario } from '../../src/index';
import type { Ficha, PessoaEncontrada } from '../../src/pessoas/ficha';
import { chamar, codigoDoErro, criarAdmin, criarPessoa, limpar } from './apoio';

beforeEach(async () => {
  await limpar();
  await criarAdmin();
});

describe('fichaUsuario', () => {
  test('junta Auth, acessos, perfil e aparelho (Rafael com o Pilares dado)', async () => {
    await criarPessoa('rafael', 'rafael.lima@exemplo.com', 'Rafael Lima');
    const db = getFirestore();
    const dadoEm = Timestamp.fromDate(new Date('2026-11-26T18:22:00Z'));
    await db.doc('acessos/rafael').set({
      cursos: {
        pilares: {
          origem: 'presente',
          plano: 'vitalicio',
          motivo: 'Sorteio da live',
          dadoPor: 'admin',
          dadoEm,
          pushEm: dadoEm,
          pais: 'BR',
        },
      },
      vistos: { pilares: Timestamp.fromDate(new Date('2026-11-26T18:24:00Z')) },
    });
    await db.doc('users/rafael').set({ name: 'Rafael', updatedAt: Timestamp.now() });
    await db.doc('users/rafael/push/device').set({
      token: 'tok',
      updatedAt: Timestamp.now(),
      permissao: 'permitida',
      conferidoEm: dadoEm,
      ultimaAbertura: dadoEm,
    });

    const ficha = await chamar<Ficha>(fichaUsuario, 'admin', { uid: 'rafael' });

    assert.equal(ficha.email, 'rafael.lima@exemplo.com');
    assert.equal(ficha.nome, 'Rafael');
    assert.deepEqual(ficha.provedores, ['password']);
    assert.ok(ficha.cadastroEm);
    assert.equal(ficha.situacao, 'ativa');
    assert.equal(ficha.bloqueio, null);
    assert.equal(ficha.acessos.length, 1);
    assert.deepEqual(ficha.acessos[0], {
      curso: 'pilares',
      origem: 'presente',
      plano: 'vitalicio',
      ate: null,
      motivo: 'Sorteio da live',
      dadoPor: 'admin',
      dadoEm: '2026-11-26T18:22:00.000Z',
      revogadoEm: null,
      pushEm: '2026-11-26T18:22:00.000Z',
      vistoEm: '2026-11-26T18:24:00.000Z',
      pais: 'BR',
    });
    assert.deepEqual(ficha.notificacoes, {
      permissao: 'permitida',
      conferidoEm: '2026-11-26T18:22:00.000Z',
      ultimaAbertura: '2026-11-26T18:22:00.000Z',
      temToken: true,
    });
  });

  test('pessoa recém-cadastrada sem documentos: ativa, sem acessos, nunca perguntado', async () => {
    await criarPessoa('marina', 'marina@exemplo.com', 'Marina');
    const ficha = await chamar<Ficha>(fichaUsuario, 'admin', { uid: 'marina' });
    assert.equal(ficha.nome, 'Marina');
    assert.deepEqual(ficha.acessos, []);
    assert.deepEqual(ficha.notificacoes, {
      permissao: 'nunca',
      conferidoEm: null,
      ultimaAbertura: null,
      temToken: false,
    });
  });

  test('bloqueio vigente aparece como suspensa', async () => {
    await criarPessoa('carlos', 'carlos@exemplo.com');
    await getFirestore().doc('acessos/carlos').set({
      bloqueio: { motivo: 'spam', desde: Timestamp.now(), ate: Timestamp.fromDate(new Date('2099-12-26')) },
    });
    const ficha = await chamar<Ficha>(fichaUsuario, 'admin', { uid: 'carlos' });
    assert.equal(ficha.situacao, 'suspensa');
    assert.equal(ficha.bloqueio?.motivo, 'spam');
    assert.equal(ficha.bloqueio?.ate, '2099-12-26T00:00:00.000Z');
  });

  test('não admin: permission-denied; sem login: unauthenticated; uid inexistente: not-found', async () => {
    await criarPessoa('rafael', 'rafael@exemplo.com');
    assert.equal(await codigoDoErro(chamar(fichaUsuario, 'rafael', { uid: 'rafael' })), 'permission-denied');
    assert.equal(await codigoDoErro(chamar(fichaUsuario, null, { uid: 'rafael' })), 'unauthenticated');
    assert.equal(await codigoDoErro(chamar(fichaUsuario, 'admin', { uid: 'ninguem' })), 'not-found');
    assert.equal(await codigoDoErro(chamar(fichaUsuario, 'admin', {})), 'invalid-argument');
  });
});

describe('buscarPessoa', () => {
  test('acha por e-mail exato logo após o cadastro (sem esperar nada)', async () => {
    await criarPessoa('nova', 'nova.pessoa@exemplo.com', 'Nova');
    const r = await chamar<{ pessoa: PessoaEncontrada | null }>(buscarPessoa, 'admin', {
      termo: '  Nova.Pessoa@Exemplo.com ',
    });
    assert.equal(r.pessoa?.uid, 'nova');
    assert.equal(r.pessoa?.nome, 'Nova');
  });

  test('acha por uid; e-mail parcial ou inexistente não acha', async () => {
    await criarPessoa('nova', 'nova@exemplo.com');
    const porUid = await chamar<{ pessoa: PessoaEncontrada | null }>(buscarPessoa, 'admin', { termo: 'nova' });
    assert.equal(porUid.pessoa?.email, 'nova@exemplo.com');
    const parcial = await chamar<{ pessoa: PessoaEncontrada | null }>(buscarPessoa, 'admin', { termo: 'nova@exemplo' });
    assert.equal(parcial.pessoa, null);
  });

  test('não admin recebe permission-denied; termo vazio, invalid-argument', async () => {
    assert.equal(await codigoDoErro(chamar(buscarPessoa, 'ana', { termo: 'x@y.com' })), 'permission-denied');
    assert.equal(await codigoDoErro(chamar(buscarPessoa, 'admin', { termo: ' ' })), 'invalid-argument');
  });
});
