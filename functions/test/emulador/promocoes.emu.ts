// H-R5-74 · criarPromocao, editarPromocao, encerrarPromocao, republicarPromocao,
// validarCupom e reservarVaga no emulador, com a Play fake.
import { afterEach, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { getFirestore } from 'firebase-admin/firestore';
import {
  criarPromocao,
  editarPromocao,
  encerrarPromocao,
  republicarPromocao,
  reservarVaga,
  usarPlay,
  validarCupom,
} from '../../src/index';
import { ErroPlay, type MotivoPlay, type OfertaPlay } from '../../src/promocoes/promocoes';
import { chamar, codigoDoErro, criarAdmin, limpar } from './apoio';

let ofertas: Map<string, OfertaPlay>;
let desativadas: string[];
let recusa: MotivoPlay | null;

beforeEach(async () => {
  await limpar();
  await criarAdmin();
  ofertas = new Map();
  desativadas = [];
  recusa = null;
  usarPlay({
    async precoCentavos() {
      return 6000;
    },
    async criarOferta(o) {
      if (recusa) throw new ErroPlay(recusa);
      ofertas.set(o.offerId, o);
    },
    async ofertaExiste(_p, id) {
      return ofertas.has(id);
    },
    async desativarOferta(_p, id) {
      if (recusa) throw new ErroPlay(recusa);
      desativadas.push(id);
    },
  });
});

afterEach(() => usarPlay(null));

const futuro = (h: number) => new Date(Date.now() + h * 3600_000).toISOString();

const todos = (nome = 'Black Friday 2026', inicioH = 24, fimH = 96, valor = 30) => ({
  tipo: 'todos',
  nome,
  desconto: { tipo: 'pct', valor },
  inicio: futuro(inicioH),
  fim: futuro(fimH),
});

const link = (extra: Record<string, unknown> = {}) => ({
  tipo: 'link',
  nome: 'Clube de Xadrez de Curitiba',
  desconto: { tipo: 'pct', valor: 20 },
  origem: 'parceiro',
  parceiro: 'Clube de Xadrez de Curitiba',
  codigo: 'CXC20',
  limite: 2,
  ...extra,
});

type Criada = { id: string; estado: string; motivo?: string; codigo?: string; link?: string; aviso?: { nome: string } };

async function detalhe(promessa: Promise<unknown>): Promise<string | undefined> {
  try {
    await promessa;
  } catch (e) {
    return (e as { details?: { codigo?: string } }).details?.codigo;
  }
  return 'ok';
}

async function promo(id: string) {
  return (await getFirestore().doc(`promocoes/${id}`).get()).data()!;
}

describe('criarPromocao', () => {
  test('só admin', async () => {
    assert.equal(await codigoDoErro(chamar(criarPromocao, 'aluno', todos())), 'permission-denied');
    assert.equal(await codigoDoErro(chamar(criarPromocao, null, todos())), 'unauthenticated');
  });

  test('Para todos: agendada, oferta black-friday-2026 com tag e datas na Play', async () => {
    const r = await chamar<Criada>(criarPromocao, 'admin', todos());
    assert.equal(r.estado, 'agendada');
    const o = ofertas.get('black-friday-2026')!;
    assert.equal(o.tag, 'lucena-todos');
    assert.equal(o.limitePorConta, 1);
    assert.ok(o.inicio && o.fim);
    const p = await promo(r.id);
    assert.equal(p.situacao, 'publicada');
    assert.deepEqual(p.funil, { cliques: 0, aberturas: 0, viramPreco: 0, compras: 0, receitaCentavos: 0 });
  });

  test('regra 5: outra Para todos no mesmo período é recusada', async () => {
    await chamar(criarPromocao, 'admin', todos());
    const outra = chamar(criarPromocao, 'admin', todos('Natal', 48, 120));
    assert.equal(await detalhe(outra), 'conflito');
    // Fora do período, pode.
    const depois = await chamar<Criada>(criarPromocao, 'admin', todos('Natal', 100, 200));
    assert.equal(depois.estado, 'agendada');
  });

  test('link: ativo, código único, oferta por nível reaproveitada, aviso de Para todos maior', async () => {
    await chamar(criarPromocao, 'admin', todos('Black Friday 2026', 2, 96));
    const r = await chamar<Criada>(criarPromocao, 'admin', link());
    assert.equal(r.estado, 'ativa');
    assert.equal(r.link, 'https://playlucena.com/oferta/CXC20?utm_source=parceiro&utm_campaign=cxc20');
    assert.equal(r.aviso?.nome, 'Black Friday 2026');
    assert.equal(ofertas.get('link-20')?.tag, 'lucena-link');
    assert.equal(ofertas.get('link-20')?.fim, null);
    assert.equal(await detalhe(chamar(criarPromocao, 'admin', link({ codigo: 'cxc20' }))), 'codigoEmUso');
    const gerado = await chamar<Criada>(criarPromocao, 'admin', link({ codigo: null, nome: 'Live' }));
    assert.match(gerado.codigo!, /^[A-HJ-NP-Z2-9]{6}$/);
  });

  test('Play recusou: Não publicada com o motivo; Tentar novamente publica', async () => {
    recusa = 'precoMinimo';
    const r = await chamar<Criada>(criarPromocao, 'admin', todos());
    assert.deepEqual([r.estado, r.motivo], ['naoPublicada', 'precoMinimo']);
    assert.equal((await promo(r.id)).situacao, 'naoPublicada');
    recusa = null;
    const de = await chamar<{ estado: string }>(republicarPromocao, 'admin', { id: r.id });
    assert.equal(de.estado, 'agendada');
    assert.equal(await detalhe(chamar(republicarPromocao, 'admin', { id: r.id })), 'jaPublicada');
  });
});

describe('editarPromocao (regra 7)', () => {
  test('só nome e limite; limite não abaixo dos usos', async () => {
    const r = await chamar<Criada>(criarPromocao, 'admin', link());
    await getFirestore().doc(`promocoes/${r.id}`).update({ usos: 1 });
    await chamar(editarPromocao, 'admin', { id: r.id, nome: 'CXC', limite: 5 });
    assert.deepEqual([(await promo(r.id)).nome, (await promo(r.id)).limite], ['CXC', 5]);
    assert.equal(await detalhe(chamar(editarPromocao, 'admin', { id: r.id, limite: 0 })), 'limiteInvalido');
    await getFirestore().doc(`promocoes/${r.id}`).update({ usos: 3 });
    assert.equal(await detalhe(chamar(editarPromocao, 'admin', { id: r.id, limite: 2 })), 'limiteAbaixoDosUsos');
    assert.equal(await detalhe(chamar(editarPromocao, 'admin', { id: r.id, desconto: { tipo: 'pct', valor: 50 } })), 'naoEditavel');
  });
});

describe('encerrarPromocao (regra 8)', () => {
  test('Para todos: desativa na Play e fica Encerrada à mão; de novo = jaEncerrada', async () => {
    const r = await chamar<Criada>(criarPromocao, 'admin', todos());
    await chamar(encerrarPromocao, 'admin', { id: r.id });
    assert.deepEqual(desativadas, ['black-friday-2026']);
    const p = await promo(r.id);
    assert.deepEqual([p.situacao, p.encerradaPor, p.encerradaPorUid], ['encerrada', 'mao', 'admin']);
    assert.equal(await detalhe(chamar(encerrarPromocao, 'admin', { id: r.id })), 'jaEncerrada');
  });

  test('Play falhou no Para todos: nada muda', async () => {
    const r = await chamar<Criada>(criarPromocao, 'admin', todos());
    recusa = 'permissao';
    assert.equal(await detalhe(chamar(encerrarPromocao, 'admin', { id: r.id })), 'play');
    assert.equal((await promo(r.id)).situacao, 'publicada');
  });

  test('link: a oferta por nível só sai quando nenhum link ativo a usa', async () => {
    const a = await chamar<Criada>(criarPromocao, 'admin', link());
    const b = await chamar<Criada>(criarPromocao, 'admin', link({ codigo: 'LIVE20', nome: 'Live' }));
    await chamar(encerrarPromocao, 'admin', { id: a.id });
    assert.deepEqual(desativadas, []);
    await chamar(encerrarPromocao, 'admin', { id: b.id });
    assert.deepEqual(desativadas, ['link-20']);
  });
});

describe('validarCupom e reservarVaga (R23, R24)', () => {
  test('pede conta; código desconhecido = naoExiste', async () => {
    assert.equal(await codigoDoErro(chamar(validarCupom, null, { codigo: 'CXC20' })), 'unauthenticated');
    assert.deepEqual(await chamar(validarCupom, 'aluno', { codigo: 'NADA' }), { valido: false, motivo: 'naoExiste' });
  });

  test('vale com a oferta link-20; encerrado à mão = encerrado', async () => {
    const r = await chamar<Criada>(criarPromocao, 'admin', link());
    const v = await chamar<{ valido: boolean; offerId: string }>(validarCupom, 'aluno', { codigo: 'cxc20' });
    assert.deepEqual([v.valido, v.offerId], [true, 'link-20']);
    await chamar(encerrarPromocao, 'admin', { id: r.id });
    assert.deepEqual(await chamar(validarCupom, 'aluno', { codigo: 'CXC20' }), { valido: false, motivo: 'encerrado' });
  });

  test('limite 2: duas reservas de outras contas esgotam a vaga; a mesma conta renova', async () => {
    await chamar(criarPromocao, 'admin', link());
    await chamar(reservarVaga, 'ana', { codigo: 'CXC20' });
    await chamar(reservarVaga, 'ana', { codigo: 'CXC20' });
    await chamar(reservarVaga, 'beto', { codigo: 'CXC20' });
    assert.equal(await detalhe(chamar(reservarVaga, 'caio', { codigo: 'CXC20' })), 'esgotado');
    assert.deepEqual(await chamar(validarCupom, 'caio', { codigo: 'CXC20' }), { valido: false, motivo: 'esgotado' });
    const ana = await chamar<{ valido: boolean }>(validarCupom, 'ana', { codigo: 'CXC20' });
    assert.equal(ana.valido, true);
  });

  test('Não publicada não vale como cupom', async () => {
    recusa = 'outro';
    await chamar(criarPromocao, 'admin', link());
    assert.deepEqual(await chamar(validarCupom, 'aluno', { codigo: 'CXC20' }), { valido: false, motivo: 'naoExiste' });
  });
});
