// Regras do Storage (foto de perfil, P2-1). Rodar com `npm --prefix firebase/test test`.
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import 'firebase/compat/storage';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-lucena',
    storage: { rules: readFileSync('../storage.rules', 'utf8') },
  });
});

after(async () => env?.cleanup());
beforeEach(async () => env.clearStorage());

const foto = (uid) => env.authenticatedContext(uid).storage().ref(`users/${uid}/avatar.jpg`);
const bytes = (n) => new Uint8Array(n);

describe('avatar users/{uid}/avatar.jpg', () => {
  test('JPEG pequeno do dono é aceito', async () => {
    await assertSucceeds(foto('ana').put(bytes(50 * 1024), { contentType: 'image/jpeg' }));
  });

  test('tipo fora de JPEG, PNG ou WebP é recusado (SVG carrega script)', async () => {
    await assertFails(foto('ana').put(bytes(1024), { contentType: 'image/svg+xml' }));
    await assertFails(foto('ana').put(bytes(1024), { contentType: 'application/octet-stream' }));
  });

  test('acima de 1 MB é recusado', async () => {
    await assertFails(foto('ana').put(bytes(1024 * 1024 + 1), { contentType: 'image/jpeg' }));
  });

  test('outra conta não grava nem lê', async () => {
    const alheia = env.authenticatedContext('bia').storage().ref('users/ana/avatar.jpg');
    await assertFails(alheia.put(bytes(1024), { contentType: 'image/jpeg' }));
    await assertFails(alheia.getDownloadURL());
  });

  test('outro caminho é recusado', async () => {
    const outro = env.authenticatedContext('ana').storage().ref('users/ana/outra.jpg');
    await assertFails(outro.put(bytes(1024), { contentType: 'image/jpeg' }));
  });
});
