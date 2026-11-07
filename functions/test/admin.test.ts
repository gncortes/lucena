import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { HttpsError } from 'firebase-functions/https';
import { exigeAdmin, LeitorAdmins } from '../src/comum/admin';

/** Firestore de mentira: só os caminhos de [existentes] existem. */
function fakeDb(existentes: string[]): LeitorAdmins & { lidos: string[] } {
  const lidos: string[] = [];
  return {
    lidos,
    doc: (caminho: string) => ({
      get: async () => {
        lidos.push(caminho);
        return { exists: existentes.includes(caminho) };
      },
    }),
  };
}

async function codigoDoErro(promessa: Promise<unknown>): Promise<string> {
  try {
    await promessa;
  } catch (e) {
    assert.ok(e instanceof HttpsError);
    return e.code;
  }
  assert.fail('devia ter lançado');
}

describe('exigeAdmin', () => {
  test('admin passa e devolve o uid', async () => {
    const db = fakeDb(['admins/gabriel']);
    assert.equal(await exigeAdmin(db, 'gabriel'), 'gabriel');
    assert.deepEqual(db.lidos, ['admins/gabriel']);
  });

  test('não admin recebe permission-denied', async () => {
    assert.equal(await codigoDoErro(exigeAdmin(fakeDb(['admins/gabriel']), 'rafael')), 'permission-denied');
  });

  test('sem login recebe unauthenticated sem ler o Firestore', async () => {
    const db = fakeDb([]);
    assert.equal(await codigoDoErro(exigeAdmin(db, undefined)), 'unauthenticated');
    assert.equal(await codigoDoErro(exigeAdmin(db, '')), 'unauthenticated');
    assert.deepEqual(db.lidos, []);
  });
});
