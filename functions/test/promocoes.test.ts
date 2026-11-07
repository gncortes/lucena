// H-R5-74 · regras 2 a 9 das promoções (sem Firestore nem Play).
import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { HttpsError } from 'firebase-functions/https';
import {
  ALFABETO_CODIGO,
  centavosDeDesconto,
  cruzam,
  estadoDe,
  gerarCodigo,
  idDaOferta,
  lerLimite,
  lerPedidoPromocao,
  linkDoCupom,
  normalizarCodigo,
  vence,
  type Desconto,
} from '../src/promocoes/regras';

const agora = new Date('2026-11-07T15:00:00Z');
const PRECO = 6000;

function erro(fn: () => unknown): string {
  try {
    fn();
  } catch (e) {
    assert.ok(e instanceof HttpsError);
    const det = e.details as { codigo?: string } | undefined;
    return det?.codigo ?? e.code;
  }
  return 'ok';
}

const blackFriday = {
  tipo: 'todos',
  nome: ' Black Friday 2026 ',
  desconto: { tipo: 'pct', valor: 30 },
  inicio: '2026-11-27T03:00:00Z',
  fim: '2026-12-01T02:59:00Z',
};

const cxc = {
  tipo: 'link',
  nome: 'Clube de Xadrez de Curitiba',
  desconto: { tipo: 'pct', valor: 20 },
  origem: 'parceiro',
  parceiro: 'Clube de Xadrez de Curitiba',
  codigo: 'cxc20',
  fim: '2027-01-01T02:59:00Z',
  limite: 100,
};

describe('regra 2 · desconto', () => {
  test('% de 5 a 90, inteiro', () => {
    const pct = (valor: number) => ({ ...blackFriday, desconto: { tipo: 'pct', valor } });
    assert.equal(erro(() => lerPedidoPromocao(pct(5), PRECO, agora)), 'ok');
    assert.equal(erro(() => lerPedidoPromocao(pct(90), PRECO, agora)), 'ok');
    assert.equal(erro(() => lerPedidoPromocao(pct(4), PRECO, agora)), 'descontoForaDaFaixa');
    assert.equal(erro(() => lerPedidoPromocao(pct(91), PRECO, agora)), 'descontoForaDaFaixa');
    assert.equal(erro(() => lerPedidoPromocao(pct(12.5), PRECO, agora)), 'descontoForaDaFaixa');
  });

  test('valor em reais menor que o preço', () => {
    const brl = (centavos: number) => ({ ...blackFriday, desconto: { tipo: 'brl', centavos } });
    assert.equal(erro(() => lerPedidoPromocao(brl(1000), PRECO, agora)), 'ok');
    assert.equal(erro(() => lerPedidoPromocao(brl(6000), PRECO, agora)), 'descontoForaDaFaixa');
    assert.equal(erro(() => lerPedidoPromocao(brl(0), PRECO, agora)), 'descontoForaDaFaixa');
    assert.equal(erro(() => lerPedidoPromocao({ ...blackFriday, desconto: { tipo: 'x' } }, PRECO, agora)), 'invalid-argument');
  });
});

