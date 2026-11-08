// H-R5-38 · publicarVersao, conferirVersao, reverterVersao e pedirCorrecao no emulador (Firestore + Storage),
// com um pacote de fixture em três lançamentos (v1 e v2 já no ar; v3 em revisão muda a fala 2 da Atração).
import { beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { HttpsError } from 'firebase-functions/https';
import { conferirVersao, pedirCorrecao, publicarVersao, reverterVersao, usarBucket } from '../../src/index';
import { chamar, codigoDoErro, criarAdmin, limpar, PROJETO } from './apoio';

const BUCKET = `${PROJETO}.appspot.com`;
usarBucket(BUCKET);

const db = () => getFirestore();
const sha = (s: string) => createHash('sha256').update(s).digest('hex');
const FALA2 = 'pilares/c4/atracao/fala2';

/** O índice que o PC grava na revisão (formato de LessonPackageIndex). */
function indice(release: string) {
  const arquivo = { bytes: 10, sha256: sha(`${release}-a`) };
  return {
    format: 1,
    status: 'published',
    release,
    packages: { 'pilares:c4': { bytes: 10, sha256: sha(release), files: { 'pilares/c4.json': arquivo } } },
  };
}

async function subirPacote(release: string, fala2: string): Promise<void> {
  const b = getStorage().bucket(BUCKET);
  const pasta = `content/releases/${release}`;
  await b.file(`${pasta}/manifest.json`).save(JSON.stringify({ format: 1, status: 'published', release, files: { 'pilares/c4.json': {} } }));
  await b.file(`${pasta}/falas.json`).save(
    JSON.stringify({ format: 1, falas: { 'pilares/c4/atracao/fala1': sha('igual'), [FALA2]: sha(fala2) } }),
  );
}

async function revisao(id: string, numero: number, estado: string, release = `r${numero}`): Promise<void> {
  await db().doc(`revisoes/${id}`).set({ curso: 'pilares', numero, resumo: `Versão ${numero}`, estado, release, indice: indice(release) });
}

const estado = async (id: string) => (await db().doc(`revisoes/${id}`).get()).data()!.estado;
const noIndice = async (destino: 'teste' | 'alunos') => (await db().doc(`conteudo/${destino}`).get()).data();

async function detalhes(p: Promise<unknown>): Promise<Record<string, unknown>> {
  try {
    await p;
  } catch (e) {
    assert.ok(e instanceof HttpsError, String(e));
    return { code: e.code, message: e.message, ...(e.details as object) };
  }
  assert.fail('devia recusar');
}

beforeEach(async () => {
  await limpar();
  await getStorage().bucket(BUCKET).deleteFiles({ force: true });
  await criarAdmin();
  await subirPacote('r1', 'texto antigo');
  await subirPacote('r2', 'texto antigo');
  await subirPacote('r3', 'texto novo');
  await revisao('v1', 1, 'anterior');
  await revisao('v2', 2, 'conferida');
  await chamar(publicarVersao, 'admin', { id: 'v2', destino: 'alunos' });
  await revisao('v3', 3, 'emRevisao');
});

describe('publicar em dois passos (teste → alunos)', () => {
  test('v3 vai ao teste, é conferida e só então aos alunos; v2 fica como anterior', async () => {
    assert.deepEqual(await detalhes(chamar(publicarVersao, 'admin', { id: 'v3', destino: 'alunos' })), {
      code: 'failed-precondition',
      message: 'Confira a versão no app de teste antes de publicar.',
      codigo: 'naoConferida',
      estado: 'emRevisao',
    });
    assert.equal((await detalhes(chamar(conferirVersao, 'admin', { id: 'v3' }))).codigo, 'naoEstaNoTeste');

    assert.deepEqual(await chamar(publicarVersao, 'admin', { id: 'v3', destino: 'teste' }), { id: 'v3', estado: 'noTeste', release: 'r3' });
    const teste = await noIndice('teste');
    assert.equal(teste!.release, 'r3');
    assert.equal(teste!.format, 1);
    assert.equal(teste!.status, 'published');
    assert.equal(teste!.resumo, 'Versão 3');
    assert.equal((await noIndice('alunos'))!.release, 'r2'); // os alunos ainda não veem

    await chamar(conferirVersao, 'admin', { id: 'v3' });
    assert.equal(await estado('v3'), 'conferida');
    await chamar(publicarVersao, 'admin', { id: 'v3', destino: 'alunos' });
    assert.equal((await noIndice('alunos'))!.release, 'r3');
    assert.equal(await estado('v3'), 'noAr');
    assert.equal(await estado('v2'), 'anterior');
    const hist = (await db().doc('revisoes/v3').get()).data()!.historico.map((h: { acao: string }) => h.acao);
    assert.deepEqual(hist, ['teste', 'conferida', 'alunos']);
  });

  test('outra versão no teste tira a anterior do teste (volta a em revisão)', async () => {
    await revisao('v4', 4, 'emRevisao', 'r3');
    await chamar(publicarVersao, 'admin', { id: 'v3', destino: 'teste' });
    await chamar(publicarVersao, 'admin', { id: 'v4', destino: 'teste' });
    assert.equal(await estado('v3'), 'emRevisao');
    assert.equal((await noIndice('teste'))!.revisao, 'v4');
  });

  test('sem pacote no Storage, índice inválido, rascunho, inexistente e quem não é admin são recusados', async () => {
    await revisao('v5', 5, 'emRevisao');
    assert.equal((await detalhes(chamar(publicarVersao, 'admin', { id: 'v5', destino: 'teste' }))).codigo, 'pacoteAusente');
    await db().doc('revisoes/v6').set({ estado: 'emRevisao', release: 'r3', indice: { format: 2, release: 'r3' } });
    assert.equal((await detalhes(chamar(publicarVersao, 'admin', { id: 'v6', destino: 'teste' }))).codigo, 'indiceInvalido');
    await revisao('v7', 7, 'rascunho', 'r3');
    assert.equal((await detalhes(chamar(publicarVersao, 'admin', { id: 'v7', destino: 'teste' }))).codigo, 'estadoInvalido');
    assert.equal(await codigoDoErro(chamar(publicarVersao, 'admin', { id: 'x', destino: 'teste' })), 'not-found');
    assert.equal(await codigoDoErro(chamar(publicarVersao, 'admin', { id: 'v3', destino: 'todos' })), 'invalid-argument');
    assert.equal(await codigoDoErro(chamar(publicarVersao, 'rafael', { id: 'v3', destino: 'teste' })), 'permission-denied');
    assert.equal((await noIndice('teste')), undefined);
  });
});

describe('reverter', () => {
  test('aponta o índice dos alunos para o lançamento antigo; a que saiu fica revertida', async () => {
    assert.deepEqual(await chamar(reverterVersao, 'admin', { id: 'v1' }), { id: 'v1', estado: 'noAr', release: 'r1' });
    const alunos = await noIndice('alunos');
    assert.equal(alunos!.release, 'r1');
    assert.equal(alunos!.revertidoDe, 'v2');
    assert.equal(await estado('v2'), 'revertida');
    // e dá para voltar à v2 de novo
    await chamar(reverterVersao, 'admin', { id: 'v2' });
    assert.equal((await noIndice('alunos'))!.release, 'r2');
  });

  test('a que está no ar e a que nunca foi aos alunos não revertem', async () => {
    assert.equal((await detalhes(chamar(reverterVersao, 'admin', { id: 'v2' }))).codigo, 'jaNoAr');
    assert.equal((await detalhes(chamar(reverterVersao, 'admin', { id: 'v3' }))).codigo, 'nuncaPublicada');
    assert.equal((await noIndice('alunos'))!.release, 'r2');
  });
});

describe('pedirCorrecao (R16)', () => {
  test('fala da versão no ar: grava o pedido "enviado" com a versão base', async () => {
    const r = await chamar<{ id: string; estado: string }>(pedirCorrecao, 'admin', {
      chave: FALA2,
      revisao: 'v2',
      problema: 'confusa',
      numero: '38% erram aqui',
    });
    assert.equal(r.estado, 'enviado');
    const p = (await db().doc(`pedidosCorrecao/${r.id}`).get()).data()!;
    assert.equal(p.chave, FALA2);
    assert.equal(p.revisaoBase, 'v2');
    assert.equal(p.numeroBase, 2);
    assert.equal(p.curso, 'pilares');
    assert.equal(p.estado, 'enviado');
    assert.equal(p.hashFala, sha('texto antigo'));
    assert.equal(p.numero, '38% erram aqui');
  });

  test('chave que não existe na versão base: not-found; "outro" sem texto: invalid-argument', async () => {
    assert.equal(
      (await detalhes(chamar(pedirCorrecao, 'admin', { chave: 'pilares/c4/atracao/fala9', revisao: 'v2', problema: 'confusa' }))).codigo,
      'falaNaoExiste',
    );
    assert.equal(await codigoDoErro(chamar(pedirCorrecao, 'admin', { chave: FALA2, revisao: 'v2', problema: 'outro' })), 'invalid-argument');
    assert.equal(await codigoDoErro(chamar(pedirCorrecao, 'admin', { chave: FALA2, revisao: 'v2', problema: 'feia' })), 'invalid-argument');
    assert.equal(await codigoDoErro(chamar(pedirCorrecao, 'admin', { chave: FALA2, revisao: 'v3', problema: 'confusa' })), 'not-found');
    assert.equal((await db().collection('pedidosCorrecao').get()).size, 0);
  });

  test('versão base trocada: a fala que mudou recusa com a frase da v3; a que não mudou passa', async () => {
    await chamar(publicarVersao, 'admin', { id: 'v3', destino: 'teste' });
    await chamar(conferirVersao, 'admin', { id: 'v3' });
    await chamar(publicarVersao, 'admin', { id: 'v3', destino: 'alunos' });
    assert.deepEqual(await detalhes(chamar(pedirCorrecao, 'admin', { chave: FALA2, revisao: 'v2', problema: 'confusa' })), {
      code: 'failed-precondition',
      message: 'Esta fala mudou na v3. Confira antes de pedir.',
      codigo: 'falaMudou',
      numero: 3,
      revisao: 'v3',
    });
    const r = await chamar<{ estado: string }>(pedirCorrecao, 'admin', {
      chave: 'pilares/c4/atracao/fala1',
      revisao: 'v2',
      problema: 'outro',
      texto: 'Falta dizer por que o rei vai à borda',
    });
    assert.equal(r.estado, 'enviado');
  });
});
