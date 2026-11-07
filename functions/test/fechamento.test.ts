// H-R5-34 · do export (fixture) ao resumo do dia, do mês e ao relatório, sem Firestore.
import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { sqlAtivos, sqlDoDia } from '../src/fechamento/consultas';
import { diaLocal, horaLocal, inicioDoDia, somarDias, ultimoDoMes } from '../src/fechamento/datas';
import {
  contar,
  LIMITE_RELATORIO,
  montarRelatorio,
  montarResumoDia,
  somarNoMes,
  type Arvore,
  type Compra,
} from '../src/fechamento/resumo';
import { EXPORT_25_11 } from './fixtures/export';

const compras: Compra[] = [
  { curso: 'pilares', origem: 'compra', plano: 'vitalicio', pais: 'BR', receitaCentavos: 6000 },
  { curso: 'pilares', origem: 'compra', plano: 'mensal', pais: 'PT', receitaCentavos: 990 },
  { curso: 'pilares', origem: 'presente', plano: 'vitalicio', pais: 'BR', receitaCentavos: 0 },
];
const fechadoEm = new Date('2026-11-26T06:12:00Z');

describe('datas em Brasília', () => {
  test('dia, hora, meia-noite e fim do mês', () => {
    assert.equal(diaLocal(new Date('2026-11-26T02:30:00Z')), '2026-11-25');
    assert.equal(horaLocal(new Date('2026-11-26T17:00:00Z')), 14);
    assert.equal(inicioDoDia('2026-11-25').toISOString(), '2026-11-25T03:00:00.000Z');
    assert.equal(somarDias('2026-12-31', 1), '2027-01-01');
    assert.equal(ultimoDoMes('2026-11-30'), true);
    assert.equal(ultimoDoMes('2026-11-29'), false);
  });
});

describe('consultas', () => {
  test('tabela e janelas não aceitam injeção', () => {
    assert.throws(() => sqlDoDia('ds.events_1`; DROP'));
    assert.throws(() => sqlAtivos('ds', { 'ativos7; x': 7 }));
    assert.match(sqlDoDia('analytics_1.events_20261125'), /FROM `analytics_1\.events_20261125`/);
    assert.match(sqlAtivos('analytics_1', { ativos7: 7 }), /AS ativos7/);
  });
});

describe('contar', () => {
  const c = contar(EXPORT_25_11, compras);

  test('cursos: inscritos, ativos, metas, página, demo, compras por país', () => {
    const p = c.cursos.pilares as Arvore;
    assert.equal(p.inscritos, 7);
    assert.equal(p.ativos, 42);
    assert.deepEqual(p.metas, { marcadas: 90, cumpridas: 70 });
    assert.equal(p.pagina, 25);
    assert.equal(p.demo, 9);
    assert.deepEqual(p.compras, { vitalicio: 1, mensal: 1, presente: 1 });
    assert.equal(p.receitaCentavos, 6990);
    assert.deepEqual((p.paises as Arvore).BR, { inscritos: 6, pagina: 25, demo: 9, compras: 2, receitaCentavos: 6000 });
    assert.deepEqual((p.paises as Arvore).PT, { inscritos: 1, compras: 1, receitaCentavos: 990 });
  });

  test('aulas, redes e países; ponto do id vira _', () => {
    const o = c.aulas.oposicao as Arvore;
    assert.equal(o.abriram, 50);
    assert.equal(o.concluiram, 12);
    assert.deepEqual(o.capitulos, { c1: { iniciaram: 30, concluiram: 20 } });
    assert.deepEqual(o.erros, { ex1_Kd7: 14 });
    assert.deepEqual(o.saida, { ex2: 4, c2: 2 });
    assert.deepEqual(c.redes, { instagram: { BR: { abriram: 18, instalaram: 7 } }, youtube: { PT: { abriram: 3 } } });
    assert.deepEqual(c.paises, { BR: { ativos: 120 }, PT: { ativos: 8 } });
  });
});

describe('resumo do dia e do mês', () => {
  const dia24 = montarResumoDia({
    dia: '2026-11-24',
    contadores: contar(EXPORT_25_11, []),
    ativos: { ativos7: 300 },
    acumAnterior: null,
    analytics: 'ok',
    fechadoEm,
  });
  const dia25 = montarResumoDia({
    dia: '2026-11-25',
    contadores: contar(EXPORT_25_11, compras),
    ativos: { ativos7: 310 },
    acumAnterior: dia24.acum,
    analytics: 'incompleto',
    fechadoEm,
  });

  test('acum soma o dia anterior, sem ativos, erros, saídas nem capítulos', () => {
    const p = (dia25.acum.cursos as Arvore).pilares as Arvore;
    assert.equal(p.inscritos, 14);
    assert.equal(p.ativos, undefined);
    assert.deepEqual(p.compras, { vitalicio: 1, mensal: 1, presente: 1 });
    assert.deepEqual((dia25.acum.aulas as Arvore).oposicao, { abriram: 100, concluiram: 24 });
    assert.equal(((dia25.acum.paises as Arvore).BR as Arvore).ativos, undefined);
    assert.deepEqual(dia25.fontes, { analytics: 'incompleto', play: 'ok' });
    assert.deepEqual(dia25.pontosAtencao, []);
  });

  test('mês soma os dias uma vez só; incompleto contamina o mês', () => {
    const m1 = somarNoMes(null, dia24, {});
    const m2 = somarNoMes(m1, dia25, { ativosMes: 900 });
    assert.deepEqual(somarNoMes(m2, dia25, {}), m2);
    assert.deepEqual(m2.dias, ['2026-11-24', '2026-11-25']);
    assert.equal(((m2.cursos.pilares as Arvore).metas as Arvore).marcadas, 180);
    assert.equal((m2.aulas.oposicao as Arvore).erros, undefined);
    assert.equal(m2.fontes.analytics, 'incompleto');
    assert.deepEqual(m2.ativos, { ativosMes: 900 });
    assert.deepEqual(m2.acum, dia25.acum);
  });

  test('relatório sem controle e ≤ 50 KB mesmo com muitas aulas', () => {
    const { relatorio, cortado } = montarRelatorio(dia25);
    assert.equal(cortado, false);
    assert.equal(relatorio.acum, undefined);
    assert.equal(relatorio.fechadoEm, undefined);

    const muitas = structuredClone(dia25);
    for (let a = 0; a < 150; a++) {
      const erros: Arvore = {};
      const capitulos: Arvore = {};
      for (let e = 0; e < 40; e++) erros[`exercicio_${e}_da_aula_${a}`] = e;
      for (let k = 0; k < 12; k++) capitulos[`capitulo_${k}`] = { iniciaram: k, concluiram: k };
      muitas.aulas[`aula_numero_${a}`] = { abriram: a, erros, saida: { ...erros }, capitulos };
    }
    const grande = montarRelatorio(muitas);
    assert.equal(grande.cortado, true);
    assert.ok(Buffer.byteLength(JSON.stringify(grande.relatorio)) <= LIMITE_RELATORIO);
  });
});
