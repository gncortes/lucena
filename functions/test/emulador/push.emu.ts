// H-R5-39 · enviarPush, contarPublico, cancelarPush, o agendador, bloquearConta e desbloquearConta no
// emulador (Auth + Firestore), com FCM fake.
import { afterEach, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import {
  bloquearConta,
  cancelarPush,
  contarPublico,
  desbloquearConta,
  desfazer,
  enviarPush,
  fichaUsuario,
  usarMensageiro,
} from '../../src/index';
import { TOKEN_NAO_REGISTRADO, type Mensageiro } from '../../src/pessoas/acessos';
import { dispararAgendadosCore } from '../../src/pessoas/push';
import { chamar, codigoDoErro, criarAdmin, criarPessoa, limpar } from './apoio';

type Enviada = Parameters<Mensageiro['send']>[0];
let enviadas: Enviada[] = [];
const fcm: Mensageiro = {
  async send(m) {
    if (m.token === 'tok-velho') throw Object.assign(new Error('not registered'), { code: TOKEN_NAO_REGISTRADO });
    if (m.token === 'tok-falha') throw new Error('unavailable');
    enviadas.push(m);
    return 'msg';
  },
};

const db = () => getFirestore();
const DIA = 86_400_000;
const atras = (dias: number) => Timestamp.fromMillis(Date.now() - dias * DIA);

async function aparelho(uid: string, permissao: string, ultimaAberturaDias = 0, token = `tok-${uid}`): Promise<void> {
  await db().doc(`users/${uid}/push/device`).set({ token, updatedAt: atras(ultimaAberturaDias), permissao, ultimaAbertura: atras(ultimaAberturaDias) });
}

async function comPilares(uid: string, revogado = false): Promise<void> {
  await db().doc(`acessos/${uid}`).set({ cursos: { pilares: { origem: 'presente', ...(revogado ? { revogadoEm: Timestamp.now() } : {}) } } });
}

beforeEach(async () => {
  await limpar();
  await criarAdmin();
  enviadas = [];
  usarMensageiro(fcm);
  // ana: Pilares, ativa; bia: Pilares, 10 dias sem abrir; caio: sem curso, 10 dias; davi: negou o push;
  // eva: Pilares revogado, 10 dias; fabio: token velho; gil: FCM falha.
  await aparelho('ana', 'permitida');
  await comPilares('ana');
  await aparelho('bia', 'permitida', 10);
  await comPilares('bia');
  await aparelho('caio', 'permitida', 10);
  await aparelho('davi', 'negada', 10);
  await comPilares('davi');
  await aparelho('eva', 'permitida', 10);
  await comPilares('eva', true);
  await aparelho('fabio', 'permitida', 0, 'tok-velho');
  await aparelho('gil', 'permitida', 0, 'tok-falha');
});

afterEach(() => usarMensageiro(null));

const tokens = () => enviadas.map((e) => e.token).sort();

describe('enviarPush', () => {
  test('todos: data-only no formato do app; contagens no pushes/{id}', async () => {
    const r = await chamar<{ id: string; estado: string; contagens: Record<string, number> }>(enviarPush, 'admin', {
      destino: { tipo: 'todos' },
      titulo: 'Final novo',
      texto: 'A atração do capítulo 4 espera você',
      tipo: 'aula',
      link: 'lucena://pilares/c4',
    });
    assert.equal(r.estado, 'enviado');
    assert.deepEqual(r.contagens, { pessoas: 7, comPush: 6, enviados: 4, semPush: 1, falhas: 1 });
    assert.deepEqual(tokens(), ['tok-ana', 'tok-bia', 'tok-caio', 'tok-eva']);
    assert.deepEqual(enviadas[0].data, {
      tipo: 'aula',
      pushId: r.id,
      titulo: 'Final novo',
      texto: 'A atração do capítulo 4 espera você',
      link: 'lucena://pilares/c4',
    });
    assert.equal(enviadas[0].notification, undefined);
    const p = (await db().doc(`pushes/${r.id}`).get()).data()!;
    assert.equal(p.estado, 'enviado');
    assert.equal(p.criadoPor, 'admin');
    assert.ok(p.enviadoEm instanceof Timestamp);
    assert.deepEqual(p.contagens, r.contagens);
  });

  test('público: curso vigente e dias sem abrir; contarPublico dá o mesmo número', async () => {
    const destino = { tipo: 'publico', curso: 'pilares', inativosDias: 7 };
    assert.deepEqual(await chamar(contarPublico, 'admin', { destino }), { pessoas: 2, comPush: 1 }); // bia e davi
    await chamar(enviarPush, 'admin', { destino, titulo: 'Volte', texto: 'Faltam 3 lições' });
    assert.deepEqual(tokens(), ['tok-bia']);
    assert.equal(enviadas[0].data.tipo, 'livre');
  });

  test('pessoa e lista de pessoas; conta suspensa fica de fora', async () => {
    await chamar(enviarPush, 'admin', { destino: { tipo: 'pessoa', uid: 'caio' }, titulo: 'Oi', texto: 'Seu plano' });
    assert.deepEqual(tokens(), ['tok-caio']);
    enviadas = [];
    await db().doc('acessos/ana').set({ bloqueio: { motivo: 'Abuso', desde: Timestamp.now(), ate: null } }, { merge: true });
    const r = await chamar<{ contagens: Record<string, number> }>(enviarPush, 'admin', {
      destino: { tipo: 'pessoas', uids: ['ana', 'bia', 'ninguem'] },
      titulo: 'Oi',
      texto: 'Texto',
    });
    assert.deepEqual(tokens(), ['tok-bia']);
    assert.equal(r.contagens.pessoas, 1);
  });

  test('pedido inválido e quem não é admin são recusados, sem gravar', async () => {
    const ok = { destino: { tipo: 'todos' }, titulo: 'T', texto: 'X' };
    assert.equal(await codigoDoErro(chamar(enviarPush, 'admin', { ...ok, titulo: '' })), 'invalid-argument');
    assert.equal(await codigoDoErro(chamar(enviarPush, 'admin', { ...ok, texto: 'x'.repeat(241) })), 'invalid-argument');
    assert.equal(await codigoDoErro(chamar(enviarPush, 'admin', { ...ok, destino: { tipo: 'publico' } })), 'invalid-argument');
    assert.equal(await codigoDoErro(chamar(enviarPush, 'admin', { ...ok, destino: { tipo: 'publico', curso: 'xadrez9' } })), 'not-found');
    assert.equal(await codigoDoErro(chamar(enviarPush, 'admin', { ...ok, tipo: 'promo' })), 'invalid-argument');
    assert.equal(await codigoDoErro(chamar(enviarPush, 'admin', { ...ok, agendadoPara: new Date(Date.now() - 1000).toISOString() })), 'invalid-argument');
    assert.equal(await codigoDoErro(chamar(enviarPush, 'ana', ok)), 'permission-denied');
    assert.equal((await db().collection('pushes').get()).size, 0);
    assert.equal(enviadas.length, 0);
  });
});

describe('agendar e cancelar', () => {
  test('agendado só sai quando vence; cancelado não sai', async () => {
    const quando = new Date(Date.now() + 3_600_000);
    const a = await chamar<{ id: string; estado: string; agendadoPara: string }>(enviarPush, 'admin', {
      destino: { tipo: 'pessoa', uid: 'ana' },
      titulo: 'Sexta',
      texto: 'Às 19h',
      agendadoPara: quando.toISOString(),
    });
    assert.deepEqual(a, { id: a.id, estado: 'agendado', agendadoPara: quando.toISOString() });
    const b = await chamar<{ id: string }>(enviarPush, 'admin', {
      destino: { tipo: 'pessoa', uid: 'bia' },
      titulo: 'Sexta',
      texto: 'Às 19h',
      agendadoPara: quando.toISOString(),
    });
    assert.deepEqual(await chamar(cancelarPush, 'admin', { id: b.id }), { id: b.id, estado: 'cancelado' });
    assert.equal(enviadas.length, 0);

    const deps = (agora: Date) => ({ db: db(), auth: getAuth(), mensageiro: fcm, agora });
    assert.deepEqual(await dispararAgendadosCore(deps(new Date())), []); // ainda não venceu
    assert.deepEqual(await dispararAgendadosCore(deps(new Date(quando.getTime() + 1000))), [a.id]);
    assert.deepEqual(tokens(), ['tok-ana']);
    assert.equal((await db().doc(`pushes/${a.id}`).get()).get('estado'), 'enviado');
    assert.equal((await db().doc(`pushes/${b.id}`).get()).get('estado'), 'cancelado');

    // enviado e cancelado não cancelam; inexistente = not-found
    const e = await codigoDoErro(chamar(cancelarPush, 'admin', { id: a.id }));
    assert.equal(e, 'failed-precondition');
    assert.equal(await codigoDoErro(chamar(cancelarPush, 'admin', { id: 'x' })), 'not-found');
  });
});

describe('bloquearConta', () => {
  test('grava bloqueios, o resumo em acessos e o registro; a Ficha mostra suspensa; tokens revogados', async () => {
    await criarPessoa('rafael', 'rafael@exemplo.com', 'Rafael Lima');
    await comPilares('rafael');
    const ate = new Date(Date.now() + 30 * DIA).toISOString();
    const r = await chamar<{ registroId: string; tokensRevogados: boolean }>(bloquearConta, 'admin', {
      uid: 'rafael',
      motivo: 'Compartilhou a conta',
      regra: 'R4-1',
      ate,
    });
    assert.equal(r.tokensRevogados, true);
    const b = (await db().doc('bloqueios/rafael').get()).data()!;
    assert.equal(b.motivo, 'Compartilhou a conta');
    assert.equal(b.regra, 'R4-1');
    assert.equal(b.adminUid, 'admin');
    assert.equal(b.ate.toDate().toISOString(), ate);
    const a = (await db().doc('acessos/rafael').get()).data()!;
    assert.equal(a.bloqueio.motivo, 'Compartilhou a conta');
    assert.equal(a.cursos.pilares.origem, 'presente'); // o curso volta sozinho no desbloqueio
    const reg = (await db().doc(`acessos/rafael/registro/${r.registroId}`).get()).data()!;
    assert.equal(reg.acao, 'bloquear');
    assert.equal(reg.tokensRevogados, true);
    assert.ok((await getAuth().getUser('rafael')).tokensValidAfterTime);

    const ficha = await chamar<{ situacao: string; bloqueio: { motivo: string; ate: string } }>(fichaUsuario, 'admin', { uid: 'rafael' });
    assert.equal(ficha.situacao, 'suspensa');
    assert.equal(ficha.bloqueio.ate, ate);

    assert.equal(await codigoDoErro(chamar(bloquearConta, 'admin', { uid: 'rafael', motivo: 'De novo' })), 'failed-precondition');
    // o registro de bloqueio não se desfaz pelo desfazer do curso
    assert.equal(await codigoDoErro(chamar(desfazer, 'admin', { uid: 'rafael', registroId: r.registroId })), 'failed-precondition');
  });

  test('desbloquear apaga o bloqueio e o resumo e registra o motivo', async () => {
    await criarPessoa('rafael', 'rafael@exemplo.com');
    await chamar(bloquearConta, 'admin', { uid: 'rafael', motivo: 'Abuso' });
    assert.equal((await db().doc('bloqueios/rafael').get()).get('ate'), null); // sem prazo
    const r = await chamar<{ registroId: string }>(desbloquearConta, 'admin', { uid: 'rafael', motivo: 'Engano' });
    assert.equal((await db().doc('bloqueios/rafael').get()).exists, false);
    assert.equal((await db().doc('acessos/rafael').get()).get('bloqueio'), undefined);
    const reg = (await db().doc(`acessos/rafael/registro/${r.registroId}`).get()).data()!;
    assert.deepEqual([reg.acao, reg.motivo], ['desbloquear', 'Engano']);
    assert.equal(await codigoDoErro(chamar(desbloquearConta, 'admin', { uid: 'rafael', motivo: 'De novo' })), 'failed-precondition');
  });

  test('sem motivo, prazo no passado, a própria conta, pessoa inexistente e quem não é admin são recusados', async () => {
    await criarPessoa('rafael', 'rafael@exemplo.com');
    assert.equal(await codigoDoErro(chamar(bloquearConta, 'admin', { uid: 'rafael' })), 'invalid-argument');
    assert.equal(await codigoDoErro(chamar(bloquearConta, 'admin', { uid: 'rafael', motivo: 'x'.repeat(65) })), 'invalid-argument');
    assert.equal(
      await codigoDoErro(chamar(bloquearConta, 'admin', { uid: 'rafael', motivo: 'Abuso', ate: new Date(Date.now() - DIA).toISOString() })),
      'invalid-argument',
    );
    assert.equal(await codigoDoErro(chamar(bloquearConta, 'admin', { uid: 'admin', motivo: 'Abuso' })), 'failed-precondition');
    assert.equal(await codigoDoErro(chamar(bloquearConta, 'admin', { uid: 'ninguem', motivo: 'Abuso' })), 'not-found');
    assert.equal(await codigoDoErro(chamar(bloquearConta, 'rafael', { uid: 'rafael', motivo: 'Abuso' })), 'permission-denied');
    assert.equal((await db().collection('bloqueios').get()).size, 0);
  });
});
