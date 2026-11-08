// H-R5-36 · ativosPeriodo: validação do período (R12) e uma consulta só ao BigQuery.
import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { ativosDoBigQuery } from '../src/fechamento/bigquery';
import { ativosPeriodoCore, validarPeriodo } from '../src/fechamento/periodo';

// 26/11/2026 às 01:00 em Brasília (04:00 UTC): ontem = 25/11.
const AGORA = new Date('2026-11-26T04:00:00Z');

const invalido = (dados: unknown, msg: RegExp) =>
  assert.throws(() => validarPeriodo(dados, AGORA), (e: { code?: string; message: string }) => {
    assert.equal(e.code, 'invalid-argument');
    assert.match(e.message, msg);
    return true;
  });

describe('validarPeriodo', () => {
  test('aceita do lançamento até ontem, e um dia só', () => {
    assert.deepEqual(validarPeriodo({ inicio: '2026-11-05', fim: '2026-11-25' }, AGORA), {
      inicio: '2026-11-05',
      fim: '2026-11-25',
    });
    assert.deepEqual(validarPeriodo({ inicio: '2026-11-10', fim: '2026-11-10' }, AGORA), {
      inicio: '2026-11-10',
      fim: '2026-11-10',
    });
  });

  test('recusa formato, data inexistente, ordem trocada, antes do lançamento, hoje e mais de 366 dias', () => {
    invalido(undefined, /datas inválidas/);
    invalido({ inicio: '10/11/2026', fim: '2026-11-20' }, /datas inválidas/);
    invalido({ inicio: '2026-11-31', fim: '2026-12-01' }, /datas inválidas/);
    invalido({ inicio: '2026-11-20', fim: '2026-11-10' }, /depois do fim/);
    invalido({ inicio: '2026-11-04', fim: '2026-11-20' }, /antes de 2026-11-05/);
    invalido({ inicio: '2026-11-10', fim: '2026-11-26' }, /até ontem/);
    const daquiAUmAno = new Date('2027-11-10T15:00:00Z');
    assert.equal(validarPeriodo({ inicio: '2026-11-05', fim: '2027-11-05' }, daquiAUmAno).fim, '2027-11-05'); // 366
    assert.throws(() => validarPeriodo({ inicio: '2026-11-05', fim: '2027-11-06' }, daquiAUmAno), /mais de 366 dias/);
  });

  test('ontem é no fuso de Brasília: 25/11 às 23:30 ainda não fechou o dia 25', () => {
    const noite = new Date('2026-11-26T02:30:00Z'); // 25/11 23:30 em Brasília
    assert.throws(() => validarPeriodo({ inicio: '2026-11-10', fim: '2026-11-25' }, noite), /até ontem/);
  });
});

describe('ativosPeriodoCore com o BigQuery falso', () => {
  test('uma consulta, datas em aaaammdd, devolve o período, os dias e os ativos', async () => {
    const consultas: { query: string; params: Record<string, string> }[] = [];
    const bq = {
      async query(q: { query: string; params: Record<string, string> }) {
        consultas.push(q);
        return [[{ ativosPeriodo: 1020 }]];
      },
    };
    const r = await ativosPeriodoCore(
      ativosDoBigQuery('analytics_123', bq as never),
      { inicio: '2026-11-10', fim: '2026-11-25' },
      AGORA,
    );
    assert.deepEqual(r, { inicio: '2026-11-10', fim: '2026-11-25', dias: 16, ativos: 1020 });
    assert.equal(consultas.length, 1);
    assert.deepEqual(consultas[0].params, { inicio: '20261110', fim: '20261125', ativosPeriodo: '20261110' });
    assert.match(consultas[0].query, /FROM `analytics_123\.events_\*`/);
    assert.match(consultas[0].query, /user_engagement/);
  });

  test('período inválido não chega ao BigQuery', async () => {
    let chamou = false;
    const fonte = {
      async ativosEntre() {
        chamou = true;
        return 0;
      },
    };
    await assert.rejects(ativosPeriodoCore(fonte, { inicio: '2026-11-01', fim: '2026-11-20' }, AGORA));
    assert.equal(chamou, false);
  });
});
