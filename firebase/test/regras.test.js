// Testes das regras do Firestore e do Storage no emulador (ficha
// docs/fluxos/abuso.md). Rodar com `npm --prefix firebase/test test`.
// Cada payload "real" copia o que o app manda hoje (FeedbackEntry.toJson,
// ProgressSummary.toJson, SyncRepository.gameJson, o aceite legal).
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import 'firebase/compat/firestore';

const { FieldValue, Timestamp } = firebase.firestore;
const servidor = () => FieldValue.serverTimestamp();

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-lucena',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
    storage: { rules: readFileSync('../storage.rules', 'utf8') },
  });
});

after(async () => env?.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('admins/admin').set({ desde: Timestamp.now() });
  });
});

const db = (uid) =>
  uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();

const semRegras = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

const antes = (segundos) => Timestamp.fromMillis(Date.now() - segundos * 1000);

// O que FeedbackEntry.toJson manda (feedback_entry.dart), com o uid.
const feedbackReal = (uid, extra = {}) => ({
  kind: 'livre',
  type: 'problema',
  text: 'O tabuleiro travou depois do lance.',
  level: '1500',
  origin: 'play',
  appVersion: '1.4.0+52',
  model: 'Pixel 7',
  manufacturer: 'Google',
  language: 'pt',
  uid,
  createdAt: servidor(),
  ...extra,
});

// Grava como o app: o feedback e a marca do ritmo no mesmo lote.
const enviarFeedback = (uid, dados = feedbackReal(uid), { ritmo = true } = {}) => {
  const firestore = db(uid);
  const ref = firestore.collection('feedback').doc();
  const lote = firestore.batch();
  lote.set(ref, dados);
  if (ritmo) {
    lote.set(
      firestore.doc(`cotas/${uid}`),
      { feedbackEm: servidor(), feedbackId: ref.id },
      { merge: true },
    );
  }
  return lote.commit();
};

// O que ProgressSummary.toJson manda (progress_summary.dart).
const resumoReal = (extra = {}) => ({
  learningV1: [
    {
      kind: 'pilares',
      unitId: 'p1-c1',
      version: 1,
      firstStartedAt: '2026-11-01T10:00:00.000Z',
      exerciseStars: { e1: 3 },
    },
  ],
  profile: {
    nickname: 'Gabriel',
    rating: 1500,
    goal: 'improve',
    levelSource: 'manual',
    lichessUser: 'gncortes',
    lichessLinkedAt: '2026-10-01T10:00:00.000Z',
    avatarColor: 4282664004,
    photo: 'none',
    country: 'BR',
    state: 'SP',
    city: 'São Paulo',
  },
  rating: { rating: 1500.5, deviation: 80.2, volatility: 0.06 },
  lessons: { oposicao: { done: true } },
  school: ['s1'],
  stars: { c1: 3 },
  challenges: ['c1'],
  positions: ['p1'],
  startRung: 2,
  speedruns: { kp: 61000 },
  race: { best: 12 },
  featured: ['f1'],
  updatedAt: Timestamp.now(),
  ...extra,
});

// O que SyncRepository.gameJson manda (sync_repository.dart).
const partidaReal = (extra = {}) => ({
  positionId: 'kp-1',
  playedAt: Timestamp.now(),
  outcome: 'win',
  fulfilled: true,
  opponent: 'maia',
  opponentLevel: 1500,
  startedAt: Timestamp.now(),
  startFen: '8/8/8/4k3/8/8/4P3/4K3 w - - 0 1',
  moves: 'e2e4 e5e6',
  userSide: 'white',
  endReason: 'checkmate',
  ...extra,
});

const gravarPartida = (uid, id = '1762430000000000-kp-1', dados = partidaReal(), { contar = true } = {}) => {
  const firestore = db(uid);
  const lote = firestore.batch();
  lote.set(firestore.doc(`users/${uid}/games/${id}`), dados);
  if (contar) {
    lote.set(firestore.doc(`cotas/${uid}`), { partidas: FieldValue.increment(1) }, { merge: true });
  }
  return lote.commit();
};

const bloquear = (uid, campos = {}) =>
  semRegras((f) => f.doc(`bloqueios/${uid}`).set({ motivo: 'spam', desde: Timestamp.now(), ...campos }));

