// T87 · Análise com o Stockfish de verdade (poucos nós, para o teste ser rápido) nas partidas do fixture.
import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { Chess } from 'chess.js';
import { analisarPartida, CONFIG_PADRAO, estrelas } from '../../src/treinador/analise';
import { partidaDoLichess } from '../../src/treinador/fontes';
import { abrirMotor, type Motor } from '../../src/treinador/motor';
import type { PartidaBruta } from '../../src/treinador/tipos';

const FIXTURES = path.resolve(__dirname, '..', '..', '..', 'test', 'fixtures');

function partidasLichess(): PartidaBruta[] {
  const linhas = fs.readFileSync(path.join(FIXTURES, 'lichess-drnykterstein.ndjson'), 'utf8').split('\n');
  return linhas
    .filter((l) => l.trim())
    .map((l) => partidaDoLichess(JSON.parse(l), 'DrNykterstein'))
    .filter((p): p is PartidaBruta => !!p);
}

const CFG = { ...CONFIG_PADRAO, nosUsuario: 60_000, nosDemais: 20_000 };

describe('analisarPartida', () => {
  let motor: Motor;
  before(async () => {
    motor = await abrirMotor();
  });
  after(async () => {
    await motor.fechar();
  });

  it('analisa a partida inteira no formato do contrato', async () => {
    const [p] = partidasLichess();
    const r = await analisarPartida(p, motor, CFG, null);
    const c = new Chess();
    c.loadPgn(p.pgn);
    assert.equal(r.lances.length, c.history().length);
    assert.ok(r.precisao >= 0 && r.precisao <= 100);
    assert.ok(r.resumo.startsWith('Precisão de '));
    assert.ok(r.exercicios.length >= 1 && r.exercicios.length <= CFG.exercicios);
    for (const e of r.exercicios) {
      const pos = new Chess(e.fen);
      // A solução é legal na posição do exercício.
      assert.doesNotThrow(() => pos.move({ from: e.solucao.slice(0, 2), to: e.solucao.slice(2, 4), promotion: e.solucao[4] }));
      assert.ok(e.estrelas >= 1 && e.estrelas <= 3);
      assert.ok(e.falas.enunciado && e.falas.acerto && e.falas.erro && e.falas.solucao);
      // O "erro" nunca entrega a solução.
      assert.ok(!e.falas.erro.includes(e.solucao.slice(2, 4)), e.falas.erro);
    }
    // Números do exercício em ordem da partida.
    const ordem = r.exercicios.map((e) => e.lance);
    assert.deepEqual(ordem, [...ordem].sort((a, b) => a - b));
    assert.equal(r.teoria, null);
    assert.equal(r.motor.versao, 'Stockfish 19 lite');
    assert.ok(r.segundosMotor > 0);
  });

  it('a posição final de mate sai com mate 0', async () => {
    const p: PartidaBruta = {
      ...partidasLichess()[0],
      pgn: '1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7# 1-0',
      cor: 'brancas',
    };
    const r = await analisarPartida(p, motor, { ...CFG, exercicios: 2 }, null);
    const ultimo = r.lances[r.lances.length - 1];
    assert.equal(ultimo.mate, 0);
    assert.equal(ultimo.cp, null);
    // 3...Nf6?? é erro grave do adversário.
    assert.equal(r.lances[5].classe, 'grave');
  });
});

describe('estrelas', () => {
  it('mate curto é 1 estrela e lance quieto é 3', () => {
    const fen = 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4';
    assert.equal(estrelas(fen, { uci: 'h5f7', cp: null, mate: 1, pv: ['h5f7'] }, { tema: 'mate' }), 1);
    assert.equal(estrelas(fen, { uci: 'd2d3', cp: 30, mate: null, pv: ['d2d3'] }, { tema: null }), 3);
  });
});
