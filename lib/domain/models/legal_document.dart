/// Os Termos de uso e a Política de privacidade lidos dentro do app
/// (H-AJU-14 / H-CON-22). O texto vem de um Markdown curto, o mesmo publicado
/// no site: `# título` (ignorado: a folha já tem título), parágrafos,
/// `## N. seção`, itens `- `, `**negrito**` e uma tabela.
enum LegalKind { terms, privacy }

/// Um trecho de texto, em negrito ou não.
typedef LegalSpan = ({String text, bool bold});

sealed class LegalBlock {
  const LegalBlock();
}

class LegalParagraph extends LegalBlock {
  const LegalParagraph(this.spans);
  final List<LegalSpan> spans;
}

class LegalBullet extends LegalBlock {
  const LegalBullet(this.spans);
  final List<LegalSpan> spans;
}

/// Uma tabela: o cabeçalho e as linhas, célula por célula.
class LegalTable extends LegalBlock {
  const LegalTable(this.header, this.rows);
  final List<String> header;
  final List<List<String>> rows;
}

class LegalSection {
  const LegalSection(this.title, this.blocks);

  /// Com o número, como no texto: "1. Quem somos".
  final String title;
  final List<LegalBlock> blocks;
}

class LegalDocument {
  const LegalDocument({required this.intro, required this.sections});

  /// O que vem antes da primeira seção ("Versão 1, em vigor desde ...").
  final List<LegalBlock> intro;
  final List<LegalSection> sections;

  static LegalDocument parse(String markdown) {
    final intro = <LegalBlock>[];
    final sections = <LegalSection>[];
    var blocks = intro;
    final table = <List<String>>[];

    void flushTable() {
      if (table.isEmpty) return;
      blocks.add(LegalTable(table.first, table.skip(1).toList()));
      table.clear();
    }

    for (final raw in markdown.split('\n')) {
      final line = raw.trim();
      if (!line.startsWith('|')) flushTable();
      if (line.isEmpty || line == '---' || line.startsWith('# ')) continue;
      if (line.startsWith('## ')) {
        blocks = <LegalBlock>[];
        sections.add(LegalSection(line.substring(3).trim(), blocks));
      } else if (line.startsWith('|')) {
        final cells = line
            .substring(1, line.endsWith('|') ? line.length - 1 : line.length)
            .split('|')
            .map((cell) => cell.trim())
            .toList();
        // A linha "|---|---|" só separa o cabeçalho.
        if (cells.every((cell) => RegExp(r'^:?-+:?$').hasMatch(cell))) {
          continue;
        }
        table.add(cells);
      } else if (line.startsWith('- ')) {
        blocks.add(LegalBullet(spans(line.substring(2))));
      } else {
        blocks.add(LegalParagraph(spans(line)));
      }
    }
    flushTable();
    return LegalDocument(intro: intro, sections: sections);
  }

  /// Quebra `**negrito**` em trechos.
  static List<LegalSpan> spans(String text) {
    final parts = text.split('**');
    return [
      for (var i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty) (text: parts[i], bold: i.isOdd),
    ];
  }
}
