import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { linkFallback, boardPreview } from '../src/link-fallback.mjs';

test('intent Android preserva host, caminho e query, inclusive tracking e escapes', () => {
  for (const host of ['playlucena.com', 'www.playlucena.com', 'lucena-2f4de.web.app']) {
    const address = `https://${host}/p/abc?fen=8%2F8+w+-&clock=60%2B1&utm_source=teste&x=a&x=b`;
    const result = linkFallback(address);
    assert.equal(result.target, address);
    assert.equal(result.fen, '8/8 w -');
    assert.equal(result.intent, `intent://${address.slice(8)}#Intent;scheme=https;package=com.gncortes.lucena;S.browser_fallback_url=${encodeURIComponent(address)};end`);
  }
});

test('/dia e /daily, inclusive barra final, mantêm o destino', () => {
  for (const path of ['/dia', '/dia/', '/daily', '/daily/']) {
    const result = linkFallback(`https://playlucena.com${path}?utm_source=teste`);
    assert.equal(result.daily, true);
    assert.ok(result.intent.includes(`${path}?utm_source=teste#Intent;`));
  }
});

test('/aula/<id> e /escola/<id> abrem a aula no app, com a query', () => {
  for (const path of ['/aula/rook.lucena', '/escola/pawn.intro/']) {
    const result = linkFallback(`https://playlucena.com${path}?utm_source=teste`);
    assert.equal(result.lesson, true);
    assert.equal(result.fen, null);
    assert.ok(result.intent.includes(`${path}?utm_source=teste#Intent;`));
  }
  for (const address of ['https://playlucena.com/aula/', 'https://playlucena.com/aula/x/y']) {
    assert.equal(linkFallback(address), null);
  }
});

test('ignora destinos terceiros e páginas normais; não injeta fragmento no intent', () => {
  for (const address of ['https://example.com/p/x', 'http://playlucena.com/dia', 'https://playlucena.com/', 'https://playlucena.com/dia/extra']) {
    assert.equal(linkFallback(address), null);
  }
  assert.ok(!linkFallback('https://playlucena.com/p/x#Intent;evil').intent.includes('evil'));
  assert.equal(linkFallback('https://playlucena.com/p/x').fen, null);
});

test('Firebase reescreve os destinos para a página que contém o fallback', () => {
  const config = JSON.parse(readFileSync(new URL('../../firebase.json', import.meta.url)));
  assert.deepEqual(config.hosting.rewrites, [
    { source: '/p/**', destination: '/index.html' },
    { source: '/dia{,/**}', destination: '/index.html' },
    { source: '/daily{,/**}', destination: '/index.html' },
    { source: '/aula/**', destination: '/index.html' },
    { source: '/escola/**', destination: '/index.html' },
  ]);
  const page = readFileSync(new URL('../src/pages/index.astro', import.meta.url), 'utf8');
  const component = readFileSync(new URL('../src/components/LinkFallback.astro', import.meta.url), 'utf8');
  assert.ok(page.includes('<LinkFallback />'));
  assert.ok(component.includes('linkFallback(window.location.href)'));
  assert.ok(component.includes('textContent = piece'));
});

test('prévia monta 64 casas na orientação pedida e rejeita formato inválido', () => {
  const fen='8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1';
  const white=boardPreview(fen);
  assert.equal(white.squares.length,64);
  assert.equal(white.squares[11],'♚');
  assert.equal(white.squares[50],'♔');
  assert.equal(white.squares[58],'♕');
  assert.equal(white.turn,'white');
  assert.deepEqual(boardPreview(fen,'black').squares,[...white.squares].reverse());
  for (const invalid of [null,'bad','9/8/8/8/8/8/8/8 w - - 0 1','<script>/8/8/8/8/8/8/8 w - - 0 1']) assert.equal(boardPreview(invalid),null);
});
