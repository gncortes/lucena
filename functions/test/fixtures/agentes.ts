// Lote de exemplo (sintético, no formato que os agentes gravam em gncortes/lucena-agentes/saida). As saídas reais ficam
// no repositório privado lucena-utils (agentes/esquema/amostras), lidas só quando ele está ao lado deste checkout.
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';

/** Compilado em lib/test/fixtures; os .json ficam em test/fixtures/agentes. */
const PASTA = join(__dirname, '..', '..', '..', 'test', 'fixtures', 'agentes');

export const EXEMPLO = 'lote-exemplo.json';
/** Lote do redator de notícias: duas notícias e a coleção que junta as duas. */
export const NOTICIAS = 'lote-noticias.json';

/** O texto do arquivo como está (o sha256 do porteiro é dele). */
export function lerAmostra(nome: string): string {
  return readFileSync(join(PASTA, nome), 'utf8');
}

/** O lote como objeto, para montar variações nos testes. */
export function loteDe(nome: string): { agente: string; resumo: string; entregas: Record<string, any>[] } {
  return JSON.parse(lerAmostra(nome));
}

/**
 * A pasta lucena-utils/agentes/esquema (fonte única do esquema e da allowlist), se este checkout estiver ao lado dela
 * (pasta principal ou worktree em .worktrees/). No CI ela não existe e os testes que dependem dela são pulados.
 */
export function esquemaDoUtils(): string | null {
  let dir = PASTA;
  for (let i = 0; i < 8; i++) {
    const candidata = join(dir, 'lucena-utils', 'agentes', 'esquema');
    if (existsSync(join(candidata, 'entregas-v1.schema.json'))) return candidata;
    const acima = dirname(dir);
    if (acima === dir) break;
    dir = acima;
  }
  return null;
}

/** As saídas reais dos agentes guardadas no lucena-utils ({nome: texto}); vazio fora da máquina do Gabriel. */
export function amostrasReais(): Record<string, string> {
  const esquema = esquemaDoUtils();
  const pasta = esquema ? join(esquema, 'amostras') : null;
  if (!pasta || !existsSync(pasta)) return {};
  return Object.fromEntries(
    readdirSync(pasta)
      .filter((f) => f.endsWith('.json'))
      .map((f) => [f, readFileSync(join(pasta, f), 'utf8')]),
  );
}
