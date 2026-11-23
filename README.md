# MOBA Manager

Jogo de gerenciamento de uma equipe de e-sports que disputa um MOBA fictício. Feito em **Godot 4.7.2** (GDScript).
O foco é a **pura administração de pessoas e números**: elenco, contratos, ego, treino, draft, finanças e competições.

**Publicação planejada:** itch.io, com versão jogável no navegador.

## Documentação

| Documento | Conteúdo |
|---|---|
| [docs/GDD.md](docs/GDD.md) | Design do jogo: tudo o que já foi decidido |
| [docs/ARQUITETURA.md](docs/ARQUITETURA.md) | Estrutura do projeto, quem cuida de quê, fluxo de trabalho |
| [docs/CONTRATO.md](docs/CONTRATO.md) | Como a lógica e a interface conversam |
| [docs/comunicacao/](docs/comunicacao/README.md) | Mensagens entre os assistentes |
| [AGENTS.md](AGENTS.md) | Instruções para assistentes de IA |

## Equipe

| Quem | Papel |
|---|---|
| Dono do projeto | Decide o design e as prioridades |
| Claude | Lógica: arquitetura, regras, dados, simulação, save |
| GPT | Apresentação: telas, arte, animações, sons |

## Como abrir

1. Clone ou baixe o repositório.
2. Na Godot 4.7.2, clique em **Importar** e selecione o arquivo `project.godot`.

## Status

Fase 1 em andamento: tela inicial (GPT) e estado do jogo, saves e gerador de jogadores (Claude) prontos.
