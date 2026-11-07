// H-R5-33 · validação do pedido de dar curso (sem Firestore).
import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { HttpsError } from 'firebase-functions/https';
import { lerPedidoDarCurso, textoDoPresente } from '../src/pessoas/acessos';

const agora = new Date('2026-11-26T18:20:00Z');

function codigo(fn: () => unknown): string {
  try {
    fn();
  } catch (e) {
    assert.ok(e instanceof HttpsError);
    return e.code;
  }
  return 'ok';
}

describe('lerPedidoDarCurso', () => {
  test('padrão: presente vitalício com push', () => {
    const p = lerPedidoDarCurso({ uid: 'rafael', curso: 'pilares', motivo: ' Sorteio da live ' }, agora);
    assert.deepEqual(p, {
      uid: 'rafael',
      curso: 'pilares',
      origem: 'presente',
      plano: 'vitalicio',
      ate: null,
      motivo: 'Sorteio da live',
      enviarPush: true,
    });
  });

  test('mensal pede data futura; vitalício não aceita data', () => {
    const p = lerPedidoDarCurso(
      { uid: 'r', curso: 'pilares', plano: 'mensal', ate: '2026-12-26T00:00:00Z', origem: 'pagoPorFora' },
      agora,
    );
    assert.equal(p.ate?.toISOString(), '2026-12-26T00:00:00.000Z');
    assert.equal(codigo(() => lerPedidoDarCurso({ uid: 'r', curso: 'pilares', plano: 'mensal' }, agora)), 'invalid-argument');
    assert.equal(
      codigo(() => lerPedidoDarCurso({ uid: 'r', curso: 'pilares', plano: 'mensal', ate: '2026-11-01' }, agora)),
      'invalid-argument',
    );
    assert.equal(
      codigo(() => lerPedidoDarCurso({ uid: 'r', curso: 'pilares', ate: '2026-12-26' }, agora)),
      'invalid-argument',
    );
  });

  test('curso inexistente = not-found; origem compra não vem do painel', () => {
    assert.equal(codigo(() => lerPedidoDarCurso({ uid: 'r', curso: 'torneio' }, agora)), 'not-found');
    assert.equal(codigo(() => lerPedidoDarCurso({ uid: 'r', curso: 'pilares', origem: 'compra' }, agora)), 'invalid-argument');
    assert.equal(codigo(() => lerPedidoDarCurso({ curso: 'pilares' }, agora)), 'invalid-argument');
  });

  test('texto do presente', () => {
    assert.equal(textoDoPresente('pilares').title, 'Você ganhou o Pilares do Xadrez');
  });
});
