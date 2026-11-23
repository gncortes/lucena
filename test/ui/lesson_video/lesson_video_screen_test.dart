import 'package:flutter_test/flutter_test.dart';

/// Testes que quebram antes (RED) da tela da aula em vídeo.
///
/// Gaps de `docs/fluxos/aula-video.md` ("Matriz de gaps", Vídeo N), lote de
/// cada um em `docs/tasks/T-aula-video-contrato.md` ("Testes que quebram
/// antes" e "Lotes"). O nome do teste é o gap. `testWidgets` só aceita
/// `skip: bool`, então os casos ficam num `group` por lote com o motivo no
/// `skip`; quando o lote entra, o skip do grupo sai (e o corpo vira o teste).
void main() {
  group('gaps L1', () {
    testWidgets(
      'Vídeo 1: toque ou arraste no tabuleiro fora da sua vez → nada: o '
      'vídeo não pausa nem move peça',
      (tester) async {
        // Arrange: tela tocando. Act: tap e drag em LessonVideoKeys.board.
        // Assert: continua tocando e a posição do tabuleiro não muda.
      },
    );

    testWidgets(
      'Vídeo 5: arrastar atravessando Teoria/Demonstração → impossível: '
      'cada etapa tem a sua barra; o fim da Teoria mostra o rodapé',
      (tester) async {
        // Act: arrastar a barra até o fim da Teoria.
        // Assert: rodapé (endRestart/endNext) visível, etapa não muda.
      },
    );

    testWidgets(
      'Vídeo 13: marcações desligadas → some tudo do tabuleiro (casas, '
      'setas, círculos); preferência lessonMarks atual',
      (tester) async {
        // Act: tocar LessonScriptKeys.marksToggle.
        // Assert: sem formas no tabuleiro; SettingsCubit.setLessonMarks(false).
      },
    );

    testWidgets(
      'Vídeo 35: tela pequena (360×740, 360×800) → tabuleiro encolhe e fica '
      'no centro (~340 em 360×740)',
      (tester) async {
        // Arrange: superfície 360×740. Assert: lado do tabuleiro 340 ± 8 e
        // centro vertical da área abaixo da app bar ± 4 dp.
      },
    );

    testWidgets(
      'Vídeo 36: tela grande (412×915, 414×896) → tabuleiro na largura '
      'toda, no centro',
      (tester) async {
        // Arrange: superfície 412×917. Assert: lado = 412 e centro vertical
        // da área abaixo da app bar ± 4 dp.
      },
    );

    testWidgets(
      'Vídeo 37: leitor de tela → não começa sozinho; botões com rótulo; '
      'barra é Slider com "0:14 de 1:02"; termo e casa são links',
      (tester) async {
        // Arrange: accessibleNavigation = true. Assert: pausado ao abrir;
        // Slider com valor "0:14 de 1:02"; tooltips; alvos ≥ 48.
      },
    );

    testWidgets(
      'Vídeo 43: carregando o vídeo/áudio → esqueleto no balão, tabuleiro na '
      'posição inicial, play desabilitado',
      (tester) async {
        // Arrange: repositório que não completa. Assert: LessonVideoKeys
        // .loading visível e playPause desabilitado.
      },
    );

    testWidgets(
      'Vídeo 44: roteiro ausente ou ilegível → aviso de lição indisponível '
      'com "Tentar de novo"',
      (tester) async {
        // Arrange: repositório falha. Assert: LessonVideoKeys.unavailable;
        // "Tentar de novo" recarrega.
      },
    );
  }, skip: 'L1: tela do vídeo (layout, barra, controles) ainda não existe');

  group('gaps L2', () {
    testWidgets(
      'Vídeo 25: sua vez esperando o lance → vídeo parado, tabuleiro com '
      'contorno, play e ±10 esmaecidos',
      (tester) async {
        // Arrange: tocar até a pergunta. Assert: LessonVideoKeys.yourMove;
        // play, back10 e forward10 com opacidade 38 %.
      },
    );
  }, skip: 'L2: sua vez (perguntas) ainda não existe');

  group('gaps L3', () {
    testWidgets(
      'Vídeo 12: legenda desligada → balão "Legenda desligada"; setas e '
      'marcas ficam; o destaque da casa citada sai; preferência salva',
      (tester) async {
        // Act: tocar LessonVideoKeys.captions. Assert: texto da legenda
        // desligada no balão, formas no tabuleiro, preferência gravada.
      },
    );
  }, skip: 'L3: preferência da legenda persistida ainda não existe');

  group('gaps L5', () {
    testWidgets(
      'Vídeo 2: toque numa casa sublinhada do balão → a casa pisca no '
      'tabuleiro (square_flash), o vídeo segue',
      (tester) async {
        // Act: tap em LessonVideoKeys.square('c8').
        // Assert: square_flash em c8 e o vídeo continua tocando.
      },
    );

    testWidgets(
      'Vídeo 17: livro → Glossário → voltar → pausa; ao voltar continua só '
      'se tocava',
      (tester) async {
        // Act: tocar glossaryButton tocando; voltar. Assert: pausou ao abrir
        // e voltou a tocar. Repetir pausado: continua pausado.
      },
    );

    testWidgets(
      'Vídeo 18: tocar termo sublinhado → pausa; Glossário com a busca = '
      'termo e folha da Wikipédia; fechar a folha deixa a lista filtrada',
      (tester) async {
        // Act: tap em LessonVideoKeys.term(id). Assert: GlossaryKeys.search
        // com o termo, folha aberta; fechar → lista filtrada; X limpa.
      },
    );

    testWidgets('Vídeo 19: termo sem internet → folha do termo com definição + '
        '"Sem internet…"', (tester) async {
      // Arrange: conectividade off. Act: tocar termo.
      // Assert: GlossaryKeys.sheet com definição e GlossaryKeys.offline.
    });

    testWidgets(
      'Vídeo 21: busca no Glossário sem resultado → estado vazio "Nenhum '
      'termo com …"',
      (tester) async {
        // Act: digitar termo inexistente em GlossaryKeys.search.
        // Assert: GlossaryKeys.empty com o texto da busca.
      },
    );
  }, skip: 'L5: Glossário (tela, busca, folhas) e termo/casa sublinhados');

  group('gaps L6', () {
    testWidgets(
      'Vídeo 33: fim da Demonstração → rodapé → Prática com a fala de '
      'entrada',
      (tester) async {
        // Arrange: Demonstração no fim. Act: tocar LessonVideoKeys.endNext.
        // Assert: tela da Prática atual com a fala de entrada.
      },
    );
  }, skip: 'L6: ligação do vídeo com a Prática');
}
