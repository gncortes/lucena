import 'package:flutter_test/flutter_test.dart';

/// Testes que quebram antes (RED) das entradas e saídas da aula em vídeo.
///
/// Entradas E1–E12 de `docs/fluxos/aula-video.md` (tabela de entradas, um
/// teste por linha); lote de cada uma em `docs/tasks/T-aula-video-contrato.md`
/// ("Testes que quebram antes" e "Lotes"). O `skip` diz o lote que resolve e
/// sai quando o lote entra (o corpo vira o teste de verdade).
void main() {
  group('entradas', () {
    test('E1: Lista de Finais / Escola / aba Aula / link /aula, lição nunca '
        'aberta → Teoria em 0:00, tocando', () {
      // Arrange: lição sem progresso. Act: navegar pela rota da aula.
      // Assert: aula em vídeo na Teoria, t = 0, tocando.
    }, skip: 'L6: vídeo vira a Teoria de toda lição (sai a flag)');

    test(
      'E2: mesmas entradas, lição com progresso salvo → pausada no começo da '
      'fala salva + aviso "Você parou aqui"',
      () {
        // Arrange: progresso na fala 3. Act: abrir a lição.
        // Assert: pausada no início da fala 3 com o aviso de retomada.
      },
      skip: 'L3: progresso salvo e aviso de retomada',
    );

    test('E3: mesmas entradas, lição concluída → conforme Vídeo 23', () {
      // Arrange: lição concluída. Act: abrir.
      // Assert: comportamento da resposta à pergunta 2 do contrato.
    }, skip: 'L6: ligação; depende da pergunta 2 ao Gabriel (Vídeo 23)');

    test('E4: reabrir o app depois de fechar à força no meio → = E2 (retomada '
        'automática)', () {
      // Arrange: progresso salvo e app reaberto. Act: lançamento.
      // Assert: rota inicial é a aula, pausada com o aviso (como E2).
    }, skip: 'L3: progresso salvo e retomada automática');

    test(
      'E5: Metas do Treino (origem treino_) → = E1/E2; o fim volta às metas',
      () {
        // Act: abrir a aula com origem treino_. Assert: abre como E1/E2 e o
        // fim da lição volta às metas do Treino.
      },
      skip: 'L6: ligação com a origem do Treino',
    );

    test('E6: livro no topo → Glossário completo, vídeo pausado', () {
      // Act: tocar o livro na app bar. Assert: rota do Glossário sem
      // filtro e a aula ficou pausada.
    }, skip: 'L5: rota do Glossário');

    test('E7: termo sublinhado no balão → Glossário filtrado + Wikipédia ou '
        'folha offline', () {
      // Act: tocar um termo. Assert: rota do Glossário com a busca = termo
      // e folha da Wikipédia (ou offline sem internet).
    }, skip: 'L5: rota do Glossário com filtro');

    test(
      'E8: voltar do Glossário → aula no mesmo instante; volta a tocar só se '
      'tocava',
      () {
        // Arrange: abrir o Glossário tocando em 30 s. Act: voltar.
        // Assert: aula em 30 s tocando; se estava pausada, pausada.
      },
      skip: 'L5: volta do Glossário para a aula',
    );

    test(
      'E9: "Próxima etapa" no fim da Teoria → Demonstração em 0:00, tocando',
      () {
        // Act: endNext no fim da Teoria. Assert: Demonstração, t = 0, tocando.
      },
      skip: 'L6: ligação Teoria → Demonstração',
    );

    test(
      'E10: "Próxima etapa" no fim da Demonstração → Prática (tela atual)',
      () {
        // Act: endNext no fim da Demonstração. Assert: Prática atual aberta.
      },
      skip: 'L6: ligação Demonstração → Prática',
    );

    test('E11: fim da Prática → fim da lição → próxima lição, ou metas com '
        'origem Treino', () {
      // Act: concluir a Prática. Assert: fim da lição (Vídeo 34) e depois
      // a próxima lição, ou as metas quando a origem é treino_.
    }, skip: 'L6: ligação do fim da lição; depende da pergunta 4 ao Gabriel');

    test('E12: seta voltar do topo, em qualquer etapa → tela de origem; '
        'progresso salvo', () {
      // Act: voltar no meio da Teoria. Assert: tela de origem e progresso
      // gravado (fala, fração, respondidas).
    }, skip: 'L3: progresso salvo na saída');
  });
}