describe('regra 3 · datas', () => {
  test('Para todos: começa daqui a 1 h ou mais', () => {
    const em = (inicio: string) => ({ ...blackFriday, inicio, fim: '2026-11-08T18:00:00Z' });
    assert.equal(erro(() => lerPedidoPromocao(em('2026-11-07T16:00:00Z'), PRECO, agora)), 'ok');
    assert.equal(erro(() => lerPedidoPromocao(em('2026-11-07T15:59:00Z'), PRECO, agora)), 'inicioCedo');
  });

  test('Para todos: fim depois do começo e no máximo 31 dias', () => {
    const fim = (f: string) => ({ ...blackFriday, fim: f });
    assert.equal(erro(() => lerPedidoPromocao(fim('2026-11-27T03:00:00Z'), PRECO, agora)), 'fimAntesDoInicio');
    assert.equal(erro(() => lerPedidoPromocao(fim('2026-12-28T03:00:00Z'), PRECO, agora)), 'ok');
    assert.equal(erro(() => lerPedidoPromocao(fim('2026-12-28T03:01:00Z'), PRECO, agora)), 'duracaoLonga');
    assert.equal(erro(() => lerPedidoPromocao({ ...blackFriday, fim: undefined }, PRECO, agora)), 'invalid-argument');
  });

  test('link: começa agora por padrão e o fim é opcional', () => {
    const p = lerPedidoPromocao({ ...cxc, fim: null }, PRECO, agora);
    assert.equal(p.inicio.toISOString(), agora.toISOString());
    assert.equal(p.fim, null);
    assert.equal(erro(() => lerPedidoPromocao({ ...cxc, fim: '2026-11-01T00:00:00Z' }, PRECO, agora)), 'fimAntesDoInicio');
  });

  test('pedido lido: nome sem espaços e datas em UTC', () => {
    const p = lerPedidoPromocao(blackFriday, PRECO, agora);
    assert.equal(p.nome, 'Black Friday 2026');
    assert.equal(p.fim?.toISOString(), '2026-12-01T02:59:00.000Z');
  });
});

describe('regra 4 · limite de usos', () => {
  test('só no link, inteiro a partir de 1, nunca abaixo dos usos', () => {
    assert.equal(lerPedidoPromocao(cxc, PRECO, agora).limite, 100);
    assert.equal(lerPedidoPromocao({ ...cxc, limite: null }, PRECO, agora).limite, null);
    assert.equal(erro(() => lerPedidoPromocao({ ...cxc, limite: 0 }, PRECO, agora)), 'limiteInvalido');
    assert.equal(erro(() => lerPedidoPromocao({ ...blackFriday, limite: 10 }, PRECO, agora)), 'invalid-argument');
  });
});

describe('regra 5 · duas valendo ao mesmo tempo', () => {
  const d = (s: string) => new Date(s);
  test('períodos que se cruzam (fim null = sem fim)', () => {
    const bf = { inicio: d('2026-11-27T03:00:00Z'), fim: d('2026-12-01T02:59:00Z') };
    assert.ok(cruzam(bf, { inicio: d('2026-11-30T00:00:00Z'), fim: d('2026-12-05T00:00:00Z') }));
    assert.ok(cruzam(bf, { inicio: agora, fim: null }));
    assert.ok(!cruzam(bf, { inicio: d('2026-12-01T02:59:00Z'), fim: null }));
    assert.ok(!cruzam(bf, { inicio: d('2026-11-05T03:00:00Z'), fim: d('2026-11-12T02:59:00Z') }));
  });

  test('vence o maior desconto; empate, a que termina primeiro', () => {
    type P = { nome: string; desconto: Desconto; fim: Date | null };
    const bf: P = { nome: 'bf', desconto: { tipo: 'pct', valor: 30 }, fim: d('2026-12-01T02:59:00Z') };
    const link: P = { nome: 'cxc', desconto: { tipo: 'pct', valor: 20 }, fim: null };
    const reais: P = { nome: 'r18', desconto: { tipo: 'brl', centavos: 1800 }, fim: d('2026-11-28T00:00:00Z') };
    assert.equal(vence(bf, link, PRECO).nome, 'bf');
    assert.equal(centavosDeDesconto(bf.desconto, PRECO), 1800);
    assert.equal(vence(bf, reais, PRECO).nome, 'r18');
    assert.equal(vence(reais, bf, PRECO).nome, 'r18');
  });
});

