// H-R5-3A · Play simulada (dev e emulador) e a escolha por ambiente.
import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { ErroPlayCompra, playComprasSimulada, playSimuladaNoAmbiente } from '../src/compras/play';

const PRODUTO = 'pilares_vitalicio';

describe('Play simulada', () => {
  test('compra com oferta: productsv2 com offerId, conta e região', async () => {
    const play = playComprasSimulada(PRODUTO);
    const c = await play.consultar('teste:compra:bf30:rafael');
    assert.equal(c.estado, 'PURCHASED');
    assert.deepEqual(c.linhas, [{ productId: PRODUTO, offerId: 'bf30', offerTags: ['promocao'] }]);
    assert.equal(c.conta, 'rafael');
    assert.equal(c.regiao, 'BR');
    assert.equal(c.teste, true);
    assert.match(c.orderId, /^GPA\.TESTE-[0-9A-F]{16}$/);
  });

  test('preço cheio (-) e sem uid: sem offerId e sem conta', async () => {
    const c = await playComprasSimulada(PRODUTO).consultar('teste:compra:-');
    assert.equal(c.linhas[0].offerId, null);
    assert.equal(c.conta, null);
  });

  test('mesmo token, mesmo orderId; acknowledge fica guardado', async () => {
    const play = playComprasSimulada(PRODUTO);
    const a = await play.consultar('teste:compra');
    assert.equal(a.reconhecida, false);
    await play.reconhecer(PRODUTO, 'teste:compra');
    const b = await play.consultar('teste:compra');
    assert.equal(b.orderId, a.orderId);
    assert.equal(b.reconhecida, true);
    assert.notEqual((await play.consultar('teste:compra:x')).orderId, a.orderId);
  });

  test('pendente e cancelada', async () => {
    const play = playComprasSimulada(PRODUTO);
    assert.equal((await play.consultar('teste:pendente')).estado, 'PENDING');
    assert.equal((await play.consultar('teste:cancelada')).estado, 'CANCELLED');
  });

  test('token fora do teste ou estado desconhecido: tokenInvalido', async () => {
    const play = playComprasSimulada(PRODUTO);
    for (const t of ['abc', 'teste:devolvida']) {
      await assert.rejects(play.consultar(t), (e) => e instanceof ErroPlayCompra && e.motivo === 'tokenInvalido');
    }
  });
});

describe('Play por ambiente', () => {
  test('emulador e lucena-dev-gnc simulam; produção não', () => {
    assert.equal(playSimuladaNoAmbiente({ FUNCTIONS_EMULATOR: 'true' }), true);
    assert.equal(playSimuladaNoAmbiente({ GCLOUD_PROJECT: 'lucena-dev-gnc' }), true);
    assert.equal(playSimuladaNoAmbiente({ GCLOUD_PROJECT: 'lucena-2f4de' }), false);
    assert.equal(playSimuladaNoAmbiente({}), false);
  });
});
