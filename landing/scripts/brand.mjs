// Gera em landing/assets/ os ícones, o mascote e as peças da página a partir
// da marca do app (assets/branding) e das peças cburnett do chessground.
// Uso: node scripts/brand.mjs [pasta das peças cburnett 3.0x]
import { mkdir, copyFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import sharp from 'sharp';

const brand = new URL('../../assets/branding/', import.meta.url);
const out = new URL('../assets/', import.meta.url);
const pieces =
  process.argv[2] ??
  `${homedir()}/.pub-cache/hosted/pub.dev/chessground-10.3.0/assets/piece_sets/cburnett/3.0x`;

await mkdir(new URL('pieces/', out), { recursive: true });

const icon = new URL('launcher_icon.png', brand).pathname;
for (const [name, size] of [
  ['favicon-32.png', 32],
  ['apple-touch-icon.png', 180],
  ['icon-512.png', 512],
]) {
  await sharp(icon).resize(size).png().toFile(new URL(name, out).pathname);
}
await sharp(icon).resize(96).webp({ quality: 90 }).toFile(new URL('logo.webp', out).pathname);

await sharp(new URL('mascot_light.png', brand).pathname)
  .resize(480)
  .webp({ quality: 88 })
  .toFile(new URL('mascot-light.webp', out).pathname);

// O mascote escuro vem sobre o fundo do app (#14211B): o fundo vira
// transparente, com uma rampa curta para as bordas não ficarem serrilhadas.
{
  const { data, info } = await sharp(new URL('mascot_dark.png', brand).pathname)
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  const bg = [20, 33, 27];
  for (let i = 0; i < data.length; i += 4) {
    const distance = Math.hypot(data[i] - bg[0], data[i + 1] - bg[1], data[i + 2] - bg[2]);
    data[i + 3] = Math.round(255 * Math.min(1, Math.max(0, (distance - 6) / 40)));
  }
  await sharp(data, { raw: info })
    .resize(480)
    .webp({ quality: 88, alphaQuality: 90 })
    .toFile(new URL('mascot-dark.webp', out).pathname);
}

for (const piece of ['wP', 'wQ']) {
  await copyFile(`${pieces}/${piece}.webp`, new URL(`pieces/${piece}.webp`, out).pathname);
}
console.log('brand assets ok');
