import type { Dictionary } from './types';

const pt: Dictionary = {
  meta: {
    title: 'Lucena: treine finais de xadrez contra o Maia e o Stockfish',
    description:
      'Aprenda xadrez pelos finais. Faça o teste de nível, estude 38 aulas de finais com o Mestre Viktor e jogue contra o Maia, que joga como gente do seu nível, até o Stockfish na força máxima. Com speedrun, Maratona e partidas às cegas.',
    ogAlt:
      'O app Lucena aberto num celular, com um final de xadrez no tabuleiro.',
  },
  nav: {
    features: 'Recursos',
    roadmap: 'Roadmap',
    support: 'Apoie',
    tester: 'Seja testador',
    skip: 'Pular para o conteúdo',
    theme: 'Alternar tema claro e escuro',
    language: 'Idioma',
    menu: 'Menu',
  },
  hero: {
    eyebrow: 'App gratuito para treinar finais de xadrez',
    title: 'Treine finais de xadrez até virar',
    titleAccent: 'técnica',
    lead: 'O Lucena ensina finais com o Mestre Viktor, do movimento das peças à posição de Lucena, e coloca você para jogá-los contra o Maia, que joga como gente do seu nível, e depois contra o Stockfish na força máxima.',
    cta: 'Quero ser testador',
    secondary: 'Ver como funciona',
    note: 'Android, versão de testes. Em breve no Google Play.',
    chips: ['Maia 1000–2600', 'Stockfish', '38 aulas de finais'],
  },
  stats: [
    { value: '9', label: 'níveis do Maia, de 1000 a 2600' },
    { value: '38', label: 'aulas de finais, em 7 módulos' },
    { value: '39', label: 'aulas na Escola do Viktor, para quem está começando' },
    { value: '250', label: 'exercícios nos testes finais das aulas' },
    { value: '80', label: 'partidas de mestres citadas nas aulas' },
    { value: '55', label: 'finais para treinar quantas vezes quiser' },
  ],
  marquee: [
    'Posição de Lucena',
    'Posição de Philidor',
    'Dama contra torre',
    'Mate de bispo e cavalo',
    'Casas-chave',
    'Oposição à distância',
    'Defesa pela última fileira',
    'Defesa pelo lado curto',
    'Triangulação',
    'Manobra de Réti',
    'Peão passado afastado',
    'Bispo errado',
  ],
  message: {
    kicker: 'Aprender xadrez pelos finais',
    title: 'Comece pelo fim do tabuleiro',
    quote:
      'Para melhorar o seu jogo, você deve estudar os finais antes de tudo.',
    quoteAuthor: 'José Raúl Capablanca, campeão mundial',
    body: [
      'Com poucas peças no tabuleiro, cada uma mostra o que sabe fazer. Fica mais fácil entender como o rei ataca, como a torre corta, como o bispo e o cavalo trabalham juntos.',
      'É aí que se aprende a jogar com precisão: cada lance conta, e você vê na hora o que funcionou. Essa clareza vale para a partida inteira.',
    ],
    boardCaption:
      'A primeira aula da escola do Viktor: só a torre no tabuleiro. Com poucas peças, cada uma mostra o que sabe fazer.',
  },
  story: {
    kicker: 'Por que o Lucena existe',
    title: 'Feito por quem ama xadrez',
    paragraphs: [
      'Sou programador e amo programar. Minha outra paixão é o xadrez. O Lucena nasceu de uma necessidade minha: os finais sempre foram o meu ponto fraco, e eu queria um jeito de treiná-los de verdade.',
      'O que funcionou foi treinar de forma progressiva: primeiro contra o Maia, que erra e acerta como gente do meu nível, depois subindo até o Stockfish. Repetir a mesma posição contra adversários cada vez mais fortes fixou as técnicas.',
      'Mas eu gosto tanto de xadrez que quis ir além: criar algo para que qualquer pessoa consiga aprender e praticar com facilidade e entrar no mundo desse jogo milenar. Quero espalhar o Lucena para que muita gente aprenda a jogar por ele e domine os finais que mais custam a entrar na cabeça.',
    ],
    philidor: {
      text:
        'E quero mostrar como os finais são fascinantes. Eles não costumam ser a parte do xadrez que mais chama atenção, mas guardam algumas das ideias mais bonitas do jogo. Há mais de 250 anos, François-André Danican Philidor já estudava essas posições, e a defesa que leva o nome dele é ensinada até hoje, inclusive aqui no Lucena. Não à toa, muitos, como o Grande Mestre Rafael Leitão, o consideram o maior gênio da história do xadrez.',
      caption: 'François-André Danican Philidor (1726–1795), gravura de Augustin de Saint-Aubin, 1772.',
      alt: 'Retrato de perfil de Philidor, gravura do século XVIII',
    },
    signature: 'Gabriel, criador do Lucena',
  },
  features: {
    kicker: 'Recursos',
    title: 'Tudo para dominar os finais',
    lead: 'Isto é o que eu já consigo entregar hoje, e já dá para treinar e evoluir de verdade. Mas é só o começo: tenho muito mais planejado para o Lucena.',
    items: {
      progression: {
        title: 'Do Maia ao Stockfish',
        body: 'Jogue contra o Maia, um motor de xadrez com rede neural criado por pesquisadores da Universidade de Toronto e treinado em milhões de partidas de pessoas no Lichess. Ele erra e acerta como gente de verdade, do 1000 ao 2600, e cada nível é um adversário com personalidade. Escolha o ritmo, suba degrau por degrau e, quando estiver pronto, enfrente o Stockfish na força máxima. Tudo roda no celular, sem internet.',
        bullets: [
          'Níveis humanos de 1000 a 2600',
          'Relógio com tempo e incremento',
          'Stockfish na força máxima',
          'Tabuleiro livre e posição personalizada',
        ],
      },
      placement: {
        title: 'Teste de nível: descubra por onde começar',
        body: 'São 20 perguntas, sem relógio, em uns 8 minutos: para onde a peça pode ir, se é mate ou afogamento, se ainda dá para rocar, quem ganha com o melhor jogo. Não sabe? Toque em "Não sei" em vez de chutar. No fim, o Viktor mostra a sua faixa de rating, o que você já domina e o que falta estudar.',
        bullets: [
          '20 perguntas, sem relógio',
          'O mapa do que você já domina e do que falta',
          'Finais para você: as aulas que faltam, na ordem certa',
        ],
      },
      school: {
        title: 'Escola do Viktor: do zero ao primeiro mate',
        body: 'Para quem está começando. O Mestre Viktor ensina como cada peça se move pegando estrelas no tabuleiro e segue com captura, xeque, roque, en passant, empates, notação, os primeiros mates e as armadilhas em que todo iniciante cai, como o mate do pastor. Cada aula é curta, com dica na hora certa, e a última é uma prova final que vale diploma.',
        bullets: [
          '39 aulas em 8 módulos',
          'Peças, regras, notação e primeiros mates',
          'Prova final e diploma',
        ],
      },
      lessons: {
        title: 'Aulas de finais aprofundadas',
        body: 'São 38 aulas em 7 módulos: finais básicos, mates difíceis, finais de peões, finais de dama, torre contra peões, finais de torre e peças menores. Da posição de Lucena e da defesa de Philidor à triangulação e à manobra de Réti. Cada aula é dividida em capítulos curtos, com uma ideia só em cada um, e muitas posições vêm de partidas reais de mestres, com link para você ver a partida inteira.',
        bullets: [
          'Teste final de exercícios, de 1 a 3 estrelas, com nota mínima para passar',
          'Dica quando travar, ao custo de um ponto',
          'Aprovado, o desafio: jogar o final de verdade contra o Maia ou o Stockfish',
          'Fontes de cada aula: livros, estudos do Lichess e partidas de mestres',
        ],
      },
      journey: {
        title: 'Jornada: um adversário de cada vez',
        body: 'O passo seguinte às aulas: vença os desafios de cada personagem para liberar o próximo, do Coco, no 1000, até o Stockfish. Cada um tem personalidade e comenta a partida num balão de fala. No caminho, desafios especiais: às cegas, um speedrun curto e uma maratona curta.',
        bullets: [
          '10 adversários, do 1000 ao Stockfish',
          'Desafios especiais às cegas e contra o relógio',
          'Estrelas e conquistas para acompanhar o progresso',
        ],
      },
      speedrun: {
        title: 'Speedrun: contra o relógio',
        body: 'Vença uma série de etapas o mais rápido que puder: um final contra todos os adversários, do mais fraco até o Stockfish, todos os desafios de um adversário, séries de exercícios ou a Jornada completa. Só o seu relógio conta, dá para pausar entre as etapas, e etapa perdida é jogada de novo com o cronômetro correndo.',
        bullets: ['Parciais por etapa', 'Recorde pessoal e histórico de tempos', 'Do Ultra Bullet ao Clássico'],
      },
      marathon: {
        title: 'Maratona: um relógio só',
        body: 'Do 1000 ao Stockfish com um relógio só: cada etapa começa com o tempo que sobrou da anterior, e uma partida emenda na outra. Perdeu, empatou ou o tempo acabou: fim da Maratona. Você escolhe o final, a dificuldade e o ritmo.',
        bullets: ['Finais de iniciante, intermediário e avançado', 'Recorde: o tempo que sobrou no fim'],
      },
      blind: {
        title: 'Às cegas',
        body: 'Jogue sem ver as peças: fale, digite ou toque os lances. Ouça onde estão as peças antes de começar, peça para repetir o lance do adversário e escolha quanto quer ver. A voz é reconhecida pelo próprio aparelho e não é gravada. Ainda é experimental.',
        bullets: ['Com tabuleiro, só com as casas ou sem tabuleiro', 'Lances por voz, teclado ou toque'],
      },
      voice: {
        title: 'O professor fala com você',
        body: 'Ligue a voz e o Mestre Viktor e os adversários leem as falas em voz alta. Cada personagem já vem com a sua voz; você escolhe a do professor, troca a de quem quiser e ajusta a velocidade e o tom.',
        bullets: ['Voz do professor e dos adversários', 'Velocidade e tom ajustáveis'],
      },
      stars: {
        title: 'Desafios das estrelas',
        body: 'Pegue as estrelas com cada peça contra o relógio: uma estrela aparece, você leva a peça até ela e outra acende. Quantas você pega antes de o tempo acabar? Três níveis por peça e mais o às cegas, em que a estrela vem só pelo nome da casa.',
        bullets: ['Três níveis por peça', 'Às cegas, pelo nome da casa', 'Recorde em cada desafio'],
      },
      analysis: {
        title: 'Análise da partida',
        body: 'Depois de jogar, reveja lance a lance com o Stockfish e descubra onde a vitória escapou ou onde a defesa segurou. Escolha a profundidade da análise, veja a melhor linha com o Stockfish no seu lugar e abra a partida no Lichess ou no chess.com.',
        bullets: [
          'Barra de avaliação',
          'Precisão e qualidade de cada lance',
          'Copiar a posição (FEN) e a partida (PGN)',
        ],
      },
      progress: {
        title: 'Seu progresso',
        body: 'Um rating de finais que muda a cada partida contra o Maia ou o Stockfish, levando em conta o quanto a posição ajudava, com o histórico ao longo do tempo. Conquistas para desbloquear, os seus números na tela inicial e cada partida guardada para rever.',
        bullets: ['Rating de finais com histórico', '50 conquistas', 'Partidas, vitórias e dias seguidos'],
      },
      custom: {
        title: 'Do seu jeito',
        body: 'Tema claro ou escuro, seis cores para o app, peças e cores do tabuleiro, relógio acima, abaixo ou um de cada lado. Escolha o que aparece na tela inicial e em que ordem. O app está em 19 idiomas.',
        bullets: [],
      },
    },
    route: {
      label: 'Cada capítulo segue o mesmo roteiro',
      steps: [
        { title: 'Pense', body: 'Antes de qualquer explicação, você olha a posição e procura o plano sozinho.' },
        { title: 'Veja', body: 'O Mestre Viktor comenta a ideia, com setas e casas marcadas, e mostra a linha lance a lance.' },
        { title: 'Jogue', body: 'Agora os lances são seus: o capítulo só segue quando você acerta.' },
        { title: 'Teste na prática', body: 'Você joga a posição até o fim contra o motor.' },
      ],
    },
  },
  levels: {
    kicker: 'Para todos os níveis',
    title: 'Sabe pouco ou já joga bem? Tem desafio para você',
    beginner: {
      title: 'Está começando',
      body: 'Faça o teste de nível ou vá direto à Escola do Viktor: como cada peça se move, xeque, mate e os primeiros finais, com aulas curtas, dicas na hora certa e adversários que jogam no seu ritmo.',
    },
    advanced: {
      title: 'Já joga bem',
      body: 'Vá às aulas de finais e converta posições teóricas contra o Maia 2600 e o Stockfish. Se você ganhar a dama contra a torre do Stockfish, a técnica é sua.',
    },
  },
  roadmap: {
    kicker: 'Roadmap',
    title: 'Para onde o Lucena vai',
    items: [
      {
        status: 'Agora',
        title: 'Versão de testes no Android',
        body: 'Distribuída pelo Firebase App Distribution, do Google. Quem entra no grupo recebe sempre a versão mais recente.',
      },
      {
        status: 'Em preparação',
        title: 'Google Play',
        body: 'A conta na Google Play já está sendo criada. A publicação vem logo, logo.',
      },
      {
        status: 'Depois',
        title: 'iPhone',
        body: 'Assim que houver recursos para publicar na App Store.',
      },
    ],
  },
  support: {
    kicker: 'Apoie o projeto',
    title: 'Ajude o Lucena a crescer',
    body: [
      'O Lucena é gratuito e feito por uma pessoa só, nas horas vagas. Se ele te ajudou e você quiser contribuir, qualquer apoio faz diferença para o app crescer mais rápido.',
      'Ainda vamos criar um jeito simples de apoiar direto pelo app, com um mural de apoiadores: quem ajudar ganha visibilidade lá dentro. Por enquanto, se quiser doar, é só me mandar um e-mail.',
    ],
    cardTitle: 'Mural de apoiadores',
    cardBody: 'Em breve no app: quem apoiar o projeto aparece lá dentro, para toda a comunidade ver.',
    cta: 'Quero apoiar',
    subject: 'Quero apoiar o Lucena',
    note:
      'E o iPhone? O Lucena vai para a App Store assim que eu tiver os recursos para publicar lá. Primeiro quero validar a ideia no Android, mas, se você usa iOS, pode ficar tranquilo: vou fazer o possível para chegar lá o quanto antes.',
  },
  tester: {
    kicker: 'Seja testador',
    title: 'Teste antes de todo mundo',
    body: 'Entre no grupo de testes e receba sempre a versão mais recente do Lucena no seu Android.',
    teachers:
      'É professor de xadrez? Passe o app para os seus alunos. Os finais são a melhor porta de entrada, e o feedback de quem ensina vale ouro.',
    safety:
      'Os testes são distribuídos pelo Firebase App Distribution, a plataforma do Google para enviar versões de teste de apps. Você recebe o convite, instala o app de testes do Firebase e baixa o Lucena por ele, com segurança.',
    safetyLink: 'Como funciona o Firebase App Distribution',
    wait: 'Prefere esperar? Sem problema: o Lucena chega à Google Play em breve.',
    cta: 'Entrar no grupo de testes',
    thanks:
      'Obrigado de verdade. Alguém dedicar tempo para testar, validar a ideia e mandar feedback é muito importante para mim. Cada mensagem ajuda a decidir o próximo passo do app.',
  },
  vision: {
    kicker: 'Visão',
    title: 'Um projeto vivo',
    body: 'O objetivo é oferecer a melhor experiência para aprender xadrez, melhorar nos finais e se desafiar neles. O Lucena vai crescer com novos recursos, guiados pelo que a comunidade pedir.',
    cta: 'Mandar uma ideia',
  },
  refs: {
    kicker: 'Créditos e referências',
    title: 'Feito sobre os ombros de gigantes',
    items: [
      { name: 'Stockfish', body: 'Motor de xadrez de código aberto (GPL-3.0), o adversário mais forte do app.' },
      { name: 'Maia', body: 'Motor de código aberto com rede neural, de pesquisadores da Universidade de Toronto, treinado em partidas de pessoas no Lichess.' },
      { name: 'Lichess', body: 'As bibliotecas de tabuleiro e de regras (chessground e dartchess) e as peças cburnett, de Colin M.L. Burnett.' },
      { name: 'Firebase App Distribution', body: 'A plataforma do Google que entrega as versões de teste.' },
      { name: 'Retrato de Philidor', body: 'Gravura de Augustin de Saint-Aubin, 1772, em domínio público (Wikimedia Commons).' },
    ],
  },
  footer: {
    tagline: 'Treine finais de xadrez contra o Maia e o Stockfish.',
    dev: 'Sou programador. Se você precisa de uma landing page, de um aplicativo ou quer conhecer meus serviços, fale comigo:',
    contact: 'Contato',
  },
  media: {
    hero: 'Escolha do nível do Maia e do ritmo, e a partida contra ele no Lucena',
    school: 'Primeira aula da escola do Viktor no Lucena: a torre e as estrelas',
    journey: 'A Jornada do Lucena: o adversário atual e os desafios',
    queenRook: 'Aula interativa de dama contra torre no Lucena',
    speedrun: 'Speedrun do Lucena: as etapas e a partida contra o relógio',
    theme: 'Escolha do tema escuro e da cor do app no Lucena',
    journeyChallenge: 'Desafio da Jornada no Lucena: mate de dama contra o Tito, nível 1200',
    exercise: 'Exercício de dama contra torre numa aula de finais do Lucena',
    queenRookLesson: 'Aula de finais do Lucena: dama contra torre, como chegar a Philidor',
    shortSide: 'Aula de finais do Lucena: a defesa pelo lado curto',
    stars: 'Desafio das estrelas do Lucena com a torre, no nível difícil',
    play: 'Reproduzir vídeo',
    pause: 'Pausar vídeo',
  },
};

export default pt;