describe('feedback (P0-1, P1-2, achado B)', () => {
  test('sem conta é recusado', async () => {
    await assertFails(db(null).collection('feedback').add(feedbackReal('ana')));
    const { uid, ...semUid } = feedbackReal('x');
    await assertFails(db(null).collection('feedback').add(semUid));
  });

  test('o FeedbackEntry real, com uid e ritmo, é aceito', async () => {
    await assertSucceeds(enviarFeedback('ana'));
  });

  test('texto acima de 500 é recusado', async () => {
    await assertFails(enviarFeedback('ana', feedbackReal('ana', { text: 'a'.repeat(501) })));
  });

  test('chave fora da lista (context de 900 KB) é recusada', async () => {
    await assertFails(enviarFeedback('ana', feedbackReal('ana', { context: 'x'.repeat(900 * 1024) })));
  });

  test('uid de outra conta é recusado', async () => {
    await assertFails(enviarFeedback('ana', feedbackReal('bia')));
  });

  test('createdAt com a hora do aparelho é recusado', async () => {
    await assertFails(enviarFeedback('ana', feedbackReal('ana', { createdAt: Timestamp.now() })));
  });

  test('sem a marca do ritmo é recusado', async () => {
    await assertFails(enviarFeedback('ana', feedbackReal('ana'), { ritmo: false }));
  });

  test('o segundo envio seguido é recusado (ritmo mínimo)', async () => {
    await assertSucceeds(enviarFeedback('ana'));
    await assertFails(enviarFeedback('ana'));
  });

  test('passado o intervalo, o envio volta a valer', async () => {
    await semRegras((f) => f.doc('cotas/ana').set({ feedbackEm: antes(120), feedbackId: 'velho' }));
    await assertSucceeds(enviarFeedback('ana'));
  });

  test('a marca do ritmo não pode voltar no tempo nem ser apagada', async () => {
    await assertSucceeds(enviarFeedback('ana'));
    await assertFails(db('ana').doc('cotas/ana').set({ feedbackEm: antes(3600), feedbackId: 'x' }, { merge: true }));
    await assertFails(db('ana').doc('cotas/ana').delete());
  });

  test('conta bloqueada não manda', async () => {
    await bloquear('ana');
    await assertFails(enviarFeedback('ana'));
  });

  test('o dono lista e apaga o próprio (exclusão da conta); outro não lê', async () => {
    await assertSucceeds(enviarFeedback('ana'));
    const meus = db('ana').collection('feedback').where('uid', '==', 'ana');
    const lista = await assertSucceeds(meus.get());
    await assertSucceeds(lista.docs[0].ref.delete());
    await assertFails(db('bia').collection('feedback').where('uid', '==', 'ana').get());
    await assertFails(db('ana').collection('feedback').get());
  });
});

describe('perfil users/{uid} (achado A, P2-4, P0-4)', () => {
  test('o aceite legal real é aceito', async () => {
    await assertSucceeds(
      db('ana').doc('users/ana').set(
        {
          legal: { acceptedVersion: 2, acceptedAt: '2026-11-06T10:00:00.000Z' },
          updatedAt: Timestamp.now(),
        },
        { merge: true },
      ),
    );
  });

  test('aceite legal com chave estranha é recusado', async () => {
    await assertFails(
      db('ana').doc('users/ana').set(
        { legal: { acceptedVersion: 2, extra: 'x'.repeat(5000) }, updatedAt: Timestamp.now() },
        { merge: true },
      ),
    );
  });

  test('o perfil novo com createdAt do servidor é aceito', async () => {
    await assertSucceeds(
      db('ana').doc('users/ana').set(
        { name: 'Ana', language: 'pt', updatedAt: Timestamp.now(), createdAt: servidor() },
        { merge: true },
      ),
    );
  });

  test('createdAt que não é a hora do servidor é recusado', async () => {
    await assertFails(
      db('ana').doc('users/ana').set({ updatedAt: Timestamp.now(), createdAt: 'x' }, { merge: true }),
    );
    await assertFails(
      db('ana').doc('users/ana').set({ updatedAt: Timestamp.now(), createdAt: antes(99999) }, { merge: true }),
    );
  });

  test('conta bloqueada não grava o perfil, mas ainda apaga', async () => {
    await semRegras((f) => f.doc('users/ana').set({ name: 'Ana', updatedAt: Timestamp.now() }));
    await bloquear('ana');
    await assertFails(db('ana').doc('users/ana').set({ name: 'Outra', updatedAt: Timestamp.now() }, { merge: true }));
    await assertSucceeds(db('ana').doc('users/ana').delete());
  });

  test('bloqueio vencido não barra', async () => {
    await bloquear('ana', { ate: antes(60) });
    await assertSucceeds(db('ana').doc('users/ana').set({ name: 'Ana', updatedAt: Timestamp.now() }, { merge: true }));
  });
});

