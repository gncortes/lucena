// T87 · Treinador no emulador (Auth + Firestore): ligar a conta, fila com cota e orçamento, a análise com o
// Stockfish de verdade (poucos nós), estatísticas, painel, push (FCM falso), busca e progresso.
import { afterEach, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import {
  treinadorAnalisar,
  treinadorAvisoModelos,
  treinadorDesligarConta,
  treinadorLigarConta,
  usarMensageiro,
  usarTreinador,
} from '../../src/index';
import type { Mensageiro } from '../../src/pessoas/acessos';
import { abrirMotor } from '../../src/treinador/motor';
import { diaBR } from '../../src/treinador/politica';
import { buscaCore, LIGAR_POR_DIA, partidaMudou, processarPartida, type DepsTreinador } from '../../src/treinador/servico';
import { httpFalso, TOKEN_LICHESS_FALSO } from '../treinador/apoio';
import { chamar, codigoDoErro, criarPessoa, limpar } from './apoio';

const db = () => getFirestore();
type Enviada = Parameters<Mensageiro['send']>[0];
let enviadas: Enviada[] = [];
let fila: { uid: string; partida: string }[] = [];

const fcm: Mensageiro = {
  async send(m) {
    enviadas.push(m);
    return 'msg';
  },
};

function deps(extra: Partial<DepsTreinador> = {}): DepsTreinador {
  return {
    db: db(),
    mensageiro: fcm,
    agora: new Date(),
    http: httpFalso(),
    enfileirar: async (uid, partida) => {
      fila.push({ uid, partida });
    },
    abrirMotor: () => abrirMotor(),
    explorador: async () => null,
    ...extra,
  };
}

async function assinante(uid: string): Promise<void> {
  await db().doc(`acessos/${uid}`).set({ cursos: { treinador: { origem: 'admin', dadoEm: Timestamp.now() } } });
}

async function aparelho(uid: string): Promise<void> {
  await db().doc(`users/${uid}/push/device`).set({ token: `tok-${uid}`, permissao: 'permitida', updatedAt: Timestamp.now() });
}

describe('treinador no emulador', () => {
  beforeEach(async () => {
    await limpar();
    enviadas = [];
    fila = [];
    usarMensageiro(fcm);
    usarTreinador({ http: httpFalso(), enfileirar: deps().enfileirar, explorador: async () => null });
    // Poucos nós para o teste ser rápido (o grátis usa nosGratis em tudo).
    await db().doc('treinador_config/geral').set({ nosGratis: 20_000, nosUsuario: 50_000, nosDemais: 20_000 });
    await criarPessoa('ana', 'ana@teste.com');
    await criarPessoa('bia', 'bia@teste.com');
  });

  afterEach(() => {
    usarMensageiro(null);
    usarTreinador(null);
  });

  test('ligar: login, plataforma, usuário inexistente e plataforma fora', async () => {
    assert.equal(await codigoDoErro(chamar(treinadorLigarConta, null, { plataforma: 'lichess', token: TOKEN_LICHESS_FALSO })), 'unauthenticated');
    assert.equal(await codigoDoErro(chamar(treinadorLigarConta, 'ana', { plataforma: 'fide', usuario: 'x1' })), 'invalid-argument');
    assert.equal(await codigoDoErro(chamar(treinadorLigarConta, 'ana', { plataforma: 'lichess', token: 'a b' })), 'invalid-argument');
    // Lichess só pelo login de lá: o nome digitado não prova o dono da conta.
    assert.equal(await codigoDoErro(chamar(treinadorLigarConta, 'ana', { plataforma: 'lichess', usuario: 'DrNykterstein' })), 'invalid-argument');
    assert.equal(await codigoDoErro(chamar(treinadorLigarConta, 'ana', { plataforma: 'lichess', token: 'token-falso-revogado-x' })), 'failed-precondition');
    assert.equal(await codigoDoErro(chamar(treinadorLigarConta, 'ana', { plataforma: 'chesscom', usuario: 'ninguem-aqui' })), 'not-found');
    usarTreinador({ http: httpFalso([], 429) });
    assert.equal(await codigoDoErro(chamar(treinadorLigarConta, 'ana', { plataforma: 'lichess', token: TOKEN_LICHESS_FALSO })), 'unavailable');
    assert.equal((await db().doc('treinador_painel/estado').get()).get('lichess.ok'), false);
    assert.equal((await db().doc('users/ana/treinador/conta').get()).exists, false);
  });

  test('ligar o Lichess (grátis): conta, 3 partidas na fila, cota da semana e conta nova no painel', async () => {
    const r = await chamar<{ usuario: string; importadas: number }>(treinadorLigarConta, 'ana', {
      plataforma: 'lichess',
      token: TOKEN_LICHESS_FALSO,
    });
    assert.deepEqual(r, { usuario: 'DrNykterstein', importadas: 3 });
    const conta = (await db().doc('users/ana/treinador/conta').get()).data()!;
    assert.equal(conta.plataforma, 'lichess');
    assert.equal(conta.usuario, 'DrNykterstein');
    assert.ok(conta.ligadaEm instanceof Timestamp);
    assert.equal(conta.avisoModelos, false);
    const partidas = await db().collection('users/ana/partidas').get();
    assert.equal(partidas.size, 3);
    assert.ok(partidas.docs.every((d) => d.get('status') === 'na_fila' && d.get('jogadaEm') instanceof Timestamp));
    assert.equal(fila.length, 3);
    assert.equal((await db().collection('treinador_fila').get()).size, 3);
    assert.equal((await db().doc('treinador_contas/ana').get()).get('semana.n'), 3);
    const dia = (await db().doc(`treinador_painel/dia-${diaBR(new Date())}`).get()).data()!;
    assert.equal(dia.contas.novas, 1);

    // Cota da semana cheia: pedir mais uma dá permission-denied (o app leva à compra).
    const uma = partidas.docs[0];
    await uma.ref.update({ status: 'nova' });
    await db().doc(`treinador_fila/ana_${uma.id}`).delete();
    const erro = await codigoDoErro(chamar(treinadorAnalisar, 'ana', { partida: uma.id, avisar: true }));
    assert.equal(erro, 'permission-denied');
  });

  test('ligar o chess.com (assinante) e analisar: partida pronta, estatísticas, painel e push', async () => {
    await assinante('bia');
    await aparelho('bia');
    // Assinante com nós baixos também (o teste mede o fluxo, não a força).
    await db().doc('treinador_config/geral').set({ nosUsuario: 50_000, nosDemais: 20_000, exerciciosPorPartida: 4 });
    const r = await chamar<{ importadas: number }>(treinadorLigarConta, 'bia', { plataforma: 'chesscom', usuario: 'Hikaru' });
    assert.equal(r.importadas, 3);
    assert.equal(fila.length, 3);
    assert.equal((await db().doc('treinador_contas/bia').get()).get('mes.n'), 3);

    const { partida } = fila[0];
    // "Me avise" com a partida já na fila: só marca.
    assert.deepEqual(await chamar(treinadorAnalisar, 'bia', { partida, avisar: true }), { status: 'na_fila' });
    assert.equal((await db().doc(`treinador_fila/bia_${partida}`).get()).get('avisar'), true);

    await processarPartida(deps(), 'bia', partida);
    const d = (await db().doc(`users/bia/partidas/${partida}`).get()).data()!;
    assert.equal(d.status, 'pronta');
    assert.equal(d.origem, 'servidor');
    assert.equal(d.plano, 'assinante');
    assert.ok(d.analisadaEm instanceof Timestamp);
    assert.ok(d.precisao >= 0 && d.precisao <= 100);
    assert.ok(d.exercicios.length >= 1 && d.exercicios.length <= 4);
    assert.ok(d.lances.length > 20);
    assert.equal(d.teoria, null);
    assert.deepEqual(Object.keys(d.fases).sort(), ['abertura', 'final', 'meio']);
    assert.ok(typeof d.resumo === 'string' && d.resumo.length > 10);
    assert.equal(d.motor.nos, 50_000);
    assert.equal((await db().doc(`treinador_fila/bia_${partida}`).get()).exists, false);

    const est = (await db().doc('users/bia/treinador/estatisticas').get()).data()!;
    assert.equal(est.partidasAnalisadas, 1);
    assert.equal(est.estilo.nivel, 'primeira');

    const dia = (await db().doc(`treinador_painel/dia-${diaBR(new Date())}`).get()).data()!;
    assert.equal(dia.partidas.pagas, 1);
    assert.equal(dia.funil.analisadas, 1);
    assert.equal(dia.exercicios.gerados, d.exercicios.length);
    assert.ok(dia.custoUsd.pagas > 0);
    assert.equal(dia.temposPushMin.length, 1);
    const estado = (await db().doc('treinador_painel/estado').get()).data()!;
    assert.equal(estado.fila.naFila, 2);
    assert.equal(estado.fila.prontasHoje, 1);

    assert.equal(enviadas.length, 1);
    assert.equal(enviadas[0].token, 'tok-bia');
    assert.equal(enviadas[0].notification, undefined);
    assert.equal(enviadas[0].data.tipo, 'treinador');
    assert.equal(enviadas[0].data.titulo, 'Sua partida foi analisada');
    assert.equal(enviadas[0].data.partida, partida);

    // Pronta: pedir de novo não refaz.
    assert.deepEqual(await chamar(treinadorAnalisar, 'bia', { partida, avisar: false }), { status: 'pronta' });

    // Segunda análise sem "me avise", dentro da hora: sem push automático.
    await processarPartida(deps(), 'bia', fila[1].partida);
    assert.equal(enviadas.length, 1);
    assert.equal((await db().doc('users/bia/treinador/estatisticas').get()).get('partidasAnalisadas'), 2);

    // Progresso espelhado pelo app: funil abriram/comecaram/terminaram.
    const total = d.exercicios.length;
    await partidaMudou(deps(), 'bia', partida, d, { ...d, progresso: { feitos: 1, acertos: 1, pontos: 10 } });
    await partidaMudou(deps(), 'bia', partida, { ...d, progresso: { feitos: 1, acertos: 1 } }, { ...d, progresso: { feitos: total, acertos: 2 } });
    const dia2 = (await db().doc(`treinador_painel/dia-${diaBR(new Date())}`).get()).data()!;
    assert.equal(dia2.funil.abriram, 1);
    assert.equal(dia2.funil.comecaram, 1);
    assert.equal(dia2.funil.terminaram, total > 1 ? 1 : 1);
    assert.equal(dia2.exercicios.feitos, total);

    // Com `resultados` e `viuAnalise`: porTipo/porTema e viramAnalise, sem contar duas vezes o mesmo exercício.
    const exs = d.exercicios as { n: number; tipo: string; tema: string | null }[];
    const resultados = Object.fromEntries(exs.map((e, i) => [String(e.n), i === 0]));
    const p1 = { feitos: total, acertos: 2 };
    const p2 = { ...p1, resultados, viuAnalise: true };
    await partidaMudou(deps(), 'bia', partida, { ...d, progresso: p1 }, { ...d, progresso: p2 });
    await partidaMudou(deps(), 'bia', partida, { ...d, progresso: p2 }, { ...d, progresso: { ...p2, pontos: 30 } });
    const dia3 = (await db().doc(`treinador_painel/dia-${diaBR(new Date())}`).get()).data()!;
    assert.equal(dia3.funil.viramAnalise, 1);
    const somaTipo = Object.values(dia3.porTipo as Record<string, { feitos?: number; acertos?: number }>);
    assert.equal(somaTipo.reduce((s, t) => s + (t.feitos ?? 0), 0), total);
    assert.equal(somaTipo.reduce((s, t) => s + (t.acertos ?? 0), 0), total > 0 ? 1 : 0);
    const tema0 = exs[0].tema ?? 'sem_tema';
    assert.ok(dia3.porTema[tema0].acertos >= 1);
    assert.equal(
      Object.values(dia3.porTema as Record<string, { feitos: number }>).reduce((s, t) => s + t.feitos, 0),
      total,
    );
  });

  test('orçamento a 100%: grátis espera na fila sem tarefa; com verba de novo, a busca libera', async () => {
    await db().doc(`treinador_painel/dia-${diaBR(new Date())}`).set({ data: diaBR(new Date()), custoUsd: { pagas: 25 } });
    await chamar(treinadorLigarConta, 'ana', { plataforma: 'lichess', token: TOKEN_LICHESS_FALSO });
    assert.equal(fila.length, 0);
    const naFila = await db().collection('treinador_fila').get();
    assert.equal(naFila.size, 3);
    assert.ok(naFila.docs.every((d) => d.get('espera') === 'orcamento'));

    await db().doc('treinador_config/geral').set({ orcamentoMensalUsd: 100 }, { merge: true });
    const r = await buscaCore(deps());
    assert.equal(r.contas, 1);
    assert.equal(r.novas, 0);
    assert.equal(r.reenfileiradas, 3);
    assert.equal(fila.length, 3);
    const dia = (await db().doc(`treinador_painel/dia-${diaBR(new Date())}`).get()).data()!;
    assert.equal(dia.contas.ligadas, 1);
    assert.equal(dia.assinantes, 0);
    assert.equal((await db().doc('treinador_painel/estado').get()).get('lichess.ok'), true);
  });

  test('429 do Lichess na busca não para o chess.com dos outros (G11)', async () => {
    await chamar(treinadorLigarConta, 'ana', { plataforma: 'lichess', token: TOKEN_LICHESS_FALSO });
    await chamar(treinadorLigarConta, 'bia', { plataforma: 'chesscom', usuario: 'hikaru' });
    // Ana foi buscada há mais tempo: vem primeiro e leva o 429.
    await db().doc('treinador_contas/ana').set({ ultimaBusca: Timestamp.fromMillis(1) }, { merge: true });
    await db().doc('treinador_contas/bia').set({ ultimaBusca: Timestamp.fromMillis(2) }, { merge: true });
    const base = httpFalso();
    const http: DepsTreinador['http'] = async (url, init) =>
      url.startsWith('https://lichess.org/api/games/') ? { status: 429, text: async () => '' } : base(url, init);
    await buscaCore(deps({ http }));
    assert.equal((await db().doc('treinador_contas/ana').get()).get('ultimaBusca').toMillis(), 1);
    assert.ok((await db().doc('treinador_contas/bia').get()).get('ultimaBusca').toMillis() > 2, 'o chess.com da Bia foi buscado');
    assert.equal((await db().doc('treinador_painel/estado').get()).get('lichess.ok'), false);
  });

  test('falha na análise: status erro, falha no painel; "Tentar de novo" do painel volta à fila', async () => {
    await assinante('bia');
    await chamar(treinadorLigarConta, 'bia', { plataforma: 'chesscom', usuario: 'hikaru' });
    const { partida } = fila[0];
    await processarPartida(
      deps({
        abrirMotor: async () => {
          throw new Error('timeout do motor');
        },
      }),
      'bia',
      partida,
    );
    const ref = db().doc(`users/bia/partidas/${partida}`);
    assert.equal((await ref.get()).get('status'), 'erro');
    assert.equal((await ref.get()).get('erroMotivo'), 'tempo');
    const estado = (await db().doc('treinador_painel/estado').get()).data()!;
    assert.equal(estado.falhasHoje.length, 1);
    assert.equal(estado.falhasHoje[0].motivo, 'tempo');
    assert.equal(estado.falhasHoje[0].refazivel, true);
    fila = [];
    await ref.update({ status: 'na_fila' });
    await partidaMudou(deps(), 'bia', partida, { status: 'erro' }, { status: 'na_fila' });
    assert.deepEqual(fila, [{ uid: 'bia', partida }]);
  });

  test('aviso de modelos e desligar (as partidas ficam)', async () => {
    await chamar(treinadorLigarConta, 'ana', { plataforma: 'lichess', token: TOKEN_LICHESS_FALSO });
    await chamar(treinadorAvisoModelos, 'ana', { ligado: true });
    assert.equal((await db().doc('users/ana/treinador/conta').get()).get('avisoModelos'), true);
    assert.equal(await codigoDoErro(chamar(treinadorAvisoModelos, 'ana', { ligado: 'sim' })), 'invalid-argument');
    await chamar(treinadorDesligarConta, 'ana', {});
    assert.equal((await db().doc('users/ana/treinador/conta').get()).exists, false);
    assert.equal((await db().doc('treinador_contas/ana').get()).exists, false);
    assert.equal((await db().collection('users/ana/partidas').get()).size, 3);
    assert.equal(await codigoDoErro(chamar(treinadorAnalisar, 'ana', { partida: 'x' })), 'invalid-argument');
    assert.equal(await codigoDoErro(chamar(treinadorAnalisar, 'ana', { partida: 'lichess_naoexiste' })), 'not-found');
  });

  test('ligar tem limite por dia, contado antes de chamar a plataforma', async () => {
    const pedidos: { url: string }[] = [];
    usarTreinador({ http: httpFalso(pedidos as never), enfileirar: deps().enfileirar, explorador: async () => null });
    for (let i = 0; i < LIGAR_POR_DIA; i++) {
      await codigoDoErro(chamar(treinadorLigarConta, 'ana', { plataforma: 'lichess', token: 'token-falso-revogado-x' }));
    }
    const antes = pedidos.length;
    assert.equal(await codigoDoErro(chamar(treinadorLigarConta, 'ana', { plataforma: 'lichess', token: TOKEN_LICHESS_FALSO })), 'resource-exhausted');
    assert.equal(pedidos.length, antes, 'recusou sem chamar a plataforma');
    // O limite é por conta: a Bia liga normalmente.
    await chamar(treinadorLigarConta, 'bia', { plataforma: 'lichess', token: TOKEN_LICHESS_FALSO });
    assert.equal((await db().doc('users/bia/treinador/conta').get()).exists, true);
  });

  test('desligar e ligar de novo não zera a cota do grátis', async () => {
    await chamar(treinadorLigarConta, 'ana', { plataforma: 'lichess', token: TOKEN_LICHESS_FALSO });
    const cota = (await db().doc('treinador_contas/ana').get()).get('semana');
    assert.ok(cota?.n > 0, 'a importação gastou cota');
    await chamar(treinadorDesligarConta, 'ana', {});
    await chamar(treinadorLigarConta, 'ana', { plataforma: 'chesscom', usuario: 'hikaru' });
    const depois = (await db().doc('treinador_contas/ana').get()).get('semana');
    assert.ok(depois.n >= cota.n, `cota voltou (${cota.n} → ${depois.n})`);
  });
});
