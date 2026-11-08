// H-R5-3A · conferirCompra no emulador, com a Play simulada (a mesma do dev):
// token de teste → productsv2 → acessos (origem compra, offerId) → acknowledge.
import { afterEach, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { getFirestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';
import { conferirCompra, usarPlay, usarPlayCompras } from '../../src/index';
import { playComprasSimulada, type PlayCompras } from '../../src/compras/play';
import { chamar, codigoDoErro, limpar } from './apoio';

const PRODUTO = 'pilares_vitalicio';
let simulada: PlayCompras;
let reconhecidas: string[];
let falharReconhecer: boolean;

type Liberado = { situacao: string; curso: string; orderId: string; offerId: string | null; jaConferida: boolean };

async function motivo(p: Promise<unknown>): Promise<string> {
  try {
    await p;
  } catch (e) {
    assert.ok(e instanceof HttpsError, String(e));
    return (e.details as { codigo: string }).codigo;
  }
  assert.fail('devia ter lançado');
}

beforeEach(async () => {
  await limpar();
  const base = playComprasSimulada(PRODUTO);
  reconhecidas = [];
  falharReconhecer = false;
  simulada = {
    consultar: (t) => base.consultar(t),
    async reconhecer(p, t) {
      if (falharReconhecer) throw new Error('Play fora');
      reconhecidas.push(t);
      await base.reconhecer(p, t);
    },
  };
  usarPlayCompras(simulada);
  usarPlay({
    async precoCentavos() {
      return 6000;
    },
    async criarOferta() {},
    async ofertaExiste() {
      return true;
    },
    async desativarOferta() {},
  });
  const db = getFirestore();
  await db.doc('users/rafael/progress/summary').set({ profile: { country: 'br' } });
  await db.doc('promocoes/bf').set({ tipo: 'todos', offerId: 'bf30', desconto: { tipo: 'pct', valor: 30 }, usos: 0, funil: { compras: 0, receitaCentavos: 0 } });
  await db.doc('promocoes/clube').set({ tipo: 'link', offerId: 'off20', desconto: { tipo: 'pct', valor: 20 }, usos: 2, funil: { compras: 2, receitaCentavos: 9600 } });
  await db.doc('promocoes/escola').set({ tipo: 'link', offerId: 'off20', desconto: { tipo: 'pct', valor: 20 }, usos: 0, funil: { compras: 0, receitaCentavos: 0 } });
  await db.doc('promocoes/escola/reservas/rafael').set({ expiraEm: new Date(Date.now() + 600_000) });
});

afterEach(() => {
  usarPlayCompras(null);
  usarPlay(null);
});

describe('conferirCompra', () => {
  test('compra com link: acesso origem compra com offerId, soma na promoção da reserva e acknowledge', async () => {
    const r = await chamar<Liberado>(conferirCompra, 'rafael', { token: 'teste:compra:off20:rafael' });
    assert.equal(r.situacao, 'liberado');
    assert.equal(r.curso, 'pilares');
    assert.equal(r.offerId, 'off20');
    assert.equal(r.jaConferida, false);
    const db = getFirestore();
    const acesso = (await db.doc('acessos/rafael').get()).get('cursos.pilares');
    assert.equal(acesso.origem, 'compra');
    assert.equal(acesso.plano, 'vitalicio');
    assert.equal(acesso.offerId, 'off20');
    assert.equal(acesso.orderId, r.orderId);
    assert.equal(acesso.pais, 'BR');
    assert.equal(acesso.regiaoCompra, 'BR');
    const escola = (await db.doc('promocoes/escola').get()).data()!;
    assert.equal(escola.usos, 1);
    assert.deepEqual(escola.funil, { compras: 1, receitaCentavos: 4800 });
    assert.equal((await db.doc('promocoes/clube').get()).get('usos'), 2);
    assert.equal((await db.doc('promocoes/escola/reservas/rafael').get()).exists, false);
    const compra = (await db.doc(`compras/${r.orderId}`).get()).data()!;
    assert.equal(compra.uid, 'rafael');
    assert.equal(compra.promocaoId, 'escola');
    assert.equal(compra.reconhecida, true);
    assert.deepEqual(reconhecidas, ['teste:compra:off20:rafael']);
    const registro = await db.collection('acessos/rafael/registro').get();
    assert.equal(registro.size, 1);
    assert.equal(registro.docs[0].get('acao'), 'compra');
  });

  test('Para todos pelo offerId; preço cheio não mexe em promoção', async () => {
    await chamar(conferirCompra, 'rafael', { token: 'teste:compra:bf30' });
    const db = getFirestore();
    assert.deepEqual((await db.doc('promocoes/bf').get()).get('funil'), { compras: 1, receitaCentavos: 4200 });
    const r = await chamar<Liberado>(conferirCompra, 'ana', { token: 'teste:compra:-' });
    assert.equal(r.offerId, null);
    assert.equal((await db.doc(`compras/${r.orderId}`).get()).get('promocaoId'), null);
    assert.equal((await db.doc('acessos/ana').get()).get('cursos.pilares.origem'), 'compra');
  });

  test('repetir o token não soma de novo (idempotente pelo orderId)', async () => {
    await chamar(conferirCompra, 'rafael', { token: 'teste:compra:bf30' });
    const r = await chamar<Liberado>(conferirCompra, 'rafael', { token: 'teste:compra:bf30' });
    assert.equal(r.jaConferida, true);
    assert.equal((await getFirestore().doc('promocoes/bf').get()).get('usos'), 1);
    assert.equal(reconhecidas.length, 1);
  });

  test('acknowledge que falha: acesso fica e a próxima chamada reconhece', async () => {
    falharReconhecer = true;
    const r = await chamar<Liberado>(conferirCompra, 'rafael', { token: 'teste:compra:-' });
    const db = getFirestore();
    assert.equal((await db.doc(`compras/${r.orderId}`).get()).get('reconhecida'), false);
    assert.equal((await db.doc('acessos/rafael').get()).get('cursos.pilares.origem'), 'compra');
    falharReconhecer = false;
    await chamar(conferirCompra, 'rafael', { token: 'teste:compra:-' });
    assert.equal((await db.doc(`compras/${r.orderId}`).get()).get('reconhecida'), true);
  });

  test('pendente não libera; cancelada, outra conta e token inválido recusam', async () => {
    const p = await chamar<{ situacao: string }>(conferirCompra, 'rafael', { token: 'teste:pendente' });
    assert.equal(p.situacao, 'pendente');
    assert.equal((await getFirestore().doc('acessos/rafael').get()).exists, false);
    assert.equal(await motivo(chamar(conferirCompra, 'rafael', { token: 'teste:cancelada' })), 'cancelada');
    assert.equal(await motivo(chamar(conferirCompra, 'rafael', { token: 'teste:compra:-:ana' })), 'outraConta');
    assert.equal(await motivo(chamar(conferirCompra, 'rafael', { token: 'xyz' })), 'tokenInvalido');
    assert.equal(await motivo(chamar(conferirCompra, 'rafael', {})), 'tokenInvalido');
    await chamar(conferirCompra, 'ana', { token: 'teste:compra:-' });
    assert.equal(await motivo(chamar(conferirCompra, 'rafael', { token: 'teste:compra:-' })), 'outraConta');
    assert.equal(await codigoDoErro(chamar(conferirCompra, null, { token: 'teste:compra:-' })), 'unauthenticated');
  });
});
