// Leitura do pacote de conteúdo no Storage (H-R5-38): só o Admin SDK; o app lê pelas regras.
import type { Bucket } from '@google-cloud/storage';
import type { LeitorConteudo } from './versoes';

export function leitorDoStorage(bucket: Bucket): LeitorConteudo {
  return {
    async ler(caminho) {
      const arquivo = bucket.file(caminho);
      const [existe] = await arquivo.exists();
      if (!existe) return null;
      const [bytes] = await arquivo.download();
      return bytes;
    },
  };
}
