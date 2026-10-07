import type { Dictionary } from './types';

const pt: Dictionary = {
  meta: {
    title: 'Lucena: treine finais de xadrez contra o Maia e o Stockfish',
    description:
      'Aprenda xadrez pelos finais. Treine finais de xadrez contra o Maia, que joga como gente do seu nível, até o Stockfish na força máxima, com aulas interativas de dama contra torre, mate de bispo e cavalo e muito mais.',
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
    lead: 'O Lucena coloca você para jogar finais contra o Maia, que joga como gente do seu nível, e depois contra o Stockfish na força máxima.',
    cta: 'Quero ser testador',
    secondary: 'Ver como funciona',
    note: 'Android, versão de testes. Em breve no Google Play.',
    chips: ['Maia 1000–2600', 'Stockfish', 'Aulas interativas'],
  },
  stats: [
    { value: '9', label: 'níveis do Maia, de 1000 a 2600' },
    { value: '12', label: 'aulas de finais clássicos' },
    { value: '25', label: 'aulas para quem está começando' },
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
        body: 'Jogue contra o Maia, um motor de xadrez com rede neural criado por pesquisadores da Universidade de Toronto e treinado em milhões de partidas de pessoas no Lichess. Ele erra e acerta como gente de verdade, do 1000 ao 2600, e cada nível é um adversário com personalidade. Escolha o ritmo, suba degrau por degrau e, quando estiver pronto, enfrente o Stockfish na força máxima.',
        bullets: [
          'Níveis humanos de 1000 a 2600',
          'Relógio com tempo e incremento',
          'Stockfish na força máxima',
        ],
      },
      lessons: {
        title: 'Aulas que dividem o difícil em passos simples',
        body: 'Finais complexos viram etapas curtas e interativas. Você aprende cada ideia, pratica na hora e só segue quando acertar.',
        bullets: [
          'Dama contra torre',
          'Mate de bispo e cavalo',
          'Finais de torre e de peões',
        ],
      },
      levels: {
        title: 'Treino para iniciantes e intermediários',
        body: 'Quem está começando aprende as peças com aulas guiadas. Quem já joga segue a Jornada: desafios por nível de rating, com adversários que têm personalidade.',
        bullets: [
          'Aulas guiadas para quem está começando',
          'Jornada por nível de rating',
          'Estrelas e conquistas para acompanhar o progresso',
        ],
      },
      speedrun: {
        title: 'Speedrun: contra o relógio',
        body: 'Resolva uma sequência de finais o mais rápido que conseguir. Bata o seu recorde e veja a técnica ficar automática.',
        bullets: ['Parciais por etapa', 'Recorde pessoal', 'Vários ritmos'],
      },
      analysis: {
        title: 'Análise da partida',
        body: 'Depois de jogar, reveja lance a lance com a avaliação da engine e descubra onde a vitória escapou ou onde a defesa segurou.',
        bullets: [
          'Barra de avaliação',
          'Melhores lances da engine',
          'Precisão de cada jogador',
        ],
      },
      custom: {
        title: 'Do seu jeito',
        body: 'Tema claro ou escuro, cores do app, peças e tabuleiro, relógio em cima ou embaixo. O app se adapta a você.',
        bullets: [],
      },
    },
  },
  levels: {
    kicker: 'Para todos os níveis',
    title: 'Sabe pouco ou já joga bem? Tem desafio para você',
    beginner: {
      title: 'Está começando',
      body: 'Aprenda como cada peça se move e dá mate com aulas curtas, dicas na hora certa e adversários que jogam no seu ritmo.',
    },
    advanced: {
      title: 'Já joga bem',
      body: 'Converta finais teóricos contra o Maia 2600 e o Stockfish. Se você ganhar a dama contra a torre do Stockfish, a técnica é sua.',
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
