// H-R5-34 · fechamentoDia e painel/hoje no emulador, com o export do Analytics em fixture.
import { beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import '../../src/index';
import { atualizarHoje, fecharDia, type Analytics } from '../../src/fechamento/fechar';
import type { LinhaEvento } from '../../src/fechamento/consultas';
import { EXPORT_25_11 } from '../fixtures/export';
import { limpar } from './apoio';

let exportPronto = true;
let intraday: LinhaEvento[] | null = EXPORT_25_11;
let consultas = 0;

const analytics: Analytics = {
  async exportPronto() {
    return exportPronto;
  },
  async linhasDoDia() {
    consultas++;
    return EXPORT_25_11;
  },
  async linhasDeHoje() {
    return intraday;
  },
  async ativos(_dia, janelas) {
    return Object.fromEntries(Object.keys(janelas).map((k) => [k, 100]));
  },
};

const db = () => getFirestore();
const em = (iso: string) => ({ db: db(), analytics, agora: new Date(iso) });
const ler = async (caminho: string) => (await db().doc(caminho).get()).data();

beforeEach(async () => {
  await limpar();
  exportPronto = true;
  intraday = EXPORT_25_11;
  consultas = 0;
});

async function acesso(uid: string, dadoEm: string, extra: Record<string, unknown>): Promise<void> {
  await db()
    .doc(`acessos/${uid}`)
    .set({ cursos: { pilares: { dadoEm: Timestamp.fromDate(new Date(dadoEm)), pais: 'BR', ...extra } } });
}

describe('fechamentoDia', () => {
  test('03:00 com export: grava dia, mês, relatório e carimbo; rodar de novo não muda nada', async () => {
    await acesso('a', '2026-11-25T15:00:00Z', { origem: 'compra', plano: 'vitalicio', receitaCentavos: 6000 });
    await acesso('b', '2026-11-25T16:00:00Z', { origem: 'presente', plano: 'vitalicio' });
    await acesso('c', '2026-11-25T17:00:00Z', { origem: 'presente', plano: 'vitalicio', revogadoEm: Timestamp.now() });
    await acesso('d', '2026-11-26T03:30:00Z', { origem: 'compra', plano: 'mensal' }); // já é dia 26 em Brasília

    assert.deepEqual(await fecharDia(em('2026-11-26T06:00:00Z')), { dia: '2026-11-25', estado: 'ok' });
    const dia = (await ler('resumosDia/2026-11-25'))!;
    assert.deepEqual(dia.cursos.pilares.compras, { vitalicio: 1, presente: 1 });
    assert.equal(dia.cursos.pilares.receitaCentavos, 6000);
    assert.deepEqual(dia.ativos, { ativos7: 100, ativos15: 100, ativos30: 100, ativos45: 100 });
    assert.equal(dia.fontes.analytics, 'ok');
    assert.deepEqual((await ler('resumosMes/2026-11'))!.dias, ['2026-11-25']);
    const rel = (await ler('relatorios/2026-11-25'))!;
    assert.equal(rel.acum, undefined);
    assert.equal(rel.cortado, false);
    assert.equal((await ler('painel/fechamento'))!.estado, 'ok');

    const antes = { dia, mes: await ler('resumosMes/2026-11') };
    assert.equal((await fecharDia(em('2026-11-26T07:00:00Z'))).estado, 'jaFechado');
    assert.deepEqual({ dia: await ler('resumosDia/2026-11-25'), mes: await ler('resumosMes/2026-11') }, antes);
    assert.equal(consultas, 1);
  });

  test('sem export: atrasado até 14:00, depois fecha com Analytics incompleto', async () => {
    exportPronto = false;
    assert.equal((await fecharDia(em('2026-11-26T06:00:00Z'))).estado, 'atrasado');
    assert.equal(await ler('resumosDia/2026-11-25'), undefined);
    const carimbo = (await ler('painel/fechamento'))!;
    assert.equal(carimbo.estado, 'atrasado');
    assert.equal(carimbo.proximaTentativa.toDate().toISOString(), '2026-11-26T07:00:00.000Z');

    assert.equal((await fecharDia(em('2026-11-26T17:00:00Z'))).estado, 'incompleto');
    const dia = (await ler('resumosDia/2026-11-25'))!;
    assert.equal(dia.fontes.analytics, 'incompleto');
    assert.deepEqual(dia.aulas, {});
    assert.equal((await ler('resumosMes/2026-11'))!.fontes.analytics, 'incompleto');
  });

  test('acum continua do último dia fechado; fim do mês grava os ativos do mês', async () => {
    await fecharDia(em('2026-11-29T06:00:00Z'));
    await fecharDia(em('2026-12-01T06:00:00Z'));
    const d30 = (await ler('resumosDia/2026-11-30'))!;
    assert.equal(d30.acum.cursos.pilares.inscritos, 14);
    assert.equal(d30.ativos.ativos3m, undefined);
    const mes = (await ler('resumosMes/2026-11'))!;
    assert.deepEqual(mes.dias, ['2026-11-28', '2026-11-30']);
    assert.deepEqual(mes.ativos, { ativosMes: 100, ativos3m: 100, ativos6m: 100, ativos12m: 100 });
    assert.equal(mes.cursos.pilares.inscritos, 14);
  });
});

describe('painel/hoje', () => {
  test('lote de hora em hora grava só painel/hoje; sem intraday fica atrasado', async () => {
    await acesso('a', '2026-11-26T15:00:00Z', { origem: 'compra', plano: 'vitalicio', receitaCentavos: 6000 });
    assert.deepEqual(await atualizarHoje(em('2026-11-26T18:20:00Z')), { dia: '2026-11-26', analytics: 'ok' });
    const hoje = (await ler('painel/hoje'))!;
    assert.equal(hoje.cursos.pilares.compras.vitalicio, 1);
    assert.equal(hoje.cursos.pilares.inscritos, 7);
    assert.equal(await ler('resumosDia/2026-11-26'), undefined);

    intraday = null;
    await atualizarHoje(em('2026-11-26T19:20:00Z'));
    assert.equal((await ler('painel/hoje'))!.fontes.analytics, 'atrasado');
  });
});