describe('regra 6 · código e link', () => {
  test('gerado: 6 caracteres sem 0/O/1/I', () => {
    assert.ok(!/[0O1I]/.test(ALFABETO_CODIGO));
    let i = 0;
    const c = gerarCodigo(() => (i++ % 10) / 10);
    assert.match(c, /^[A-HJ-NP-Z2-9]{6}$/);
    assert.equal(gerarCodigo(() => 0.999999), '999999');
  });

  test('editável: 4 a 20 maiúsculas e números', () => {
    assert.equal(normalizarCodigo(' cxc20 '), 'CXC20');
    assert.equal(erro(() => normalizarCodigo('CX2')), 'codigoInvalido');
    assert.equal(erro(() => normalizarCodigo('A'.repeat(21))), 'codigoInvalido');
    assert.equal(erro(() => normalizarCodigo('CXC-20')), 'codigoInvalido');
    assert.equal(lerPedidoPromocao(cxc, PRECO, agora).codigo, 'CXC20');
  });

  test('origem obrigatória; parceiro pede o nome', () => {
    assert.equal(erro(() => lerPedidoPromocao({ ...cxc, origem: 'tiktok' }, PRECO, agora)), 'invalid-argument');
    assert.equal(erro(() => lerPedidoPromocao({ ...cxc, parceiro: ' ' }, PRECO, agora)), 'parceiroFaltando');
    assert.equal(lerPedidoPromocao({ ...cxc, origem: 'instagram', parceiro: 'x' }, PRECO, agora).parceiro, null);
  });

  test('link do cupom', () => {
    assert.equal(
      linkDoCupom('CXC20', 'parceiro'),
      'https://playlucena.com/oferta/CXC20?utm_source=parceiro&utm_campaign=cxc20',
    );
  });

  test('id da oferta na Play: slug + ano; link por nível', () => {
    const p = lerPedidoPromocao(blackFriday, PRECO, agora);
    assert.equal(idDaOferta(p), 'black-friday-2026');
    assert.equal(idDaOferta({ ...p, nome: 'Lançamento' }), 'lancamento-2026');
    assert.equal(idDaOferta({ ...p, tipo: 'link' }), 'link-30');
    assert.equal(idDaOferta({ ...p, tipo: 'link', desconto: { tipo: 'brl', centavos: 1000 } }), 'link-brl-1000');
  });
});

describe('regra 7 · editar o limite', () => {
  test('não abaixo dos usos feitos', () => {
    assert.equal(lerLimite(12, 12), 12);
    assert.equal(lerLimite(null, 12), null);
    assert.equal(erro(() => lerLimite(11, 12)), 'limiteAbaixoDosUsos');
  });
});

describe('regras 8 e 9 · estados', () => {
  const base = {
    situacao: 'publicada' as const,
    inicio: new Date('2026-11-27T03:00:00Z'),
    fim: new Date('2026-12-01T02:59:00Z') as Date | null,
    limite: null as number | null,
    usos: 0,
  };
  test('Agendada, Ativa e Encerrada por data', () => {
    assert.deepEqual(estadoDe(base, agora), { estado: 'agendada' });
    assert.deepEqual(estadoDe(base, new Date('2026-11-28T00:00:00Z')), { estado: 'ativa' });
    assert.deepEqual(estadoDe(base, new Date('2026-12-01T02:59:00Z')), { estado: 'encerrada', por: 'data' });
  });

  test('Encerrada por limite e à mão; Não publicada com o motivo', () => {
    const link = { ...base, inicio: agora, fim: null, limite: 100 };
    assert.deepEqual(estadoDe({ ...link, usos: 12 }, agora), { estado: 'ativa' });
    assert.deepEqual(estadoDe({ ...link, usos: 100 }, agora), { estado: 'encerrada', por: 'limite' });
    assert.deepEqual(estadoDe({ ...link, situacao: 'encerrada', encerradaPor: 'mao' }, agora), {
      estado: 'encerrada',
      por: 'mao',
    });
    assert.deepEqual(estadoDe({ ...link, situacao: 'naoPublicada', motivoPlay: 'precoMinimo' }, agora), {
      estado: 'naoPublicada',
      motivo: 'precoMinimo',
    });
  });
});
