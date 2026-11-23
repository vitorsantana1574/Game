# Arquitetura do projeto

Este documento define **como o projeto é organizado**, **quem cuida de cada parte** e **como as partes conversam**.
Vale para todos que trabalham no repositório: o dono do projeto, o Claude e o GPT.

- O que o jogo **é** (regras, sistemas, decisões de design): [GDD.md](GDD.md)
- Como a lógica e a interface **conversam** (sinais, ações, dados): [CONTRATO.md](CONTRATO.md)
- Como o Claude e o GPT **trocam mensagens**: [comunicacao/README.md](comunicacao/README.md)

---

## 1. Tecnologia

| Item | Escolha | Motivo |
|---|---|---|
| Motor | **Godot 4.7.2**, versão padrão (sem .NET) | Gratuito, leve, projeto todo em texto |
| Linguagem | **GDScript** | Nativa da Godot; não precisa de .NET |
| Renderizador | **Compatibility** (OpenGL) | É o único que funciona na exportação para **navegador** (itch.io) |
| Resolução base | **1920×1080**, escalando para outras telas | Jogo de gerenciamento com muita informação na tela |
| Idioma | **Português do Brasil** | Textos, código comentado e documentos |

## 2. Divisão de responsabilidades

O projeto é dividido em **duas metades que não se misturam**:

| | **Lógica** | **Apresentação** |
|---|---|---|
| **Responsável** | **Claude** | **GPT** |
| **O que é** | Regras, dados, simulação, economia, save | Telas, arte, animações, movimento visual, sons |
| **Pergunta que responde** | "O que acontece?" | "Como isso aparece para o jogador?" |
| **Roda sem tela?** | **Sim**, obrigatoriamente | Não |

### Regra de ouro

> **A lógica nunca depende da interface.** A lógica não sabe que existe tela, botão, sprite ou som.
> **A interface nunca decide regras.** Ela só mostra o estado do jogo e chama as ações definidas no [CONTRATO.md](CONTRATO.md).

Por quê:
- O GPT pode refazer uma tela inteira sem quebrar a simulação.
- O Claude pode mudar uma regra sem quebrar uma tela.
- A simulação roda **sem interface** para testar milhares de temporadas e calibrar o balanceamento.

### Caso especial: a partida

A partida é onde as duas metades mais se encostam, então a divisão precisa ser exata:

- **A simulação (Claude) decide o que acontece e onde:** posições lógicas dos campeões no mapa, quem ataca quem, abates, torres, objetivos, visão, ouro, experiência, texto da narração. O resultado é uma **linha do tempo de eventos** (ver [CONTRATO.md](CONTRATO.md)).
- **O visual (GPT) decide como isso aparece:** sprites, interpolação do movimento entre posições, animações de ataque e habilidade, efeitos, câmera, sons e o painel de narração.

A partida é **simulada primeiro e exibida depois**. O visual "reproduz" a linha do tempo, como um vídeo. Assim, o resultado nunca depende da velocidade do computador ou da animação.

## 3. Estrutura de pastas

```
/
├── AGENTS.md              Instruções para assistentes de IA (leitura obrigatória)
├── CLAUDE.md              Aponta o Claude para o AGENTS.md
├── README.md              Apresentação do projeto
├── project.godot          Configuração do projeto Godot
│
├── docs/                  Documentação
│   ├── GDD.md             O que o jogo é (design)
│   ├── ARQUITETURA.md     Este documento
│   ├── CONTRATO.md        Ponte entre lógica e interface
│   └── comunicacao/       Mensagens entre Claude e GPT
│       ├── README.md      Como usar
│       └── mensagens/     Uma mensagem por arquivo
│
├── core/                  ── LÓGICA (Claude) ──
│   ├── autoload/          Singletons globais (estado do jogo, barramento de sinais)
│   ├── models/            Classes de dados: jogador, campeão, time, técnico, contrato
│   ├── systems/           Sistemas: liga, contratos, treino, ego, economia, reputação
│   └── simulation/        Simulação da partida e do draft
├── data/                  ── DADOS (Claude) ──
│   ├── campeoes/          Definição dos campeões
│   ├── config/            Dificuldades, balanceamento, constantes
│   ├── nomes/             Listas para gerar nomes de jogadores, times e regiões
│   └── narracao/          Modelos de frase da narração
├── tests/                 ── TESTES (Claude) ── testes automáticos da lógica
├── tools/                 ── FERRAMENTAS (Claude) ── simulador de temporadas e balanceamento
│
├── ui/                    ── INTERFACE (GPT) ──
│   ├── telas/             Telas: menu, elenco, contratação, agenda, draft, tabela da liga...
│   ├── componentes/       Peças reaproveitáveis: carta de jogador, barra de energia, botões
│   ├── temas/             Tema visual da Godot (cores, fontes, estilos)
│   └── partida/           Cena visual da partida: mapa, campeões em movimento, narração
├── assets/                ── ARTE (GPT) ──
│   ├── sprites/           campeoes/, monstros/, mapa/, icones/, efeitos/
│   ├── animacoes/         Animações
│   ├── fontes/            Fontes
│   └── CREDITOS.md        Origem e licença de cada arte (criado pelo GPT)
└── audio/                 ── SOM (GPT) ──
    ├── musica/            Trilhas
    ├── efeitos/           Efeitos sonoros
    └── CREDITOS.md        Origem e licença de cada som (criado pelo GPT)
```

