// Datas que saem das Functions para o painel: sempre ISO 8601 em UTC.
import { Timestamp } from 'firebase-admin/firestore';

/** Timestamp, Date ou texto de data → ISO; o resto → null. */
export function iso(valor: unknown): string | null {
  if (valor instanceof Timestamp) return valor.toDate().toISOString();
  if (valor instanceof Date) return valor.toISOString();
  if (typeof valor === 'string' && valor.length > 0) {
    const d = new Date(valor);
    return Number.isNaN(d.getTime()) ? null : d.toISOString();
  }
  return null;
}
