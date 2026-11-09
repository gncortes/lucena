// Os cursos que o servidor conhece (id usado em acessos/{uid}.cursos.{id}).
// Curso novo entra aqui antes de poder ser dado ou vendido.
export const CURSOS: Readonly<Record<string, { nome: string }>> = {
  pilares: { nome: 'Pilares do Xadrez' },
  treinador: { nome: 'Treinador de partidas' },
};

export function cursoExiste(id: unknown): id is string {
  return typeof id === 'string' && Object.prototype.hasOwnProperty.call(CURSOS, id);
}
