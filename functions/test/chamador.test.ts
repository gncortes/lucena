// AG-5b.3 · Reconferência do chamador do porteiro (sem rede: verificador falso).
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { ChamadorRecusado, conferirChamador, emailDoPorteiro, type DadosDoToken } from '../src/agentes/chamador';

const PORTEIRO = emailDoPorteiro('lucena-dev-gnc');
const AUD = 'https://importarlote-abc123-rj.a.run.app';
const com = (d: DadosDoToken) => async () => d;
const recusa = (p: Promise<void>) => assert.rejects(p, ChamadorRecusado);

describe('conferirChamador', () => {
  it('aceita a conta porteiro-agentes com aud do importarLote (Cloud Run ou cloudfunctions.net)', async () => {
    await conferirChamador('Bearer x', com({ email: PORTEIRO, email_verified: true, aud: AUD }), PORTEIRO);
    await conferirChamador(
      'Bearer x',
      com({ email: PORTEIRO, email_verified: true, aud: 'https://southamerica-east1-lucena-dev-gnc.cloudfunctions.net/importarLote' }),
      PORTEIRO,
    );
  });

  it('sem cabeçalho, sem Bearer ou token que não confere: recusa', async () => {
    await recusa(conferirChamador(undefined, com({}), PORTEIRO));
    await recusa(conferirChamador('Basic abc', com({}), PORTEIRO));
    await recusa(
      conferirChamador('Bearer x', async () => {
        throw new Error('assinatura');
      }, PORTEIRO),
    );
  });

  it('outra conta, e-mail não verificado ou aud de outro serviço: recusa', async () => {
    await recusa(conferirChamador('Bearer x', com({ email: 'alguem@gmail.com', email_verified: true, aud: AUD }), PORTEIRO));
    await recusa(conferirChamador('Bearer x', com({ email: PORTEIRO, email_verified: false, aud: AUD }), PORTEIRO));
    await recusa(conferirChamador('Bearer x', com({ email: PORTEIRO, email_verified: true, aud: 'https://outra-abc-rj.a.run.app' }), PORTEIRO));
    await recusa(conferirChamador('Bearer x', com({ email: PORTEIRO, email_verified: true, aud: 'http://importarlote-x.run.app' }), PORTEIRO));
    await recusa(conferirChamador('Bearer x', com({ email: PORTEIRO, email_verified: true }), PORTEIRO));
  });
});
