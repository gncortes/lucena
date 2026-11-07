// H-R5-35 · Pontos de atenção: resposta gravada do funil, telas e permissão do BigQuery, ordem e corte.
import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import {
  etapasDoFunil,
  FLUXO_PERMISSAO,
  FLUXO_TELA,
  FUNIS,
  lerPontosAtencao,
  pedidoDoFunil,
  pontosDeAtencao,
  sqlPermissao,
  sqlTelas,
  type Etapa,
} from '../src/fechamento/atencao';
import { atencaoDoAnalytics, type ClienteFunil } from '../src/fechamento/bigquery';
import { FUNIL_ENTRADA_19_25, FUNIL_POUCOS } from './fixtures/funil';

const [ENTRADA, , , CONTA] = FUNIS;
const e = (fluxo: string, passo: string, chegaram: number, seguiram: number): Etapa => ({ fluxo, passo, chegaram, seguiram });

describe('funil da Data API', () => {
  test('o pedido usa um passo por evento e OR quando há mais de um', () => {
    const p = pedidoDoFunil('123', CONTA, '2026-11-19', '2026-11-25');
    assert.equal(p.property, 'properties/123');
    assert.deepEqual(p.dateRanges, [{ startDate: '2026-11-19', endDate: '2026-11-25' }]);
    assert.deepEqual(p.funnel.steps[0].filterExpression, { funnelEventFilter: { eventName: 'conta_convite' } });
    assert.deepEqual(p.funnel.steps[1].filterExpression, {
      orGroup: { expressions: [{ funnelEventFilter: { eventName: 'sign_up' } }, { funnelEventFilter: { eventName: 'login' } }] },
    });
  });

  test('resposta gravada vira etapas: chegaram no passo, seguiram para o próximo', () => {
    assert.deepEqual(etapasDoFunil(ENTRADA, FUNIL_ENTRADA_19_25), [
      e('Entrada no app', 'Primeira abertura', 400, 360),
      e('Entrada no app', 'Boas-vindas', 360, 270),
      e('Entrada no app', 'Fim das boas-vindas', 270, 243),
    ]);
    assert.deepEqual(etapasDoFunil(CONTA, FUNIL_POUCOS), [e('Criação de conta', 'Convite para a conta', 12, 0)]);
    assert.throws(() => etapasDoFunil(CONTA, {}), /funnelTable/);
  });
});

describe('pontosDeAtencao', () => {
  test('maior piora primeiro, um passo por fluxo, < 30 pessoas fora, até 5', () => {
    const atual = [
      ...etapasDoFunil(ENTRADA, FUNIL_ENTRADA_19_25), // pior passo: Boas-vindas, 25%
      e(FLUXO_PERMISSAO, 'Pedido de permissão', 200, 78), // 61%
      e('Criação de conta', 'Convite para a conta', 29, 0), // poucos
      e(FLUXO_TELA, '/level-test/:pos', 100, 86), // 14%
      e(FLUXO_TELA, '/', 500, 100), // a saída natural
      e(FLUXO_TELA, '/a', 50, 40),
      e(FLUXO_TELA, '/b', 50, 40),
      e(FLUXO_TELA, '/c', 50, 40),
    ];
    const anterior = [
      e('Entrada no app', 'Boas-vindas', 300, 230), // 23,3% → +1,7
      e(FLUXO_PERMISSAO, 'Pedido de permissão', 100, 46), // 54% → +7
      e(FLUXO_TELA, '/level-test/:pos', 100, 89), // 11% → +3
      e(FLUXO_TELA, '/a', 10, 10), // poucos antes: sem comparação
    ];
    const p = pontosDeAtencao(atual, anterior);
    assert.equal(p.length, 5);
    assert.deepEqual(
      p.map((x) => [x.passo, x.saida, x.variacaoPp]),
      [
        ['Pedido de permissão', 0.61, 7],
        ['/level-test/:pos', 0.14, 3],
        ['Boas-vindas', 0.25, 1.7],
        ['/a', 0.2, null],
        ['/b', 0.2, null],
      ],
    );
  });

  test('sem nada com 30 pessoas, a lista sai vazia', () => {
    assert.deepEqual(pontosDeAtencao([e('Tela', '/x', 29, 0)], []), []);
  });

  test('janela de 7 dias até o dia fechado e os 7 anteriores', async () => {
    const pedidos: string[] = [];
    const r = await lerPontosAtencao(
      {
        async etapas(inicio, fim) {
          pedidos.push(`${inicio}..${fim}`);
          return [];
        },
      },
      '2026-11-25',
    );
    assert.deepEqual(pedidos.sort(), ['2026-11-12..2026-11-18', '2026-11-19..2026-11-25']);
    assert.deepEqual(r, { inicio: '2026-11-19', fim: '2026-11-25', itens: [] });
  });
});

describe('fonte real com clientes falsos', () => {
  test('junta funis, permissão e telas; datas do BigQuery em aaaammdd', async () => {
    const consultas: { query: string; params: Record<string, string> }[] = [];
    const bq = {
      async query(q: { query: string; params: Record<string, string> }) {
        consultas.push(q);
        return q.query.includes('aviso_permitido')
          ? [[{ chegaram: 200, seguiram: 78 }]]
          : [[{ tela: '/level-test/:pos', chegaram: 100, sairam: 14 }]];
      },
    };
    const ga: ClienteFunil = {
      async runFunnelReport(p) {
        return [p.funnel.steps[0].name === 'Primeira abertura' ? FUNIL_ENTRADA_19_25 : FUNIL_POUCOS];
      },
    };
    const etapas = await atencaoDoAnalytics('analytics_123', '123', bq as never, ga).etapas('2026-11-19', '2026-11-25');
    assert.deepEqual(consultas[0].params, { inicio: '20261119', fim: '20261125' });
    assert.ok(etapas.some((x) => x.fluxo === 'Entrada no app' && x.passo === 'Boas-vindas' && x.chegaram === 360));
    assert.deepEqual(etapas.find((x) => x.fluxo === FLUXO_PERMISSAO), e(FLUXO_PERMISSAO, 'Pedido de permissão', 200, 78));
    assert.deepEqual(etapas.find((x) => x.fluxo === FLUXO_TELA), e(FLUXO_TELA, '/level-test/:pos', 100, 86));
  });

  test('SQL não aceita dataset com injeção', () => {
    assert.throws(() => sqlTelas('ds`; DROP'));
    assert.throws(() => sqlPermissao('a.b'));
    assert.match(sqlTelas('analytics_1'), /FROM `analytics_1\.events_\*`/);
  });
});