describe('bloqueios/{uid} (P0-4)', () => {
  test('só o admin grava; o dono lê o próprio', async () => {
    await assertFails(db('ana').doc('bloqueios/ana').set({ motivo: 'x', desde: Timestamp.now() }));
    await assertSucceeds(db('admin').doc('bloqueios/ana').set({ motivo: 'spam', desde: Timestamp.now() }));
    await assertSucceeds(db('ana').doc('bloqueios/ana').get());
    await assertFails(db('ana').doc('bloqueios/ana').delete());
    await assertFails(db('bia').doc('bloqueios/ana').get());
  });
});

describe('progresso users/{uid}/progress (P0-2)', () => {
  test('o resumo real é aceito', async () => {
    await assertSucceeds(db('ana').doc('users/ana/progress/summary').set(resumoReal()));
  });

  test('id diferente de summary é recusado', async () => {
    await assertFails(db('ana').doc('users/ana/progress/lixo-1').set(resumoReal()));
  });

  test('apelido acima de 20 caracteres é recusado', async () => {
    const resumo = resumoReal();
    resumo.profile.nickname = 'a'.repeat(21);
    await assertFails(db('ana').doc('users/ana/progress/summary').set(resumo));
  });

  test('chave estranha no topo ou no perfil é recusada', async () => {
    await assertFails(db('ana').doc('users/ana/progress/summary').set(resumoReal({ lixo: 'x' })));
    const resumo = resumoReal();
    resumo.profile.bio = 'x';
    await assertFails(db('ana').doc('users/ana/progress/summary').set(resumo));
  });

  test('lista acima do teto é recusada', async () => {
    const muitos = Array.from({ length: 5001 }, (_, i) => `p${i}`);
    await assertFails(db('ana').doc('users/ana/progress/summary').set(resumoReal({ positions: muitos })));
  });

  test('conta bloqueada não grava', async () => {
    await bloquear('ana');
    await assertFails(db('ana').doc('users/ana/progress/summary').set(resumoReal()));
  });
});

describe('partidas users/{uid}/games (P0-2)', () => {
  test('a partida real, contada, é aceita e não muda depois', async () => {
    await assertSucceeds(gravarPartida('ana'));
    await assertFails(gravarPartida('ana'));
  });

  test('sem contar na cota é recusada', async () => {
    await assertFails(gravarPartida('ana', undefined, undefined, { contar: false }));
  });

  test('id fora do padrão é recusado', async () => {
    await assertFails(gravarPartida('ana', 'qualquer coisa'));
    await assertFails(gravarPartida('ana', `1-${'a'.repeat(200)}`));
  });

  test('chave estranha ou lances enormes são recusados', async () => {
    await assertFails(gravarPartida('ana', undefined, partidaReal({ lixo: 1 })));
    await assertFails(gravarPartida('ana', undefined, partidaReal({ moves: 'e2e4 '.repeat(4000) })));
  });

  test('passado o teto de partidas, é recusada', async () => {
    await semRegras((f) => f.doc('cotas/ana').set({ partidas: 20000 }));
    await assertFails(gravarPartida('ana'));
  });

  test('a contagem não volta nem pula', async () => {
    await semRegras((f) => f.doc('cotas/ana').set({ partidas: 10 }));
    await assertFails(db('ana').doc('cotas/ana').set({ partidas: 0 }, { merge: true }));
    await assertFails(db('ana').doc('cotas/ana').set({ partidas: 12 }, { merge: true }));
  });

  test('conta bloqueada não grava', async () => {
    await bloquear('ana');
    await assertFails(gravarPartida('ana'));
  });
});

describe('push users/{uid}/push/device', () => {
  test('o token real é aceito; bloqueado não grava', async () => {
    await assertSucceeds(db('ana').doc('users/ana/push/device').set({ token: 't', updatedAt: Timestamp.now() }));
    await bloquear('ana');
    await assertFails(db('ana').doc('users/ana/push/device').set({ token: 'u', updatedAt: Timestamp.now() }));
  });
});

describe('challenges (P1-1): fechada, o app não usa', () => {
  test('criar e ler são recusados', async () => {
    await assertFails(db('ana').doc('challenges/abc').set({ owner: 'ana', lixo: 'x'.repeat(1000) }));
    await assertFails(db(null).doc('challenges/abc').get());
  });
});

