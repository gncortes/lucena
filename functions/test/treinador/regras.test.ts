// T87 · Fontes (respostas gravadas), política de fila, teoria (explorador falso), estatísticas e texto do push.
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { Timestamp } from 'firebase-admin/firestore';
import { calcularEstatisticas, type PartidaParaEstatistica } from '../../src/treinador/estatisticas';
import { buscarPartidas, conferirUsuario, donoDoTokenLichess, ErroFonte, nomeDaAberturaChesscom } from '../../src/treinador/fontes';
import {
  CONFIG_TREINADOR_PADRAO,
  configDaAnalise,
  custoUsd,
  decidir,
  direitoVigente,
  lerConfig,
  semanaBR,
  somarCota,
} from '../../src/treinador/politica';
import { textoDoPush } from '../../src/treinador/servico';
import { acharTeoria, chaveFen, tokenLichess, type LanceExplorador, type RespostaExplorador } from '../../src/treinador/teoria';
import { httpFalso, TOKEN_LICHESS_FALSO, type Pedido } from './apoio';

describe('fontes', () => {
  it('confere o usuário do Lichess e do chess.com com o nome oficial', async () => {
    const pedidos: Pedido[] = [];
    const http = httpFalso(pedidos);
    assert.equal(await conferirUsuario(http, 'lichess', 'DrNykterstein'), 'DrNykterstein');
    assert.equal(await conferirUsuario(http, 'chesscom', 'hikaru'), 'Hikaru');
    assert.equal(await conferirUsuario(http, 'lichess', 'ninguem-aqui'), null);
    assert.equal(await conferirUsuario(http, 'chesscom', 'ninguem-aqui'), null);
    // User-Agent próprio: o Lichess recusa o padrão.
    assert.ok(pedidos.every((p) => p.headers['User-Agent']?.startsWith('Lucena/')));
  });

  it('o token do login do Lichess diz o dono da conta; token revogado dá null', async () => {
    const pedidos: Pedido[] = [];
    assert.equal(await donoDoTokenLichess(httpFalso(pedidos), TOKEN_LICHESS_FALSO), 'DrNykterstein');
    assert.equal(await donoDoTokenLichess(httpFalso(pedidos), 'token-falso-revogado-x'), null);
    assert.equal(pedidos[0].url, 'https://lichess.org/api/account');
    await assert.rejects(donoDoTokenLichess(httpFalso([], 429), 'x'), (e: unknown) => e instanceof ErroFonte && e.motivo === 'limite');
  });

  it('429 do Lichess vira ErroFonte limite; 500 vira fora', async () => {
    await assert.rejects(conferirUsuario(httpFalso([], 429), 'lichess', 'x'), (e: unknown) => e instanceof ErroFonte && e.motivo === 'limite');
    await assert.rejects(conferirUsuario(httpFalso([], 500), 'lichess', 'x'), (e: unknown) => e instanceof ErroFonte && e.motivo === 'fora');
  });

  it('partidas do Lichess no formato do contrato', async () => {
    const ps = await buscarPartidas(httpFalso(), 'lichess', 'DrNykterstein', null, 3);
    assert.equal(ps.length, 3);
    for (const p of ps) {
      assert.match(p.id, /^lichess_[A-Za-z0-9]{8}$/);
      assert.ok(['bullet', 'blitz', 'rapida'].includes(p.ritmo));
      assert.match(p.cadencia, /^\d+(,\d+)?\+\d+$/);
      assert.ok(['brancas', 'pretas'].includes(p.cor));
      assert.ok(['vitoria', 'derrota', 'empate'].includes(p.resultado));
      assert.ok(p.pgn.includes('1. '));
      assert.ok(p.url.startsWith('https://lichess.org/'));
    }
  });

  it('partidas do chess.com: mais novas primeiro, até o máximo, e `desde` corta as antigas', async () => {
    const ps = await buscarPartidas(httpFalso(), 'chesscom', 'hikaru', null, 3);
    assert.equal(ps.length, 3);
    assert.ok(ps[0].jogadaEm >= ps[1].jogadaEm && ps[1].jogadaEm >= ps[2].jogadaEm);
    assert.ok(ps.every((p) => p.id.startsWith('chesscom_') && p.plataforma === 'chesscom'));
    const depois = await buscarPartidas(httpFalso(), 'chesscom', 'hikaru', ps[0].jogadaEm.getTime(), 10);
    assert.equal(depois.length, 0);
    assert.equal(nomeDaAberturaChesscom('https://www.chess.com/openings/Sicilian-Defense-Najdorf-Variation-6.Be3'), 'Sicilian Defense Najdorf Variation');
  });
});

