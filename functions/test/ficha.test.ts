// H-R5-32 · as partes puras da Ficha.
import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { Timestamp } from 'firebase-admin/firestore';
import { acessosDaFicha, permissaoDoAparelho, situacaoDaConta } from '../src/pessoas/ficha';

const agora = new Date('2026-11-26T18:20:00Z');

describe('situacaoDaConta', () => {
  test('Auth desativado = encerrada, mesmo com bloqueio', () => {
    assert.equal(situacaoDaConta(true, { ate: null }, agora), 'encerrada');
  });
  test('bloqueio sem fim ou com fim no futuro = suspensa', () => {
    assert.equal(situacaoDaConta(false, { motivo: 'spam' }, agora), 'suspensa');
    assert.equal(situacaoDaConta(false, { ate: Timestamp.fromDate(new Date('2026-12-26')) }, agora), 'suspensa');
  });
  test('bloqueio vencido ou ausente = ativa', () => {
    assert.equal(situacaoDaConta(false, { ate: Timestamp.fromDate(new Date('2026-11-01')) }, agora), 'ativa');
    assert.equal(situacaoDaConta(false, undefined, agora), 'ativa');
  });
});

describe('permissaoDoAparelho', () => {
  test('sem documento ou valor estranho = nunca', () => {
    assert.equal(permissaoDoAparelho(undefined), 'nunca');
    assert.equal(permissaoDoAparelho({ permissao: 'talvez' }), 'nunca');
    assert.equal(permissaoDoAparelho({ permissao: 'negada' }), 'negada');
  });
});

describe('acessosDaFicha', () => {
  test('um item por curso, em ordem, com o visto do curso', () => {
    const lista = acessosDaFicha({
      cursos: { torneio: { origem: 'compra' }, pilares: { origem: 'presente', plano: 'mensal' } },
      vistos: { pilares: Timestamp.fromDate(new Date('2026-11-26T18:24:00Z')) },
    });
    assert.deepEqual(
      lista.map((a) => [a.curso, a.origem, a.vistoEm]),
      [
        ['pilares', 'presente', '2026-11-26T18:24:00.000Z'],
        ['torneio', 'compra', null],
      ],
    );
  });
  test('sem documento = lista vazia', () => {
    assert.deepEqual(acessosDaFicha(undefined), []);
  });
});