describe('inscritos/* (P2-3): só o servidor conta', () => {
  test('cliente não grava; admin lê', async () => {
    await assertFails(db('ana').doc('inscritos/all').set({ total: 1 }));
    await assertFails(db(null).doc('inscritos/all').set({ total: 1 }));
    await assertSucceeds(db('admin').doc('inscritos/all').get());
    await assertFails(db('ana').doc('inscritos/all').get());
  });
});

// ------------------------------------------------------------ R5 (H-R5-31)

describe('push/device com a permissão (H-R5-31)', () => {
  test('as duas escritas do app (token; permissão) com merge passam', async () => {
    const ref = db('ana').doc('users/ana/push/device');
    await assertSucceeds(ref.set({ token: 't', updatedAt: Timestamp.now() }, { merge: true }));
    await assertSucceeds(
      ref.set(
        { permissao: 'permitida', conferidoEm: Timestamp.now(), ultimaAbertura: Timestamp.now() },
        { merge: true },
      ),
    );
    await assertSucceeds(db('admin').doc('users/ana/push/device').get());
    await assertSucceeds(ref.delete());
  });

  test('permissão fora da lista, campo a mais ou data como texto são recusados', async () => {
    const ref = db('ana').doc('users/ana/push/device');
    await assertSucceeds(ref.set({ token: 't', updatedAt: Timestamp.now() }));
    await assertFails(ref.set({ permissao: 'talvez' }, { merge: true }));
    await assertFails(ref.set({ conferidoEm: '2026-11-06' }, { merge: true }));
    await assertFails(ref.set({ marca: 'x' }, { merge: true }));
    await assertFails(db('beto').doc('users/ana/push/device').get());
  });
});

describe('acessos/{uid} (H-R5-31): cursos só pela Function', () => {
  const curso = () => ({
    origem: 'presente',
    plano: 'vitalicio',
    dadoPor: 'admin',
    dadoEm: Timestamp.now(),
    pais: 'BR',
  });

  beforeEach(() =>
    semRegras((fs) => fs.doc('acessos/ana').set({ cursos: { pilares: curso() } })),
  );

  test('o dono lê e marca só vistos; o admin lê', async () => {
    await assertSucceeds(db('ana').doc('acessos/ana').get());
    await assertSucceeds(db('admin').doc('acessos/ana').get());
    await assertSucceeds(
      db('ana').doc('acessos/ana').set({ vistos: { pilares: Timestamp.now() } }, { merge: true }),
    );
    await assertSucceeds(
      db('ana').doc('acessos/ana').update({ 'vistos.escola': Timestamp.now() }),
    );
  });

  test('o dono não se dá curso, não cria, não apaga; outro não lê', async () => {
    await assertFails(
      db('ana').doc('acessos/ana').update({ 'cursos.torneio': curso() }),
    );
    await assertFails(
      db('ana').doc('acessos/ana').update({ 'cursos.pilares.plano': 'mensal' }),
    );
    await assertFails(db('ana').doc('acessos/ana').delete());
    await assertFails(db('beto').doc('acessos/beto').set({ vistos: {} }));
    await assertFails(db('beto').doc('acessos/ana').get());
    await assertFails(db('ana').collection('acessos').get());
    await assertFails(db('admin').doc('acessos/ana').update({ 'cursos.torneio': curso() }));
  });

  test('registro: admin lê; ninguém grava pelo app', async () => {
    await assertSucceeds(db('admin').doc('acessos/ana/registro/r1').get());
    await assertFails(db('ana').doc('acessos/ana/registro/r1').get());
    await assertFails(db('admin').doc('acessos/ana/registro/r1').set({ acao: 'dar' }));
  });
});

describe('coleções só do servidor (H-R5-31)', () => {
  const caminhos = [
    'resumosDia/2026-11-25',
    'resumosMes/2026-11',
    'painel/hoje',
    'relatorios/2026-11-25',
    'pedidosCorrecao/p1',
    'revisoes/v1',
    'entregas/e1',
    'decisoes/d1',
    'lotes/2026-11-09-memista-0211',
    'quarentena/q1',
    'agentesNoite/2026-11-09',
    'agentesMes/2026-11',
    'config/agentes',
    'pushes/p1',
    'promocoes/promo1',
  ];

  for (const caminho of caminhos) {
    test(`${caminho}: admin lê; aluno não lê; ninguém grava`, async () => {
      await assertSucceeds(db('admin').doc(caminho).get());
      await assertFails(db('ana').doc(caminho).get());
      await assertFails(db(null).doc(caminho).get());
      await assertFails(db('admin').doc(caminho).set({ x: 1 }));
      await assertFails(db('ana').doc(caminho).set({ x: 1 }));
    });
  }
});

