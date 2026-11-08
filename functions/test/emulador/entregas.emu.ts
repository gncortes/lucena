// H-R5-37 · decidirEntrega e marcarFonteConferida no emulador (R5 §11 R9/R13).
import { beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';
import { decidirEntrega, marcarFonteConferida } from '../../src/index';
import { diaLocal, somarDias } from '../../src/fechamento/datas';
import { chamar, codigoDoErro, criarAdmin, limpar } from './apoio';

const db = () => getFirestore();
const ler = async (id: string) => (await db().doc(`entregas/${id}`).get()).data()!;
const ontem = () => somarDias(diaLocal(new Date()), -1);

async function item(id: string, extra: Record<string, unknown> = {}): Promise<void> {
  await db()
    .doc(`entregas/${id}`)
    .set({ estado: 'sugerido', tipo: 'post', formato: 'posicao', pais: 'BR', titulo: 'Lucena na rodada 7', ...extra });
}

async function decisoes() {
  return (await db().collection('decisoes').get()).docs.map((d) => d.data());
}

async function travas(p: Promise<unknown>): Promise<string[]> {
  try {
    await p;
  } catch (e) {
    assert.ok(e instanceof HttpsError);
    assert.equal(e.code, 'failed-precondition');
    return (e.details as { travas: string[] }).travas;
  }
  assert.fail('devia travar');
}

beforeEach(async () => {
  await limpar();
  await criarAdmin();
  await criarAdmin('admin2');
});

describe('decidirEntrega · reprovar', () => {
  test('grava decisão e motivo no item e em decisoes/ (vai ao relatório)', async () => {
    await item('e1');
    const r = await chamar(decidirEntrega, 'admin', { id: 'e1', decisao: 'reprovar', motivo: 'temaRepetido' });
    assert.deepEqual(r, { id: 'e1', estado: 'reprovado' });
    const e = await ler('e1');
    assert.equal(e.estado, 'reprovado');
    assert.equal(e.decisao.motivo, 'temaRepetido');
    assert.equal(e.decisao.por, 'admin');
    assert.ok(e.decisao.em instanceof Timestamp);
    const [d] = await decisoes();
    assert.equal(d.entregaId, 'e1');
    assert.equal(d.titulo, 'Lucena na rodada 7');
    assert.equal(d.dia, diaLocal(new Date()));
  });

  test('sem motivo, motivo fora da lista e "outro" sem frase: invalid-argument, nada gravado', async () => {
    await item('e1');
    for (const dados of [
      { id: 'e1', decisao: 'reprovar' },
      { id: 'e1', decisao: 'reprovar', motivo: 'feio' },
      { id: 'e1', decisao: 'reprovar', motivo: 'outro', frase: '   ' },
      { id: 'e1', decisao: 'arquivar' },
    ]) {
      assert.equal(await codigoDoErro(chamar(decidirEntrega, 'admin', dados)), 'invalid-argument');
    }
    assert.equal((await ler('e1')).estado, 'sugerido');
    assert.deepEqual(await decisoes(), []);
    await chamar(decidirEntrega, 'admin', { id: 'e1', decisao: 'reprovar', motivo: 'outro', frase: 'Já saiu ontem' });
    assert.equal((await ler('e1')).decisao.frase, 'Já saiu ontem');
  });

  test('já decidido por outro admin: jaDecidido; item inexistente: not-found; quem não é admin: permission-denied', async () => {
    await item('e1');
    await chamar(decidirEntrega, 'admin2', { id: 'e1', decisao: 'reprovar', motivo: 'lanceErrado' });
    try {
      await chamar(decidirEntrega, 'admin', { id: 'e1', decisao: 'reprovar', motivo: 'temaRepetido' });
      assert.fail('devia recusar');
    } catch (e) {
      assert.ok(e instanceof HttpsError);
      assert.equal(e.code, 'failed-precondition');
      assert.deepEqual(e.details, { codigo: 'jaDecidido' });
    }
    assert.equal((await ler('e1')).decisao.por, 'admin2');
    assert.equal((await decisoes()).length, 1);
    assert.equal(await codigoDoErro(chamar(decidirEntrega, 'admin', { id: 'x', decisao: 'aprovar' })), 'not-found');
    assert.equal(
      await codigoDoErro(chamar(decidirEntrega, 'rafael', { id: 'e1', decisao: 'aprovar' })),
      'permission-denied',
    );
  });
});

describe('decidirEntrega · aprovar', () => {
  test('vídeo sem vídeo, fonte não conferida e fato de hoje travam; depois de resolver, aprova e agenda', async () => {
    const hoje = diaLocal(new Date());
    await item('v1', {
      estado: 'aguardandoVideo',
      formato: 'video',
      dataFato: hoje,
      fontes: [
        { afirmacao: 'Moura tinha torre e peão', url: 'https://lichess.org/broadcast/x', data: ontem() },
        { afirmacao: 'Moura liderava', url: 'https://cbx.org.br/x', data: ontem() },
      ],
    });
    assert.deepEqual(await travas(chamar(decidirEntrega, 'admin', { id: 'v1', decisao: 'aprovar' })), [
      'semVideo',
      'fonteNaoConferida',
      'fatoDeHoje',
    ]);

    await db()
      .doc('entregas/v1')
      .update({ dataFato: ontem(), midias: [{ tipo: 'video', url: 'midia/v1/a.mp4', origem: 'gabriel' }] });
    assert.deepEqual(await chamar(marcarFonteConferida, 'admin', { id: 'v1', indice: 0 }), {
      id: 'v1',
      indice: 0,
      pendentes: 1,
    });
    assert.deepEqual(await travas(chamar(decidirEntrega, 'admin', { id: 'v1', decisao: 'aprovar' })), [
      'fonteNaoConferida',
    ]);
    await chamar(marcarFonteConferida, 'admin2', { id: 'v1', indice: 1 });

    const amanha = new Date(Date.now() + 86_400_000).toISOString();
    const r = await chamar(decidirEntrega, 'admin', { id: 'v1', decisao: 'aprovar', agendadoPara: amanha });
    assert.deepEqual(r, { id: 'v1', estado: 'aprovado' });
    const e = await ler('v1');
    assert.equal(e.estado, 'aprovado');
    assert.equal(e.decisao.agendadoPara.toDate().toISOString(), amanha);
    assert.equal(e.fontes[1].conferidaPor, 'admin2');
    assert.deepEqual(await decisoes(), []); // aprovação não vai ao relatório
  });

  test('agendar no passado é invalid-argument; post sem fontes nem vídeo aprova direto', async () => {
    await item('p1');
    assert.equal(
      await codigoDoErro(chamar(decidirEntrega, 'admin', { id: 'p1', decisao: 'aprovar', agendadoPara: '2020-01-01T00:00:00Z' })),
      'invalid-argument',
    );
    assert.deepEqual(await chamar(decidirEntrega, 'admin', { id: 'p1', decisao: 'aprovar' }), { id: 'p1', estado: 'aprovado' });
  });
});

describe('marcarFonteConferida', () => {
  test('a 1ª conferência fica; índice fora: not-found; item decidido: jaDecidido', async () => {
    await item('e1', { fontes: [{ afirmacao: 'a', url: 'https://x', data: ontem() }] });
    await chamar(marcarFonteConferida, 'admin', { id: 'e1', indice: 0 });
    await chamar(marcarFonteConferida, 'admin2', { id: 'e1', indice: 0 });
    assert.equal((await ler('e1')).fontes[0].conferidaPor, 'admin');
    assert.equal(await codigoDoErro(chamar(marcarFonteConferida, 'admin', { id: 'e1', indice: 3 })), 'not-found');
    assert.equal(await codigoDoErro(chamar(marcarFonteConferida, 'admin', { id: 'e1', indice: -1 })), 'invalid-argument');
    await chamar(decidirEntrega, 'admin', { id: 'e1', decisao: 'aprovar' });
    assert.equal(
      await codigoDoErro(chamar(marcarFonteConferida, 'admin', { id: 'e1', indice: 0 })),
      'failed-precondition',
    );
  });
});