## 4. Quem pode escrever onde

Todos podem **ler** tudo. Cada pasta tem **um único dono que escreve**.

| Caminho | Dono | Os outros podem... |
|---|---|---|
| `core/`, `data/`, `tests/`, `tools/` | **Claude** | Ler. Pedir mudanças por mensagem. |
| `ui/`, `assets/`, `audio/` | **GPT** | Ler. Pedir mudanças por mensagem. |
| `docs/GDD.md` | **Claude** (registra as decisões do dono do projeto) | Ler. Sugerir por mensagem. |
| `docs/ARQUITETURA.md`, `docs/CONTRATO.md` | **Claude** | Ler. Pedir mudanças por mensagem. |
| `project.godot` | **Claude** | Pedir mudanças por mensagem (ex.: tamanho da janela, cena inicial). |
| `AGENTS.md`, `CLAUDE.md`, `README.md` | **Claude** | Pedir mudanças por mensagem. |
| `docs/comunicacao/mensagens/` | **Todos** | Criar mensagens novas. Só altera a linha de status de mensagens endereçadas a si. |

**O dono do projeto pode mudar qualquer regra deste documento.** A palavra dele vale mais que qualquer regra aqui.

### Arquivos de cena (`.tscn`)

As cenas da Godot dão conflito quando duas pessoas editam o mesmo arquivo. Por isso:
- **Cenas de tela e da partida visual são do GPT.**
- **A lógica do Claude não tem cenas**: é feita de scripts (`.gd`) e recursos de dados.
- Se uma tela precisa de um dado novo, o GPT pede por mensagem; o Claude expõe o dado no [CONTRATO.md](CONTRATO.md).

## 5. Fluxo de trabalho no Git

- Trabalho direto na branch **`main`**, já que cada um só escreve nas suas pastas.
- **Antes de começar e antes de enviar:** `git pull --rebase` para pegar o trabalho do outro.
- **Commits pequenos e frequentes**, com prefixo de quem fez:
  - `[claude] adiciona gerador de jogadores`
  - `[gpt] cria tela de elenco`
- **Nunca** apagar, mover ou reescrever arquivos da área do outro.
- Se um `git pull` der conflito num arquivo da área do outro, **fique com a versão do outro** e avise por mensagem.

## 6. Convenções de código

| Item | Padrão | Exemplo |
|---|---|---|
| Nomes de arquivos e pastas | `snake_case`, sem acentos | `gerador_jogadores.gd`, `tela_elenco.tscn` |
| Classes (`class_name`) | `PascalCase` | `Jogador`, `Contrato` |
| Funções e variáveis | `snake_case` | `calcular_salario()`, `energia_atual` |
| Constantes | `MAIUSCULAS` | `MAX_JOGADORES` |
| Sinais | verbo no passado, `snake_case` | `jogador_contratado`, `partida_terminou` |
| Idioma dos nomes | Português, sem acentos | `resistencia`, `dominio_campeao` |
| Comentários | Português | |
| Tipagem | **Sempre tipar** variáveis e funções | `var energia: float = 100.0` |

## 7. Conteúdo gerado por IA

- **Código e arquitetura feitos por IA não precisam ser declarados** nas plataformas.
- **Arte, sons, música e textos gerados por IA precisam ser declarados** na página do jogo (itch.io), e o jogo deixa de aparecer para quem usa o filtro "No AI".
- Por isso, **todo arquivo de arte ou som deve ser registrado** em `assets/CREDITOS.md` ou `audio/CREDITOS.md`, com a origem (gerado por IA, pacote gratuito, feito à mão) e a licença.
- **Proibido:** qualquer coisa de League of Legends ou de outros jogos e marcas (campeões, logos, sons, nomes).

## 8. Ordem de construção (Fase 1)

| Etapa | Claude (lógica) | GPT (apresentação) |
|---|---|---|
| 1 | Modelos de dados, gerador de jogadores, estado do jogo | Tema visual, tela inicial, tela de configuração da carreira |
| 2 | Contratos, contratação, técnico | Telas de mercado, contratação e elenco |
| 3 | Agenda, treino, energia, ego | Tela de agenda semanal e perfil do jogador |
| 4 | Campeões e draft | Tela de draft |
| 5 | Simulação da partida (linha do tempo) | Cena visual da partida e painel de narração |
| 6 | Liga, calendário, playoffs | Tabela, calendário, chaveamento |
| 7 | Save/load | Menus de salvar e carregar |
| 8 | Simulador de balanceamento | Ajustes visuais finais |
| 9 | Exportação para navegador | Página do itch.io |

Em cada etapa, o Claude publica primeiro as funções e sinais no [CONTRATO.md](CONTRATO.md), para o GPT poder começar a tela ao mesmo tempo.