describe('conteudo/{teste|alunos} (H-R5-38): índices de pacotes', () => {
  test('quem tem conta lê os dois; sem conta não; ninguém grava nem lista', async () => {
    await semRegras((f) => f.doc('conteudo/alunos').set({ format: 1, release: 'r2' }));
    await assertSucceeds(db('ana').doc('conteudo/alunos').get());
    await assertSucceeds(db('ana').doc('conteudo/teste').get());
    await assertFails(db(null).doc('conteudo/alunos').get());
    await assertFails(db('ana').doc('conteudo/outro').get());
    await assertFails(db('ana').collection('conteudo').get());
    await assertFails(db('admin').doc('conteudo/alunos').set({ format: 1, release: 'r9' }));
    await assertFails(db('ana').doc('conteudo/teste').set({ format: 1 }));
  });
});

describe('treinador (T87): servidor grava; dono espelha só o progresso', () => {
  const partida = 'users/ana/partidas/lichess_abc12345';
  beforeEach(async () => {
    await semRegras(async (f) => {
      await f.doc(partida).set({ status: 'pronta', precisao: 88, exercicios: [] });
      await f.doc('users/ana/partidas/lichess_erro0001').set({ status: 'erro' });
      await f.doc('users/ana/treinador/conta').set({ plataforma: 'lichess', usuario: 'ana' });
      await f.doc('treinador_painel/estado').set({ fila: {} });
      await f.doc('treinador_modelos/B12').set({ modelos: [] });
    });
  });

  test('o dono lê partida e conta e grava o progresso', async () => {
    await assertSucceeds(db('ana').doc(partida).get());
    await assertSucceeds(db('ana').doc('users/ana/treinador/conta').get());
    await assertSucceeds(db('ana').doc(partida).set({ progresso: { feitos: 2, acertos: 1, pontos: 30 } }, { merge: true }));
    await assertSucceeds(
      db('ana')
        .doc(partida)
        .update({ progresso: { feitos: 2, acertos: 1, pontos: 30, resultados: { 1: true, 2: false }, viuAnalise: true } }),
    );
  });

  test('o dono não muda a análise, o status nem a conta; outro não lê', async () => {
    await assertFails(db('ana').doc(partida).update({ precisao: 100 }));
    await assertFails(db('ana').doc(partida).update({ status: 'na_fila' }));
    await assertFails(db('ana').doc(partida).set({ progresso: { feitos: 'dois' } }, { merge: true }));
    await assertFails(db('ana').doc(partida).update({ progresso: { feitos: 1, viuAnalise: 'sim' } }));
    await assertFails(db('ana').doc(partida).update({ progresso: { feitos: 1, resultados: 'tudo' } }));
    await assertFails(db('ana').doc('users/ana/partidas/lichess_novo0001').set({ status: 'pronta' }));
    await assertFails(db('ana').doc('users/ana/treinador/conta').set({ usuario: 'outro' }));
    await assertFails(db('bia').doc(partida).get());
  });

  test('o painel põe a partida com erro de volta na fila e só isso', async () => {
    await assertSucceeds(db('admin').doc('users/ana/partidas/lichess_erro0001').update({ status: 'na_fila' }));
    await assertFails(db('admin').doc(partida).update({ status: 'na_fila' }));
    await assertSucceeds(db('admin').doc('treinador_painel/estado').get());
    await assertFails(db('admin').doc('treinador_painel/estado').set({ x: 1 }));
    await assertSucceeds(db('admin').doc('treinador_config/geral').set({ exerciciosPorPartida: 5 }));
    await assertFails(db('ana').doc('treinador_config/geral').get());
  });

  test('modelos: quem tem conta lê; fila, contas e teoria ninguém lê pelo app', async () => {
    await assertSucceeds(db('ana').doc('treinador_modelos/B12').get());
    await assertFails(db('ana').doc('treinador_modelos/B12').set({ modelos: [] }));
    await assertFails(db('admin').doc('treinador_fila/ana_x').get());
    await assertFails(db('ana').doc('treinador_contas/ana').get());
    await assertFails(db('ana').doc('treinador_teoria/x').get());
  });
});