describe('política da fila', () => {
  const agora = new Date('2026-11-11T15:00:00Z'); // quarta
  const cfg = CONFIG_TREINADOR_PADRAO;

  it('config: padrões e limites (exercícios de 1 a 6)', () => {
    assert.equal(lerConfig(undefined).exerciciosPorPartida, 4);
    assert.equal(lerConfig({ exerciciosPorPartida: 9 }).exerciciosPorPartida, 6);
    assert.equal(lerConfig({ exerciciosPorPartida: 0 }).exerciciosPorPartida, 1);
    assert.equal(lerConfig({ exerciciosPorPartida: 'x' }).exerciciosPorPartida, 4);
    assert.equal(lerConfig({ tipos: { adversario: false } }).tipos.adversario, false);
    assert.equal(lerConfig({ tipos: { adversario: false } }).tipos.seu_melhor, true);
  });

  it('direito vigente: sem revogação e com `ate` futuro ou sem `ate`', () => {
    assert.equal(direitoVigente(undefined, agora), false);
    assert.equal(direitoVigente({ origem: 'admin' }, agora), true);
    assert.equal(direitoVigente({ ate: Timestamp.fromDate(new Date('2026-12-01')) }, agora), true);
    assert.equal(direitoVigente({ ate: Timestamp.fromDate(new Date('2026-11-01')) }, agora), false);
    assert.equal(direitoVigente({ revogadoEm: Timestamp.fromDate(agora) }, agora), false);
  });

  it('orçamento a 100%: grátis espera, assinante segue', () => {
    assert.deepEqual(decidir(cfg, 'gratis', undefined, 5, agora), { entra: true, plano: 'gratis', espera: null });
    assert.deepEqual(decidir(cfg, 'gratis', undefined, 20, agora), { entra: true, plano: 'gratis', espera: 'orcamento' });
    assert.deepEqual(decidir(cfg, 'assinante', undefined, 999, agora), { entra: true, plano: 'assinante', espera: null });
  });

  it('cota do grátis por semana e teto do assinante por mês', () => {
    let conta = {};
    for (let i = 0; i < 3; i++) conta = { ...conta, ...somarCota(conta, 'gratis', agora) };
    assert.deepEqual(decidir(cfg, 'gratis', conta, 0, agora), { entra: false, plano: 'gratis', motivo: 'cota' });
    // Semana seguinte zera.
    const segunda = new Date('2026-11-16T12:00:00Z');
    assert.equal(semanaBR(segunda), '2026-11-16');
    assert.equal(decidir(cfg, 'gratis', conta, 0, segunda).entra, true);
    const teto = { mes: { id: '2026-11', n: 150 } };
    assert.deepEqual(decidir(cfg, 'assinante', teto, 0, agora), { entra: false, plano: 'assinante', motivo: 'teto' });
    assert.deepEqual(decidir({ ...cfg, ativo: false }, 'assinante', undefined, 0, agora).entra, false);
    assert.deepEqual(decidir({ ...cfg, filaGratis: false }, 'gratis', undefined, 0, agora).entra, false);
  });

  it('nós por plano e custo por segundo', () => {
    assert.equal(configDaAnalise(cfg, 'assinante').nosUsuario, 1_000_000);
    assert.equal(configDaAnalise(cfg, 'gratis').nosUsuario, 300_000);
    assert.equal(configDaAnalise({ ...cfg, exerciciosPorPartida: 6 }, 'gratis').exercicios, 6);
    assert.ok(Math.abs(custoUsd(100) - 0.00406) < 1e-6);
  });
});

describe('teoria', () => {
  // Base falsa: 1.e4 e5 2.Cf3 Cc6 são muito jogados; 2...a6 quase nunca.
  const base: Record<string, LanceExplorador[]> = {
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -': [{ uci: 'e2e4', san: 'e4', white: 500, draws: 300, black: 400 }],
    'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -': [{ uci: 'e7e5', san: 'e5', white: 300, draws: 200, black: 250 }],
    'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -': [{ uci: 'g1f3', san: 'Nf3', white: 200, draws: 100, black: 150 }],
    'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq -': [
      { uci: 'b8c6', san: 'Nc6', white: 120, draws: 60, black: 90 },
      { uci: 'g8f6', san: 'Nf6', white: 40, draws: 30, black: 30 },
      { uci: 'a7a6', san: 'a6', white: 3, draws: 0, black: 1 },
    ],
    'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq -': [{ uci: 'f1b5', san: 'Bb5', white: 80, draws: 30, black: 40 }],
    'rnbqkb1r/pppp1ppp/5n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq -': [{ uci: 'f3e5', san: 'Nxe5', white: 30, draws: 10, black: 10 }],
  };
  const pedidos: string[] = [];
  const explorador = async (fen: string): Promise<RespostaExplorador> => {
    pedidos.push(fen);
    return { moves: base[fen.split(' ').slice(0, 4).join(' ')] ?? [] };
  };

  it('acha a saída da teoria com os candidatos e a linha em SAN', async () => {
    const t = await acharTeoria('1. e4 e5 2. Nf3 a6 3. Nxe5 *', explorador);
    assert.ok(t);
    assert.equal(t.lance, 3);
    assert.equal(t.fen.split(' ')[0], 'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R');
    assert.deepEqual(
      t.candidatos.map((c) => c.san),
      ['Nc6', 'Nf6'],
    );
    assert.deepEqual(t.candidatos[0].linha, ['Nc6', 'Bb5']);
    assert.equal(t.candidatos[0].partidas, 270);
  });

  it('sem resposta, erro do explorador ou primeiro lance fora: null', async () => {
    assert.equal(await acharTeoria('1. a3 e5 *', explorador), null);
    assert.equal(await acharTeoria('1. e4 e5 *', async () => null), null);
    assert.equal(
      await acharTeoria('1. e4 e5 2. Nf3 a6 *', async () => {
        throw new Error('fora');
      }),
      null,
    );
  });

  it('chave do cache sem relógios e sem barras', () => {
    assert.equal(chaveFen('8/8/8/8/8/8/8/K6k w - - 12 40'), '8_8_8_8_8_8_8_K6k w - -');
  });

  it('token: variável do ambiente, senão Secret Manager; sem acesso, null (sem criar nem imprimir)', async () => {
    const antes = process.env.LICHESS_TOKEN;
    delete process.env.LICHESS_TOKEN;
    try {
      assert.equal(await tokenLichess(httpFalso(), undefined, async () => 'x'), null);
      assert.equal(await tokenLichess(httpFalso([], 403), 'p', async () => 'x'), null);
      const http = async () => ({ status: 200, text: async () => JSON.stringify({ payload: { data: Buffer.from('abc').toString('base64') } }) });
      assert.equal(await tokenLichess(http, 'p', async () => 'x'), 'abc');
      process.env.LICHESS_TOKEN = 'do-ambiente';
      assert.equal(await tokenLichess(httpFalso(), 'p', async () => 'x'), 'do-ambiente');
    } finally {
      if (antes === undefined) delete process.env.LICHESS_TOKEN;
      else process.env.LICHESS_TOKEN = antes;
    }
  });
});

describe('estatísticas', () => {
  const agora = new Date('2026-11-11T15:00:00Z');
  const p = (id: string, dias: number, extra: Partial<PartidaParaEstatistica> = {}): PartidaParaEstatistica => ({
    id,
    jogadaEm: new Date(agora.getTime() - dias * 86_400_000),
    cor: 'brancas',
    resultado: 'vitoria',
    abertura: { eco: 'B12', nome: 'Caro-Kann Defense' },
    precisao: 80,
    fases: { abertura: 90, meio: 70, final: null },
    teoria: { lance: 9 },
    erros: [],
    ...extra,
  });

  it('semanas, fases, temas, aberturas e estilo', () => {
    const erro = (tema: string | null) => ({ lance: 20, indice: 39, fen: 'f', fase: 'meio' as const, tema });
    const est = calcularEstatisticas(
      [
        p('a', 0, { erros: [erro('garfo')] }),
        p('b', 1, { erros: [erro('garfo'), erro(null)], resultado: 'derrota' }),
        p('c', 8, { precisao: 60, teoria: { lance: 11 } }),
      ],
      agora,
    );
    assert.equal(est.partidasAnalisadas, 3);
    assert.equal(est.precisaoSemanas.length, 2);
    assert.equal(est.precisaoSemanas[1].precisao, 80);
    assert.deepEqual(est.errosPorFase, { abertura: 0, meio: 3, final: 0 });
    assert.equal(est.errosPorTema.garfo.length, 2);
    assert.equal(est.aberturas[0].partidas, 3);
    assert.equal(est.aberturas[0].vitorias, 2);
    // Meio-lance 9 → lance 5.
    assert.deepEqual(est.aberturas[0].saidaTeoria, { lance: 5, vezes: 2 });
    assert.equal(est.estilo.nivel, 'primeira');
    assert.equal(est.estilo.fortes[0].texto, 'Precisão de 90% na abertura');
    assert.deepEqual(
      est.estilo.acertar.map((x: { texto: string }) => x.texto),
      ['Precisão de 70% no meio-jogo', 'Erros com garfos em 2 partidas'],
    );
  });

  it('sem partidas: tudo vazio', () => {
    const est = calcularEstatisticas([], agora);
    assert.equal(est.partidasAnalisadas, 0);
    assert.deepEqual(est.aberturas, []);
    assert.deepEqual(est.estilo, { nivel: 'primeira', fortes: [], acertar: [] });
  });
});

describe('push', () => {
  it('texto do push com a precisão e os exercícios', () => {
    assert.equal(textoDoPush({ precisao: 87, exercicios: [{}, {}, {}, {}] as never }), 'Precisão de 87%. 4 exercícios para treinar.');
    assert.equal(textoDoPush({ precisao: 95, exercicios: [{}] as never }), 'Precisão de 95%. 1 exercício para treinar.');
  });
});
